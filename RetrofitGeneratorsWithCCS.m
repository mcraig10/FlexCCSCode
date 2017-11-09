%Michael Craig, 13 July 2015
%Function retrofits CCS on coal-fired generators. Top portion of script
%includes all of the parameters used in defining flexible/inflexible CCS
%generators. Based on inputs, CCS retrofitted may be flexible or
%inflexible. In adding inflexible CCS, only the coal plant's parameters are
%changed; for flexible CCS, these changes are made, and venting and solvent
%storage generators are also added to the power fleet. Included in SS
%generator is a dummy generator that provides power to the SS
%generator unit when pumping.

%INPUTS: futurepowerfleetforplexos, mwccstoadd (MW of CCS to retrofit),
%flexibleccs (if =1, add flexible CCS; if =0, add inflexible CCS).
%OUTPUTS: futurepowerfleetforplexos (includes venting and solvent storage
%generators if adding flexible CCS), regeneratoroversize (% by which regenerator is oversized/undersized; if
%not oversized, value = 0); solventstoragesize (hours of full load
%operation), stminload (steam turbine min load, as %age ponits below boiler load, so if
%boiler min load is 30%, stminload=10 means st min load is 20%). 

function [futurepowerfleetforplexos,regeneratoroversize,capacitypenalty,...
    solventstoragecapacitypenaltyreduction,ventingcapacitypenaltyreduction,stminload] =...
    RetrofitGeneratorsWithCCS(futurepowerfleetforplexos, ...
    mwccstoadd, flexibleccs, pc, solventstoragesize)


%% GET COLUMN NUMBERS OF FLEET
[fleetorisidcol, fleetunitidcol, fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol, fleetregioncol, fleetstatecol, fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);
fleetvomcol=find(strcmp(futurepowerfleetforplexos(1,:),'VOMPerMWhCalculated'));
bitfuelusecol=find(strcmp(futurepowerfleetforplexos(1,:),'BITFuelUseTotal'));
subbitfuelusecol=find(strcmp(futurepowerfleetforplexos(1,:),'SUBFuelTotal'));
noxpricecol=find(strcmp(futurepowerfleetforplexos(1,:),'NOxPrice($/kg)'));
so2pricecol=find(strcmp(futurepowerfleetforplexos(1,:),'SO2Price($/kg)'));
so2groupcol=find(strcmp(futurepowerfleetforplexos(1,:),'SO2CSAPRGroup'));


%% ADD COLUMNS TO FUTUREPOWERFLEET
%Run this section of code every time call script so that these
%futurepowerfleet always has the columsn tacked on to end, even if not
%used. Necessary for operations in CreatePLEXOSImportFile.

%Add column in futurepowerfleet that indicates whether has CCS retrofit.
%Also add columns for pumping parameters for solvent storage (even if not
%including any because don't have flexible CCS) - Pump Efficiency, Pump
%Load, Pump Units. (Min Pump Load = 0, so no need to enter.)
%Fill in columns with zeros.
zeroscell=num2cell(zeros(size(futurepowerfleetforplexos,1)-1,1)); %-1 b/c account for header
fleetccsretrofitcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,fleetccsretrofitcol}='CCS Retrofit';
futurepowerfleetforplexos(2:end,fleetccsretrofitcol)=zeroscell;
fleetpumpunitscol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,fleetpumpunitscol}='Pump Units';
futurepowerfleetforplexos(2:end,fleetpumpunitscol)=zeroscell;
fleetpumpeffcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,fleetpumpeffcol}='Pump Efficiency (%)';
futurepowerfleetforplexos(2:end,fleetpumpeffcol)=zeroscell;
fleetpumploadcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,fleetpumploadcol}='Pump Load (MW)';
futurepowerfleetforplexos(2:end,fleetpumploadcol)=zeroscell;
fleettruesscapaccol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,fleettruesscapaccol}='True SS Capacity (MW)';
futurepowerfleetforplexos(2:end,fleettruesscapaccol)=zeroscell;
%Also add columns for CCS retrofit parameters from IECM. 
ccshrpenaltycol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,ccshrpenaltycol}='CCS HR Penalty (%)';
futurepowerfleetforplexos(2:end,ccshrpenaltycol)=zeroscell;
ccscapacpenaltycol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,ccscapacpenaltycol}='CCS Capacity Penalty (%)';
futurepowerfleetforplexos(2:end,ccscapacpenaltycol)=zeroscell;
ccssshrpenaltycol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,ccssshrpenaltycol}='CCS SS HR Penalty (%)';
futurepowerfleetforplexos(2:end,ccssshrpenaltycol)=zeroscell;
ccssscapacitypenaltycol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,ccssscapacitypenaltycol}='CCS SS Capacity Penalty (%)';
futurepowerfleetforplexos(2:end,ccssscapacitypenaltycol)=zeroscell;
%This is energy for extra solvent to bind CO2 from the fuel used to
%generate energy for storing lean solvent.
eextrasolventperestoredsolventcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,eextrasolventperestoredsolventcol}='E for Extra Solvent per E Used to Store Lean Solvent (MMWh/MWh)';
futurepowerfleetforplexos(2:end,eextrasolventperestoredsolventcol)=zeroscell;
eregenpereco2capturecol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,eregenpereco2capturecol}='E to Regenerator per E to CO2 Capture (MWh/MWh)';
futurepowerfleetforplexos(2:end,eregenpereco2capturecol)=zeroscell;
egridpereregenandco2capcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,egridpereregenandco2capcol}='E to Grid per E to CO2 Capture and Regenerator (MMWh/MWh)';
futurepowerfleetforplexos(2:end,egridpereregenandco2capcol)=zeroscell;
egridperestoredsolventcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,egridperestoredsolventcol}='E to Grid per E Used to Store Lean Solvent (MMWh/MWh)';
futurepowerfleetforplexos(2:end,egridperestoredsolventcol)=zeroscell;

%Also create dummy output variables
regeneratoroversize=0; capacitypenalty=0;
ventingcapacitypenaltyreduction=0; solventstoragecapacitypenaltyreduction=0;
stminload=0;

%Also add columns that will hold HR & emissions rates just for use in econ
%dispatch. Need these because flexible CCS base unit, which is included in
%econ dispatch, won't have appropriate HR & ems rate once strip out rest of
%units. So will put value just for ED here. Initailize these columns with
%"true" columns.
hrforedcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,hrforedcol}='HRForED';
futurepowerfleetforplexos(2:end,hrforedcol)=futurepowerfleetforplexos(2:end,fleetheatratecol);
co2emsrateforedcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,co2emsrateforedcol}='CO2EmsRateForED';
futurepowerfleetforplexos(2:end,co2emsrateforedcol)=futurepowerfleetforplexos(2:end,fleetco2emsratecol);
noxemsrateforedcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,noxemsrateforedcol}='NOxEmsRateForED';
futurepowerfleetforplexos(2:end,noxemsrateforedcol)=futurepowerfleetforplexos(2:end,fleetnoxemsratecol);
so2emsrateforedcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,so2emsrateforedcol}='SO2EmsRateForED';
futurepowerfleetforplexos(2:end,so2emsrateforedcol)=futurepowerfleetforplexos(2:end,fleetso2emsratecol);
vomforedcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,vomforedcol}='VOMForED';
futurepowerfleetforplexos(2:end,vomforedcol)=futurepowerfleetforplexos(2:end,fleetvomcol);


%% RETROFIT CCS PLANTS
if mwccstoadd>0
    
%% SET PARAMETERS**********************************************************

%% IMPORT PARAMETERS FROM IECM
%Below function runs regressions on CCS paramaeters imported from IECM for
%bit and subbit plants separately. Regression is run on 3 plants of varying
%heat rate - all regressions are run with net heat rate, either of pre-CCS
%or w/ CCS plant, as independent variable. Parameters imported here:
%CCS & SS/Venting HR & Capacity penalties (regressed on original HR), then
%several variables regressed on post-CCS retrofit HR: regenerator to CO2
%capture system energy use, energy use for extra solvent to capture CO2
%from fuel used to generate energy to store lean solvent, energy delviered
%to grid per energy used at regenerator plus CO2 captrue system, energy
%delivered to grid while discharging stored solvent per unit of energy used
%to store solvent. 
[lmnethrpenaltybit, lmcapacpenaltybit, lmssnethrpenaltybit, lmsscapacpenaltybit, ...
    lmeextraperestoresolventbit, lmegridpereco2capandregenbit, lmegridssperetostoreleanbit,regentoco2capeuseratiobit,...
    lmnethrpenaltysubbit, lmcapacpenaltysubbit, lmssnethrpenaltysubbit, lmsscapacpenaltysubbit, ...
    lmeextraperestoresolventsubbit, lmegridpereco2capandregensubbit, lmegridssperetostoreleansubbit,regentoco2capeuseratiosubbit]...
    = RunRegressionsOnIECMCCSParameters(pc);

%% CO2 CAPTURE 
%Some parameters already imported above.
%CO2 emissions reduction from CCS retrofit
co2emissionsreduction=90; %percent

%Year in which CCS is installed (for calculating ages of boilers, which in
%turn determines which plants meet Haibo criteria).
yeartoinstallccs=2020;

%SO2 emissions rate with CO2 capture. Zero out SO2 emissions rate due to
%higher required SO2 removal prior to CO2 capture.
so2emissionsratewithccs=0;

%Min stable level remains same % of capacity. 
%Ramp rate remains same % of capacity. 

%% FLEXIBLE CCS FACILITIES' PARAMETERS (NOT INCLUDED ABOVE)
if flexibleccs==1
    
    %% SOLVENT STORAGE PARAMETERS
    %Already loaded in several parameters above.    
    %Regenerator oversize
    regeneratoroversize=0; %percent
    
    %Solvent storage ramp rate (%/min.)
    solventstorageramprate=4; %percent/min.
        
    %Steam turbine minimum load - this is not a part of the SS generator.
    %Rather, this is the min load (% of capacity) for the steam turbine at
    %the base plant, since if solvent storage is included at plant, plant
    %can meet min load of boiler with plant generation + regenerating rich
    %solvent (i.e., w/ pumping). ST min load is given as percentage points
    %lower than boiler min load, i.e. min load currently used for coal
    %plants. E.g., if min load of coal plant is originally 40% and
    %stminload=10, then ST min load = 30% (=40%-10%). Value based on
    %IEAGHG 2012 paper. 
    stminload=10; %percent lower than boiler min load
    
    %% VENTING
    %Will use same parameters for venting as for solvent storage;
    %parameters other than ramp rate imported above.
    %Venting ramp rate
    ventingramprate=4; %percent/min.
end

%% SELECT PLANTS TO RETROFIT***********************************************
%Base coal plant selection for retrofits on Haibo paper. Key indicators:
%thermal efficiency, age, control technologies, and capacity. Isolate these
%values for coal plants, find coal plants that meet Haibo criteria and have
%all necessary CTs installed for CCS, then go down list and retrofit CCS
%until have desired capacity (per mwccstoadd). 

%Isolate coal plants
coalplantrows=find(strcmp(futurepowerfleetforplexos(:,fleetfueltypecol),'Coal'));
coalplants=futurepowerfleetforplexos(coalplantrows,:);
%Eliminate newly-constructed (constructed by IPM) coal plants, which have
%the name 'New' in the PlantName column
plantnamecol=find(strcmp(futurepowerfleetforplexos(1,:),'PlantName'));
newcoalplantrows=find(strcmp(coalplants(:,plantnamecol),'New'));
coalplants(newcoalplantrows,:)=[];

%Isolate boiler ages - online year column is 'OnLineYear'
onlineyearcol=find(strcmp(futurepowerfleetforplexos(1,:),'OnLineYear'));
%Put boiler ages into numeric array
onlineyears=cell2mat(coalplants(:,onlineyearcol));
%Get age by subtracting from yeartoinstallccs
boilerages=yeartoinstallccs-onlineyears;

%Get heat rate
heatrates=cell2mat(coalplants(:,fleetheatratecol));
%Get thermal efficiency (%Thermal efficiency = 3414/HR)
thermalefficiencies=3414./heatrates;

%Get capacities
capacities=cell2mat(coalplants(:,fleetcapacitycol));

%Haibo paper criteria: net thermal efficiency > 30% (=3414/HR), capacity > 300 MW. 
%Also specifies plants of 20-40 years old is best; here, just use <40 years
%old in 2020. 2020 because that's a good midrange in when coal plants may
%be retrofitting CCS in near future, and <40 years old because, 1, to get
%enough capacity of CCS retrofits in system, and 2, better to be young than
%old. Isolate coal generators that meet these criteria.
plantsthermaleffhigh=(thermalefficiencies>.3);
plantscapachigh=(capacities>300);
plantsyoung=boilerages<40;

%Find overlap
plantsmeetinghaibocriteria=coalplants(plantsthermaleffhigh & plantscapachigh & plantsyoung,:);

%CONTROL TECHNOLOGIES
%Get column names for control tech info (SCR in first, FGD in second)
postcombcol=find(strcmp(futurepowerfleetforplexos(1,:),'Post Combustion Control and Heat Rate Improvement'));
scrubbercol=find(strcmp(futurepowerfleetforplexos(1,:),'Post Combustion Control (Scrubber: Wet/Dry)'));
%For coal plants in compliance w/ Haibo criteria, see which ones have SCR &
%scrubber (necessary for CO2 capture).
plantshaiboandcts={};
for i=1:size(plantsmeetinghaibocriteria,1)
    if findstr(plantsmeetinghaibocriteria{i,scrubbercol},'Scrubber')
        if findstr(plantsmeetinghaibocriteria{i,postcombcol},'SCR')
            plantshaiboandcts(end+1,:)=plantsmeetinghaibocriteria(i,:);
        end
    end
end
plantshaiboandcts

%Now select plants for CCS retrofits - sort from most to lease efficient 
%(lowest to highest HR), and save ORIS and Unit ID.
ccsretrofitcapac=0; 
plantshaiboandcts=sortrows(plantshaiboandcts,fleetheatratecol); %ascending, so lowest HR (most efficietn) is first
%Continue while have less flexible CCS than target
plantsforccsretrofit={}; 
rowctr=1;
while ccsretrofitcapac<=mwccstoadd
    %Get curr plant ORIS & unit ID
    currplant=plantshaiboandcts(rowctr,:);
    plantsforccsretrofit(end+1,:)={currplant{1,fleetorisidcol},currplant{1,fleetunitidcol}};
    %Increase MW of CCS installed
    currplantcapac=currplant{1,fleetcapacitycol};
    ccsretrofitcapac=ccsretrofitcapac+currplantcapac;
    %Increase row ctr
    rowctr=rowctr+1;
end


%% RETROFIT PLANTS*********************************************************
%When retrofit CCS, need to: increase heat rate, reduce capacity and CO2 emissions, and reduce min stable level
%and ramp rate of plant; and add solvent storage and venting generators if
%adding flexible CCS. Also need to save various parameter values obtained from IECM
%and stored in the imported regressions above. 
%For those regressions, need to determine plant's fuel type, then use
%predict to get appropriate value for regression.
%Other necessary model components (constraints, etc.)
%will be handled in another script. 

%Iterate through plants previously selected for retrofits; find row in
%futurepowerfleet; make necessary changes.
for i=1:size(plantsforccsretrofit,1)
    %Find row in futurepowerfleet
    currplantoris=plantsforccsretrofit{i,1};
    currplantunitid=plantsforccsretrofit{i,2};
    basegenrowinfleet=find(strcmp(futurepowerfleetforplexos(:,fleetorisidcol),currplantoris) & ...
        strcmp(futurepowerfleetforplexos(:,fleetunitidcol),currplantunitid));
    %Also determine whether plant is bit or subbit - want to use columns
    %'BITFuelUseTotal' and 'SUBFuelTotal' - whichever is larger. (For
    %plants eligible for retrofits, don't have values in both columns
    %anyways.)
    plantbituse=futurepowerfleetforplexos{basegenrowinfleet,bitfuelusecol};
    plantsubbituse=futurepowerfleetforplexos{basegenrowinfleet,subbitfuelusecol};
    if plantbituse > plantsubbituse
        currplantfuel='Bit';
    else
        currplantfuel='Subbit';
    end
    
    %For regressions that depend on fuel type, set which regressions will
    %be used based on fuel type.
    if strcmp(currplantfuel,'Bit')
        lmnethrpenalty=lmnethrpenaltybit;
        lmcapacpenalty=lmcapacpenaltybit;
        lmssnethrpenalty=lmssnethrpenaltybit;
        lmsscapacpenalty=lmsscapacpenaltybit;
        lmeextraperestoresolvent=lmeextraperestoresolventbit;
        lmegridpereco2capandregen=lmegridpereco2capandregenbit;
        lmegridssperetostorelean=lmegridssperetostoreleanbit;
        regentoco2capeuseratio=regentoco2capeuseratiobit;
    elseif strcmp(currplantfuel,'Subbit')
        lmnethrpenalty=lmnethrpenaltysubbit;
        lmcapacpenalty=lmcapacpenaltysubbit;
        lmssnethrpenalty=lmssnethrpenaltysubbit;
        lmsscapacpenalty=lmsscapacpenaltysubbit;
        lmeextraperestoresolvent=lmeextraperestoresolventsubbit;
        lmegridpereco2capandregen=lmegridpereco2capandregensubbit;
        lmegridssperetostorelean=lmegridssperetostoreleansubbit;
        regentoco2capeuseratio=regentoco2capeuseratiosubbit;
    end
    
%% ALTER PARAMETERS OF BASE PLANT
    %Add CCS retrofit indicator
    futurepowerfleetforplexos{basegenrowinfleet,fleetccsretrofitcol}=1;
    
    %If flexible CCS, will use gross heat rate post-CCS retrofit, which = net heat rate
    %prior to CCS retrofit, which is just heat rate already assigned to
    %plant. However, need to calculate net HR post-CCS retrofit for later
    %regressions, so also calculate that. 
    %If inflexible CCS, use net heat rate. 
    %Increase heat rate (New HR = Old HR * (1+HRPenalty/100))
    ccsgrosshr=futurepowerfleetforplexos{basegenrowinfleet,fleetheatratecol};
    ccshrpenalty=predict(lmnethrpenalty,ccsgrosshr)*100; %comes out as fraction; convert to %
    futurepowerfleetforplexos{basegenrowinfleet,ccshrpenaltycol}=ccshrpenalty;
    ccsnethr=ccsgrosshr * (1+ccshrpenalty/100);
    if flexibleccs==0
        futurepowerfleetforplexos{basegenrowinfleet,fleetheatratecol}=ccsnethr;
    end
    
    %Save heat rate value in col for econ dispatch - want the inflexible
    %CCS heat rate.
    futurepowerfleetforplexos{basegenrowinfleet,hrforedcol}=ccsnethr;
    
    %Save original capacity
    originalcapac=futurepowerfleetforplexos{basegenrowinfleet,fleetcapacitycol};
    %Now modify capacity w/ CCS capacity penalty - use predict.
    ccscapacpenalty=predict(lmcapacpenalty,ccsgrosshr)*100; %comes out as fraction; convert to %
    futurepowerfleetforplexos{basegenrowinfleet,ccscapacpenaltycol}=ccscapacpenalty;
    futurepowerfleetforplexos{basegenrowinfleet,fleetcapacitycol}=...
        originalcapac * (1+ccscapacpenalty/100);%Capac penalty already comes out as negative
    
    %EMISSIONS
    %Since dealing with emissions rates in lb/MWh, when I reduce capacity
    %of plant, I need to scale up CO2 emissions so that total emissions
    %(Rate*Capac) does not change. For flex CCS, going to model emissions at each
    %proxy unit, so need to scale emissions based on joint capacity of base
    %CCS & continuous solvent unit. For inflex CCS, just scale based on capacity
    %of base generator.
    %To do this, first get original emissions rates & masses.
    originalco2emissionsrate=futurepowerfleetforplexos{basegenrowinfleet,fleetco2emsratecol};
    originalco2mass=originalco2emissionsrate*originalcapac;
    originalnoxemissionsrate=futurepowerfleetforplexos{basegenrowinfleet,fleetnoxemsratecol};
    originalnoxmass=originalnoxemissionsrate*originalcapac;
    originalso2emissionsrate=futurepowerfleetforplexos{basegenrowinfleet,fleetso2emsratecol};
    originalso2mass=originalso2emissionsrate*originalcapac;
    
    %Now get capacity with which we will scale emissions. Need following
    %IECM parameter first (and load this outside if statement so get value
    %even if doing inflexible CCS).
    futurepowerfleetforplexos{basegenrowinfleet,egridpereregenandco2capcol}=...
            predict(lmegridpereco2capandregen,ccsnethr);
    if flexibleccs==0
        emissionsratescapacforscale=futurepowerfleetforplexos{basegenrowinfleet,fleetcapacitycol};
    elseif flexibleccs==1
        %Need to get continuous solvent capacity.
        %Capacity = CCSCapacity/(EGrid/ECO2Capture+Regenerator) 
        solventcapacity=futurepowerfleetforplexos{basegenrowinfleet,fleetcapacitycol}/futurepowerfleetforplexos{basegenrowinfleet,egridpereregenandco2capcol};
        %Add to base CCS capacity
        emissionsratescapacforscale=solventcapacity+futurepowerfleetforplexos{basegenrowinfleet,fleetcapacitycol};
    end
        
    %Now scale emissions
    newco2emissionsrate=originalco2mass/emissionsratescapacforscale;
    newnoxemissionsrate=originalnoxmass/emissionsratescapacforscale;
    newso2emissionsrate=originalso2mass/emissionsratescapacforscale;
    
    %Now save emissions rates - reduce CO2, set SO2=0, nothing to NOx. Zero
    %out SO2 b/c of higher removal requirements w/ CCS, but will have SO2
    %emissions rate w/ venting. 
    futurepowerfleetforplexos{basegenrowinfleet,fleetco2emsratecol}=...
        newco2emissionsrate * (1-co2emissionsreduction/100);   
    futurepowerfleetforplexos{basegenrowinfleet,fleetnoxemsratecol}=newnoxemissionsrate;
    futurepowerfleetforplexos{basegenrowinfleet,fleetso2emsratecol}=so2emissionsratewithccs;
    
    %Now save emissions rates to col for ED. If inflexible CCS, copy over
    %value. If flexible CCS, want same value as inflexible CCS (since won't
    %include any flexible components in ED).
    futurepowerfleetforplexos{basegenrowinfleet,so2emsrateforedcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetso2emsratecol}; %always the same (0)
    if flexibleccs==0
        futurepowerfleetforplexos{basegenrowinfleet,co2emsrateforedcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetco2emsratecol};
        futurepowerfleetforplexos{basegenrowinfleet,noxemsrateforedcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetnoxemsratecol};
    elseif flexibleccs==1
        emsratescalarfored=futurepowerfleetforplexos{basegenrowinfleet,fleetcapacitycol};
        futurepowerfleetforplexos{basegenrowinfleet,co2emsrateforedcol}=originalco2mass/emsratescalarfored*(1-co2emissionsreduction/100);
        futurepowerfleetforplexos{basegenrowinfleet,noxemsrateforedcol}=originalnoxmass/emsratescalarfored;
    end
    
    %VOM
    %VOM in PLEXOS is in $/MWh. If not modeling flexible CCS, need to
    %increase VOM to account for smaller net capacity of CCS generator. If
    %modeling flexible CCS, VOM is also assigned to continuous solvent, so
    %don't need change real value, but do need to change value in
    %VOMforEDcol because cont solvent is not included in simple ED.
    originalvom=futurepowerfleetforplexos{basegenrowinfleet,fleetvomcol};
    postretrofitvom=originalvom*originalcapac...
            /futurepowerfleetforplexos{basegenrowinfleet,fleetcapacitycol};
    futurepowerfleetforplexos{basegenrowinfleet,vomforedcol}=postretrofitvom;
    if flexibleccs==0
        futurepowerfleetforplexos{basegenrowinfleet,fleetvomcol}=postretrofitvom;
    end
    
    %Reduce min stable level. First back-calculate min load as % of
    %capacity. Then, if inflexible CCS, multiply by new capacity to get new min load. 
    %If flexible CCS, allow plant to reach min load level accepted by ST,
    %and will add another constraint that limits plant generation +
    %pumpload to original % min load. 
    minloadasfraction=futurepowerfleetforplexos{basegenrowinfleet,fleetminloadcol}/originalcapac;
    futurepowerfleetforplexos{basegenrowinfleet,fleetminloadcol}=...
        futurepowerfleetforplexos{basegenrowinfleet,fleetcapacitycol}*minloadasfraction;
    
    %Reduce ramp rate - back-calc ramp up/down as % of capacity, then
    %multiply by new capacity to get new min load
    ramprateupasfraction=futurepowerfleetforplexos{basegenrowinfleet,fleetmaxrampupcol}/originalcapac;
    rampratedownasfraction=futurepowerfleetforplexos{basegenrowinfleet,fleetmaxrampdowncol}/originalcapac;
    futurepowerfleetforplexos{basegenrowinfleet,fleetmaxrampdowncol}=...
        futurepowerfleetforplexos{basegenrowinfleet,fleetcapacitycol}*rampratedownasfraction;
    futurepowerfleetforplexos{basegenrowinfleet,fleetmaxrampupcol}=...
        futurepowerfleetforplexos{basegenrowinfleet,fleetcapacitycol}*ramprateupasfraction;
    
    %Save other IECM-derived retrofit parameters - these parameters all use
    %net HR post-CCS retrofit. 2 regressions:
    futurepowerfleetforplexos{basegenrowinfleet,eextrasolventperestoredsolventcol}=...
        predict(lmeextraperestoresolvent,ccsnethr);
    futurepowerfleetforplexos{basegenrowinfleet,egridperestoredsolventcol}=...
        predict(lmegridssperetostorelean,ccsnethr);
    %Then have E to regen per E to co2 cap ratio - this is not done by
    %regression, so just match based on closest heat rate.
    hrcol=find(strcmp(regentoco2capeuseratio(1,:),'CCS Net HR (Btu/kWh)'));
    ratiocol=find(strcmp(regentoco2capeuseratio(1,:),'E to Regenerator/E to CO2Cap (MWh/MWh)'));
    hrs=cell2mat(regentoco2capeuseratio(2:end,hrcol));
    ratios=cell2mat(regentoco2capeuseratio(2:end,ratiocol));
    hrdiffs=hrs-ccsnethr;
    [~,closesthrrow]=min(abs(hrdiffs));
    currratio=ratios(closesthrrow);
    futurepowerfleetforplexos{basegenrowinfleet,eregenpereco2capturecol}=currratio;
    
    %% ADD FLEXIBLE CCS GENERATORS
    if flexibleccs==1
        %% ADD CONTINUOUS SOLVENT GENERATOR
        %This generator breaks out energy use for capturing CO2 during
        %normal (continuous) operations.
        %Add generator
        solventfleetrow=size(futurepowerfleetforplexos,1)+1;
        futurepowerfleetforplexos{solventfleetrow,fleetorisidcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetorisidcol}; %equivalent to = currplantoris
        futurepowerfleetforplexos{solventfleetrow,fleetunitidcol}=...
            strcat(futurepowerfleetforplexos{basegenrowinfleet,fleetunitidcol},'ContinuousSolvent');%equivalent to = using currplantunitid+SS
        
        %Capacity = CCSCapacity/(EGrid/ECO2Capture+Regenerator) -> this
        %gives how much energy needs to go to co2 cap for max output.
        %Capacity is calculated above.
        futurepowerfleetforplexos{solventfleetrow,fleetcapacitycol}=solventcapacity;
        
        %Heat rate = gross HR
        solventhr=ccsgrosshr;
        futurepowerfleetforplexos{solventfleetrow,fleetheatratecol}=solventhr;
        
        %No ramp limit; but is included in aggregate boiler ramp rate
        %constraint. 
        
        %Set emissions rates equal to emisisons rates of base CCS unit. 
        futurepowerfleetforplexos{solventfleetrow,fleetso2emsratecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetso2emsratecol};
        futurepowerfleetforplexos{solventfleetrow,fleetnoxemsratecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetnoxemsratecol};
        futurepowerfleetforplexos{solventfleetrow,fleetco2emsratecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetco2emsratecol};
        
        %Copy down NOx & SO2 price info.
        futurepowerfleetforplexos{solventfleetrow,noxpricecol}=futurepowerfleetforplexos{basegenrowinfleet,noxpricecol};
        futurepowerfleetforplexos{solventfleetrow,so2pricecol}=futurepowerfleetforplexos{basegenrowinfleet,so2pricecol};
        futurepowerfleetforplexos{solventfleetrow,so2groupcol}=futurepowerfleetforplexos{basegenrowinfleet,so2groupcol};
        
        %Plug 0 into CCS retrofit
        futurepowerfleetforplexos{solventfleetrow,fleetccsretrofitcol}=0;
        
        %Set other values: min load = 0; Fossil unit; Coal fuel type; ContinuousSolvent plant type;
        %region, state, and fuel price same as CCS-equipped generator. VOM
        %= 0. 
        futurepowerfleetforplexos{solventfleetrow,fleetminloadcol}=0;
        futurepowerfleetforplexos{solventfleetrow,fleetplanttypecol}='ContinuousSolvent';
        futurepowerfleetforplexos{solventfleetrow,fleetfueltypecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfueltypecol};
        futurepowerfleetforplexos{solventfleetrow,fleetfossilunitcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfossilunitcol};
        futurepowerfleetforplexos{solventfleetrow,fleetstatecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetstatecol};
        futurepowerfleetforplexos{solventfleetrow,fleetregioncol}=futurepowerfleetforplexos{basegenrowinfleet,fleetregioncol};
        futurepowerfleetforplexos{solventfleetrow,fleetfuelpricecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfuelpricecol};
        futurepowerfleetforplexos{solventfleetrow,fleetvomcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetvomcol};
        %Set pump units to zero
        futurepowerfleetforplexos{solventfleetrow,fleetpumpunitscol}=0;
        %Also save bit & subbit fuel use
        futurepowerfleetforplexos{solventfleetrow,bitfuelusecol}=futurepowerfleetforplexos{basegenrowinfleet,bitfuelusecol};
        futurepowerfleetforplexos{solventfleetrow,subbitfuelusecol}=futurepowerfleetforplexos{basegenrowinfleet,subbitfuelusecol};
        %Zero out start cost & min down time
        futurepowerfleetforplexos{solventfleetrow,fleetstartcostcol}=0;
        futurepowerfleetforplexos{solventfleetrow,fleetmindowntimecol}=0;
        
        %% ADD SOLVENT STORAGE GENERATORS
        %% SOLVENT STORAGE DISCHARGE DUMMY 1
        %Solvent storage discharge dummy 1 is constrained to be equal to
        %some scalar of the output from pump unit 1. Pump unit 1's
        %generation does not contribute to demand. Rather, all generation towards demand
        %from pump unit 1 is sent through SS discharge dummy 1, which has
        %all the parameters of a unit that's discharging stored solvent.
        
        %Create name
        ssdischargedummy1row=size(futurepowerfleetforplexos,1)+1;
        futurepowerfleetforplexos{ssdischargedummy1row,fleetorisidcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetorisidcol}; %equivalent to = currplantoris
        futurepowerfleetforplexos{ssdischargedummy1row,fleetunitidcol}=...
            strcat(futurepowerfleetforplexos{basegenrowinfleet,fleetunitidcol},'SSDischargeDummy1');%equivalent to = using currplantunitid+SS
        
        %First get capacity penalty reduction from SS discharge. 
        sscapacpenalty=predict(lmsscapacpenalty,ccsgrosshr)*100; %comes out as negative fraction; convert to %
        futurepowerfleetforplexos{ssdischargedummy1row,ccssscapacitypenaltycol}=sscapacpenalty;
        
        %Capacity = PBase * (1 - CPCCS * (1-CPRDischarge)) = PBase * (1-CapacPenaltySS)
        %Max capacity is capacity of generator w/ full SS discharge; use
        %max capacity of SS discharge to allow small amounts of pumping at
        %pump unit 1 and then full discharge w/out having to use pump 2 if
        %never want to engage in full charging.
        ssdischargedummy1capac=originalcapac*(1+sscapacpenalty/100); %add since already negative
        ssdischargetotalcapac=ssdischargedummy1capac;
        futurepowerfleetforplexos{ssdischargedummy1row,fleetcapacitycol}=ssdischargedummy1capac;
        
        %Heat rate = HR when discharging SS = HRGrossCCS * (1 + HRPCCS *
        %(1-HRPRDischarge)) = HRGross*(1+HRPss). Need to get HR Penalty.
        sshrpenalty=predict(lmssnethrpenalty,ccsgrosshr)*100; %convert from fraction to %
        futurepowerfleetforplexos{ssdischargedummy1row,ccssshrpenaltycol}=sshrpenalty;
        futurepowerfleetforplexos{ssdischargedummy1row,fleetheatratecol}=ccsgrosshr*(1+sshrpenalty/100);
        
        %Set fuel costs and VOM to values for base
        %generator.
        futurepowerfleetforplexos{ssdischargedummy1row,fleetvomcol}=originalvom*originalcapac...
            /futurepowerfleetforplexos{ssdischargedummy1row,fleetcapacitycol};
        futurepowerfleetforplexos{ssdischargedummy1row,fleetfuelpricecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfuelpricecol};
        
        %Emissions rates values, since they are used in PLEXOS as ton/MWh,
        %need to be scaled based on capacity of CCS/TOTAL capacity of SS
        %discharge.
        futurepowerfleetforplexos{ssdischargedummy1row,fleetso2emsratecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetso2emsratecol}*...
            emissionsratescapacforscale/ssdischargetotalcapac;
        futurepowerfleetforplexos{ssdischargedummy1row,fleetnoxemsratecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetnoxemsratecol}*...
            emissionsratescapacforscale/ssdischargetotalcapac;
        futurepowerfleetforplexos{ssdischargedummy1row,fleetco2emsratecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetco2emsratecol}*...
            emissionsratescapacforscale/ssdischargetotalcapac;
        
        %Copy down NOx & SO2 price info
        futurepowerfleetforplexos{ssdischargedummy1row,noxpricecol}=futurepowerfleetforplexos{basegenrowinfleet,noxpricecol};
        futurepowerfleetforplexos{ssdischargedummy1row,so2pricecol}=futurepowerfleetforplexos{basegenrowinfleet,so2pricecol};
        futurepowerfleetforplexos{ssdischargedummy1row,so2groupcol}=futurepowerfleetforplexos{basegenrowinfleet,so2groupcol};
        
        %Set ramp limit.
        futurepowerfleetforplexos{ssdischargedummy1row,fleetmaxrampdowncol}=...
            futurepowerfleetforplexos{ssdischargedummy1row,fleetcapacitycol}*solventstorageramprate/100;
        futurepowerfleetforplexos{ssdischargedummy1row,fleetmaxrampupcol}=...
            futurepowerfleetforplexos{ssdischargedummy1row,fleetcapacitycol}*solventstorageramprate/100;
        
        %Plug 0 into CCS retrofit
        futurepowerfleetforplexos{ssdischargedummy1row,fleetccsretrofitcol}=0;
        
        %Set other values: min load = 0; Fossil unit; Coal fuel type; SSDischargeDummy plant type;
        %region, and state same as CCS-equipped generator.
        futurepowerfleetforplexos{ssdischargedummy1row,fleetminloadcol}=0;
        futurepowerfleetforplexos{ssdischargedummy1row,fleetplanttypecol}='SSDischargeDummy';
        futurepowerfleetforplexos{ssdischargedummy1row,fleetfueltypecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfueltypecol};
        futurepowerfleetforplexos{ssdischargedummy1row,fleetfossilunitcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfossilunitcol};
        futurepowerfleetforplexos{ssdischargedummy1row,fleetstatecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetstatecol};
        futurepowerfleetforplexos{ssdischargedummy1row,fleetregioncol}=futurepowerfleetforplexos{basegenrowinfleet,fleetregioncol};
        futurepowerfleetforplexos{ssdischargedummy1row,fleetpumpunitscol}=0;
        %Also save bit & subbit fuel use
        futurepowerfleetforplexos{ssdischargedummy1row,bitfuelusecol}=futurepowerfleetforplexos{basegenrowinfleet,bitfuelusecol};
        futurepowerfleetforplexos{ssdischargedummy1row,subbitfuelusecol}=futurepowerfleetforplexos{basegenrowinfleet,subbitfuelusecol};
        %Zero out start cost & min down time
        futurepowerfleetforplexos{ssdischargedummy1row,fleetstartcostcol}=0;
        futurepowerfleetforplexos{ssdischargedummy1row,fleetmindowntimecol}=0;
        
        
        %% SOLVENT STORAGE DISCHARGE DUMMY 2
        %See below
        
        %% SOLVENT STORAGE PUMP UNIT 1
        %STORAGE GENERATOR
        %Add solvent storage generator to fleet. Naming convention: same ORIS
        %as parent generator, unit ID same as parent generator +
        %'SolventStorage'.
        sspump1row=size(futurepowerfleetforplexos,1)+1;
        futurepowerfleetforplexos{sspump1row,fleetorisidcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetorisidcol}; %equivalent to = currplantoris
        futurepowerfleetforplexos{sspump1row,fleetunitidcol}=...
            strcat(futurepowerfleetforplexos{basegenrowinfleet,fleetunitidcol},'SSPump1');%equivalent to = using currplantunitid+SS
        
        %Set capacity as: PPump1 = PDischarge1/EDischarge. This will allow
        %discharge unit to reach max capacity. Include constraint (in
        %CreatePLEXOSImportFile) to limit pump load of unit. 
        sspump1gencapac=ssdischargedummy1capac/futurepowerfleetforplexos{basegenrowinfleet,egridperestoredsolventcol};
        futurepowerfleetforplexos{sspump1row,fleetcapacitycol}=sspump1gencapac;
        %Set pump load to different value; need to limit this value to pump
        %load at which base generation would go to ~0 (technically 1). 
        sspump1capac=(futurepowerfleetforplexos{basegenrowinfleet,fleetcapacitycol}-1)/...
            futurepowerfleetforplexos{basegenrowinfleet,egridpereregenandco2capcol}/...
            (1+futurepowerfleetforplexos{basegenrowinfleet,eextrasolventperestoredsolventcol});
        futurepowerfleetforplexos{sspump1row,fleetpumploadcol}=sspump1capac;
        
        %Set heat rate to 1 (so basically what goes in = what goes out) 
        %and fuel cost and VOM to zero.
        futurepowerfleetforplexos{sspump1row,fleetheatratecol}=1;
        futurepowerfleetforplexos{sspump1row,fleetvomcol}=0;
        futurepowerfleetforplexos{sspump1row,fleetfuelpricecol}=0;
        
        %Zero out emissions rates - captured at charge & dsicharge dummies.
        futurepowerfleetforplexos{sspump1row,fleetso2emsratecol}=0;
        futurepowerfleetforplexos{sspump1row,fleetnoxemsratecol}=0;
        futurepowerfleetforplexos{sspump1row,fleetco2emsratecol}=0;
        
        %Also allow unlimited ramp, but will include in group boiler-level
        %constraint.
        
        %Plug 0 into CCS retrofit
        futurepowerfleetforplexos{sspump1row,fleetccsretrofitcol}=0;
        
        %Set other values: min load = 0; Fossil unit; Coal fuel type; SSPump plant type;
        %region, and state same as CCS-equipped generator.
        futurepowerfleetforplexos{sspump1row,fleetminloadcol}=0;
        futurepowerfleetforplexos{sspump1row,fleetplanttypecol}='SSPump';
        futurepowerfleetforplexos{sspump1row,fleetfueltypecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfueltypecol};
        futurepowerfleetforplexos{sspump1row,fleetfossilunitcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfossilunitcol};
        futurepowerfleetforplexos{sspump1row,fleetstatecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetstatecol};
        futurepowerfleetforplexos{sspump1row,fleetregioncol}=futurepowerfleetforplexos{basegenrowinfleet,fleetregioncol};
        
        %Also save bit & subbit fuel use
        futurepowerfleetforplexos{sspump1row,bitfuelusecol}=futurepowerfleetforplexos{basegenrowinfleet,bitfuelusecol};
        futurepowerfleetforplexos{sspump1row,subbitfuelusecol}=futurepowerfleetforplexos{basegenrowinfleet,subbitfuelusecol};
        %Zero out start cost & min down time
        futurepowerfleetforplexos{sspump1row,fleetstartcostcol}=0;
        futurepowerfleetforplexos{sspump1row,fleetmindowntimecol}=0;
        %Now add remaining PUMPING parameters
        %Pump Units - set to 1.
        futurepowerfleetforplexos{sspump1row,fleetpumpunitscol}=1;
        %Pump Efficiency (%) - pump efficiency gives round-trip efficiency
        %of pumping. Here, assume no solvent is ever lost from storage
        %tanks, e.g. due to evaporation. So efficiency is 100%.
        futurepowerfleetforplexos{sspump1row,fleetpumpeffcol}=100; %use a %, which is required intpu to PLEXOS
        
        
        %% SOLVENT STORAGE PUMP UNIT 2
        %Pump unit 2 only differs from pump unit 1 in its capacity and what
        %constraints it is included in; thus, can just replicate pump unit
        %1 here, and alter capacity.
        sspump2row=size(futurepowerfleetforplexos,1)+1;
        %Copy in sspump2row
        futurepowerfleetforplexos(sspump2row,:)=futurepowerfleetforplexos(sspump1row,:);
        
        %Replace ORIS and unit IDs
        futurepowerfleetforplexos{sspump2row,fleetorisidcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetorisidcol}; %equivalent to = currplantoris
        futurepowerfleetforplexos{sspump2row,fleetunitidcol}=...
            strcat(futurepowerfleetforplexos{basegenrowinfleet,fleetunitidcol},'SSPump2');%equivalent to = using currplantunitid+SS
        
        %Replace capacity. Capacity of pump 2 = capacity of continuous
        %solvent generator - capacity of pump 1
        sspump2capac=solventcapacity-sspump1capac;
        futurepowerfleetforplexos{sspump2row,fleetcapacitycol}=sspump2capac;
        
        %Also replace pump load w/ same value
        futurepowerfleetforplexos{sspump2row,fleetpumploadcol}=sspump2capac;
        
        
        %% SOLVENT STORAGE DISCHARGE DUMMY 2 
        %Same as discharge dummy 1 except for name, capacity and ramp limit, so copy
        %down rest of row and then replace those values.
        ssdischargedummy2row=size(futurepowerfleetforplexos,1)+1;
        futurepowerfleetforplexos(ssdischargedummy2row,:)=futurepowerfleetforplexos(ssdischargedummy1row,:);
        
        %Replace names
        futurepowerfleetforplexos{ssdischargedummy2row,fleetorisidcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetorisidcol}; %equivalent to = currplantoris
        futurepowerfleetforplexos{ssdischargedummy2row,fleetunitidcol}=...
            strcat(futurepowerfleetforplexos{basegenrowinfleet,fleetunitidcol},'SSDischargeDummy2');%equivalent to = using currplantunitid+SS

        %Replace capacity. Capacity of pump dummy 2 = PBase * (1-CapacPenaltySS) *
        %PPump2/(PPump1+PPump2).
        ssdischargedummy2capac=originalcapac*(1+sscapacpenalty/100)*sspump2capac/(sspump1capac+sspump2capac); %add since already negative
        futurepowerfleetforplexos{ssdischargedummy2row,fleetcapacitycol}=ssdischargedummy2capac;
        
        %Replace ramp limit w/  new capacity.
        futurepowerfleetforplexos{ssdischargedummy2row,fleetmaxrampdowncol}=...
            futurepowerfleetforplexos{ssdischargedummy2row,fleetcapacitycol}*solventstorageramprate/100;
        futurepowerfleetforplexos{ssdischargedummy2row,fleetmaxrampupcol}=...
            futurepowerfleetforplexos{ssdischargedummy2row,fleetcapacitycol}*solventstorageramprate/100;
        
        %VOM is same as discharge 1 b/c substitutes for one another
        
        %% SOLVENT STORAGE PUMP DUMMY 1
        %Pump dummy 1 provides the generation for all pumping at SS pump unit
        %1.
        sspumpdummy1row=size(futurepowerfleetforplexos,1)+1;
        futurepowerfleetforplexos{sspumpdummy1row,fleetorisidcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetorisidcol}; %equivalent to = currplantoris
        futurepowerfleetforplexos{sspumpdummy1row,fleetunitidcol}=...
            strcat(futurepowerfleetforplexos{basegenrowinfleet,fleetunitidcol},'SSPumpDummy1');%equivalent to = using currplantunitid+SS
        
        %Capacity = capacity of pump unit 1
        sspumpdummy1capac=sspump1capac;
        futurepowerfleetforplexos{sspumpdummy1row,fleetcapacitycol}=sspumpdummy1capac;
        
        %Heat rate = gross CCS heat rate.
        futurepowerfleetforplexos{sspumpdummy1row,fleetheatratecol}=ccsgrosshr;
        
        %VOM = continuous solvent value
        futurepowerfleetforplexos{sspumpdummy1row,fleetvomcol}=futurepowerfleetforplexos{solventfleetrow,fleetvomcol};
        
        %Set fuel cost to base generator value
        futurepowerfleetforplexos{sspumpdummy1row,fleetfuelpricecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfuelpricecol};
        
        %Set emissions rates to base CCS unit
        futurepowerfleetforplexos{sspumpdummy1row,fleetso2emsratecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetso2emsratecol};
        futurepowerfleetforplexos{sspumpdummy1row,fleetnoxemsratecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetnoxemsratecol};
        futurepowerfleetforplexos{sspumpdummy1row,fleetco2emsratecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetco2emsratecol};
        
        %Copy down NOx & SO2 price info.
        futurepowerfleetforplexos{sspumpdummy1row,noxpricecol}=futurepowerfleetforplexos{basegenrowinfleet,noxpricecol};
        futurepowerfleetforplexos{sspumpdummy1row,so2pricecol}=futurepowerfleetforplexos{basegenrowinfleet,so2pricecol};
        futurepowerfleetforplexos{sspumpdummy1row,so2groupcol}=futurepowerfleetforplexos{basegenrowinfleet,so2groupcol};
        
        %Also allow unlimited ramp, but will include in group boiler-level
        %constraint.
        
        %Plug 0 into CCS retrofit
        futurepowerfleetforplexos{sspumpdummy1row,fleetccsretrofitcol}=0;
        
        %Set other values: min load = 0; Fossil unit; Coal fuel type; SSPumpDummy plant type;
        %region, and state same as CCS-equipped generator.
        futurepowerfleetforplexos{sspumpdummy1row,fleetminloadcol}=0;
        futurepowerfleetforplexos{sspumpdummy1row,fleetplanttypecol}='SSPumpDummy';
        futurepowerfleetforplexos{sspumpdummy1row,fleetfueltypecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfueltypecol};
        futurepowerfleetforplexos{sspumpdummy1row,fleetfossilunitcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfossilunitcol};
        futurepowerfleetforplexos{sspumpdummy1row,fleetstatecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetstatecol};
        futurepowerfleetforplexos{sspumpdummy1row,fleetregioncol}=futurepowerfleetforplexos{basegenrowinfleet,fleetregioncol};
        futurepowerfleetforplexos{sspumpdummy1row,fleetpumpunitscol}=0;
        %Also save bit & subbit fuel use
        futurepowerfleetforplexos{sspumpdummy1row,bitfuelusecol}=futurepowerfleetforplexos{basegenrowinfleet,bitfuelusecol};
        futurepowerfleetforplexos{sspumpdummy1row,subbitfuelusecol}=futurepowerfleetforplexos{basegenrowinfleet,subbitfuelusecol};
        %Zero out start cost & min down time
        futurepowerfleetforplexos{sspumpdummy1row,fleetstartcostcol}=0;
        futurepowerfleetforplexos{sspumpdummy1row,fleetmindowntimecol}=0;
        
        
        %% SOLVENT STORAGE PUMP DUMMY 2
        %Pump dummy 2 provides the generation for all pumping at SS pump unit
        %2. Same as pump dummy 1 except for name & capacity, so copy down
        %row & then fill in those values. 
        sspumpdummy2row=size(futurepowerfleetforplexos,1)+1;
        futurepowerfleetforplexos(sspumpdummy2row,:)=futurepowerfleetforplexos(sspumpdummy1row,:);
        
        %Replace names
        futurepowerfleetforplexos{sspumpdummy2row,fleetorisidcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetorisidcol}; %equivalent to = currplantoris
        futurepowerfleetforplexos{sspumpdummy2row,fleetunitidcol}=strcat(futurepowerfleetforplexos{basegenrowinfleet,fleetunitidcol},'SSPumpDummy2');%equivalent to = using currplantunitid+SS

        %Replace capacity. Capacity of pump dummy 2 = capacity of pump 2.
        %Also replace pump load (equal to capacity).
        sspumpdummy2capac=sspump2capac;
        futurepowerfleetforplexos{sspumpdummy2row,fleetcapacitycol}=sspumpdummy2capac;
        futurepowerfleetforplexos{sspumpdummy2row,fleetpumploadcol}=sspumpdummy2capac;
      
        %% VENTING WHILE CHARGING GENERATOR
        %Add venting generator while charging - this generator may vent
        %emissions while SS is charging. This is a separate unit from
        %venting generator.
        %Create name
        ssventwhilechargerow=size(futurepowerfleetforplexos,1)+1;
        futurepowerfleetforplexos{ssventwhilechargerow,fleetorisidcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetorisidcol}; %equivalent to = currplantoris
        futurepowerfleetforplexos{ssventwhilechargerow,fleetunitidcol}=...
            strcat(futurepowerfleetforplexos{basegenrowinfleet,fleetunitidcol},'SSVentWhenCharge');%equivalent to = using currplantunitid+SS
        
        %Capacity = capacity of base CCS generator.
        ssventwhenchargecapac=futurepowerfleetforplexos{basegenrowinfleet,fleetcapacitycol};
        futurepowerfleetforplexos{ssventwhilechargerow,fleetcapacitycol}=ssventwhenchargecapac;
        
        %Heat rate = gross HR = HR of base generator.
        futurepowerfleetforplexos{ssventwhilechargerow,fleetheatratecol}=ccsgrosshr;
        
        %Set fuel costs, VOM and NOX emissions rates to values for base
        %generator.
        futurepowerfleetforplexos{ssventwhilechargerow,fleetvomcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetvomcol};
        futurepowerfleetforplexos{ssventwhilechargerow,fleetfuelpricecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfuelpricecol};
        futurepowerfleetforplexos{ssventwhilechargerow,fleetnoxemsratecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetnoxemsratecol};
        
        %SO2 emissions rate increases while venting, since zero'd out while
        %running CCS system. 
        futurepowerfleetforplexos{ssventwhilechargerow,fleetso2emsratecol}=newso2emissionsrate;
                
        %CO2 emissions rates is set to: ERVentCharge =  ERPreCCS * PMAXPreCCS / PMAXVentCharge – ERCharge1 * (PMaxCharge1+PMaxCharge2)/PMAXVentCharge
        sspumptotalcapac=sspump1capac+sspump2capac;
        futurepowerfleetforplexos{ssventwhilechargerow,fleetco2emsratecol}=...
            originalco2emissionsrate*originalcapac/ssventwhenchargecapac - ...
            futurepowerfleetforplexos{sspumpdummy1row,fleetco2emsratecol}*...
            sspumptotalcapac/ssventwhenchargecapac;
        %SO2 emissions rate is a little different, since charge SO2 rate is zero,
        %so don't need to subtract it out. 
        %SO2 emissions rate = ERpreccs * PMaxPreCCS/PMaxVentCharge
        futurepowerfleetforplexos{ssventwhilechargerow,fleetso2emsratecol}=...
            originalso2emissionsrate*originalcapac/ssventwhenchargecapac;
        %NOx emissions is like CO2 - need to factor out NOx emissions from
        %the charging unit.
        futurepowerfleetforplexos{ssventwhilechargerow,fleetnoxemsratecol}=...
            originalnoxemissionsrate*originalcapac/ssventwhenchargecapac - ...
            futurepowerfleetforplexos{sspumpdummy1row,fleetnoxemsratecol}*...
            sspumptotalcapac/ssventwhenchargecapac;
        
        %Copy down NOx & SO2 price info.
        futurepowerfleetforplexos{ssventwhilechargerow,noxpricecol}=futurepowerfleetforplexos{basegenrowinfleet,noxpricecol};
        futurepowerfleetforplexos{ssventwhilechargerow,so2pricecol}=futurepowerfleetforplexos{basegenrowinfleet,so2pricecol};
        futurepowerfleetforplexos{ssventwhilechargerow,so2groupcol}=futurepowerfleetforplexos{basegenrowinfleet,so2groupcol};
        
        %Set ramp limit.
        futurepowerfleetforplexos{ssventwhilechargerow,fleetmaxrampdowncol}=...
            futurepowerfleetforplexos{ssventwhilechargerow,fleetcapacitycol}*ventingramprate/100;
        futurepowerfleetforplexos{ssventwhilechargerow,fleetmaxrampupcol}=...
            futurepowerfleetforplexos{ssventwhilechargerow,fleetcapacitycol}*ventingramprate/100;
        
        %Plug 0 into CCS retrofit
        futurepowerfleetforplexos{ssventwhilechargerow,fleetccsretrofitcol}=0;
        
        %Set other values: min load = 0; Fossil unit; Coal fuel type; SSVentWhenCharge plant type;
        %region, and state same as CCS-equipped generator.
        futurepowerfleetforplexos{ssventwhilechargerow,fleetminloadcol}=0;
        futurepowerfleetforplexos{ssventwhilechargerow,fleetplanttypecol}='SSVentWhenCharge';
        futurepowerfleetforplexos{ssventwhilechargerow,fleetfueltypecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfueltypecol};
        futurepowerfleetforplexos{ssventwhilechargerow,fleetfossilunitcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfossilunitcol};
        futurepowerfleetforplexos{ssventwhilechargerow,fleetstatecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetstatecol};
        futurepowerfleetforplexos{ssventwhilechargerow,fleetregioncol}=futurepowerfleetforplexos{basegenrowinfleet,fleetregioncol};
        futurepowerfleetforplexos{ssventwhilechargerow,fleetpumpunitscol}=0;
        %Also save bit & subbit fuel use
        futurepowerfleetforplexos{ssventwhilechargerow,bitfuelusecol}=futurepowerfleetforplexos{basegenrowinfleet,bitfuelusecol};
        futurepowerfleetforplexos{ssventwhilechargerow,subbitfuelusecol}=futurepowerfleetforplexos{basegenrowinfleet,subbitfuelusecol};
        %Zero out start cost & min down time
        futurepowerfleetforplexos{ssventwhilechargerow,fleetstartcostcol}=0;
        futurepowerfleetforplexos{ssventwhilechargerow,fleetmindowntimecol}=0;
        
        
        %% END OF SOLVENT STORAGE GENERATORS
        
        
        %% ADD VENTING GENERATOR
        %Add venting generator to fleet. Use same parameters as used for
        %solvent storage above.
        %Naming convention: same ORIS
        %as parent generator, unit ID same as parent generator +
        %'Venting'.
        ventfleetrow=size(futurepowerfleetforplexos,1)+1;
        futurepowerfleetforplexos{ventfleetrow,fleetorisidcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetorisidcol}; %equivalent to = currplantoris
        futurepowerfleetforplexos{ventfleetrow,fleetunitidcol}=strcat(futurepowerfleetforplexos{basegenrowinfleet,fleetunitidcol},'Venting');
        
        %Capacity of plant; assume same capacity as when fully discharging
        %SS.
        ventcapacity=originalcapac*(1+sscapacpenalty/100);
        futurepowerfleetforplexos{ventfleetrow,fleetcapacitycol}=ventcapacity;
        
        %Heat rate of plant - set equal to HR when discharging SS.
        futurepowerfleetforplexos{ventfleetrow,fleetheatratecol}=futurepowerfleetforplexos{ssdischargedummy1row,fleetheatratecol};
        %Set VOM equal to discharge value
        futurepowerfleetforplexos{ventfleetrow,fleetvomcol}=futurepowerfleetforplexos{ssdischargedummy1row,fleetvomcol};
        
        %Add ramp rate.
        futurepowerfleetforplexos{ventfleetrow,fleetmaxrampdowncol}=...
            futurepowerfleetforplexos{ventfleetrow,fleetcapacitycol}*ventingramprate/100;
        futurepowerfleetforplexos{ventfleetrow,fleetmaxrampupcol}=...
            futurepowerfleetforplexos{ventfleetrow,fleetcapacitycol}*ventingramprate/100;
        
        %Fill in CCS retrofits & pump units w/ a zero.
        futurepowerfleetforplexos{ventfleetrow,fleetccsretrofitcol}=0;
        futurepowerfleetforplexos{ventfleetrow,fleetpumpunitscol}=0;
        %Set other values: min load = 0; Venting plant type; CO2 emissions rate
        %same as pre-CCS generator;
        %fossil unit, fuel type, region, state, fuel price, NOx & SO2 emissions rates, and VO&M same as CCS-equipped generator.
        futurepowerfleetforplexos{ventfleetrow,fleetminloadcol}=0;
        futurepowerfleetforplexos{ventfleetrow,fleetplanttypecol}='Venting';
        futurepowerfleetforplexos{ventfleetrow,fleetfueltypecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfueltypecol};
        futurepowerfleetforplexos{ventfleetrow,fleetfossilunitcol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfossilunitcol};
        futurepowerfleetforplexos{ventfleetrow,fleetstatecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetstatecol};
        futurepowerfleetforplexos{ventfleetrow,fleetregioncol}=futurepowerfleetforplexos{basegenrowinfleet,fleetregioncol};
        futurepowerfleetforplexos{ventfleetrow,fleetfuelpricecol}=futurepowerfleetforplexos{basegenrowinfleet,fleetfuelpricecol};
        
        %Need to scale emissions rates based on capacities so total output
        %is the same at max capacity for base & vent generator. 
        futurepowerfleetforplexos{ventfleetrow,fleetso2emsratecol}=originalso2emissionsrate*originalcapac/ventcapacity;
        futurepowerfleetforplexos{ventfleetrow,fleetnoxemsratecol}=originalnoxemissionsrate*originalcapac/ventcapacity;
        futurepowerfleetforplexos{ventfleetrow,fleetco2emsratecol}=originalco2emissionsrate*originalcapac/ventcapacity;
               
        %Copy down NOx & SO2 pricing info
        futurepowerfleetforplexos{ventfleetrow,noxpricecol}=futurepowerfleetforplexos{basegenrowinfleet,noxpricecol};
        futurepowerfleetforplexos{ventfleetrow,so2pricecol}=futurepowerfleetforplexos{basegenrowinfleet,so2pricecol};
        futurepowerfleetforplexos{ventfleetrow,so2groupcol}=futurepowerfleetforplexos{basegenrowinfleet,so2groupcol};
        
        %Also save bit & subbit fuel use
        futurepowerfleetforplexos{ventfleetrow,bitfuelusecol}=futurepowerfleetforplexos{basegenrowinfleet,bitfuelusecol};
        futurepowerfleetforplexos{ventfleetrow,subbitfuelusecol}=futurepowerfleetforplexos{basegenrowinfleet,subbitfuelusecol};
        %Zero out start cost & min down time of generator
        futurepowerfleetforplexos{ventfleetrow,fleetstartcostcol}=0;
        futurepowerfleetforplexos{ventfleetrow,fleetmindowntimecol}=0;
    end
end
end %if mwccstoadd>0











