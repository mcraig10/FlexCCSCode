%Michael Craig, 3 June 2015
%This script calculates the required carbon price necessary for compliance
%with the Clean Power Plan. 
%INPUTS: future power fleet, file name that has demand profile, file name
%that has wind generation profile, and file name that has solar generation
%profile. (Files are in PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM
%Output\DataFiles folder)
%OUTPUTS: CO2 price that triggers CPP-compliant emissions rate (cppequivalentco2price),
%cell array w/ all tested CO2 prices and the emissions rate and mass limit
%gaps at those prices, and the MISO region-wide emissions rate and mass
%limits.
%CO2 price will be passed into PLEXOS as Shadow Price property to Emissions
%object

function [cppequivalentco2price,carbonpricesandemissionsmassgap,misoemissionsmasslimit]=...
    CalculateCarbonPriceForCompliance(futurepowerfleetforplexos,...
    demandfilenames,csvfilenamewithwindgenprofiles,csvfilenamewithsolargenprofiles,...
    demandscenarioforanalysis,modelhydrowithmonthlymaxenergy,hydroratingfactors,...
    usenldc,groupplants,removehydrofromdemand,testlowermasslimit,masslimitscalar, pc)

%% 
if strcmp(pc,'work')
    dirforfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output';
elseif strcmp(pc,'personal')
    dirforfiles='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output';
end

%% GET COLUMN NUMBERS OF FLEET
[fleetorisidcol, fleetunitidcol, fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol, fleetregioncol, fleetstatecol, fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol, fleetpumpunitscol, fleetpumpeffcol, fleetpumploadcol,...
    fleetccsretrofitcol,fleettruesscapacitycol,fleetaffectedegucol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);
fleetvomcol=find(strcmp(futurepowerfleetforplexos(1,:),'VOMPerMWhCalculated'));

%% COPY FLEET FOR ECON DISPATCH
futurepowerfleetforecondispatch=futurepowerfleetforplexos;

%% SHRINK PLANT FLEET SIZE
%Only shrink fleet size if haven't already groupled plants together
if groupplants==0
    %Plant fleet size for MISO is ~1,800 in both the base case and under
    %compliance with CPP, even after aggregating oil-fired generators to plant
    %level, if don't do additional grouping (as indiciated by groupplants
    %variable. To shrink plant fleet size, aggregate NGCTs, oil-fired facilities,
    %and LF Gas facilities.
    %LF Gas: ~250 generators, with a capacity <1 GW. Aggregate to single
    %facility w/ capacity-weighted average HR & CO2 emissions rate & VOM. (Most
    %HRs & CO2 values are the same, rest are similar, & all VOM values same.)
    %NGCTs: ~500 generators w/ capacity of 17 GW. Lots of variability in HR,
    %CO2 ems rate, & VOM.
    %Oil-fired facilities: ~400 generators w/ capacity of ~8.5 GW.
    
    %LANDFILL GAS
    %Find rows of LF Gas facilities
    lfgasrows=find(strcmp(futurepowerfleetforecondispatch(:,fleetfueltypecol),'LF Gas'));
    %Get capacity, HR, CO2 ems rate,VOM & fuel price of those plants
    lfgascapac=cell2mat(futurepowerfleetforecondispatch(lfgasrows,fleetcapacitycol));
    lfgashr=cell2mat(futurepowerfleetforecondispatch(lfgasrows,fleetheatratecol));
    lfgasvom=cell2mat(futurepowerfleetforecondispatch(lfgasrows,fleetvomcol));
    lfgasco2emsrate=cell2mat(futurepowerfleetforecondispatch(lfgasrows,fleetco2emsratecol));
    lfgasfuelprice=cell2mat(futurepowerfleetforecondispatch(lfgasrows,fleetfuelpricecol));
    %Get capacity weights
    totallfgascapac=sum(lfgascapac);
    lfgascapacweights=lfgascapac/totallfgascapac;
    %Get capacity-weighted values
    lfgashravg=sum(lfgashr.*lfgascapacweights);
    lfgasvomavg=sum(lfgasvom.*lfgascapacweights);
    lfgasco2emsrateavg=sum(lfgasco2emsrate.*lfgascapacweights);
    lfgasfuelpriceavg=sum(lfgasfuelprice.*lfgascapacweights);
    %Delete old LF Gas facilities
    futurepowerfleetforecondispatch(lfgasrows,:)=[];
    %Add new aggregate LF Gas facility, manually add in HR & VOM & CO2 ems & fuel
    %price. Arbitrarily put LF Gas facility in Illinois - doesn't matter.
    futurepowerfleetforecondispatch=AddSingleNewPlantIntoFutureFleetCellArray(futurepowerfleetforecondispatch,...
        'LF Gas','Illinois',totallfgascapac);
    futurepowerfleetforecondispatch{end,fleetheatratecol}=lfgashravg;
    futurepowerfleetforecondispatch{end,fleetvomcol}=lfgasvomavg;
    futurepowerfleetforecondispatch{end,fleetco2emsratecol}=lfgasco2emsrateavg;
    futurepowerfleetforecondispatch{end,fleetfuelpricecol}=lfgasfuelpriceavg;
end

%% REMOVE FLEXIBLE CCS GENERATORS FROM FLEET
%If adding flexible CCS to fleet, then will have venting and solvent
%storage associated generators in the PLEXOS fleet, but these aren't real
%generators; rather, they represent the additional capacity the flexible
%CCS generator can achieve by using its solvent storage or venting. When
%calculating the CO2 equivalent price, the venting and solvent storage
%facilities will be eliminated from the fleet.
%Find rows of generators, and make sure not empty (if
%empty, then can skip rest of section, which means didn't add flexible
%CCS). 
%To use strfind, need a full cell array, but some futurepowerfleet unit IDs
%are empties; therefore, create a temporary copy of the unit IDs, fill in
%empty cells, and search in that; row #s will be same as futurepowerfleet.
unitidsisolated=futurepowerfleetforecondispatch(:,fleetunitidcol);
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
clear unitidsisolated emptyunitids;
if not(isempty(ssandventingrows)) %if SS or venting generators in fleet
    %Remove rows from fleet
    futurepowerfleetforecondispatch(ssandventingrows,:)=[];
end

%% CALCULATE NET DEMAND
%Load demand
[~,~,demanddata]=xlsread(fullfile(dirforfiles,demandfilenames{1}));

%TRANSLATE HOURLY DEMAND TO VERTICAL FORMAT
%Demand format: Year, Month, Day, then hours 1-24 demand. So need to go
%down each row, copy values in row for columns 4:27, and add to vertical
%array
demandhour1col=find(strcmp(demanddata(1,:),'Day'))+1;
hourlydemand=zeros((size(demanddata,1)-1)*(size(demanddata,2)-demandhour1col+1),1);
for i=2:size(demanddata,1)
    demandthisday=cell2mat(demanddata(i,demandhour1col:(demandhour1col+23)));
    currday=i-1;
    firsthrofday=(currday-1)*24+1;
    lasthrofday=currday*24;
    hourlydemand(firsthrofday:lasthrofday)=demandthisday';
end

%Only need to calculate NLDC not already using net demand; if already using
%net demand, then demand imported above will already be net load.
if usenldc==1
    hourlynetdemand=hourlydemand;
elseif usenldc==0
    %% SOLAR AND WIND
    %Calculate hourly net demand by subtracting out solar and wind generation
    %from demand. Need to:
    %1) Read in data files for demand, wind & solar
    %2) Get hourly wind & solar generation
    %3) Subtract hourly wind and solar data from demand
    %Also subtract our hydro demand if modelhydrowithmonthlymaxenergy==0 (i.e.,
    %if modelign hydro plants w/ rating factor, no tmonthly max energy)
    
    %Load wind and solar gen
    [~,~,windcfs]=xlsread(fullfile(dirforfiles,csvfilenamewithwindgenprofiles));
    [~,~,solarcfs]=xlsread(fullfile(dirforfiles,csvfilenamewithsolargenprofiles));
    
    %WIND
    %Get hourly wind generation
    %First, get wind generators
    windrows=find(strcmp(futurepowerfleetforecondispatch(:,fleetfueltypecol),'Wind'));
    windgenerators=futurepowerfleetforecondispatch(windrows,:);
    %Wind generation data is in hourly increments, with columsn being a diff
    %generator. Columns of wind gen are labelled 'ORIS-' - so need to add dash
    %before trying to find wind generators' column.
    %For each wind generator, find column w/ CF data, then multiply hourly CFs
    %w/ capacity & save to array
    hourlywindgen=zeros(size(windcfs,1)-1,size(windrows,1)); %-1 to account for header
    for i=1:size(windgenerators,1)
        %Convert ORIS ID to right label
        windgenlabel=strcat(windgenerators{i,fleetorisidcol},'-');
        %Get CF column
        windcfcol=find(strcmp(windcfs(1,:),windgenlabel));
        %Multiply hour CFs by capacity
        windgencapac=windgenerators{i,fleetcapacitycol};
        windgengen=cell2mat(windcfs(2:end,windcfcol))/100*windgencapac;
        %Save to hourlywindgen
        hourlywindgen(:,i)=windgengen;
    end
    %Sum hourly wind generation
    totalhourlywindgen=sum(hourlywindgen,2);
    
    
    %SOLAR
    %Get hourly solar generation - same format as wind.
    %Get solar gens
    solarrows=find(strcmp(futurepowerfleetforecondispatch(:,fleetfueltypecol),'Solar'));
    solargenerators=futurepowerfleetforecondispatch(solarrows,:);
    %For each solar generator, find column w/ CF data, then multiply hourly CFs
    %w/ capacity & save to array
    hourlysolargen=zeros(size(solarcfs,1)-1,size(solarrows,1)); %-1 to account for header
    for i=1:size(solargenerators,1)
        %Convert ORIS ID to right label
        solargenlabel=strcat(solargenerators{i,fleetorisidcol},'-');
        %Get CF column
        solarcfcol=find(strcmp(solarcfs(1,:),solargenlabel));
        %Multiply hour CFs by capacity
        solargencapac=solargenerators{i,fleetcapacitycol};
        solargengen=cell2mat(solarcfs(2:end,solarcfcol))/100*solargencapac; %divide by 100 b/c using RFs in PLEXOS not CFs
        %Save to hourlysolargen
        hourlysolargen(:,i)=solargengen;
    end
    %Sum hourly solar generation
    totalhourlysolargen=sum(hourlysolargen,2);
    
    %Subtract total hourly wind and solar gen from demand
    hourlynetdemand=hourlydemand-totalhourlysolargen-totalhourlywindgen;
    
    %Remove wind and solar generators
    windandsolarrows=vertcat(windrows,solarrows);
    futurepowerfleetforecondispatch(windandsolarrows,:)=[];
    
    %Sum total wind and solar annual generation so can pass into economic
    %dispatch function.
    totalannualsolarandwindgeneration=sum(totalhourlysolargen)+sum(totalhourlywindgen);
    
    
    %% HYDRO
    %Now handle hydro capacity, which are treated differently dpeending on
    %whether using capacity factors or max monthly energy. If max monthly
    %eneryg, drop from fleet. If modeling w/ rating factors, though, can account for them
    %just like wind and solar below, so leave them in the fleet. Hydro only
    %accounts for ~2 GW in the system, so dropping them shouldn't have large
    %effect.
    if removehydrofromdemand==0
        if modelhydrowithmonthlymaxenergy==1
            hydrorows=find(strcmp(futurepowerfleetforecondispatch(:,fleetfueltypecol),'Hydro'));
            futurepowerfleetforecondispatch(hydrorows,:)=[];
        elseif modelhydrowithmonthlymaxenergy==0
            %For each hydro plant, convert monthly rating factor to generation amount,
            %stack up generation for each month, then add up.
            hydrorows=find(strcmp(futurepowerfleetforecondispatch(:,fleetfueltypecol),'Hydro')); %will use this later to eliminate hydro columns
            hydroplants=futurepowerfleetforecondispatch(hydrorows,:);
            annualhourlyhydrogen=zeros(size(hourlynetdemand,1),size(hydroratingfactors,2)-1); %-1 on ratingfactors to account for first column of ORIS IDs
            for i=2:size(hydroratingfactors,1)
                %Get current ORIS and rating factors
                currhydrooris=hydroratingfactors(i,1);
                currplantratingfactors=hydroratingfactors(i,2:end);
                %Find row in future power fleet
                rowinfleet=find(strcmp(hydroplants(:,fleetorisidcol),num2str(currhydrooris)));
                %Get capacity of plant
                hydroplantcapac=hydroplants{rowinfleet,fleetcapacitycol};
                %For each month RF, multiply capacity by RF/100 to get hourly
                %generation in that month, then expand for # hours in month.
                %Number days in each month
                daysinmonth=[31,28,31,30,31,30,31,31,30,31,30,31];
                currplantannualhourlygen=[];
                for monthctr=1:size(daysinmonth,2) %2: b/c 1st col = row headers
                    %Get days in current month & RF of current month
                    numhoursinmonth=daysinmonth(monthctr)*24;
                    currratingfactor=currplantratingfactors(monthctr);
                    %Get hourly generation this month
                    currhourlygen=currratingfactor/100*hydroplantcapac;
                    %Now expand for number hours in month
                    hourlygenthismonth=repmat(currhourlygen,numhoursinmonth,1);
                    %Now add to hourly gen array for whole year
                    currplantannualhourlygen=[currplantannualhourlygen;hourlygenthismonth];
                end
                %Now add annual generation for this plant to generation by all
                %other plants
                annualhourlyhydrogen(:,i-1)=currplantannualhourlygen;
            end
            
            %Sum all hourly hydro generation
            totalannualhydrogen=sum(annualhourlyhydrogen,2);
            %Subtract total hourly hydro gen from demand
            hourlynetdemand=hourlynetdemand-totalannualhydrogen;
            %Remove hydro generators
            futurepowerfleetforecondispatch(hydrorows,:)=[];
        end
    end
end

%% GET EMISSIONS MASS LIMITS UNDER CLEAN POWER PLAN
%EMISSIONS MASS: ADD MASS FOR ALL STATES
%Two masses possible: for existing units only and new and existing units
%only. Mass standards only apply to affected EGUs (pg. 882,892 of final
%rule). Use existing units only for now.

%Import data
if strcmp(pc,'work')
    emissionsmassfiledir='C:\Users\mtcraig\Desktop\EPP Research\Databases\EPA IPM Final Clean Power Plan Files';
elseif strcmp(pc,'personal')
    emissionsmassfiledir='C:\Users\mcraig10\Desktop\EPP Research\Databases\EPA IPM Final Clean Power Plan Files';
end
emissionsmassfilename='tsd-cpp-emission-performance-rate-goal-computation-appendix-1-5.xlsx';
[~,~,emissionsmasslimitsdata]=xlsread(fullfile(emissionsmassfiledir,emissionsmassfilename),'Appendix 5- State Goals');
%Rows and columns of data
dataheaderrow=4; %need 'Average Annual Affected Source Mass Goals (Short Tons)'
statecolunderdataheader=1; %State names go down 1st row where header is listed
year2030masslimitrow=5; %same row as 'State' label

%Get data columns
firstcolwithdata=find(strcmp(emissionsmasslimitsdata(dataheaderrow,:),'Average Annual Affected Source Mass Goals (Short Tons)'));
statecol=firstcolwithdata+statecolunderdataheader-1;
year2030masslimitcol=find(strcmp(emissionsmasslimitsdata(year2030masslimitrow,:),'Final'));

%Now, for each state in MISO, find mass limit for existing units
statemasslimits={'State','MassLimitExisting'};
statemasslimitsexistinglimitcol=2;
statesinregion=unique(futurepowerfleetforplexos(2:end,fleetstatecol));
%When group plants, label them as state of 'MISO'. Eliminate MISO from
%state names here.
if find(strcmp(statesinregion,'MISO'))
    misorow=find(strcmp(statesinregion,'MISO'));
    statesinregion(misorow)=[];
end
for i=1:size(statesinregion,1)
    %Get curr state & limit (given in short tons)
    currstate=statesinregion{i};
    emissionsmasslimitsrow=find(strcmp(emissionsmasslimitsdata(:,statecol),currstate));
    currmasslimitexisting=emissionsmasslimitsdata{emissionsmasslimitsrow,year2030masslimitcol};
    %Save data
    statemasslimits{end+1,1}=currstate;
    statemasslimits{end,statemasslimitsexistinglimitcol}=...
        currmasslimitexisting;
end
%Sum limits to get MISO total
finalcppemissionsmasslimitmiso=sum(cell2mat(statemasslimits(2:end,statemasslimitsexistinglimitcol))); %short tons
%Convert limits to kg for comparison to output from economic dispatch
%function below. [907.185 kg/short ton]
shorttontokg=907.185;
finalcppemissionsmasslimitmiso=finalcppemissionsmasslimitmiso*shorttontokg; %kg

%% ADJUST CPP MASS LIMIT IF TESTING LOWER VALUE
%If testing higher emissions reductions (i.e., lower mass limit), then need
%to scale that value down. 
if testlowermasslimit==1 
    finalcppemissionsmasslimitmiso=finalcppemissionsmasslimitmiso*masslimitscalar;
end

%% SAVE MASS LIMIT IN CELL ARRAY 
misoemissionsmasslimit={'MassExisting(kg)';
    finalcppemissionsmasslimitmiso};

%% RUN ECONOMIC DISPATCH
%Iterate through a series of carbon prices, beginning at 0 and moving up in
%$10 increments. Each time, check output against rate limit. (Also check
%against mass limit & save results.)
%If not below rate, increment up. If did satisfy, then run $5 lower and
%save that output too.
emissionsmassgap=1000; %set to arbitrary positive value
carbonpricesandemissionsmassgap={'CarbonPrice($/ton)','EmsMassGap(kg)'};
emissionsmassgapcol=find(strcmp(carbonpricesandemissionsmassgap(1,:),'EmsMassGap(kg)'));
carbonpricecol=find(strcmp(carbonpricesandemissionsmassgap(1,:),'CarbonPrice($/ton)'));
carbonpricectr=0; endrun=0;
while emissionsmassgap>0
    %Define carbon price ($/ton) (conversion handled in RunEconDispatch...)
    carbonprice=carbonpricectr*10;
    carbonprice
    
    %Function runs economic dispatch for each hour for full year, and outputs
    %total annual emissions in terms of a mass and rate value
    %INPUTS: plant fleet, net demand, carbon price to test
    %OUTPUTS: emissions mass [kg] given dispatching of plants w/ CO2 price
    [emissionsmasscppaffectedegu] = RunEconDispatchWithCarbonPrice(futurepowerfleetforecondispatch,...
        hourlynetdemand,carbonprice);
    
    %Update gap
    emissionsmassgap=emissionsmasscppaffectedegu-finalcppemissionsmasslimitmiso;
    %Save gap
    carbonpricesandemissionsmassgap{end+1,carbonpricecol}=carbonprice;
    carbonpricesandemissionsmassgap{end,emissionsmassgapcol}=emissionsmassgap;
    
    %Test if solved mass < CPP mass (gap < 0) - if so, then continue to run
    %@ $2 less increments.
    if emissionsmassgap<0 && carbonprice>0
        while emissionsmassgap<0
            %Subtract 2 from carbon price
            carbonprice=carbonprice-2;
            carbonprice
            
            %Rerun economic dispatch
            [emissionsmasscppaffectedegu] = RunEconDispatchWithCarbonPrice(futurepowerfleetforecondispatch,...
                hourlynetdemand,carbonprice);
            
            %Update gaps
            emissionsmassgap=emissionsmasscppaffectedegu-finalcppemissionsmasslimitmiso;
            %Save gaps
            carbonpricesandemissionsmassgap{end+1,carbonpricecol}=carbonprice;
            carbonpricesandemissionsmassgap{end,emissionsmassgapcol}=emissionsmassgap;
            
            %Test if solved mass now > CPP mass - if so, increment CO2 price up
            %by 1.
            if emissionsmassgap>0
                %Add 1 to carbon price
                carbonprice=carbonprice+1;
                carbonprice
                
                %Rerun economic dispatch
                [emissionsmasscppaffectedegu] = RunEconDispatchWithCarbonPrice(futurepowerfleetforecondispatch,...
                    hourlynetdemand,carbonprice);
                
                %Update gaps
                emissionsmassgap=emissionsmasscppaffectedegu-finalcppemissionsmasslimitmiso;
                %Save gaps
                carbonpricesandemissionsmassgap{end+1,carbonpricecol}=carbonprice;
                carbonpricesandemissionsmassgap{end,emissionsmassgapcol}=emissionsmassgap;
                
                %Set emissionsrategap>0 so exit while loop
                emissionsmassgap=1;
                endrun=1;
            end
        end
    elseif emissionsmassgap<0 && carbonprice==0
        endrun=1;
    end
    
    %Increment counter
    carbonpricectr=carbonpricectr+1;
    if endrun==1
        emissionsmassgap=-1;
    end
end

%% DETERMINE CARBON PRICE
%Determine carbon price that minimally satisfies emissions rate limit.
emissionsmassgaps=cell2mat(carbonpricesandemissionsmassgap(2:end,emissionsmassgapcol));
%Get negative value closest to zero; isolate negatives, then get max
negativeemissionsgaps=emissionsmassgaps(emissionsmassgaps<0);
smallestcompliantemissionsgap=max(negativeemissionsgaps);
%Now look up carbon price
rowofemsgap=find(emissionsmassgaps==smallestcompliantemissionsgap);
allcarbonprices=cell2mat(carbonpricesandemissionsmassgap(2:end,carbonpricecol));
cppequivalentco2price=allcarbonprices(rowofemsgap);





















