%Michael Craig, 15 June 2015
%This script calculates the fleet-wide emissions rate and emissions mass
%pursuant to the Clean Power Plan.
%INPUTS: econdispatchorplexos (=0 if getting emissions rate for econ
%dispatch calculation of carbon price, =1 if running on PLEXOS output),
%windandsolargeneration (only used if taking in econ dispatch output since
%wind and solar generators are not in the futurepowerfleet array in that
%case), demandscenariosforanalysis (which demand scenario is being
%analyzed; used for getting EE savings), and futurepowerfleet (generator
%info).
%OUTPUTS: cppemissionsrate [lb/MWh], cppemissionsmass [kg] (CPP emissions rate and mass)

function [cppemissionsrate, cppemissionsmass] = CalculateCPPEmissionsRateAndMass(econdispatchorplexos, ...
    windandsolargeneration, demandscenariosforanalysis, futurepowerfleet)

%% NOTES
%For econ dispatch output, fleet does not include wind or solar generators,
%so need to include windandsolargeneration. 

%% GENERAL APPROACH
%Calculate emissions rate per Clean Power Plan using output from economic
%dispatch. See ResearchJournal for details on calculation of emissions
%rate, but in general, the value is calculated as:
%EmissionsFromAffectedFFUnits/(GenByAffectedFFUnits + AllREGeneration +
%5.8%*90%*NuclearGen +
%Cumulative%EESavings*BaselineDemandAfterEE*1.0751*GenerationAsShareOfConsumption).

%Affected units are FF units > 25 MW (coal, NG, & oil). Generation as share
%of consumption is included only if a state is a net importer, meaning
%generation < demand; if generation > demand, then set this value equal to
%1. See ResearchJournal for more details on emissions rate calculation.

%% GET COLUMN NUMBERS
[fleetorisidcol,fleetunitidcol,fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol,fleetregioncol,fleetstatecol,fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleet);
totalannualgencol=find(strcmp(futurepowerfleet(1,:),'TotalAnnualGen(MWh)'));


%% CALCULATE EMISSIONS MASS
%Get CO2 emissions rates
plantco2emrates=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleet,fleetco2emsratecol);
%Get total emissions [kg/MWh*MWh = kg]
cppemissionsmass=sum(plantco2emrates.*cell2mat(futurepowerfleet(2:end,totalannualgencol)));


%% CALCULATE EMISSIONS RATE
%% NUCLEAR GENERATION
%Take 5.8% of total nuclear generation, then apply a 90% CF, and that's
%total nuclear generation included in denominator. 
%Find nuclear generators, then get total annual generation from them, then
%multiply by 5.8% and 90%.

%CPP PARAMETERS
nuclearcf=.9; %defined by CPP
nuclearatrisk=.058; %defined by CPP

%CALCULATION
nucleargenrows=find(strcmp(futurepowerfleet(:,fleetfueltypecol),'Nuclear'));
nucleargen=cell2mat(futurepowerfleet(nucleargenrows,totalannualgencol)); 
totalnucleargen=sum(nucleargen); %sum all nuclear gen
totalnucleargenmodified=totalnucleargen*nuclearatrisk*nuclearcf;


%% RENEWABLE ENERGY GENERATION
%Sum generation by wind, solar and geothermal.
%Note that, for now, excluding biomass from affected sources besides those
%that are coal steam fossil units.

%Get geothermal generation.
geothermalrows=find(strcmp(futurepowerfleet(:,fleetfueltypecol),'Geothermal'));
geothermalgen=cell2mat(futurepowerfleet(geothermalrows,totalannualgencol));

%For econ dispatch output, have wind and solar generation passed in
%separately.
if econdispatchorplexos==0
    %Sum wind, solar & geothermal gen
    totalregen=windandsolargeneration+sum(geothermalgen);
elseif econdispatchorplexos==1
    %Get wind and solar gen
    windrows=find(strcmp(futurepowerfleet(:,fleetfueltypecol),'Wind'));
    windgen=cell2mat(futurepowerfleet(windrows,totalannualgencol));
    solarrows=find(strcmp(futurepowerfleet(:,fleetfueltypecol),'Solar'));
    solargen=cell2mat(futurepowerfleet(solarrows,totalannualgencol));
    %Sum wind, solar and geothermal gen
    totalregen=sum(windgen)+sum(solargen)+sum(geothermalgen);
end


%% EE SAVINGS
%EE savings are calculated by multiplying cumulative % of EE savings by
%2012 baseline demand after EE, and then accounting for generation as share
%of demand. Get cumultaive % of EE savings and baseline from TSD document
%for current scenario analyzing. If put in own EE savings values later,
%will need to modify this. Do this for each state. Then scale final saved
%demand by 7.51% scaling factor, which accounts for T&D losses. Then have
%to account for share of generation in-state.
%First, open TSD doc to get 2012 baseline demand & % savings.
directoryforfiles='C:\Users\mcraig10\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\';
if demandscenariosforanalysis==1 || demandscenariosforanalysis==0 %0 scenario is base case, data for which is in all TSDDocs files, so just use this one
    filetoimport=strcat(directoryforfiles,'CPP_TSDDocs_Scenario1Description_AnnualStateEESavings.xlsx');
elseif demandscenariosforanalysis==4
    filetoimport=strcat(directoryforfiles,'CPP_TSDDocs_Scenario4_LowerEE.xlsx');
end
[~,~,eedata]=xlsread(filetoimport,'Sorted_by_State');
%Now get 2012 baseline demand after EE
%Trim top 3 rows
eedata(1:3,:)=[];
%Turn first row into strings
for i=1:size(eedata,2)
    if isnan(eedata{1,i})==0
        eedata{1,i}=num2str(eedata{1,i});
    end
end
%Get year 2012 and 2030 data columns
year2012col=find(strcmp(eedata(1,:),'2012'));
year2030col=find(strcmp(eedata(1,:),'2030'));
statenamecol=1; datalabelscol=2;
%Get list of states - need to get EE savings for each state
states=unique(futurepowerfleet(2:end,fleetstatecol));
stateeesavings={'State','EE Savings (MWh)'};
for i=1:size(states,1)
    currstate=states{i};
    %Get row of state in EE data
    rowofstateindata=find(strcmp(eedata(:,statenamecol),currstate));
    %Get row for sales after EE and cumulative % savings
    rowofposteesalesforstate=find(strcmp(eedata(rowofstateindata:end,datalabelscol),...
        'Sales after EE'),1)+rowofstateindata-1;
    rowofcumulativesavings2030=find(strcmp(eedata(rowofstateindata:end,datalabelscol),...
        'Net cumulative savings as a percent of sales before EE'),1)+rowofstateindata-1;
    %2012 sales after EE
    salesafteree2012=eedata{rowofposteesalesforstate,year2012col};    
    %Cumulative % savings
    cumulativepercentsavings=eedata{rowofcumulativesavings2030,year2030col};
    %Calculate total EE savings for emissions rate calculation
    currstateeesavings=salesafteree2012*cumulativepercentsavings*1000; %scale from GWh to MWh
    %Save value
    stateeesavings{end+1,1}=currstate;
    stateeesavings{end,2}=currstateeesavings;
end
%Now have to account for share of generation in-state. This value is in
%CPP_TSDDocs_GoalComputation
[~,~,sharegenerationinstatedata]=xlsread(strcat(directoryforfiles,'CPP_TSDDocs_GoalComputation.xlsx'),'Appendix 1 - Proposed Goals');
sharegenerationlabelsrow=find(strcmp(sharegenerationinstatedata(:,1),'State'));
sharegenerationcol=find(strcmp(sharegenerationinstatedata(sharegenerationlabelsrow,:),'State Generation as % of sales'));
%For each state, get share of generation; if <100%, then multiply into EE
%savings and done. If >100%, then just keep EE value as is.
for i=2:size(stateeesavings,1)
    currstate=stateeesavings{i,1};
    %Get % of gen in state
    rowofstate=find(strcmp(sharegenerationinstatedata(:,1),currstate));
    sharegeneration=sharegenerationinstatedata{rowofstate,sharegenerationcol};
    %Check value if <100%; if so, reduce avoided generation. 
    if sharegeneration<1
        stateeesavings{i,2}=stateeesavings{i,2}*sharegeneration;
    end
end
%Scale state EE savings by 1.0751 to account for T&D losses per IPM.
stateeesavings(2:end,2)=num2cell(cell2mat(stateeesavings(2:end,2))*1.0751);
%Get total EE savings
totalavoidedgeneration=sum(cell2mat(stateeesavings(2:end,2)));


%% FOSSIL UNIT GENERATION
%Fossil units are >25 MW and marked as fossil units in parsed file. So find
%plants marked as Fossil and >25 MW and not marked as "New" in PlantName
%column. Also remove plants that have a fuel input of < 250 MMBtu.
% futurepowerfleetforecondispatchforfossilunits=[futurepowerfleetforecondispatch,num2cell(1:size(futurepowerfleetforecondispatch,1))'];
fossilunitsrows=find(strcmp(futurepowerfleet(:,fleetfossilunitcol),'Fossil')); 
fossilunits=futurepowerfleet(fossilunitsrows,:);
%Isolate plants >25 MW
fossilunitsizes=cell2mat(fossilunits(:,fleetcapacitycol));
fossilunits=fossilunits(fossilunitsizes>=25,:);
%Eliminate any plants marked "New"
fleetplantnamecol=find(strcmp(futurepowerfleet(1,:),'PlantName'));
newplantrows=find(strcmp(fossilunits(:,fleetplantnamecol),'New'));
fossilunits(newplantrows,:)=[];
%Eliminate plants that can burn less than 250 MMBtu/hr
fossilunitshr=cell2mat(fossilunits(:,fleetheatratecol));
fossilunitssize=cell2mat(fossilunits(:,fleetcapacitycol));
heatinputperhour=fossilunitshr.*fossilunitssize/1000; %convert to MMBtu/hr
fossilunits=fossilunits(heatinputperhour>=250,:);
%Sum fossil generation
fossilunitsgeneration=cell2mat(fossilunits(:,totalannualgencol));
totalaffectedfossilgeneration=sum(fossilunitsgeneration);


%% FOSSIL UNIT EMISSIONS
%Multiply total generation by each affected fossil unit by its emissions
%rate
fossilunitsco2emrates=cell2mat(fossilunits(:,fleetco2emsratecol));
totalaffectedfossilemissions=sum(fossilunitsco2emrates.*fossilunitsgeneration);


%% EMISSIONS RATE CALCULATION
%Divide total fossil emissions by total fossil generation + RE generation +
%nuclear generation + avoided generation from EE.
%Want in units of lb/MWh. 
%Units now: [kg] / [MWh + MWh + MWh + MWh] 
%Conversion: [kg/MWh] * [2.20462 lb/kg]
kgtolb=2.20462;
cppemissionsrate=totalaffectedfossilemissions*kgtolb/...
    (totalaffectedfossilgeneration+totalavoidedgeneration+totalregen+totalnucleargenmodified);

