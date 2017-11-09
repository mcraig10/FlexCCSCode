%Michael Craig, 19 August 2015
%This script adds a column to futurepowerfleetforplexos that indicates
%whether the unit is an affected EGU under the final Clean Power Plan (1)
%or not (0). 
%Criteria for affected EGUs:
%Affected EGU means a steam generating unit, IGCC, or stationary CT that
%meets relevant applicability conditions in sec. 60.5845.  (pg. 64959).
%Sec. 60.5845: >25 MW, >250 MMBtu/hr of fossil burn, stationary CT that are
%either CC or CHP CT, and commenced construction before 1/8/2014 (pg. 64953). 
%Excludes combined cycle plants that can't burn NG, so does not include
%oil-burning CCs (1508 of pre-FR publication). 
%Definition of base load rating = generation during steady state (see pg.
%64959). 

function [futurepowerfleetforplexos] = IdentifyAffectedEGUsUnderCPP(futurepowerfleetforplexos)

%First get rows of data
[fleetorisidcol, fleetunitidcol, fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol, fleetregioncol, fleetstatecol, fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol, fleetpumpunitscol, fleetpumpeffcol, fleetpumploadcol,...
    fleetccsretrofitcol,fleettruesscapacitycol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);

%Add column for affected EGU indicator
affectedegucol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,affectedegucol}='Affected EGU CPP';

%Now get affected EGUs. Operationalize by looking for following plant
%types: Coal Steam, Combined Cycle, Fossil Waste, IGCC, O/G Steam. All of
%these units are Fossil units. Fossil Waste not listed as steam in parsed
%files, but in EIA860, is marked as steam prime mover, so include. Don't
%include landfill gas since not defined as a natural gas (1550). Above
%units include Pet. Coke and Waste Coal, which are both listed as Coal
%Steam in parsed file (and all Pet. Coke and Waste Coal are marked as Coal
%Steam). All CCs are NG or oil - need to throw out oil units.
%Also want to include venting, SS generators, and dummy SS pump generators
%associated w/ flexible CCS facilities, if any. Can look for 'Venting',
%'SolventStorage', and 'PumpDummy' in UnitID column. 

%First get rows of affected EGUs by plant type.
planttypesofaffectedegus={'Coal Steam';'Combined Cycle';'Fossil Waste';...
    'IGCC';'O/G Steam'};
planttypeofaffectedegusrows=[];
for i=1:size(planttypesofaffectedegus,1)
    currplanttype=planttypesofaffectedegus{i};
    temprows=find(strcmp(futurepowerfleetforplexos(:,fleetplanttypecol),currplanttype));
    %If combined cycle, only include natural gas burning plants
    if strcmp(currplanttype,'Combined Cycle')
        ngccrows=find(strcmp(futurepowerfleetforplexos(temprows,fleetfueltypecol),'NaturalGas'));
        temprows=temprows(ngccrows);
    end
    planttypeofaffectedegusrows=[planttypeofaffectedegusrows;temprows];
end
%Also add any flexible CCS-associated generators - 'SSPump', 'SSPumpDummy',
%'Venting', 'SSVentWhenCharge', 'SSDischargeDummy'
unitidsisolated=futurepowerfleetforplexos(:,fleetunitidcol);
emptyunitids=cellfun('isempty',unitidsisolated);
unitidsisolated(emptyunitids)={''}; %fill in empties w/ empty strings
ventingrowscell=strfind(unitidsisolated,'Venting'); %returns cell w/ empty rows when not venting & # of place in string where Venting starts
continuoussolventrowscell=strfind(unitidsisolated,'ContinuousSolvent'); 
sspumprowscell=strfind(unitidsisolated,'SSPump'); %see prev line description
sspumpdummyrowscell=strfind(unitidsisolated,'SSPumpDummy'); 
ssdischargedummyrowscell=strfind(unitidsisolated,'SSDischargeDummy'); 
ssventwhenchargerowscell=strfind(unitidsisolated,'SSVentWhenCharge'); 
ventingrows=find(not(cellfun('isempty',ventingrowscell))); %gives index of rows of venting generators
continuoussolventrows=find(not(cellfun('isempty',continuoussolventrowscell))); 
sspumprows=find(not(cellfun('isempty',sspumprowscell))); 
sspumpdummyrows=find(not(cellfun('isempty',sspumpdummyrowscell))); 
ssdischargedummyrows=find(not(cellfun('isempty',ssdischargedummyrowscell))); 
ssventwhenchargerows=find(not(cellfun('isempty',ssventwhenchargerowscell))); 
ssandventingrows=[ventingrows;continuoussolventrows;sspumprows;sspumpdummyrows;ssdischargedummyrows;ssventwhenchargerows];
%Combine flexible CCS gens w/ affected EGUs
planttypeofaffectedegusrows=[planttypeofaffectedegusrows;ssandventingrows];

%Sort rows
planttypeofaffectedegusrows=sortrows(planttypeofaffectedegusrows);

%Get generators >=25 MW
gencapacs=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleetforplexos,fleetcapacitycol);
gencapacs=[0;gencapacs]; %add 0 for first row
gensgreaterthan25mw=find(gencapacs>=25);

%Get generators with fuel burn >250 MMBtu/hr
genhrs=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleetforplexos,fleetheatratecol); %in Btu/kWh
genhrs=[0;genhrs]; %add 0 for first row
genfuelburn=genhrs/1000.*gencapacs; %Btu/kWh * 1000kWh/MWh * MMBtu/1E6Btu
genfuelburngreaterthan250=find(genfuelburn>=250);

%Find generators marked "New" (since only existing units are affected). All
%generators in parsed file except nukes come online in 2016 or earlier,
%which means, assuming 3 year construction period for NGCC (and longer for
%coal), all these units began construction before 2014, so all are
%covered. So only "New" units are considered not to have begun construction
%before 1/8/2014. 
fleetplantnamecol=find(strcmp(futurepowerfleetforplexos(1,:),'PlantName'));
newplantrows=find(strcmp(futurepowerfleetforplexos(:,fleetplantnamecol),'New')==0); %DON'T want new units

%Use ismember to aggregate results
affectedegusrows=planttypeofaffectedegusrows(ismember(planttypeofaffectedegusrows,gensgreaterthan25mw)); %gives rows in first array that are in second
affectedegusrows=affectedegusrows(ismember(affectedegusrows,genfuelburngreaterthan250));
affectedegusrows=affectedegusrows(ismember(affectedegusrows,newplantrows));

%Now create array w/ 1s and 0s. Don't need to account for header b/c
%already accounted for affectedegusrows
affectedeguarray=zeros(size(futurepowerfleetforplexos,1)-1,1);
affectedeguarray(affectedegusrows-1)=1; 

%Now add to futurepowerfleet
futurepowerfleetforplexos(2:end,affectedegucol)=num2cell(affectedeguarray);


