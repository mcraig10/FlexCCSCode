%Michael Craig
%1/18/15
%This script creates an Excel file formatted for importing into PLEXOS and
%calls a separate function that creates Excel files for PLEXOS of demand
%profiles in 2030. The Excel created by this script includes generator info
%as well as demand datafile info and spatial (zone, node, regional) info. 

%% PARAMETERS
%WHICH PC RUNNING ON******************************************************
%Set whether running on work or personal PC.
pc='personal' %'work' or 'personal'
%*************************************************************************

%CARBON CAPTURE AND SEQUESTRATION TOGGLES**********************************
%Capacity of CCS retrofits to add to the fleet in MW
mwccstoadd=2000 %MW

%flexibleccs toggles whether to add flexible (1) or inflexible (0) CCS
%facilities.
flexibleccs=1

%Allow / disallow venting at flexible CCS unit. (Affects venting and
%venting when charging unit.)
allowventing=0

%If not including CCS, set flexbileccs to zero
if (mwccstoadd==0) flexibleccs=0; end;
%**************************************************************************

%SOLVENT STORAGE TANK SIZE*************************************************
%Solvent storage tank size for flexible CCS. Value given is # of hours at
%full output that can be enabled by discharging stored solvent.
solventstoragesize=1;
%Set SS tank size to 0 if inflexbile CCS (since no SS)
if flexibleccs==0
    solventstoragesize=0;
end
%**************************************************************************

%WIND PARAMETERS***********************************************************                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              **********************************
%WIND CAPACITY ADDITION
%Capacity of wind to add to base fleet
mwwindtoadd=0

%GATHER WIND AND SOLAR GENERATION PROFILES
%Often turn off wind and solar generation profile gathering as it takes a
%long time. Set toggle to 1 if want generation profiles.
gatherwindandsolarprofiles=1
%**************************************************************************

%SET HIGHER EMISSIONS REDUCTION TARGET*************************************
%Use this parameter to achieve greater emissions reductions than would be
%achieved under the CPP. The parameter scales down the mass limit set by
%the CPP. The value of this scalar is calculated in the file
%StateFactSheetsData_3Dec2015 in the Databases\Final CPP\State Fact Sheets
%folder. The default value is 0.7182 - this achieves a 50% reduction from
%2012 levels in 2030 in our region of analysis. The Clean Power Plan, on
%the other hand, achieves a 30.4% reduction. Note that this is NOT sayign
%the CPP achieves all these reductions - other factors contribute to this
%reduction. I could not find state-specific baseline 2030 emissions to
%isolate the effect of the CPP. 
testlowermasslimit=1 %set to 1 if want to reduce limit, 0 if not
masslimitscalar=.7182 %.7182 is default value - see above comment.
if (testlowermasslimit==0) masslimitscalar==1; end;
%**************************************************************************

%NATURAL GAS PRICE SCENARIOS***********************************************
%Alter natural gas prices in IPM in order to run high/low NGs. Do this w/ a
%scalar to manipulate NG prices up & down.
runnatgaspricescenario=0
if runnatgaspricescenario==1
    %Set scenario to run (if running one) 
    ngpricescenario='High' %'Low' or 'High'
        
    %If not running scenario, set scalar to 1 (so doesn't change NG prices);
    %otherwise set scalar based on scenario. Calculated scalars in Excel using
    %Goal Seek (databases -> Natural Gas Price Data -> NaturalGasUnits...csv)
    %such that capacity-weighted natural gas price of fleet = $3.5 or $6.5
    %per MMBtu for low & high gas price scenarios, respectively. (Just a mean
    %natural gas price gives essentially the same scalars.)
    if (strcmp(ngpricescenario,'High')) ngpricescalar=1.21; elseif (strcmp(ngpricescenario,'Low')) ngpricescalar=0.65; end;
else
    ngpricescalar=1;
end
%**************************************************************************

%CLEAN POWER PLAN PARAMETERS***********************************************
%CPP COMPLIANCE SCENARIO
%Which CPP compliance scenario parsed file to import
compliancescenario='Mass'
% compliancescenario='Base'

%DEMAND SCENARIO
%Define demand scenario for analysis
%Scenarios: 0 = base case (no extra EE relative to base case), 1 (~1%/yr EE
%savings - EE rate assumed, after ramp up, in IPM runs for final CPP)
demandscenarioforanalysis=1 %options: 0,1
%scaleenergyefficiencysavings is used to scale energy efficiency savings up
%or down depending on desired amount. Basically, when using
%demandscenarioforanalysis=1, get some EE % savings for each state; this
%scalar is multiplied into that % savings to increase/reduce % savings.
%Resulting value is then used to scale 2030 pre-EE demand up/down. Only set
%this value to increments of tenths. 
scaleenergyefficiencysavings=0.5
%**************************************************************************

%CARBON PRICE CALCULATIONS*************************************************
%WHETHER TO FORCE COMPLIANCE WITH CLEAN POWER PLAN
%Following toggle controls whether you determine and include in the UCED a
%CO2 price that enforces compliance with CPP. Set this to 1 in order to
%include CO2 price. Only turn this off when running base case, i.e. no CPP.
calculatecppco2price=1

%FORCE CO2 PRICE TO CERTAIN VALUE
%Want to run some scenarios in which we force CO2 price to a certain value.
%If do this, then don't want to calculate CPP-equivalent CO2 price, but
%rather just include imposed CO2 price.
setco2pricetoinputvalue=0
co2priceinput=10 %$/ton

%Ensure that if calculate CPP-equivalent CO2 price, don't want to force CO2
%price.
if (calculatecppco2price==1) setco2pricetoinputvalue=0; end;
%Zero out input co2 price if not setting co2 price based on that value
if (setco2pricetoinputvalue==0) co2priceinput=0; end;
%**************************************************************************
%RESERVE REQUIREMENTS******************************************************
%Indicate whether to use NREL or current (2015) MISO reserve requirements.
reserverequirements='nrel' %'nrel' or 'miso'
%**************************************************************************

%RAMP RATES****************************************************************
%Two sets of ramp rates available, PHORUM or scaled PHORUM such that coal
%plants ramp at roughly ~1.5-3%/min. in agreement w/ published values. If
%variable = 1, then use scaled values; if = 0, use unscaled values. Scaled
%values are 5x PHORUM values. 
usescaledramprates=1 %default=1
%**************************************************************************

%FLEET COMPRESSION*********************************************************
%Following parameters are used to shrink the size of the optimization to
%improve computational tractability when adding flex CCS units.
%GROUP TOGETHER OIL, LFGAS AND NGCT PLANTS
%Indicates whether group together oil plants, LF Gas plants, and NGCTs to
%shrink fleet size.
groupplants=1

%WHETHER TO INCLUDE MIN STABLE LOAD FOR CTS, MSW, LFGAS, FWASTE
%Set whether to include min stable load on all CTs (NG & oil), MSW, LF Gas,
%& Fwaste plants (include min load if =1)
includeminloadCTmswLFGASfwaste=1

%WHETHER TO INCLUDE NLDC
%Set whether to use NLDC for demand (if =1, then use NLDC). Will subtract
%wind, solar & hydro generation from demand to create NLDC
usenldc=0

%WHETHER TO TAKE OUT HYDRO FROM DEMAND
%Toggles whether hydro is taken out of demand. Force to 1 if using NLDC.
removehydrofromdemand=1

%WHETHER TO COMPRESS ALL WIND GENERATORS INTO SINGLE GENERATOR
%When equal to 1, below parameter will group all wind generators into
%single generator. If using NLDC, this is obviated, since wind will be
%rmeoved from demand. The purpose of doing this is to avoid bouncing back &
%forth b/wn equally-zero-cost wind generators in solving MIP.
groupwindandsolarplants=1

%If using NLDC, set other parameters accordingly.
if usenldc==1
    groupwindandsolarplants=0;
    removehydrofromdemand=1;
end
%**************************************************************************

%OTHER PARAMETERS (RARELY CHANGED)*****************************************
%INPUT NOX AND SO2 PRICES
%Values taken from CSAPR final rule. So2 group: Table III-1. Emission
%Allowance Prices: RIA, Table 7-12. NOx price for annual program. Values
%given in $2007 - convert to $2011, which is what IPM costs are in.
tontokg=907.185;
cpi2007=207.342;
cpi2011=224.939;
noxandso2prices={'NOxCSAPR',600/tontokg;'SO2CSAPR1',1100/tontokg;'SO2CSAPR2',700/tontokg};
noxandso2prices(:,2)=num2cell(cell2mat(noxandso2prices(:,2))*cpi2011/cpi2007);

%REGION/ZONE/NODE
%Define region, zone and node name
regionname='MISO';
zonename='MISOZone';
nodename='MISONode';

%HOW TO MODEL MISO
%Two options for modeling MISO: 
%1) As the IPM regions marked MIS_, which only includes areas in the upper Midwest in MISO, such that parts of MO, for
%instance, are not in MISO but parts are. Note that Entergy is not included
%in this. [modelmisowithfullstates=0]
%2) Including only complete states in MISO, such that the following states
%are completely included in MISO: ND, SD, MN, IA, MO, WI, MI, IL and IN.
%This area is equivalent to the EPA's North Central region in the regional
%compliance strategy with the Clean Power Plan. This option has the benefit
%of being able to model each state's emissions rate under the CPP, which
%is not possible to apportion between parts of states, and it also avoids
%the need to split up an emissions mass limit. [modelmisowithfullstates=1]
modelmisowithfullstates=1; 

%HOW TO MODEL HYDRO
%Two options to model hydro: Monthly Max Energy w/ MT Schedule in PLEXOS,
%or monthly capacity factor, which essentially limits hydro to a flat
%amount of generation in each hour based on the CF. 
modelhydrowithmonthlymaxenergy=0; 

%PUMPED HYDRO
%Delete pumped hydro storage facilities (set to 1)
deletepumpedhydro=1;

%HEAT RATE IMPROVEMENT
%Define assumed level of heat rate improvement achievable at coal plants in
%system. For now, single unit input for all plants. Updated 8/6/15 for
%final CPP, which assumes HRI of 4.3% in Eastern Interconnect.
hrimprovement=.043;
hrimprovementassumedbyepa=.043;

%SUPPRESS MIP SOLVER OUTPUT
%MIP solver in PLEXOS, by default, outputs progress messages, task size,
%etc. If suppresssolveroutput=1, this information is not shown. (Controlled
%through Diagnostic object.)
suppresssolveroutput=0;
%**************************************************************************


%% FILE NAME
basefilename=strcat('CPPEEPt',num2str(10*scaleenergyefficiencysavings),...
    'FlxCCS',num2str(flexibleccs),'MW',num2str(mwccstoadd),'WndMW',num2str(mwwindtoadd),...
    'Rmp',num2str(usescaledramprates),'MSL',num2str(includeminloadCTmswLFGASfwaste),...
    'Vnt',num2str(allowventing));
if calculatecppco2price==0
    basefilename=strcat(basefilename,'CO2P0');
end
if runnatgaspricescenario==1
    basefilename=strcat(basefilename,'NG',ngpricescenario);
end
if testlowermasslimit==1
    basefilename=strcat(basefilename,'LwrLmt');
end
if strcmp(reserverequirements,'nrel')
    basefilename=strcat(basefilename,'NRELRes');
end
if usenldc==1
    basefilename=strcat(basefilename,'NLDC');
end
if groupplants==0
    basefilename=strcat(basefilename,'Grp0');
end
if solventstoragesize==1
    basefilename=strcat(basefilename,'SSH1');
end


%% GENERAL PLEXOS PARAMETERS
%Name of model object
nameofmodel='Base';

%% CREATE FLEET AND GATHER DATA
%% RUN FUNCTION THAT PARSES CPP PARSED FILE
%This function reads in the CPP parsed file from EPA, isolates the MISO
%plants, does some processing, and then outputs
%parseddataworetiredwadjustmentsmiso, which contains all the plants in the
%parsed file still operating in 2025. 
[parseddataworetiredwadjustmentsiso] = CPPParsedFileImport...
    (compliancescenario,hrimprovement,modelmisowithfullstates,pc);
'Imported parsed CPP file'

%Replace baghouse retrofit column name w/ somethign w/out commas - messes
%up when try to write fleet to CSV later.
bagcol=find(strcmp(parseddataworetiredwadjustmentsiso(1,:),'Baghouse Retrofit (in conjunction with either dry FGD, ACI+Toxecon, and/or DSI)'));
parseddataworetiredwadjustmentsiso{1,bagcol}='Baghouse Retrofit (in conjunction with either dry FGD or ACI+Toxecon andor DSI)';
clear bagcol

%This function reads in the output of the above function and isolates the
%new plants in the CPP from existing plants that are expected to still be
%operating in 2025. Then it adds on new plants to those existing plants
%depending on the input parameter.
[futurepowerfleetforplexos] = AddNewPlantsToFutureFleet(parseddataworetiredwadjustmentsiso,pc);
'Added new plants to fleet'
%futurepowerfleetforplexos has same format as parsed data file

%% DOWNSCALE OIL-FIRED GENERATORS TO PLANT LEVEL
%Lots of oil-fired generators in IPM; for MISO, there are over 1,100
%oil-fired generators, 932 of which are less than 5 MW in size. (526 are
%between 1 and 2 MW, and 218 are less than 1 MW.) To shrink the model size,
%I downscale oil-fired generators to the plant level, of which there are
%351. Heat rates of oil-fired generators do not significantly differ within
%a plant; for most oil-fired plants, generator heat rates are identical, or
%vary by ~1000 or less Btu/kWh. Additionally, unit commitment parameters
%for oil-fired generators don't vary by size (i.e., assume a linear
%relationship between parameters and plant size), and external values of fuel prices and
%emissions rates are used for oil-fired generators, so there is no worry
%about having to average these (although they should be nearly the same for
%generators within a plant anyways). For these reasons, aggregating
%oil-fired generators to the plant level should not affect model accuracy. 
%Also note that some oil-fired generators do have NOx control techs
%installed; for those generators, I don't downscale them.
[futurepowerfleetforplexos] = DownscaleOilFiredGeneratorsToPlantLevel(futurepowerfleetforplexos);
'Downscaled oil-fired generators'

%% GET WIND AND SOLAR GENERATION PROFILES
%Toggle is used to turn off gathering of wind and solar generation profiles
%when debugging other parts of script; getting this data takes a while and
%so is often turned off. 
if gatherwindandsolarprofiles==1
    % GET WIND DATA FOR NEW WIND POWER PLANTS
    %Gather hourly wind generation data from NREL Eastern Wind Dataset.
    [csvfilenamewithwindgenprofiles,futurepowerfleetforplexos,~,windcapacityfactors]=...
        GatherWindGenerationProfilesFromNRELDataForFutureFleet...
        (futurepowerfleetforplexos, compliancescenario, mwwindtoadd, mwccstoadd, flexibleccs, usenldc, groupwindandsolarplants, pc);
    'Gathered wind generation profiles'
    
    % GET SOLAR DATA FOR NEW SOLAR POWER PLANTS
    %Gather hourly solar generation data from EPA IPM.
    [csvfilenamewithsolargenprofiles,futurepowerfleetforplexos,solarratingfactors] = ...
        GatherSolarGenerationProfilesForFutureFleet...
        (futurepowerfleetforplexos,compliancescenario,mwwindtoadd, mwccstoadd, flexibleccs, usenldc, groupwindandsolarplants, pc);
    'Gathered solar generation profiles'
end

%% AGGREGATE HYDRO PLANTS AND GET MONTHLY MAX ENERGY VALUES
%Call function that combines hydro generators into a single plant and matches
%each plant to either monthly maximum energy value (calculated in
%AnalyzeEIA923HydroMonthlyGeneration script) or a monthly capacity factor
%value (determined w/ modelhydrowithmonthlymaxenergy switch). 
%Monthly max energy is output in MWh here, whereas rating factors are in
%percents.
%NOTE: filling in empty monthly max energy for new plants is hardcoded in
%this function. Revisit if necessary.
%INPUTS: future fleet, compliance scenario indicator, whether model hydro
%w/ monthly max energy or capacity factors (monthly max energy if = 1).
[futurepowerfleetforplexos,hydromonthlymaxenergy,hydroratingfactors]=...
    AggregateHydroPlantsAndGetMonthlyMaxEnergyValues...
    (futurepowerfleetforplexos,compliancescenario,modelhydrowithmonthlymaxenergy,pc);
'Aggregated hydro plants'

%% ADD FUEL PRICE DATA TO FUTURE POWER FLEET
%As of May 26, 2015, fuel prices for each power plant in parsed files are
%claculated by dividing the total fuel cost by total fuel use for each
%plant (yielding a fuel price of $/GJ). 
%The below function calculates this ratio and adds a column to the
%end of the fleet cell array with the fuel operational cost, in $/GJ (as
%needed by PLEXOS). 
%The function relies on a hardcoded fuel price for oil generators, which
%needs to be updated once the final rule comes out (written 5/26/15). 
[futurepowerfleetforplexos] = AddFuelPricesToFleet(futurepowerfleetforplexos);
'Added fuel prices'

%% ADD EMISSIONS RATE DATA TO FUTURE POWER FLEET
%As of April 1, 2015, emissions rates for CPP Parsed Files are calculated
%by dividing total power generation in the parsed files by the total
%emissions. The below function calculates these emissions rates and
%adds columns to the end of the cell array with the emissions rates. 
%For generators without aggregate generation or emissions data (since they
%are not dispatched in IPM), I use a capacity-weighted average emissions
%factor for generator w/ the same fuel and generator type. The emissions
%factor is then converted to an emissions rate using each plant's
%individual heat rate.
%Emissions rate values are output in kg/MWh, as used in PLEXOS.
%Function has hardcoded emissions rates from PHORUM data for oil-fired
%generators.
[futurepowerfleetforplexos] = AddEmissionsRatesToFleet...
    (futurepowerfleetforplexos,hrimprovement,hrimprovementassumedbyepa);
'Added emissions rates'

%% ASSIGN NOX AND SO2 EMISSION PRICES TO GENERATORS
%Following function assigns NOx and SO2 emissions prices, based on CSAPR
%projected values, to generators in model. The NOx and So2 emissions prices
%are set and assigned within the function. Outputs emissions prices in
%$/kg.
[futurepowerfleetforplexos] = AssignNOxAndSO2Prices(futurepowerfleetforplexos,noxandso2prices);

%% AGGREGATE OIL, LFGAS AND NGCT GENERATORS
%In addition to downscaling oil-fired generators to plant level, need to
%further reduce fleet size. Accomplish this by grouping together individual
%oil-fired generators, LF Gas generators, and NGCTs. 
if groupplants==1
    [futurepowerfleetforplexos] = GroupPlants(futurepowerfleetforplexos);
end
'Grouped plants'

%% SCALE NATURAL GAS PRICES IF RUNNING NG PRICE SCENARIO
%Scale natural gas prices if running a natural gas price scenario (high or
%low)
if runnatgaspricescenario==1
    %INPUTS: fleet, scalar for NG prices.
    %OUTPUTS: fleet
    [futurepowerfleetforplexos] = AlterNaturalGasPrices(futurepowerfleetforplexos,ngpricescalar);
end

%% ADD UNIT COMMITMENT PARAMETERS TO FUTURE POWER FLEET 
%UC parameters (min load, min down time, start cost, ramp limits) are derived 
%from PHORUM. See research journal, March 19, 2015, for description of data. 
%Below function takes in future power fleet, imports UC parameters from
%PHORUM, matches each row from futurepowerfleet to a set of UC parameters,
%and stores those values at the end of futurepowerfleet. 
%INPUTS: future fleet, usescaledramprates (indicates whether to use scaled
%or unscaled PHORUM ramp rates), includeminloadCTmswLFGASfwaste (indicates
%whether include min stable load on CTs, MSW, lf gas, & f waste plants)
[futurepowerfleetforplexos] = AddUCParametersToFleet(futurepowerfleetforplexos,usescaledramprates,includeminloadCTmswLFGASfwaste,pc);
'Added UC parameters'

%% RETROFIT GENERATORS WITH CCS
%Below function retrofits generators with CCS. Run script even if no CCS
%added in order to add some column headers to futurepowerfleet (necessary
%for calculations below). If statement inside function skips rest of function if not
%actually adding any MW of CCS.
%INPUTS: futurepowerfleetforplexos, mwccstoadd (MW of CCS to retrofit),
%flexibleccs (if =1, add flexible CCS; if =0, add inflexible CCS).
%OUTPUTS: futurepowerfleetforplexos (includes venting and solvent storage
%generators if adding flexible CCS), regeneratoroversize (% by which regenerator is oversized/undersized; if
%not oversized, value = 0); solventstoragesize (hours of full load
%operation), ccscapacitypenalty (capacity penalty (%) from CCS retrofit),
%stminload (steam turbine min load, as %age ponits below boiler load, so if
%boiler min load is 30%, stminload=10 means st min load is 20%). 
[futurepowerfleetforplexos,regeneratoroversize,ccscapacitypenalty,...
    solventstoragecapacitypenaltyreduction,ventingcapacitypenaltyreduction,stminload] =...
    RetrofitGeneratorsWithCCS(futurepowerfleetforplexos, ...
    mwccstoadd, flexibleccs, pc, solventstoragesize);
'Retrofit CCS'

%% IDENTIFY UNITS AFFECTED BY CLEAN POWER PLAN
%This script adds a column to futurepowerfleetforplexos that marks whether
%the unit is an affected EGU under the final CPP. 
[futurepowerfleetforplexos] = IdentifyAffectedEGUsUnderCPP(futurepowerfleetforplexos);

%% GET NECESSARY COLUMNS OF DATA FROM FUTURE FLEET DATASET
[fleetorisidcol, fleetunitidcol, fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol, fleetregioncol, fleetstatecol, fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol, fleetpumpunitscol, fleetpumpeffcol, fleetpumploadcol,...
    fleetccsretrofitcol,fleettruesscapacitycol,fleetaffectedegucol,fleethrpenaltycol,...
    fleetcapacpenaltycol,fleetsshrpenaltycol,fleetsscapacpenaltycol,fleeteextraperestorecol,...
    fleeteregenpereco2capcol,fleetegridpereco2capandregencol,fleetegriddischargeperestorecol,...
    fleetnoxpricecol,fleetso2pricecol,fleetso2groupcol,fleetco2emsrateforedcol,...
    fleetso2emsrateforedcol,fleetnoxemsrateforedcol,fleethrforedcol,fleetvomforedcol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);

%% DELETE PUMPED STORAGE FACILITIES
if deletepumpedhydro==1
    %Get rows of pumped hydro facilities
    pumpedhydrorows=find(strcmp(futurepowerfleetforplexos(:,fleetplanttypecol),'Pumped Storage'));
    %Delete rows
    futurepowerfleetforplexos(pumpedhydrorows,:)=[];
    'Deleted pumped storage facilities'
end
%Make sure no 'Pumps' units left - don't have UC parameters assigned to
%them, so don't want them staying in. 
if find(strcmp(futurepowerfleetforplexos(:,fleetfueltypecol),'Pumps'))
    'Pumps fuel type still in fleet!'
end

%% 





%% CREATE FILES FOR PLEXOS

%% SLIM FLEET IF USING NLDC
%Save fleet. Do this even if not using NLDC, b/c futurepowerfleetfull is
%input to later functions.
futurepowerfleetfull=futurepowerfleetforplexos;

%If using NLDC, then need to remove wind, solar and hydro from the fleet
%that's input to PLEXOS.
if usenldc==1
    windrows=find(strcmp(futurepowerfleetforplexos(:,fleetfueltypecol),'Wind'));
    solarrows=find(strcmp(futurepowerfleetforplexos(:,fleetfueltypecol),'Solar'));
    hydrorows=find(strcmp(futurepowerfleetforplexos(:,fleetfueltypecol),'Hydro'));
    allrowstoremove=[windrows;solarrows;hydrorows];
    futurepowerfleetforplexos(allrowstoremove,:)=[];
elseif removehydrofromdemand==1
    %If just removing hydro from demand, not other units
    hydrorows=find(strcmp(futurepowerfleetforplexos(:,fleetfueltypecol),'Hydro'));
    allrowstoremove=hydrorows;
    futurepowerfleetforplexos(allrowstoremove,:)=[];
end

%% CREATE FUNCTION FOR CREATING PLEXOS GENERATOR OBJECT NAME
%Name generators in PLEXOS as: ORISID-UNITID
createplexosobjname = @(arraywithdata,orisidcol,unitidcol,rowofinfo) strcat(arraywithdata{rowofinfo,orisidcol},...
        '-',arraywithdata{rowofinfo,unitidcol});

%% SET UP GENERATOR DATA
%OBJECTS*******************************************************************
%Object - declare all objects in model.
objectheaders={'Class','Name'};
%Possible objects (basically class names): Data File, Generator, Fuel, 
%Emission, Region, Zone, Node, Scenario, Line.
%Make generator names ORISCode+UnitID.
objectdata={};
for i=2:size(futurepowerfleetforplexos,1)
    plexosgenname=createplexosobjname(futurepowerfleetforplexos,...
        fleetorisidcol,fleetunitidcol,i);
    objectdata=AddObjectToPLEXOSFile(objectdata,'Generator',plexosgenname);
end

%Categories - I haven't found a use for this sheet yet, so leave empty.
categoryheaders={'Category_ID','Class','Category','Rank','Class_ID','Name'};
categorydata={};

%MEMBERSHIPS***************************************************************
%Memberships - assign relationships between objects, e.g. emissions and
%node. 
%6/15/15: Do NOT add a membership to fuel type - Price property of Fuel
%object will override Fuel Price property of Generator. There's really no
%reason as of today anyways to add Fuel memberships to PLEXOS. 
%Memberships I care about: location (i.e., node), emission.
%Assign fuel type to each generator; SO2, NOx & CO2/CO2CPP emissions to each
%generator; region to each generator.
membershipsheaders={'Parent_Class','Child_Class','Collection','Parent_Object','Child_Object'};
membershipsdata={};
%CO2CPP emission object is for affected EGUs under CPP, whereas CO2 object
%is for rest of generators. Have two emission objects because only CO2CPP
%will have price attached to it to force compliance w/ CPP. 
listofemissions={'NOx';'SO2';'CO2'};
listofallemissions={'NOx';'NOxCSAPR';'SO2';'SO2CSAPR1';'SO2CSAPR2';'CO2';'CO2CPP'};
for i=2:size(futurepowerfleetforplexos,1)
    %Parent class: Generator
    %Child classes: Fuel, Region (also emission)
    %Collections: Fuels, Region (also emissions)
    %Parent obj: generator name
    %Child obj: varies
    
    plexosgenname=createplexosobjname(futurepowerfleetforplexos,...
        fleetorisidcol,fleetunitidcol,i);
    
    %Add Generator-Node membership for all units.
    membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Generator','Node',plexosgenname,...
        nodename);

    %Add Generator-Emissions memberships
    for j=1:size(listofemissions,1)
        curremission=listofemissions{j};
        if strcmp(curremission,'CO2')
            %For CO2, if generator is affected EGU, add 'CO2EGU' membership
            if futurepowerfleetforplexos{i,fleetaffectedegucol}==1
                curremission='CO2CPP';
            end
        elseif strcmp(curremission,'NOx')
            if futurepowerfleetforplexos{i,fleetnoxpricecol}>0
                curremission='NOxCSAPR';
            end
        elseif strcmp(curremission,'SO2')
            if futurepowerfleetforplexos{i,fleetso2groupcol}==1
                curremission='SO2CSAPR1';
            elseif futurepowerfleetforplexos{i,fleetso2groupcol}==2
                curremission='SO2CSAPR2';
            end
        end
        membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Emission','Generator',curremission,...
            plexosgenname);
    end
end

%Attributes - I haven't found a use for this sheet, so skip.
attributeheaders={'Name','Class','Attribute','Value'};
attributedata={};

%PROPERTIES****************************************************************
%Generator properties of interest: Units (always 1), Max Capacity [MW], Min
%Stable Level [MW], Heat Rate [GJ/MWh], VO&M Charge [$/MWh], Rating Factor
%[%], Min Stable Level [MW], Start Cost [$], Max Ramp Up [MW/min.], Max
%Ramp Down [MW/min.], Min Down Time [hours], Production Rate [of NOx, SO2 & CO2
%emissions; kg/MWh], Fuel Price [$/GJ]
%Generator properties of interest for solvent storage (pump) facilities
%only: Pump Units, Pump Load, Pump Efficiency
%UC parameters (min stable level, start cost, max ramp up, max ramp down,
%min down time) are all derived from PHORUM values (imported above). 
propertiesofinterest={'Units';'Max Capacity';'Heat Rate';'VO&M Charge';...
    'Min Stable Level';'Start Cost';'Max Ramp Up';'Max Ramp Down';...
    'Min Down Time';'Production Rate';'Fuel Price'};
propertiesofinterestsolventstorage={'Pump Units';'Pump Load';'Pump Efficiency'};
propertiesheader={'Parent_Class','Child_Class','Collection','Parent_Object',...
    'Child_Object','Property','Band_ID','Value','Units','Date_From','Date_To',...
    'Pattern','Action','Variable','Filename','Scenario','Memo','Period_Type_ID'};
propertiesdata={}; gjtobtu=1.055E-6;
for i=2:size(futurepowerfleetforplexos,1)
    %Create PLEXOS gen name
    plexosgenname=createplexosobjname(futurepowerfleetforplexos,...
            fleetorisidcol,fleetunitidcol,i);
    for j=1:size(propertiesofinterest,1)    
        %Get property value
        if strcmp(propertiesofinterest{j,1},'Units') 
            propertyvalue=1; %value
        elseif strcmp(propertiesofinterest{j,1},'Max Capacity') 
            propertyvalue=futurepowerfleetforplexos{i,fleetcapacitycol};
        elseif strcmp(propertiesofinterest{j,1},'Heat Rate') 
            %If pump units, want HR=1 so don't do below conversion; otherwise, scale for gjtobtu
            if strcmp(futurepowerfleetforplexos{i,fleetplanttypecol},'SSPump')==0
                propertyvalue=futurepowerfleetforplexos{i,fleetheatratecol}*gjtobtu*1000; %Btu/kWh * 1000kWh/MWh * 1.055E-6GJ/Btu
            else
                propertyvalue=1;
            end
        elseif strcmp(propertiesofinterest{j,1},'VO&M Charge') 
            propertyvalue=futurepowerfleetforplexos{i,strcmp(futurepowerfleetforplexos(1,:),'VOMPerMWhCalculated')};
        elseif strcmp(propertiesofinterest{j,1},'Min Stable Level')
            %If flexible CCS generator, base CCS generator should be
            %allowed to go down to 1, so input that value & ignore what's
            %in cell, which is used in group constraints later.
            if flexibleccs==1 && futurepowerfleetforplexos{i,fleetccsretrofitcol}==1
                propertyvalue=1;
            else
                propertyvalue=futurepowerfleetforplexos{i,fleetminloadcol};
            end
        elseif strcmp(propertiesofinterest{j,1},'Start Cost')
            propertyvalue=futurepowerfleetforplexos{i,fleetstartcostcol};
        elseif strcmp(propertiesofinterest{j,1},'Max Ramp Up')
            %If flexible CCS generator, ramp values enforced in group
            %constraint, so input capacity of plant here to allow
            %ramp over full output.
            if flexibleccs==1 && futurepowerfleetforplexos{i,fleetccsretrofitcol}==1
                propertyvalue=futurepowerfleetforplexos{i,fleetcapacitycol};
            else
                propertyvalue=futurepowerfleetforplexos{i,fleetmaxrampupcol};
            end
        elseif strcmp(propertiesofinterest{j,1},'Max Ramp Down')
            %If flexible CCS generator, ramp values enforced in group
            %constraint, so input capacity of plant here to allow
            %ramp over full output.
            if flexibleccs==1 && futurepowerfleetforplexos{i,fleetccsretrofitcol}==1
                propertyvalue=futurepowerfleetforplexos{i,fleetcapacitycol};
            else
                propertyvalue=futurepowerfleetforplexos{i,fleetmaxrampdowncol};
            end
        elseif strcmp(propertiesofinterest{j,1},'Min Down Time')
            propertyvalue=futurepowerfleetforplexos{i,fleetmindowntimecol};
        elseif strcmp(propertiesofinterest{j,1},'Fuel Price')
            propertyvalue=futurepowerfleetforplexos{i,fleetfuelpricecol};
        elseif strcmp(propertiesofinterest{j,1},'Production Rate')
            propertyvalue=[futurepowerfleetforplexos{i,fleetnoxemsratecol};
                futurepowerfleetforplexos{i,fleetso2emsratecol};
                futurepowerfleetforplexos{i,fleetco2emsratecol}];
        end

        %Add row to properties. 
        if strcmp(propertiesofinterest{j,1},'Production Rate')==0 %if not production (emission) rate
            %AddPropertyToPLEXOSFile(propertiesdata,parentclass,childclass,parentobj,...
                %childobj, propertyname, propertyvalue, filename, scenarioname, datefrom, dateto)
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Generator','System',...
                plexosgenname, propertiesofinterest{j,1}, propertyvalue,'','','','');
        else 
            %If production (emission) rate, parent class is 'Emission', and
            %the parent object is the name of the emission, so parent
            %object is set within function. Instead, use parent class here
            %to indicate whether the unit is an affected EGU under CPP and
            %therefore should be assigned CO2CPP membership, or if gets
            %regular CO2 membership.
            if futurepowerfleetforplexos{i,fleetaffectedegucol}==1
                emparentname='CO2CPP';
            else
                emparentname='CO2';
            end
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Emission','Generator',emparentname,...
                plexosgenname, propertiesofinterest{j,1}, propertyvalue,'','','','');
        end
    end 
    
    %Add properties unique to pumped storage (solvent storage) facilities.
    %Test if pumped storage by seeing if has any pump units
    if futurepowerfleetforplexos{i,fleetpumpunitscol}==1
        %Get property value
        for j=1:size(propertiesofinterestsolventstorage,1)
            if strcmp(propertiesofinterestsolventstorage{j,1},'Pump Units')
                propertyvalue=futurepowerfleetforplexos{i,fleetpumpunitscol};
            elseif strcmp(propertiesofinterestsolventstorage{j,1},'Pump Load')
                propertyvalue=futurepowerfleetforplexos{i,fleetpumploadcol};
            elseif strcmp(propertiesofinterestsolventstorage{j,1},'Pump Efficiency')
                propertyvalue=futurepowerfleetforplexos{i,fleetpumpeffcol};
            end
            
            %Add row to property
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Generator','System',...
                plexosgenname, propertiesofinterestsolventstorage{j,1}, propertyvalue,'','','','');
        end 
    end
end



%LOAD AND GENERATION PARTICIPATION FACTORS FOR FLEXIBLE CCS****************
%If running flexible CCS, need to set load and generation participation
%factors for some components - pump units, pump dummy units, and continuous
%solvent units - to zero. A value of 0 means that the unit is still
%included in the objective function but its generation and pump load are
%not included in the supply=demand constraint at the node. 
if flexibleccs==1
    if mwccstoadd>0
        %Plant types for zero participation factors:
        planttypesforzeroparticipationfactor={'SSPump';'SSPumpDummy';'ContinuousSolvent'};
        for i=1:size(planttypesforzeroparticipationfactor,1)
            currplanttype=planttypesforzeroparticipationfactor{i};
            %Find units of that plant type
            unitsofplanttyperows=find(strcmp(futurepowerfleetforplexos(:,fleetplanttypecol),currplanttype));
            %For each unit, add property
            for j=1:size(unitsofplanttyperows,1)
                currfleetrow=unitsofplanttyperows(j);
                plexosgenname=createplexosobjname(futurepowerfleetforplexos,...
                    fleetorisidcol,fleetunitidcol,currfleetrow);
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Generator','Node',plexosgenname,...
                    nodename, 'Generation Participation Factor', 0,'','','','');
                if strcmp(currplanttype,'SSPump')
                    propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Generator','Node',plexosgenname,...
                        nodename, 'Load Participation Factor', 0,'','','','');
                end
            end
        end
    end
end
'Added generator data to properties'

%% CREATE HEAD AND TAIL STORAGE FACILITIES FOR SOLVENT STORAGE
%Need to do this for both pump units
%Only add if adding flexible CCS
if mwccstoadd>0
    if flexibleccs==1
        %Storage properties for PLEXOS. Initial Volume uses Max Volume, so
        %put it after Max Volume.
        storageproperties={'Units';'Max Volume';'Initial Volume';'End Effects Method'}; %;'Internal Volume Scalar'}
        %Iterate through each solvent storage facility being added. ID
        %solvent storage generators by finding generators w/ Pump Units = 1.
        sspumprows=find([futurepowerfleetforplexos{2:end,fleetpumpunitscol}]==1)+1; %add 1 to acct for header being skipped
        for rownum=1:size(sspumprows,2) %solventstoragerows has columns, not rows
            ssrow=sspumprows(rownum);
            %Get SS generator PLEXOS name
            plexosgenname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,ssrow);
            %Create head and tail storage names by adding 'Lean' or 'Rich'
            %to end of PLEXOS name
            leanstoragename=strcat(plexosgenname,'Lean');
            richstoragename=strcat(plexosgenname,'Rich');
            
            %OBJECTS*******************************************************************
            %Add rich and lean storage objects
            objectdata=AddObjectToPLEXOSFile(objectdata,'Storage',leanstoragename);
            objectdata=AddObjectToPLEXOSFile(objectdata,'Storage',richstoragename);
                        
            %MEMBERSHIPS***************************************************************
            %Memberships to add: Generator,Storage,Head Storage,[Storage
            %Name]. Also for Tail Storage. Lean = head, rich = tail.
            %AddMembership function handles assignment to head/tail, which
            %is in Collections field. 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Generator','Storage',plexosgenname,...
                richstoragename);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Generator','Storage',plexosgenname,...
                leanstoragename);
            
            %PROPERTIES****************************************************************
            %Properties to add: Units=1, Max and Initial Volume, End Effects Method=1
            %(value of 1 sets it to "Free", which means end volume of the optimization horizon does
            %not have to equal the initial volume). Min Volume defaults to 0.
            for currpropertyrow=1:size(storageproperties,1)
                currproperty=storageproperties{currpropertyrow,1};
                if strcmp(currproperty,'Units')
                    propertyvaluelean=1;
                    propertyvaluerich=1;
                elseif strcmp(currproperty,'Max Volume')
                    %Volume is based on storage volume values used in other
                    %papers. Key storage size input parameter is # hours SS generator
                    %can generate at when operating at full load. 
                    %Therefore, calculate max volume as:
                    %MaxVolume=HoursStorage*CapacitySSGen/1000.
                    %[GWh]=[Hr]*[MW]/(1000MW/GW)
                    %Pump 1 storage volume is set to combined storage
                    %volume of pumps 1 and 2, whereas pump 2 storage volume
                    %is set according to pump 2 capacity.                     
                    if strfind(futurepowerfleetforplexos{ssrow,fleetunitidcol},'Pump1')
                        %Find pump 2 row
                        pump1unitid=futurepowerfleetforplexos{ssrow,fleetunitidcol};
                        pump2unitid=strcat(pump1unitid(1:end-1),'2');
                        pump2row=find(strcmp(futurepowerfleetforplexos(:,fleetunitidcol),pump2unitid));
                        %Pump 2 row SHOULD be the next row in sspumprows
                        %array - check that.
                        if pump2row ~= (ssrow+1)
                            'Pump2RowDoesNotEqualPump1Row+1'
                        end
                        %Now get combined capacities of pump 1 & 2
                        sspump1capac=futurepowerfleetforplexos{ssrow,fleetcapacitycol}; 
                        sspump2capac=futurepowerfleetforplexos{pump2row,fleetcapacitycol}; 
                        combinedsscapac=sspump1capac+sspump2capac;
                        maxvolume=solventstoragesize*combinedsscapac/1000;
                        propertyvaluelean=maxvolume;
                        propertyvaluerich=maxvolume;
                    elseif strfind(futurepowerfleetforplexos{ssrow,fleetunitidcol},'Pump2')
                        ssgencapacity=futurepowerfleetforplexos{ssrow,fleetcapacitycol}; %convert from MWh to GWh
                        maxvolume=solventstoragesize*ssgencapacity/1000;
                        propertyvaluelean=maxvolume;
                        propertyvaluerich=maxvolume;
                    end
                elseif strcmp(currproperty,'Initial Volume')
                    %This is what each storage will start with in terms of
                    %volume at the first period of the whole optimization;
                    %so if run daily steps for full year, initial volume
                    %determines volume in hour 1 of day 1. Set initial
                    %volume of pump 1 lean to half its max volume, and
                    %initial volume of pump 2 lean to 0. This results in
                    %half of the total solvent being initially stored as
                    %lean solvent (since the max volume of pump 1 is the
                    %combined capacity of stored solvent).
                    if strfind(futurepowerfleetforplexos{ssrow,fleetunitidcol},'Pump1')
                        propertyvaluelean=maxvolume/2;
                        propertyvaluerich=maxvolume/2;
                    elseif strfind(futurepowerfleetforplexos{ssrow,fleetunitidcol},'Pump2')
                        propertyvaluelean=0;
                        propertyvaluerich=maxvolume;
                    end
                elseif strcmp(currproperty,'End Effects Method')
                    propertyvaluelean=1;
                    propertyvaluerich=1;
                end
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Storage','System',...
                    leanstoragename, currproperty, propertyvaluelean,'','','','');
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Storage','System',...
                    richstoragename, currproperty, propertyvaluerich,'','','','');
            end
        end
    end
end

%% ADD RATING FACTORS FOR WIND, HYDRO, SOLAR IF NOT USING NLDC
if usenldc==0
    %% ADD MONTHLY MAX ENERGY OR RATING FACTOR PROPERTY TO HYDRO PLANTS
    %Either add monthly max energy values or rating factors per month for each
    %hydro facility, based on whether modelhydrowithmonthlymaxenergy = 0 (use
    %rating factors) or 1 (use monthly max energy).
    %Monthly max energy data in hydromonthlymaxenergy; rating factor data in
    %hydroratingfactors. Both arrays are in the same format - across top is
    %month #, across left is ORIS ID, and then values are in middle. Both are
    %input as dynamic values into PLEXOS, so can just substitute values out.
    
    %Only add hydro rating factors if not already removed hydro from
    %demand.
    if removehydrofromdemand==0
        %Get hydro rows
        hydrogenrows=find(strcmp(futurepowerfleetforplexos(:,fleetplanttypecol),'Hydro'));
        %For each hydro row, get max monthly energy or rating factor
        for i=1:size(hydrogenrows,1)
            %Get ORIS ID
            temprowinfuturefleet=hydrogenrows(i);
            temporisid=futurepowerfleetforplexos{temprowinfuturefleet,fleetorisidcol};
            temporisid=str2num(temporisid);
            %Create generator name (for AddProperty call below)
            plexosgenname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,temprowinfuturefleet);
            %Now get row in monthly max energy or rating factor array. (Really
            %would be the same either way as of 7/2/15, since set up identically.)
            if modelhydrowithmonthlymaxenergy==1 %use monthly max energy
                rowwithdata=find(hydromonthlymaxenergy(:,1)==temporisid);
            elseif modelhydrowithmonthlymaxenergy==0 %use rating factors
                rowwithdata=find(hydroratingfactors(:,1)==temporisid);
            end
            %For each month, fill in Date From as 1st of that month; PLEXOS
            %auto-fills gaps (so if have Date From of 1/1/2012 and 2/1/2012, the
            %value for 1/1/2012 will apply for all of January). Each plant only has
            %1 entry, so rowwithmonthlyenergydata will have length of 1. Make sure
            if size(rowwithdata,1)>1
                'WARNING: rowwithmonthlyenergydata has more than 1 row!'
            end
            %Add property for each month
            for j=2:size(hydromonthlymaxenergy,2)
                %Get month
                currmonth=j-1; %if j=2, really in January (month 1)
                %Create Date From string
                tempdatefrom=strcat(num2str(currmonth),'/1/2030');
                %Get monthly max energy and convert to **GWh** (which is what Max
                %Energy Month is in PLEXOS) or get rating factor (already in % so
                %no further conversions needed), and then add to Properties list.
                if modelhydrowithmonthlymaxenergy==1
                    temphydrodata=hydromonthlymaxenergy(rowwithdata,j)/1000;
                    propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Generator','System',...
                        plexosgenname, 'Max Energy Month', temphydrodata,'','',tempdatefrom,''); %don't include Date To
                elseif modelhydrowithmonthlymaxenergy==0
                    temphydrodata=hydroratingfactors(rowwithdata,j);
                    propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Generator','System',...
                        plexosgenname, 'Rating Factor', temphydrodata,'','',tempdatefrom,''); %don't include Date To
                end
            end
        end
        clear temprowinfuturefleet temporisid tempdatefrom rowwithmonthlyenergydata;
    end
    
    %% ADD WIND RATING FACTOR FILE
    %First create object for data file
    nameofwindratingdatafile='NRELWindGenProfiles';
    objectdata = AddObjectToPLEXOSFile(objectdata,'Data File',nameofwindratingdatafile);
    
    %Create Data File Filename property
    propertiesdata = AddPropertyToPLEXOSFile(propertiesdata,'System','Data File','System',...
        nameofwindratingdatafile,'Filename',0,csvfilenamewithwindgenprofiles,'','1/1/2030','12/31/2030');
    %Add data file to Rating Factor property of wind generators
    windrows=find(strcmp(futurepowerfleetforplexos(:,fleetfueltypecol),'Wind'));
    for i=1:size(windrows,1)
        currrow=windrows(i,1);
        %Get generator PLEXOS name
        plexosgenname=createplexosobjname(futurepowerfleetforplexos,...
            fleetorisidcol,fleetunitidcol,windrows(i)); %windrows has row of in futurepowerfleet... array which is what I want
        %Add data
        propertiesdata = AddPropertyToPLEXOSFile(propertiesdata,'System','Generator','System',...
            plexosgenname,'Rating Factor',0,strcat('{Object}',nameofwindratingdatafile),'','1/1/2030','12/31/2030');
    end
    
    %Add attribute for wind capacity factor data file that sets datetime
    %convention so that datetime is read as being at the end of the period
    %(i.e., 11:00 is for hour 10:01-11:00). Do this by setting Datetime
    %Convention attribute to 1.
    attributedata = AddAttributeToPLEXOSFile(attributedata, nameofwindratingdatafile, 'Data File', 'Datetime Convention',...
        1);
    
    %% ADD SOLAR RATING FACTOR FILE
    %First create object for data file
    nameofsolarratingdatafile='NRELSolarGenProfiles';
    objectdata = AddObjectToPLEXOSFile(objectdata,'Data File',nameofsolarratingdatafile);
    
    %Create Data File Filename property
    propertiesdata = AddPropertyToPLEXOSFile(propertiesdata,'System','Data File','System',...
        nameofsolarratingdatafile,'Filename',0,csvfilenamewithsolargenprofiles,'','1/1/2030','12/31/2030');
    %Add data file to Rating Factor property of wind generators
    solarrows=find(strcmp(futurepowerfleetforplexos(:,fleetfueltypecol),'Solar'));
    for i=1:size(solarrows,1)
        currrow=solarrows(i,1);
        %Get generator PLEXOS name
        plexosgenname=createplexosobjname(futurepowerfleetforplexos,...
            fleetorisidcol,fleetunitidcol,solarrows(i)); %solarrows has row of in futurepowerfleet... array which is what I want
        %Add data
        propertiesdata = AddPropertyToPLEXOSFile(propertiesdata,'System','Generator','System',...
            plexosgenname,'Rating Factor',0,strcat('{Object}',nameofsolarratingdatafile),'','1/1/2030','12/31/2030');
    end
    
    %Add attribute for wind capacity factor data file that sets datetime
    %convention so that datetime is read as being at the end of the period
    %(i.e., 11:00 is for hour 10:01-11:00). Do this by setting Datetime
    %Convention attribute to 1.
    attributedata = AddAttributeToPLEXOSFile(attributedata, nameofsolarratingdatafile, 'Data File', 'Datetime Convention',...
        1);
end

%% ADD FUEL OBJECTS TO PLEXOS FILE
%6/15/15: Price property of Fuel object will override Fuel Price property
%of Generators. As of today, there's no reason to add a fuel object to
%PLEXOS, so do not do it. 
% %Don't need to add fuel prices - already included at generator level
% %Fuel objects - get unique fuels, and then create object for each
% listoffuels=unique(futurepowerfleetforplexos(2:end,fleetfueltypecol));
% for i=1:size(listoffuels,1)
%     %Add fuel object
%     objectdata=AddObjectToPLEXOSFile(objectdata,'Fuel',listoffuels{i,1});
% end

%% ADD EMISSION OBJECTS
%Memberships to generators are added above
for i=1:size(listofallemissions,1)
    %Add emissions object
    objectdata=AddObjectToPLEXOSFile(objectdata,'Emission',listofallemissions{i});
    
    %Add prices for CSAPR emissions - these are marked as '...CSAPR'
    if findstr(listofallemissions{i},'CSAPR')
        currpricerow=find(strcmp(noxandso2prices(:,1),listofallemissions{i}));
        currprice=noxandso2prices{currpricerow,2};
        propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Emission','System',...
            listofallemissions{i},'Shadow Price',currprice,'','','',''); %$/kg
        propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Emission','System',...
            listofallemissions{i},'Price',currprice,'','','',''); %$/kg
    end
end

%% CALL FUNCTION TO CREATE DEMAND PROFILE
%Call function to create demand profile for specified demand scenario
%specified above. Demand scenario assumes a certain penetration of energy
%efficiency (or no additional relative to base case (Scenario 0)). 
%Also input states for analysis. This is the same regardless of value of modelmisowithfullstates
statesforanalysis={'Illinois';'Indiana';'Iowa';'Michigan';...
    'Minnesota';'Missouri';'North Dakota';'South Dakota';'Wisconsin'}; %cell list of states, 1 per row; do not include 'State' as label at top
[demanddataobjnames, demandfilenames]=CreateDemandProfileForPLEXOS(demandscenarioforanalysis,statesforanalysis,...
    modelmisowithfullstates,scaleenergyefficiencysavings,futurepowerfleetfull,usenldc,removehydrofromdemand,...
    solarratingfactors,windcapacityfactors,hydroratingfactors,pc);

%Create scenario names (PLEXOS object) for demand scenarios
for i=1:size(demandscenarioforanalysis,1)
    demandscenariosforanalysisscenarionames{i,1}=strcat('DemandScenario',num2str(demandscenarioforanalysis(i)));
end

%% ADD REGIONS/ZONES/NODES, DEMAND DATA, SCENARIOS FOR DEMAND DATA, AND ASSIGN SCENARIO TO MODEL
%First create region & zone objects 
objectdata = AddObjectToPLEXOSFile(objectdata,'Region',regionname);
objectdata = AddObjectToPLEXOSFile(objectdata,'Zone',zonename);
objectdata = AddObjectToPLEXOSFile(objectdata,'Node',nodename);
%Then create scenario objects for each demand profile
for i=1:size(demandscenariosforanalysisscenarionames,1)
    objectdata = AddObjectToPLEXOSFile(objectdata,'Scenario',demandscenariosforanalysisscenarionames{i});
end
%Then add memberships from node to zone, zone to region, node to region
membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Zone','Region',zonename,...
    regionname);
membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Node','Zone',nodename,...
    zonename);
membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Node','Region',nodename,...
    regionname);
%Add in load participation factors
propertiesdata = AddPropertyToPLEXOSFile(propertiesdata,'System','Zone','System',...
    zonename,'Load Participation Factor',1,'','','','');
propertiesdata = AddPropertyToPLEXOSFile(propertiesdata,'System','Node','System',...
    nodename,'Load Participation Factor',1,'','','','');
%Disallow dump energy
propertiesdata = AddPropertyToPLEXOSFile(propertiesdata,'System','Node','System',...
    nodename,'Allow Dump Energy',0,'','','','');

%Now create demand data object and add properties
for i=1:size(demanddataobjnames,1)
    %Create object
    currdemanddataobjname=demanddataobjnames{i,1}; %'MISO Demand' was old demand data object name;
    currdemandfilename=demandfilenames{i,1};
    objectdata = AddObjectToPLEXOSFile(objectdata,'Data File',currdemanddataobjname);
    
    %Add property for demand file
    propertiesdata = AddPropertyToPLEXOSFile(propertiesdata,'System','Data File','System',...
        currdemanddataobjname,'Filename',0,currdemandfilename,'','1/1/2030','12/31/2030');
    %Add demand file to zone, and tag demand file with scenario name.
    %Scenario name array is same length as demanddataobjnames.
    propertiesdata = AddPropertyToPLEXOSFile(propertiesdata,'System','Zone','System',...
        zonename,'Load',0,strcat('{Object}',currdemanddataobjname),strcat('{Object}',demandscenariosforanalysisscenarionames{i}),...
        '1/1/2030','12/31/2030');   
    
    %Add membership for demand scenario to model
    membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Model','Scenario',nameofmodel,...
        demandscenariosforanalysisscenarionames{i});
  
    %Add attribute for demand data files with Datetime Convention set to
    %value of 1 (which indicates the datetime refers to the end of the
    %period). 
    [attributedata] = AddAttributeToPLEXOSFile(attributedata, currdemanddataobjname, 'Data File', 'Datetime Convention',...
        1);
end

    
%% ADD PLEXOS SIMULATION OBJECTS
%Simulation objects include Production, Performance, Horizon, etc.
%For each simulation object, need to: 1) Create object. 2) Assign
%membership from object to Model. 3) Modify attributes.

%PRODUCTION
%Production: key attribute is 'Unit Commitment Optimality' which should be
%set to 2
modelcomponent='Production';
nameofproductionobj='MIP';
objectdata = AddObjectToPLEXOSFile(objectdata,modelcomponent,nameofproductionobj);
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofproductionobj, modelcomponent, 'Unit Commitment Optimality',...
        2); 
membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Model',modelcomponent,nameofmodel,...
    nameofproductionobj);

%PERFORMANCE
%Performance: key attribute is SOLVER, which should be set to 1 (for CPLEX)
modelcomponent='Performance';
nameofperformanceobj='CPLEX';
objectdata = AddObjectToPLEXOSFile(objectdata,modelcomponent,nameofperformanceobj);
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofperformanceobj, modelcomponent, 'SOLVER',...
        1); 
membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Model',modelcomponent,nameofmodel,...
    nameofperformanceobj);

%MID-TERM SCHEDULE
%Only need this if using max monthly energy for hydro plants
if modelhydrowithmonthlymaxenergy==1
    %Mid-term schedule: there are many options associated with MT schedule,
    %most importantly the way in which time periods are handled and units are
    %committed. Options are partial, fitted & sampled; some preserve
    %time-ordering of demand and enforce UC constraints, others use LDCs, etc.
    %Option is coded via Chronology attribute. Use partial as default.
    mtscheduletype='partial'; %alternatives: fitted, sampled
    modelcomponent='MT Schedule';
    nameofmtobj=strcat('MT',mtscheduletype);
    objectdata = AddObjectToPLEXOSFile(objectdata,modelcomponent,nameofmtobj);
    %Attribute data: if partial, don't need attributes. If fitted or sampled,
    %need to set chronology to right value, and then can set block count.
    if strcmp(mtscheduletype,'partial')==0 %IF NOT PARTIAL (if partial, don't need to add these attributes)
        if strcmp(mtscheduletype,'fitted')
            %Set chronology and block count
            attributechronology=3;
            attributeblockcount=9;
            attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmtobj, modelcomponent, 'Chronology',...
                attributechronology);
            attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmtobj, modelcomponent, 'Block Count',...
                attributeblockcount);
        elseif strcmp(mtscheduletype,'sampled')
            %Set chronology and block count
            attributechronology=4;
            attributeblockcount=9;
            attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmtobj, modelcomponent, 'Chronology',...
                attributechronology);
            attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmtobj, modelcomponent, 'Block Count',...
                attributeblockcount);
        else
            'Wrong MT schedule type entered!'
        end
    end
    membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Model',modelcomponent,nameofmodel,...
        nameofmtobj);
end

%FLAT FILES
%Add Report feature so simulation writes Flat Files, and sets their Format
%as 'Periods in Columns'
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmodel, 'Report', 'Flat File Format',...
    1);
%Set Flat File format to 'Periods in Columns'
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmodel, 'Report', 'Write Flat Files',...
    -1);
%Disable Flat File reporting for Period interval, and set to report for Day
%and Fiscal Year
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmodel, 'Report', 'Output Results by Fiscal Year',...
    -1);
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmodel, 'Report', 'Output Results by Day',...
    -1);
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmodel, 'Report', 'Output Results by Period',...
    -1); %0 for off, -1 for on
%Set filtering properties to zero, which turns off the filtering - this means that all objects are
%reported on.
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmodel, 'Report', 'Filter Objects In Summary',...
    0); %0 is off
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmodel, 'Report', 'Filter Objects By Interval',...
    0); %0 is off


%UNIQUE NAME
%Set solution output from Model to be written to folder with Unique Name
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmodel, 'Model', 'Make Unique Name',...
    -1);

%HORIZON
%Add Horizon starting date (Date From, Chrono Date From) attributes. Values
%of 47484 for both start simulation at 1/1/2030.
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmodel, 'Horizon', 'Date From',...
    47484);
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmodel, 'Horizon', 'Chrono Date From',...
    47484);
%Add length of horizon (Step Type, Chrono Step Count). Values of 4 & 365,
%respectively, set it to run for full year in daily time steps.
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmodel, 'Horizon', 'Step Type',...
    4);
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofmodel, 'Horizon', 'Chrono Step Count',...
    365);

%DIAGNOSTICS
%Add diagnostic object
nameofdiagnostic='Diags';
modelcomponent='Diagnostic';
objectdata = AddObjectToPLEXOSFile(objectdata,modelcomponent,nameofdiagnostic);
%Add membership of diagnostic to model
membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Model',modelcomponent,nameofmodel,...
    nameofdiagnostic);
%Write LP Files and Objective Function diagnostic files. Also turn off some
%reporting fiels (MIP Progress, Summary Each Step, and Task Size). 
%Don't write solution files; that's just an XML file that's already
%contained in ZIP solution file. 
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofdiagnostic, modelcomponent, 'LP Files',...
    0);
attributedata = AddAttributeToPLEXOSFile(attributedata, nameofdiagnostic, modelcomponent, 'Objective Function',...
    0);
if suppresssolveroutput==1
    attributedata = AddAttributeToPLEXOSFile(attributedata, nameofdiagnostic, modelcomponent, 'Step Summary',...
        0);
    attributedata = AddAttributeToPLEXOSFile(attributedata, nameofdiagnostic, modelcomponent, 'Task Size',...
        0);
    attributedata = AddAttributeToPLEXOSFile(attributedata, nameofdiagnostic, modelcomponent, 'Times',...
        -1);
    attributedata = AddAttributeToPLEXOSFile(attributedata, nameofdiagnostic, modelcomponent, 'MIP Progress',...
        0);
end
'Added PLEXOS simulation objects'


%% ADD RESERVES TO PLEXOS
%Either use MISO reserves or 3% + 5% NREL rule.
%If using MISO reserves:
%Add reserve classes to PLEXOS model. MISO has three types of operating reserves:
%Regulating reserves: 300-500 MW, 5-min response time, on-line, bidirectional.
%Spinning reserves: 1000 MW, 10-min response time, on-line.
%Supplemental reserves: 1000 MW, 10-min response time, on- or off-line.
%Spinning + Supplemental = Contingency Reserves.
%I model regulating reserves as up and down reserves, and
%spinning and supplemental as just up. (PLEXOS has diff properties for
%up/down for regulating & spinning; supplemental is defined always as up.)
%Mapping between MISO and PLEXOS terminology:
%Regulation Raise/Lower in PLEXOS = regulating in MISO.
%Raise in PLEXOS = spinning in MISO.
%Operational in PLEXOS = supplemental in MISO.
%OfferPriceProportionOfEnergyOffer column indicates the proportion of
%reserve offer price relative to energy offer price. Set to 0.3 for
%regulation and 0.2 for other reserves. Based on observed energy and
%reserve offers. Used below to set Offer Price parameter.

%If using NREL reserves: only use spinning reserves, which are set to 3%
%max daily load + 5% hourly wind generation (per Western Wind NREL study,
%Oates & Jaramillo 2013, Weis et al. 2015). Keep some information from MISO
%spinning reserves, like offer proportion, PLEOXS type, and timeframe.

%MISO RESERVE INFORMATION**************************************************
misoreserves={'ReserveName','ProvisionMW','TimeframeSec.','PLEXOSType','OfferPriceProportionOfEnergyOffer';
    'RegulatingUp',400,5*60,3,0.38;
    'RegulatingDown',400,5*60,4,0.38;
    'Spinning',1000,10*60,1,0.26;
    'Supplemental',1000,10*60,6,0.22};
reservenamecol=find(strcmp(misoreserves(1,:),'ReserveName'));
reserveprovisioncol=find(strcmp(misoreserves(1,:),'ProvisionMW'));
reservetimeframecol=find(strcmp(misoreserves(1,:),'TimeframeSec.'));
reservetypecol=find(strcmp(misoreserves(1,:),'PLEXOSType'));
reserveofferpriceproportioncol=find(strcmp(misoreserves(1,:),'OfferPriceProportionOfEnergyOffer'));

%If using NREL reserve requirements, just need spinning row, and eliminate
%the provision value.
if strcmp(reserverequirements,'nrel')
    spinningrow=find(strcmp(misoreserves(:,reservenamecol),'Spinning'));
    misoreserves{spinningrow,reserveprovisioncol}=0;
    misoreserves=[misoreserves(1,:);misoreserves(spinningrow,:)];
    
    %Create file with hourly reserve information
    [reservefileobjname, reservefilenameforplexos] = CalculateHourlyNRELReserveRequirement...
        (futurepowerfleetfull, windcapacityfactors, pc, mwwindtoadd, demandfilenames);
end

%OBJECTS AND PROPERTIES****************************************************
%Add reserve objects and properties. Properties:
%Add Timeframe [sec. over which reserve applies], Min Provision [MW required in reserve],
%and Type properties. %Key to type: 1=raise (spin  up), 2=lower (spin down), 3= regulation raise,
%4 = regulation lower, 5 = operational (off-line generators)
modelcomponent='Reserve'; %for all reserves
%Iterate over each reserve in misoreserves (startign in row 2 b/c header)
for i=2:size(misoreserves,1)
    %Add object
    nameofreserveobj=misoreserves{i,reservenamecol};
    objectdata = AddObjectToPLEXOSFile(objectdata,modelcomponent,nameofreserveobj);
    
    %Add type
    typereserve=misoreserves{i,reservetypecol};
    propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Reserve','System',...
        nameofreserveobj, 'Type', typereserve,'','','','');
    
    %Add timeframe
    timeframe=misoreserves{i,reservetimeframecol};
    propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Reserve','System',...
        nameofreserveobj, 'Timeframe', timeframe,'','','','');
    
    %Add provision
    if strcmp(reserverequirements,'miso')
        misoprovision=misoreserves{i,reserveprovisioncol};
        propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Reserve','System',...
            nameofreserveobj, 'Min Provision', misoprovision,'','','','');
    elseif strcmp(reserverequirements,'nrel')
        %Add object for data file
        objectdata = AddObjectToPLEXOSFile(objectdata,'Data File',reservefileobjname);
        propertiesdata = AddPropertyToPLEXOSFile(propertiesdata,'System','Data File','System',...
            reservefileobjname,'Filename',0,reservefilenameforplexos,'','1/1/2030','12/31/2030');
        %Create property to attach data file to spinning reserve provision
        propertiesdata = AddPropertyToPLEXOSFile(propertiesdata,'System','Reserve','System',...
            nameofreserveobj,'Min Provision',0,strcat('{Object}',reservefileobjname),'',...
            '1/1/2030','12/31/2030');
    end
    
    if strcmp(reserverequirements,'miso')
        %Make mutually exclusive (set to 'Yes' with value of 1), which
        %prohibits same MW from being provided to multiple reserves. Only
        %do this if using MISO reserves since don't have other types of
        %reserves in the case of NREL reserves.
        propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Reserve','System',...
            nameofreserveobj, 'Mutually Exclusive', 1,'','','','');
    end
    
    clear timeframe provision typereserve nameofreserveobj;
end

%MEMBERSHIPS**************************************************************
%Add reserve and constraint memberships
%Now need to add generators to each reserve class, and also create
%constraints for each generator. For constraint, need to create Constraint
%as object, assign generator to constraint, and then define constraint
%properties.
%MEMBERSHIPS:
%Don't allow solar, wind, and dummy SS generators to contribute to reserves.
%(Dummy SS not even a real generator; handled later.)
fueltypestoexcludefromreserves={'Wind','Solar'};
%Disallow hydro from contributing ot reserves if modeling w/ capacity
%factors.
if modelhydrowithmonthlymaxenergy==0 %if not modeling w/ max energy
    fueltypestoexcludefromreserves=[fueltypestoexcludefromreserves,'Hydro'];
end
%Otherwise, allow all dispatchable generators to participate in reserves.
%This excludes pumping units, pumping dummy units, and continuous solvent
%units, all of which are associated with flexible CCS.
%Create base for constraint objects.
for fleetctr=2:size(futurepowerfleetforplexos,1)
    %Check if fuel type is not one of fuel types to be excluded
    if any(ismember(futurepowerfleetforplexos{fleetctr,fleetfueltypecol},fueltypestoexcludefromreserves))==0
        %Check that it's not a dummy generator, continuous solvent
        %generator, or pump unit
        if strcmp(futurepowerfleetforplexos{fleetctr,fleetplanttypecol},'ContinuousSolvent')==0 && ...
                strcmp(futurepowerfleetforplexos{fleetctr,fleetplanttypecol},'SSPump')==0 && ...
                strcmp(futurepowerfleetforplexos{fleetctr,fleetplanttypecol},'SSPumpDummy')==0
            currgenname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,fleetctr);
            %Add membership of generator each reserve
            for reservectr=2:size(misoreserves,1) %for each reserve (row 1 = header)
                currreservename=misoreserves{reservectr,reservenamecol};
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Reserve','Generator',currreservename,...
                    currgenname);
            end
            clear gencapac;
        end
    end
end

%If using MISO reserves, do below; if using NREL, don't need to since no
%non-spinning reserves w/ NREL.
if strcmp(reserverequirements,'miso')
    %Add constraints on venting & SS discharge generators prohibiting them
    %from participating as non-spinning reserves. Find venting and solvent storage generators by looking for unit IDs ending
    %with 'Venting', 'SSDischargeDummy', and 'SSVentWhenCharge'. Other units
    %(Pump, PumpDummy, and ContinousSolvent are not allowed to participate in
    %any reserves).
    %To use strfind, need a full cell array, but some futurepowerfleet unit IDs
    %are empties; therefore, create a temporary copy of the unit IDs, fill in
    %empty cells, and search in that; row #s will be same as futurepowerfleet.
    unitidsisolated=futurepowerfleetforplexos(:,fleetunitidcol);
    emptyunitids=cellfun('isempty',unitidsisolated);
    unitidsisolated(emptyunitids)={''}; %fill in empties w/ empty strings
    ventingrowscell=strfind(unitidsisolated,'Venting'); %returns cell w/ empty rows when not venting & # of place in string where Venting starts
    ssdischargedummyrowscell=strfind(unitidsisolated,'SSDischargeDummy');
    ssventwhenchargerowscell=strfind(unitidsisolated,'SSVentWhenCharge');
    ventingrows=find(not(cellfun('isempty',ventingrowscell))); %gives index of rows of venting generators
    ssdischargedummyrows=find(not(cellfun('isempty',ssdischargedummyrowscell)));
    ssventwhenchargerows=find(not(cellfun('isempty',ssventwhenchargerowscell)));
    %Use unique when aggregating because SSPump includes SSPumpDummy rows
    ventanddischargerows=unique([ventingrows;ssdischargedummyrows;ssventwhenchargerows]);
    clear unitidsisolated emptyunitids;
    replacementreserveflexccsbasename='NoReplaceRes';
    for i=1:size(ventanddischargerows,1)
        %Get current row
        currrow=ventanddischargerows(i);
        %Get PLEXOS gen name for current row
        currgenname=createplexosobjname(futurepowerfleetforplexos,...
            fleetorisidcol,fleetunitidcol,currrow);
        %Get constraint name
        constraintname=strcat(replacementreserveflexccsbasename,currgenname);
        %Add object
        objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname);
        %Add constraint that forces replacement reserves from solvent storage
        %and venting generators to equal zero. I.e., constraint is:
        %SolventStorageReplacementReserves=0. Same for venting. Do this by
        %setting 'Replacement Reserve Provision Coefficient' equal to 1, and
        %RHS = 0, and Sense = 0 (0 is =).
        propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
            constraintname, 'Sense', 0,'','','','');
        propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
            constraintname, 'RHS', 0,'','','','');
        propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
            currgenname, 'Replacement Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
        %Add generator membership to constraint
        membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
            currgenname);
    end
end

'Added reserves to PLEXOS'

%% ADD CONSTRAINTS ON FLEXIBLE CCS AND ASSOCIATED VENTING & SS GENERATORS
%Only add if adding flexible CCS generators. Below, base plant refers to
%the coal-fired generator retrofit w/ CCS.
if mwccstoadd>0
    if flexibleccs==1
        %Get plants retrofit w/ CCS
        genswithccsretrofit=(cell2mat(futurepowerfleetforplexos(2:end,fleetccsretrofitcol))==1); %array w/ 0s for rows w/out retrofit & 1 w/ retrofit
        rowswithccsretrofit=find(genswithccsretrofit==1)+1; %returns row #s of retrofits; add 1 for missing header
        for i=1:size(rowswithccsretrofit,1)
            currbasegenrow=rowswithccsretrofit(i);
            %Get curr ORIS and unit ID
            currorisid=futurepowerfleetforplexos{currbasegenrow,fleetorisidcol};
            currunitid=futurepowerfleetforplexos{currbasegenrow,fleetunitidcol};
            %SS and venting generators are named [UnitID]Venting and
            %[UnitID]SolventStorage - so find rows w/ each unit ID for the
            %same ORIS ID.
            %***PUMP, PUMP DUMMY & DISCHARGE DUMMY 1 & 2
            continuoussolventunitid=strcat(currunitid,'ContinuousSolvent');
            ventingunitid=strcat(currunitid,'Venting');
            ventwhenchargeunitid=strcat(currunitid,'SSVentWhenCharge');
            pump1unitid=strcat(currunitid,'SSPump1');
            pump2unitid=strcat(currunitid,'SSPump2');
            pumpdummy1unitid=strcat(currunitid,'SSPumpDummy1');
            pumpdummy2unitid=strcat(currunitid,'SSPumpDummy2');
            dischargedummy1unitid=strcat(currunitid,'SSDischargeDummy1');
            dischargedummy2unitid=strcat(currunitid,'SSDischargeDummy2');
            
            currunitcontinuoussolventrow=find(strcmp(futurepowerfleetforplexos(:,fleetunitidcol),continuoussolventunitid) & ...
                strcmp(futurepowerfleetforplexos(:,fleetorisidcol),currorisid));
            currunitventingrow=find(strcmp(futurepowerfleetforplexos(:,fleetunitidcol),ventingunitid) & ...
                strcmp(futurepowerfleetforplexos(:,fleetorisidcol),currorisid));
            currunitventwhenchargerow=find(strcmp(futurepowerfleetforplexos(:,fleetunitidcol),ventwhenchargeunitid) & ...
                strcmp(futurepowerfleetforplexos(:,fleetorisidcol),currorisid));
            currunitpump1row=find(strcmp(futurepowerfleetforplexos(:,fleetunitidcol),pump1unitid) & ...
                strcmp(futurepowerfleetforplexos(:,fleetorisidcol),currorisid));
            currunitpump2row=find(strcmp(futurepowerfleetforplexos(:,fleetunitidcol),pump2unitid) & ...
                strcmp(futurepowerfleetforplexos(:,fleetorisidcol),currorisid));
            currunitpumpdummy1row=find(strcmp(futurepowerfleetforplexos(:,fleetunitidcol),pumpdummy1unitid) & ...
                strcmp(futurepowerfleetforplexos(:,fleetorisidcol),currorisid));
            currunitpumpdummy2row=find(strcmp(futurepowerfleetforplexos(:,fleetunitidcol),pumpdummy2unitid) & ...
                strcmp(futurepowerfleetforplexos(:,fleetorisidcol),currorisid));
            currunitdischargedummy1row=find(strcmp(futurepowerfleetforplexos(:,fleetunitidcol),dischargedummy1unitid) & ...
                strcmp(futurepowerfleetforplexos(:,fleetorisidcol),currorisid));
            currunitdischargedummy2row=find(strcmp(futurepowerfleetforplexos(:,fleetunitidcol),dischargedummy2unitid) & ...
                strcmp(futurepowerfleetforplexos(:,fleetorisidcol),currorisid));
            
            %Get PLEXOS names for base, SS & venting gens
            currbasegenname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,currbasegenrow);
            currcontinuoussolventgenname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,currunitcontinuoussolventrow);
            currventinggenname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,currunitventingrow);
            currventwhenchargegenname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,currunitventwhenchargerow);
            currpump1genname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,currunitpump1row);
            currpump2genname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,currunitpump2row);
            currpumpdummy1genname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,currunitpumpdummy1row);
            currpumpdummy2genname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,currunitpumpdummy2row);
            currdischargedummy1genname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,currunitdischargedummy1row);
            currdischargedummy2genname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,currunitdischargedummy2row);
            
            %NOTE:*********************************************************
            %Below, 'Venting' will be used to refer to venting generator,
            %whereas 'VentCharge' will be used to refer to venting
            %generator when charging. 
            
%ON/OFF CONSTRAINTS********************************************
            %-BasePlantOn + SSPumpOn + SSGenOn <= 0 (ensures SSGen & SSPump can't be on
                %at same time, and neither can be on if base plant not on)
            baseconstraintname='Pump1AndBaseOn';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Units Generating Coefficient', -1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Units Generating Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Units Pumping Coefficient', 1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname); 
            
            %Replicate above for pump 2
            baseconstraintname='Pump2AndBaseOn';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Units Generating Coefficient', -1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Units Generating Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Units Pumping Coefficient', 1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump2genname); 
            
            %VentingOn + SSPump1On + SSGen1On <= 1 (ensures SS pump & venting
                %can't be on at once.
            baseconstraintname='VentAndPump1On';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 1,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Units Generating Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Units Generating Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Units Pumping Coefficient', 1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname); 
            
            %Replicate above for Pump2.
            baseconstraintname='VentAndPump2On';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 1,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Units Generating Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Units Generating Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Units Pumping Coefficient', 1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump2genname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname); 
            
            %-SSPump1On - SSPump2On + VentChargeOn <= 0 (ensures vent when charge
                %can only be on if pump units 1 and/or 2 are on).
            baseconstraintname='VentChargeAndPumpsOn';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Units Generating Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Units Pumping Coefficient', -1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Units Pumping Coefficient', -1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump2genname);      
            
            %Pump2PumpOn - Pump1PumpLoad/(Pump1LoadCapac-0.05) <= 0
                %Ensures pump 2 can't turn on unless pump 1 is at maximum
                %capacity.
            baseconstraintname='Pump2On';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Units Pumping Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Pump Load Coefficient', ...
                -1/(futurepowerfleetforplexos{currunitpump1row,fleetpumploadcol}-0.05),'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump2genname); 
            
            %-BasePlantOn + VentingOn <= 0 (ensures venting can't be on if base plant
                %not on)
            baseconstraintname='VentingAndBaseOn';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Units Generating Coefficient', -1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Units Generating Coefficient', 1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname); 
            
            %-BasePlantOn + VentChargeOn <= 0 (vent charge can't be on
                %unless base CCS plant is on).
            baseconstraintname='VentChargeAndBaseOn';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Units Generating Coefficient', -1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Units Generating Coefficient', 1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname); 
            
            %-BasePlantOn + ContinuousSolventOn <= 0 (continuous solvent can't be on
                %unless base CCS plant is on).
            baseconstraintname='ContSolventAndBaseOn';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Units Generating Coefficient', -1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname, 'Units Generating Coefficient', 1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname); 
            
            %-BasePlantOn + Discharge1On <= 1 (dummy discharge 1 can't be on
                %unless base CCS plant is on).
            baseconstraintname='Discharge1AndBaseOn';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Units Generating Coefficient', -1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Units Generating Coefficient', 1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname); 
            
            %-BasePlantOn + Discharge2On <= 1 (dummy discharge 2 can't be on
                %unless base CCS plant is on).
            baseconstraintname='Discharge2AndBaseOn';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Units Generating Coefficient', -1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Units Generating Coefficient', 1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname);                     
                
                        
%MIN LOAD CONSTRAINTS******************************************
            %Three min load constraints need to be added: one for total
            %steam turbine load, one for total boiler load, and another
            %that enforces the min load of the base CCS generator during
            %normal operations and enforces a lower min load when other
            %generators (vent, vent when charge, or discharge generators)
            %are on.
            
            %First get min loads of steam turbine (ST) & boiler
            currboilerminload=futurepowerfleetforplexos{currbasegenrow,fleetminloadcol};
            currstminloadfraction=currboilerminload/futurepowerfleetforplexos{currbasegenrow,fleetcapacitycol}-...
                stminload/100;
            currstminload=currstminloadfraction*futurepowerfleetforplexos{currbasegenrow,fleetcapacitycol};
            
            %CCSGen >= STMin*CCSOn - (VentOn + VentChargeOn + Discharge1On +
            %Discharge2On)*(STMin-1)
                %Modifies min load of CCS gen so = true ST min load when no
                %other generators are on, and =1 when other generators are
                %on.
            %Set names
            baseconstraintname='BaseGenMinLoad';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', 1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS',0, '','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Units Generating Coefficient', ...
                -currstminload,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Units Generating Coefficient', ...
                currstminload-1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Units Generating Coefficient', ...
                currstminload-1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Units Generating Coefficient', ...
                currstminload-1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Units Generating Coefficient', ...
                currstminload-1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname); 
                
            %CCSGen + PumpDummy1Gen + PumpDummy2Gen + Discharge1Gen +
            %Discharge2Gen + VentChargeGen + VentGen + ContinuousSolventGen >= CCSBoilerMin*CCSOn.
                %Sets min load of all generators to min load of boiler.
            %Set names
            baseconstraintname='AllGenBoilerMinLoad';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', 1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS',0, '','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Units Generating Coefficient', ...
                -currboilerminload,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpumpdummy1genname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpumpdummy2genname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname, 'Generation Coefficient', 1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpumpdummy1genname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpumpdummy2genname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname); 
            
            %CCSGen + Discharge1Gen + Discharge2Gen + VentChargeGen +
            %VentGen >= CCSSteamTurbineMin*CCSOn
                %Sets min load of all electricity-outputting generators to
                %min load of steam turbine.
                %stminload = percentage points below boiler load, so if
                %boiler min load is 30%, stminload=10 means st min load is 20%). 
            %Set names
            baseconstraintname='AllGenSTMinLoad';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', 1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS',0, '','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Units Generating Coefficient', ...
                -currstminload,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Generation Coefficient', 1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname); 
            
            
%ELECTRICITY OUTPUT LIMITS*************************************
            %VentGen <= VentMaxCapacity - CCSGen*(1-CPvent)/(1-CPccs) =
            %VentMaxCapacity - CCSGen*(VentCapac/CCSCapac)
                %This restricts venting generation based on CCS output; CP
                %= capacity penalty. 
            baseconstraintname='VentGenLimit';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=, 0 is =
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', futurepowerfleetforplexos{currunitventingrow,fleetcapacitycol},'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Generation Coefficient', ...
                futurepowerfleetforplexos{currunitventingrow,fleetcapacitycol}/futurepowerfleetforplexos{currbasegenrow,fleetcapacitycol},...
                '','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            
            %CCSGen <= CCSMax - EGrid/ECO2Cap&Regen * (1+EContSolv/EStorSolv)*Pump1PumpLoad    
            baseconstraintname='CCSGenLimit';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=, 0 is =
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', futurepowerfleetforplexos{currbasegenrow,fleetcapacitycol},'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Pump Load Coefficient', ...
                futurepowerfleetforplexos{currbasegenrow,fleetegridpereco2capandregencol}*(1+futurepowerfleetforplexos{currbasegenrow,fleeteextraperestorecol}),...
                '','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname); 
            
            %ContinuousSolventGen = 1/(EGrid/ECO2Cap&Regen) * CCSGen +
            %EContSolv/EStorSolv*Pump1Load - Pump2Load
            baseconstraintname='ContSolvGenLimit';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', 0,'','','',''); %-1 is <=, 0 is =
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Generation Coefficient', -1/futurepowerfleetforplexos{currbasegenrow,fleetegridpereco2capandregencol},'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Pump Load Coefficient', ...
                -futurepowerfleetforplexos{currbasegenrow,fleeteextraperestorecol},...
                '','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Pump Load Coefficient', ...
                1,...
                '','','','');
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump2genname);
            
            %VentChargeGen <= EGrid/ECO2Capture&Regen * (Pump1PumpLoad +
            %Pump2PumpLoad)*((CCSMaxCapac-1)/VentChargeMaxCapac)
                %This constraint restricts venting while charging
                %generation based on the total pump load and the ratio of
                %the base CCS generator and venting while charging
                %capacities. The final term -
                %(CCSMaxCapac-1)/VentChargeCapac - is included such that at
                %full output from the vent while charging unit, the base
                %CCS facility can remain on at 1 MW. 
            baseconstraintname='VentChargeGen';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=, 0 is =
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Pump Load Coefficient', ...
                -futurepowerfleetforplexos{currbasegenrow,fleetegridpereco2capandregencol}...
                *(futurepowerfleetforplexos{currbasegenrow,fleetcapacitycol}-1)/futurepowerfleetforplexos{currunitventwhenchargerow,fleetcapacitycol},'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Pump Load Coefficient', ...
                -futurepowerfleetforplexos{currbasegenrow,fleetegridpereco2capandregencol}...
                *(futurepowerfleetforplexos{currbasegenrow,fleetcapacitycol}-1)/futurepowerfleetforplexos{currunitventwhenchargerow,fleetcapacitycol},'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump2genname);
            
            
%PUMPING DUMMY AND DISCHARGE TO PUMP RELATIONSHIPS*************
            %PumpDummy1Gen = Pump1PumpLoad
            baseconstraintname='DummyPump1Equality';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', 0,'','','',''); %-1 is <=, 0 is =
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpumpdummy1genname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Pump Load Coefficient', -1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpumpdummy1genname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname); 
            
            %PumpDummy2Gen = Pump2PumpLoad
            baseconstraintname='DummyPump2Equality';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', 0,'','','',''); %-1 is <=, 0 is =
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpumpdummy2genname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Pump Load Coefficient', -1,'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpumpdummy2genname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump2genname); 
            
            %DischargeDummy1Gen=EGenDischarge/EtoStore*Pump1Gen
            baseconstraintname='DummyDischarge1Equality';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', 0,'','','',''); %-1 is <=, 0 is =
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Generation Coefficient', -futurepowerfleetforplexos{currbasegenrow,fleetegriddischargeperestorecol},'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname); 
            
            %DischargeDummy2Gen=EGenDischarge/EtoStore*Pump2Gen
            baseconstraintname='DummyDischarge2Equality';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', 0,'','','',''); %-1 is <=, 0 is =
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','','');
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Generation Coefficient', 1,'','','',''); 
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Generation Coefficient', -futurepowerfleetforplexos{currbasegenrow,fleetegriddischargeperestorecol},'','','',''); 
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump2genname); 

            
%SOLVENT STORAGE RESERVES**************************************
            %DischargeReserves <= End Volume of Head Storage (lean solvent)
                %(ensures reserves by SS don't exceed end volume of time period (see research journal page 73); reserve
                %coefficients should be for Raise and Regulation Raise). 
                %Since now not assigning HR to pump storage unit, don't
                %need to use scalars of any sort in equation.
                %Note that this constraint operates on the discharge unit,
                %since pump units are not allowed to engage in generation
                %or reserves. Therefore, need to include parameter  linking
                %energy in pump unit to total potential discharge.
            %Need name of associated head storage (lean solvent)- lean solvents are named
            %[SSGenPLEXOSName]Lean
            leansolventname=strcat(currpump1genname,'Lean');
            baseconstraintname='Discharge1Reserves';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','',''); %RHS is capac of generator
            %PLEXOS automatically divides by 1000 to account for GW in head
            %to MW of reserves.
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Storage',constraintname,...
                leansolventname, 'End Volume Coefficient',...
                -1000,'','','','');  %need to multiply by 1000 tpo account for IVS; otherwise, end vol is in GWh and so reserves are limited to GWh value instead of MWh value
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            if strcmp(reserverequirements,'miso') %only have regulation reserves if using MISO reserves
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currdischargedummy1genname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            end
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname);    
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Storage',constraintname,...
                leansolventname);
            
            %Repeat above for pump 2
            leansolventname=strcat(currpump2genname,'Lean');
            baseconstraintname='Discharge2Reserves';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', 0,'','','',''); %RHS is capac of generator
            %PLEXOS automatically divides by 1000 to account for GW in head
            %to MW of reserves.
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Storage',constraintname,...
                leansolventname, 'End Volume Coefficient',...
                -1000,'','','',''); %need to multiply by 1000 tpo account for IVS; otherwise, end vol is in GWh and so reserves are limited to GWh value instead of MWh value
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            if strcmp(reserverequirements,'miso') %only have regulation reserves if using MISO reserves
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currdischargedummy2genname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            end
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname);    
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Storage',constraintname,...
                leansolventname);

            
%ADD RESERVE CONSTRAINT ON UNIT GROUPS*************************************            
            %Two constraints on all units' reserves. Two constraints together constrain
            %reserves based on ramping potential of base CCS generator + concurrent ramping
            %of cont solvent gen + spare energy available for
            %venting/discharging in cont and pumped solvent gen. These constraints
            %essentially force relationship that discharging & venting only
            %provide power by reducing parasitic load of CCS. Thus,
            %discharge can't ramp freely; can only provide reserves by
            %eliminating cont or pumped solvent energy use, and CCS increase gen can
            %also provide reserves. These series of two constraints
            %essentially enforce a min() function on 2 RHSs. Note that the
            %first of these two constraints is included separately for
            %raise and regulation reserves, as CCSMaxRes is different for
            %those two values. 
            
            %CCSRes + VentRes + VentChargeRes + Discharge1Res + Discharge2Res <=
            %CCSMaxRes*(1+1/(EGrid/ECO2Capture))+ContSolvGen+Pump1PumpLoad+Pump2PumpLoad
                %REGULATION RESERVES
            %Only need constraint if using MISO reserves (since NREL
            %doesn't have regulation reserves).
            if strcmp(reserverequirements,'miso')
                currgenramprate=futurepowerfleetforplexos{currbasegenrow,fleetmaxrampupcol};
                regreserverow=find(strcmp(misoreserves(:,reservenamecol),'RegulatingUp'));
                regreservetimeframe=misoreserves{regreserverow,reservetimeframecol}/60; %/60 to convert to minutes
                basegenmaxregraise=currgenramprate*regreservetimeframe; %MW/min * min = MW
                %Add name
                baseconstraintname='VentAndDisRegResCCSMaxRes';
                constraintname=strcat(baseconstraintname,currbasegenname);
                %Add constraint object
                objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname);
                %Add constraint properties
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                    constraintname, 'Sense', -1,'','','',''); %-1 is <=
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                    constraintname, 'RHS', basegenmaxregraise*(1+1/futurepowerfleetforplexos{currbasegenrow,fleetegridpereco2capandregencol}),'','','',''); %RHS is true capac of SS generator
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currbasegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventinggenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventwhenchargegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currdischargedummy1genname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currdischargedummy2genname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currcontinuoussolventgenname, 'Generation Coefficient', -1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currpump1genname, 'Pump Load Coefficient', -1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currpump2genname, 'Pump Load Coefficient', -1,'','','',''); %1 is the value of the coefficient
                %Add generator membership to constraint
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currbasegenname);
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currventinggenname);
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currventwhenchargegenname);
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currdischargedummy1genname);
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currdischargedummy2genname);
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currcontinuoussolventgenname);
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currpump1genname);
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currpump2genname);
            end
            
            %CCSRes + VentRes + VentCharge + Discharge1Res + Discharge2Res <=
            %CCSMaxRes*(1+1/(EGrid/ECO2Capture))+ContSolvGen+Pump1PumpLoad+Pump2PumpLoad
                %SPINNING RESERVES
            currgenramprate=futurepowerfleetforplexos{currbasegenrow,fleetmaxrampupcol};
            raisereserverow=find(strcmp(misoreserves(:,reservenamecol),'Spinning'));
            raisereservetimeframe=misoreserves{raisereserverow,reservetimeframecol}/60; %/60 to convert to minutes;
            basegenmaxraiseraise=currgenramprate*raisereservetimeframe; %MW/min * min = MW
            %Add name
            baseconstraintname='VentAndDisRaiseResCCSMaxRes';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', basegenmaxraiseraise*(1+1/futurepowerfleetforplexos{currbasegenrow,fleetegridpereco2capandregencol}),'','','',''); %RHS is true capac of SS generator
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname, 'Generation Coefficient', -1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Pump Load Coefficient', -1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Pump Load Coefficient', -1,'','','',''); %1 is the value of the coefficient
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump2genname); 
            
            %CCSRes + VentRes + VentCharge + Discharge1Res + Discharge2Res <=
            %(CCSMaxCapac-CCSGen)*(1+1/(EGrid/ECO2Capture))+ContSolvGen+Pump1PumpLoad+Pump2PumpLoad
                %SPINNING AND REGULATION RESERVES
            ccsmaxcapac=futurepowerfleetforplexos{currbasegenrow,fleetcapacitycol};
            %Add name
            baseconstraintname='VentAndDisResCCSSpareCapac';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', ccsmaxcapac*(1+1/futurepowerfleetforplexos{currbasegenrow,fleetegridpereco2capandregencol}),'','','',''); %RHS is true capac of SS generator
            if strcmp(reserverequirements,'miso') %only have regulation reserves if using MISO reserves
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currbasegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventinggenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventwhenchargegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currdischargedummy1genname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currdischargedummy2genname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            end
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname, 'Generation Coefficient', -1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Generation Coefficient', (1+1/futurepowerfleetforplexos{currbasegenrow,fleetegridpereco2capandregencol}),'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Pump Load Coefficient', -1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Pump Load Coefficient', -1,'','','',''); %1 is the value of the coefficient
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump2genname); 
            
            %CCSReserves <= (PMaxSolvent - pSolvent - pPump1 -
            %pPump2)*EGrid
                %This constraint restricts spinning reserves from the base
                %CCS generator to available solvent capacity times the
                %coefficient that relates solvent energy use to net grid
                %output.
            solventmaxcapac=futurepowerfleetforplexos{currunitcontinuoussolventrow,fleetcapacitycol};
            egrid=futurepowerfleetforplexos{currbasegenrow,fleetegridpereco2capandregencol};
            %Add name
            baseconstraintname='CCSSpareSolventRes';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', solventmaxcapac*egrid,'','','',''); %RHS is true capac of SS generator
            if strcmp(reserverequirements,'miso') %only have regulation reserves if using MISO reserves
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currbasegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            end
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname, 'Generation Coefficient', egrid,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Generation Coefficient', egrid,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Generation Coefficient', egrid,'','','',''); %1 is the value of the coefficient
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump2genname);   
            clear solventmaxcapac egrid;
            
            %rCCS + rDischarge1 + rDischarge2 + rVent <= RDischarge1
                %Limit max reserves from all units to max reserves from
                %discharge 1. Spinning reserves.
            currssramprate=futurepowerfleetforplexos{currunitdischargedummy1row,fleetmaxrampupcol};
            raisereserverow=find(strcmp(misoreserves(:,reservenamecol),'Spinning'));
            raisereservetimeframe=misoreserves{raisereserverow,reservetimeframecol}/60; %/60 to convert to minutes
            ssmaxraise=currssramprate*raisereservetimeframe; %MW/min * min = MW
            %Add name
            baseconstraintname='LimRaiseResToSSMaxRes';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', ssmaxraise,'','','',''); %RHS is true capac of SS generator
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname);
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname);   
            clear ssmaxraise currssramprate regreserverow regreservetimeframe
            
            %Duplicate above for regulation reserves
            if strcmp(reserverequirements,'miso')
                currssramprate=futurepowerfleetforplexos{currunitdischargedummy1row,fleetmaxrampupcol};
                regreserverow=find(strcmp(misoreserves(:,reservenamecol),'RegulatingUp'));
                regreservetimeframe=misoreserves{regreserverow,reservetimeframecol}/60; %/60 to convert to minutes
                ssmaxregraise=currssramprate*regreservetimeframe; %MW/min * min = MW
                %Add name
                baseconstraintname='LimRegResToSSMaxRes';
                constraintname=strcat(baseconstraintname,currbasegenname);
                %Add constraint object
                objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname);
                %Add constraint properties
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                    constraintname, 'Sense', -1,'','','',''); %-1 is <=
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                    constraintname, 'RHS', ssmaxregraise,'','','',''); %RHS is true capac of SS generator
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currbasegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currdischargedummy1genname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currdischargedummy2genname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventinggenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventwhenchargegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                %Add generator membership to constraint
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currbasegenname);
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currdischargedummy1genname);
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currdischargedummy2genname);
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currventinggenname);
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currventwhenchargegenname);
                clear ssmaxregraise currssramprate regreserverow regreservetimeframe
            end
            
%ADD RESERVE + GENERATION CONSTRAINTS ON UNIT GROUPS***********
            %CCSReserve + VentReserve + Discharge1Res + Discharge2Res + VentWhenChargeRes + 
            %CCSGen + VentGen + Discharge1Gen + Discharge2Gen + VentWhenChargeGen <= 
            %SSDischarge1MaxCapac
                %Limit net generation + reserves to max gen w/ SS discharge
                %(= max gen w/ venting)
            %Get SS penalty
            ssdischarge1maxcapac=futurepowerfleetforplexos{currunitdischargedummy1row,fleetcapacitycol};
            %Add name
            baseconstraintname='AllGenAndReserves';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS',ssdischarge1maxcapac,'','','',''); %RHS is true capac of SS generator
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            if strcmp(reserverequirements,'miso') %only have regulation reserves if using MISO reserves
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currbasegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventinggenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currdischargedummy1genname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currdischargedummy2genname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventwhenchargegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            end
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname); 
            clear ssdischarge1maxcapac
            
            %CCSReserve + VentCharge + CCSGen + VentChargeGen <= CCSMaxCapac
            %Add name
            baseconstraintname='CCSAndVentChargeGenAndRes';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', futurepowerfleetforplexos{currbasegenrow,fleetcapacitycol},'','','',''); %RHS is true capac of SS generator
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            if strcmp(reserverequirements,'miso')
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currbasegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventwhenchargegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            end
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname);  
            
            
%ADD CONSTRAINT ON TOTAL PRODUCTION (NET + INTERNAL) AT PLANT**************
            %All gen + reserves + solvent <= ContSolventMax + SSMax
                %This constraint allows for SS discharge reserves to be
                %provided even when @ max base generation.
            ssdischarge1maxcapac=futurepowerfleetforplexos{currunitdischargedummy1row,fleetcapacitycol};
            contsolventmaxcapac=futurepowerfleetforplexos{currunitcontinuoussolventrow,fleetcapacitycol};
            %Add name
            baseconstraintname='AllGenResAndSolvent';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS',ssdischarge1maxcapac+contsolventmaxcapac,'','','',''); %RHS is true capac of SS generator
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpumpdummy1genname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpumpdummy2genname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            if strcmp(reserverequirements,'miso') %only have regulation reserves if using MISO reserves
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currbasegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventinggenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currdischargedummy1genname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currdischargedummy2genname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventwhenchargegenname, 'Regulation Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            end
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Raise Reserve Provision Coefficient', 1,'','','',''); %1 is the value of the coefficient
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpumpdummy1genname); 
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpumpdummy2genname); 
            clear contsolventmaxcapac ssdischarge1maxcapac

            
%ADD GROUP RAMPING CONSTRAINTS*********************************
            %RampCCS + RampDischarge1 + RampDischarge2 + RampVentCharge +
            %RampPumpDummy1 + RampPumpDummy2 + RampContinuousSolvent + RampVent <= RampLimitCCS
                %This is basicaly limiting ramping of fuel input, hence
                %inclusion of all generators. Set ramp limit to lowest ramp
                %limit, which is base plant, which is set based on boiler
                %ramping. Note that Ramp here refers to RampUp-RampDown;
                %can use Ramp Coefficient in PLEXOS (which is equivalent to
                %using Ramp Up Coeff = 1 and Ramp Down Coeff = -1).
            %Add name
            baseconstraintname='RampUpAllUnits';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            %Need to multiply RHS by 60 since constraint is in MW, not
            %MW/min., and ramp value is in MW/min.
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', futurepowerfleetforplexos{currbasegenrow,fleetmaxrampupcol}*60,'','','',''); %RHS is true capac of SS generator
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Ramp Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Ramp Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname, 'Ramp Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Ramp Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Ramp Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Ramp Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpumpdummy1genname, 'Ramp Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpumpdummy2genname, 'Ramp Coefficient', 1,'','','',''); %1 is the value of the coefficient
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpumpdummy1genname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpumpdummy2genname);  

            
            %RampCCS <= MaxRampCCS + (VentChargeOn + Discharge1On +
            %Discharge2On + VentOn)*CCSMaxCapac
                %This constraint enforces max ramp of CCS when other
                %components are not on, and allows it to ramp freely when
                %those other components are on (so, for instance, venting
                %generator can totally replace base generator).
            ccsmaxcapac=futurepowerfleetforplexos{currbasegenrow,fleetcapacitycol};
            %Add name
            baseconstraintname='RampCCSUnit';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            %Need to multiply RHS by 60 since constraint is in MW, not
            %MW/min., and ramp value is in MW/min.
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', futurepowerfleetforplexos{currbasegenrow,fleetmaxrampupcol}*60,'','','',''); %RHS is true capac of SS generator
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currbasegenname, 'Ramp Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventinggenname, 'Units Generating Coefficient', -ccsmaxcapac,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname, 'Units Generating Coefficient', -ccsmaxcapac,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname, 'Units Generating Coefficient', -ccsmaxcapac,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname, 'Units Generating Coefficient', -ccsmaxcapac,'','','',''); %1 is the value of the coefficient
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currbasegenname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventinggenname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy1genname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currdischargedummy2genname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currventwhenchargegenname);  
            
            
%TOTAL SOLVENT FLOW CONSTRAINT*********************************************
            %Pump1Gen + Pump2Gen + Pump1PumpLoad + Pump2PumpLoad +
            %ContinuousSolventGen <= ContinuousSolventCapacity
                %Enforce total solvent flow constraint. Power generation at
                %affected units are all equivalent to solvent flow.
                %Combined solvent flow rate cannot exceed max capacity of
                %continuous solvent unit, which is size of regneerator when
                %right-sized.
            %Add name
            baseconstraintname='SolventFlow';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', futurepowerfleetforplexos{currunitcontinuoussolventrow,fleetcapacitycol},'','','',''); %RHS is true capac of SS generator
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Pump Load Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Pump Load Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump1genname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currpump2genname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname, 'Generation Coefficient', 1,'','','',''); %1 is the value of the coefficient
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump1genname);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currpump2genname);  
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                currcontinuoussolventgenname);
            
%COMBINED END VOLUME CONSTRAINT********************************************
            %EndVolPump1Lean + EndVolPump2Lean <= MaxVolPump1Lean
                %This constraint limits total stored solvent at any time to
                %the max volume of stored lean at pump 1, which is equal to
                %the total capacity of the stored solvent system (which
                %varies with # hours of storage & solvent throughput).
            %Get lean solvent names
            leansolvent1name=strcat(currpump1genname,'Lean');
            leansolvent2name=strcat(currpump2genname,'Lean');
            %Get total lean solvent volume with:
            %StoredLeanVol=SolventStorageSize*TotalSSGenCapacity/1000
            ssgen1capac=futurepowerfleetforplexos{currunitpump1row,fleetcapacitycol};
            ssgen2capac=futurepowerfleetforplexos{currunitpump2row,fleetcapacitycol};
            totalstoredvolume=solventstoragesize*(ssgen1capac+ssgen2capac)/1000;
            %Now create constraint
            baseconstraintname='EndVolume';
            constraintname=strcat(baseconstraintname,currbasegenname);
            %Add constraint object
            objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname); 
            %Add constraint properties
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'Sense', -1,'','','',''); %-1 is <=
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                constraintname, 'RHS', totalstoredvolume,'','','',''); %RHS is true capac of SS generator
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Storage',constraintname,...
                leansolvent1name, 'End Volume Coefficient', 1,'','','',''); %1 is the value of the coefficient
            propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Storage',constraintname,...
                leansolvent2name, 'End Volume Coefficient', 1,'','','',''); %1 is the value of the coefficient
            %Add generator membership to constraint
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Storage',constraintname,...
                leansolvent1name);   
            membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Storage',constraintname,...
                leansolvent2name);  
            
%DISALLOW VENTING UNITS FROM TURNING OF IF DON'T ALLOW VENTING*************
            if allowventing==0
                %VentOn + VentChargeOn <= 0
                    %This constraint prohibits venting or venting when
                    %charging units from turning on.
                baseconstraintname='DisallowVent';
                constraintname=strcat(baseconstraintname,currbasegenname);
                %Add constraint object
                objectdata = AddObjectToPLEXOSFile(objectdata,'Constraint',constraintname);
                %Add constraint properties
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                    constraintname, 'Sense', -1,'','','',''); %-1 is <=
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Constraint','System',...
                    constraintname, 'RHS', 0,'','','',''); 
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventinggenname, 'Units Generating Coefficient', 1,'','','',''); %1 is the value of the coefficient
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Constraint','Generator',constraintname,...
                    currventwhenchargegenname, 'Units Generating Coefficient', 1,'','','',''); %1 is the value of the coefficient
                %Add generator membership to constraint
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currventinggenname);
                membershipsdata=AddMembershipToPLEXOSFile(membershipsdata,'Constraint','Generator',constraintname,...
                    currventwhenchargegenname);
            end
        end 
        'Added flexible CCS constraints'
    end
end


%%
%% DETERMINE CARBON PRICE TO ACHIEVE CLEAN POWER PLAN COMPLIANCE
if calculatecppco2price==1
    %Call function that determines required carbon price to comply with the
    %Clean Power Plan. Does so by reducing plant fleet size, then running a
    %simple economic dispatch (LP) on net system demand for each hour of year
    %for a given C price, and checking emissions mass/rate against requirements
    %under Clean Power Plan.
    %INPUTS: future power fleet, file name that has demand profile, file name
    %that has wind generation profile, file name that has solar generation
    %profile, and how hydro is modeled (modelhydrowithmonthlymaxenergy=1 if
    %using monthly max energy, 0 if using capacity factor; pass this in b/c if
    %using capcaity factor, then want to eliminate hydro plants along w/ wind &
    %solar),usenldc (indicates whether using NLDC),groupplants (indicates
    %whether grouping certain plants)
    %OUTPUTS: CO2 price that triggers CPP-compliant emissions rate (cppequivalentco2price) [$/ton],
    %cell array w/ all tested CO2 prices and the emissions rate and mass limit
    %gaps at those prices, and the MISO region-wide emissions rate and mass
    %limits
    'StartingCarbonPriceCalculations'
    [cppequivalentco2price,carbonpricesandemissions,misoemissionsrateandmasslimits]=...
        CalculateCarbonPriceForCompliance(futurepowerfleetforplexos,...
        demandfilenames,csvfilenamewithwindgenprofiles,csvfilenamewithsolargenprofiles,...
        demandscenarioforanalysis,modelhydrowithmonthlymaxenergy,hydroratingfactors,...
        usenldc,groupplants,removehydrofromdemand,testlowermasslimit,masslimitscalar,pc);
    'DeterminedCarbonPriceForCPPCompliance'
elseif setco2pricetoinputvalue==1
    cppequivalentco2price=co2priceinput;
else
    cppequivalentco2price=0;
end

%% ADD CARBON PRICE TO PLEXOS SHEET
%Add carbon price as a 'Shadow Price' and 'Price' property to the CO2CPP
%emissions object. Note that CO2CPP is the CO2 objected for affected EGUs
%under CPP, and only want to assign carbon tax to them. 

%Shadow Price property is necessary to have the emissions
%cost be rolled into the operating cost coefficient on the generator in the
%optimization objective function. Shadow Price should automatically carry
%over to Price, but will fill it in anyways.
%Shadow Price and Price in PLEXOS: [$/kg]
%Price from above function: [$/ton]
%Convert ton to kg: [$/ton]*[ton/907.185kg]=[$/kg]
cppequivalentco2pricekg=cppequivalentco2price/tontokg;
propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Emission','System',...
                'CO2CPP','Shadow Price',cppequivalentco2pricekg,'','','','');
propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'System','Emission','System',...
                'CO2CPP','Price',cppequivalentco2pricekg,'','','','');


%% ADD RESERVE OFFER PRICE AND QUANTITY
%To co-optimize reserves in PLEXOS, need to input an Offer Price and Offer
%Quantity for each generator-reserve pair. Offer Price is set to some
%proportion of the generator's operating cost (HR*FC + EmRate*EmPrice + VOM).
%Offer Quantity is set equal to ramp ramp of generator times timeframe of
%reserve. 
%Go through fleet, excluding generators that don't participate in reserves.
%For each generator, for each reserve, add in Offer Price and Offer
%Quantity. 
fleetvomcol=find(strcmp(futurepowerfleetforplexos(1,:),'VOMPerMWhCalculated'));
for fleetctr=2:size(futurepowerfleetforplexos,1)
    %Check if fuel type is not one of fuel types to be excluded
    if any(ismember(futurepowerfleetforplexos{fleetctr,fleetfueltypecol},fueltypestoexcludefromreserves))==0
        %Check that it's not a pump, pump dummy, or continuous solvent
        %generator
        if strcmp(futurepowerfleetforplexos{fleetctr,fleetplanttypecol},'ContinuousSolvent')==0 && ...
                strcmp(futurepowerfleetforplexos{fleetctr,fleetplanttypecol},'SSPump')==0 && ...
                strcmp(futurepowerfleetforplexos{fleetctr,fleetplanttypecol},'SSPumpDummy')==0
            %Get generator name
            currgenname=createplexosobjname(futurepowerfleetforplexos,...
                fleetorisidcol,fleetunitidcol,fleetctr);
            %Get gen ramp rate
            currgenramprate=futurepowerfleetforplexos{fleetctr,fleetmaxrampupcol};
            %Get gen info for calculating operating cost. Use
            %fleethrforedcol instead of fleetheatratecol b/c for flexible
            %CCS generators, watn the base CCS generator to reflect net
            %heat rate of CCS unit, not gross heat rate; but have ot use
            %regular column for vent & SS discharge units, since don't have
            %values in hrforedcol. Same for emissions rate and VOM too.
            if strcmp(futurepowerfleetforplexos{fleetctr,fleetplanttypecol},'SSDischargeDummy') || ...
                    strcmp(futurepowerfleetforplexos{fleetctr,fleetplanttypecol},'SSVentWhenCharge') || ...
                    strcmp(futurepowerfleetforplexos{fleetctr,fleetplanttypecol},'Venting')
                genhr=futurepowerfleetforplexos{fleetctr,fleetheatratecol}*gjtobtu*1000;
                genco2emsrate=futurepowerfleetforplexos{fleetctr,fleetco2emsratecol};
                genso2emsrate=futurepowerfleetforplexos{fleetctr,fleetso2emsratecol};
                gennoxemsrate=futurepowerfleetforplexos{fleetctr,fleetnoxemsratecol};
                genvom=futurepowerfleetforplexos{fleetctr,fleetvomcol};
            else
                genhr=futurepowerfleetforplexos{fleetctr,fleethrforedcol}*gjtobtu*1000;
                genco2emsrate=futurepowerfleetforplexos{fleetctr,fleetco2emsrateforedcol};
                genso2emsrate=futurepowerfleetforplexos{fleetctr,fleetso2emsrateforedcol};
                gennoxemsrate=futurepowerfleetforplexos{fleetctr,fleetnoxemsrateforedcol};
                genvom=futurepowerfleetforplexos{fleetctr,fleetvomforedcol};
            end           
            %Get remaining parameters
            genso2price=futurepowerfleetforplexos{fleetctr,fleetso2pricecol};
            gennoxprice=futurepowerfleetforplexos{fleetctr,fleetnoxpricecol};
            genfuelcost=futurepowerfleetforplexos{fleetctr,fleetfuelpricecol};
            genaffectedegu=futurepowerfleetforplexos{fleetctr,fleetaffectedegucol}; %only adding CO2 price to affected EGUs
            %Calculate operating cost
            genopcost=genhr*genfuelcost+genvom+genco2emsrate*cppequivalentco2pricekg*genaffectedegu+...
                gennoxemsrate*gennoxprice+genso2emsrate*genso2price;
            %For each reserve, get offer quantity then add properties
            for reservectr=2:size(misoreserves,1) %for each reserve (row 1 = header)
                %Get reserve name & timeframe
                currreservename=misoreserves{reservectr,reservenamecol};
                reservetimeframe=misoreserves{reservectr,reservetimeframecol}/60; %convert from sec to min
                %Calculate Offer Quantity (ramp rate * reserve timeframe)
                genofferquantity=reservetimeframe*currgenramprate;
                %Calculate Offer Price (accounting for proportion to energy
                %cost)
                offerpriceproportion=misoreserves{reservectr,reserveofferpriceproportioncol};
                genofferprice=genopcost*offerpriceproportion;
                %Add Offer Price and Offer Quantity for generator-reserve
                %pair
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Reserve','Generator',currreservename,...
                    currgenname,'Offer Price',genofferprice,'','','','');
                propertiesdata=AddPropertyToPLEXOSFile(propertiesdata,'Reserve','Generator',currreservename,...
                    currgenname,'Offer Quantity',genofferquantity,'','','','');
            end            
        end
    end
end
'Added Reserves'
            
            
%%            
%% IMPORT REPORT SHEET
%Report sheet sets the fields that are reported by the Report Simulation
%object. I manually selected desired fields, then exported the database and
%saved the 'Reports' sheet to a new Excel file. 
%Import Reports sheet; then it's exported to Excel file without edits below.
if strcmp(pc,'work')
    reportfiletoimport='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\ReportsSheetForInclusionInImportedPLEXOSFile_1April2015.xlsx';
elseif strcmp(pc,'personal')
    reportfiletoimport='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\ReportsSheetForInclusionInImportedPLEXOSFile_1April2015.xlsx';
end
[~,~,reportfields]=xlsread(reportfiletoimport,'Reports');

%% SAVE MAT FILE
if strcmp(pc,'work')
    basematfilenametosave=strcat('C:\Users\mtcraig\Desktop\EPP Research\Matlab\Fleets\',basefilename);
elseif strcmp(pc,'personal')
    basematfilenametosave=strcat('C:\Users\mcraig10\Desktop\EPP Research\Matlab\Fleets\',basefilename);
end
matfilenametosave=strcat(basematfilenametosave,'.mat');
save(matfilenametosave);

%% SAVE FULL AND PLEXOS FLEETS TO CSV FILES
cell2csv(strcat(basematfilenametosave,'.csv'), futurepowerfleetforplexos);
if usenldc==1
    cell2csv(strcat(basematfilenametosave,'FULL.csv'), futurepowerfleetfull);
end

%% WRITE MAIN EXCEL FILE FOR PLEXOS
%File name to write
if strcmp(pc,'work')
    filenametowritemain=strcat('C:\Users\mtcraig\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\',basefilename,'.xlsx');
elseif strcmp(pc,'personal')
    filenametowritemain=strcat('C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\',basefilename,'.xlsx');
end

%Concatenate headers with data
objectdatatowrite=vertcat(objectheaders,objectdata);
categorydatatowrite=vertcat(categoryheaders,categorydata);
membershipsdatatowrite=vertcat(membershipsheaders,membershipsdata);
attributesdatatowrite=vertcat(attributeheaders,attributedata);
propertiesdatatowrite=vertcat(propertiesheader,propertiesdata);

%Sheets need to be named in a specific manner. PLEXOS will skip over 'Sheet
%1', 'Sheet 2', 'Sheet 3' if leave them in. 
%Set sheet names.
objectsheetname='Objects';
categoriessheetname='Categories';
membershipssheetname='Memberships';
attributessheetname='Attributes';
propertiessheetname='Properties';
reportssheetname='Reports';

xlswrite(filenametowritemain,objectdatatowrite,objectsheetname);
xlswrite(filenametowritemain,categorydatatowrite,categoriessheetname);
xlswrite(filenametowritemain,membershipsdatatowrite,membershipssheetname);
xlswrite(filenametowritemain,attributesdatatowrite,attributessheetname);
xlswrite(filenametowritemain,propertiesdatatowrite,propertiessheetname);
xlswrite(filenametowritemain,reportfields,reportssheetname);


