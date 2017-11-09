%Michael Craig
%January 19, 2015
%This function creates demand profiles for 2030 and saves them to separate CSV
%files.

%If usenldc=1, then use NLDC, meaning need to subtract wind, solar, hydro
%from demand curve
function [demanddataobjnames,demandfilenames] = CreateDemandProfileForPLEXOS...
    (demandscenarioforanalysis,statesforanalysis,modelmisowithfullstates,scaleenergyefficiencysavings,...
    futurepowerfleetfull,usenldc,removehydrofromdemand,solarratingfactors,windcapacityfactors,hydroratingfactors, pc)
%OUTPUT: demanddataobjnames - an array of demand data object names and file
%names (where the demand files are saved), both of which are then put into
%the PLEXOS import file.
%Initialize output
demanddataobjnames={}; demandfilename={};

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
    fleeteregenpereco2capcol,fleetegridpereco2capandregencol,fleetegriddischargeperestorecol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetfull);

%% COLLECT EE SAVINGS DATA FROM SCENARIOS
%Energy efficiency adoption rates are based on scenarios from EPA final CPP. 
%EPA assumes 1% energy efficiency adoption rate in IPM run for final
%CPP, even though no EE included in building blocks. 
%Following function determines proportional growth/fall in demand from BAU
%pre-EE 2013 to post-EE 2030 for each state under input scenarios.
%This does not depend on modelmisowithfullstates - states included are the
%same regardless, and the following function doesn't worry about splitting
%up states if only partly included in MISO.
[demandchangeproportions,demandbeforeee2013]=CalculateEESavingsFromIPMScenarios(demandscenarioforanalysis,...
    statesforanalysis,scaleenergyefficiencysavings,pc);

%% IMPORT IPM DEMAND PROFILE 
%Name of file w/ hourly demand data. Load curves are provided at region
%level. 
if strcmp(pc,'work')
    demandfile='C:\Users\mtcraig\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\IPM513BaseCaseLoadDurationCurves_27Oct0214.xlsx';
elseif strcmp(pc,'personal')
    demandfile='C:\Users\mcraig10\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\IPM513BaseCaseLoadDurationCurves_27Oct0214.xlsx';
end
[~,~,demanddataall]=xlsread(demandfile,'Attachment 2-1');

%% GET HOURLY DEMAND FOR EACH MISO SUBREGION
%Hourly demand is given for each MISO region. Setup of data:
%Col A & top 3 rows are empty. Col B = region name. C = Month. D = Day.
%E-AB are Hours 1-> 24
%Remove top 3 rows and left column
demanddataall(1:3,:)=[];
demanddataall(:,1)=[];
%Bottom of file also has lots of blank rows for some reason - find last row
%of data, and truncate it there
for i=1:size(demanddataall,1)
    if isnan(demanddataall{i,1})
        nanrow=i;
        break
    end
end
demanddataall(nanrow:end,:)=[];

%Get region, month, day col
demandregioncol=find(strcmp(demanddataall(1,:),'Region'));
demandmonthcol=find(strcmp(demanddataall(1,:),'Month'));
demanddaycol=find(strcmp(demanddataall(1,:),'Day'));
demandhour1col=find(strcmp(demanddataall(1,:),'Hour 1'));

%Get demand data for each MISO region
allregions=unique(demanddataall(:,1));
demandmisoregions={};
%Define array w/ extra regions that need to be added in; only used when
%modeling MISO with full states only. Column 1 = region already included,
%column 2 = region whose demand needs to be included in first col's demand.
if modelmisowithfullstates==1
    extraregions={'MIS_MAPP','MAP_WAUE';
        'MIS_IL','PJM_COMD'};
end
for i=1:size(allregions,1)
    if strcmp(allregions{i,1}(1:3),'MIS')==1 %if row is a MISO region
        demandmisoregionscol=size(demandmisoregions,2)+1;
        demandmisoregions{1,demandmisoregionscol}=allregions{i,1};
        demandmisorowctr=2; %row 1 = region name
        %Get rows of demand data for that region
        rowsofdemanddata=find(strcmp(allregions{i,1},demanddataall(:,1)));
        %For selected rows, step through cols and save
        for rowiter=1:size(rowsofdemanddata,1)
            currrow=rowsofdemanddata(rowiter,1);
            for coliter=demandhour1col:(demandhour1col+23)
                demandmisoregions{demandmisorowctr,demandmisoregionscol}=demanddataall{currrow,coliter};
                demandmisorowctr=demandmisorowctr+1;
            end
        end
        
        %If modeling MISO with full states, need to add MAP_WAUE to
        %MIS_MAPP and PJM_COMD to MIS_IL. So, if either in MIS_MAPP or
        %MIS_IL, find accompanying region and add in demand profile.
        if modelmisowithfullstates==1
            if find(strcmp(extraregions(:,1),allregions{i,1}))
                %Get extra region to add
                rowofextraregion=find(strcmp(extraregions(:,1),allregions{i,1}));
                extraregion=extraregions{rowofextraregion,2};
                %Find rows of demand for that region
                rowsofdemanddata=find(strcmp(extraregion,demanddataall(:,1)));
                %Reset row counter for saving data
                demandmisorowctr=2;
                %For selected rows, step through cols and add values to
                %values already in demand array
                for rowiter=1:size(rowsofdemanddata,1)
                    currrow=rowsofdemanddata(rowiter,1);
                    for coliter=demandhour1col:(demandhour1col+23)
                        demandmisoregions{demandmisorowctr,demandmisoregionscol}=...
                            demandmisoregions{demandmisorowctr,demandmisoregionscol}+...
                            demanddataall{currrow,coliter};
                        demandmisorowctr=demandmisorowctr+1;
                    end
                end
            end
        end
    end
end

%% CREATE 2030 DEMAND PROFILES FOR EACH SCENARIO
%Have 2 demand scenarios: Scenario 1 and 4.
%First, map regions to states - import map.
if strcmp(pc,'work')
    mapofmisoregionstostatesfilename='C:\Users\mtcraig\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\MapIPMMISORegionsToStates.xlsx';
elseif strcmp(pc,'personal')
    mapofmisoregionstostatesfilename='C:\Users\mcraig10\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\MapIPMMISORegionsToStates.xlsx';
end
[~,~,mapofmisostatestoregions]=xlsread(mapofmisoregionstostatesfilename,'Sheet1');
mapstate1col=find(strcmp(mapofmisostatestoregions(1,:),'State 1'));
mapstate2col=find(strcmp(mapofmisostatestoregions(1,:),'State 2'));
mapipmregioncol=find(strcmp(mapofmisostatestoregions(1,:),'IPM Region'));

%Creating demand profiles depends on which MISO region used. If modeling
%MISO as incomplete states (modelmisowithfullstates=0), then for each
%scenario, for each MISO subregion, the growth in demand is found for each
%applicable state, and then demand is scaled accordingly. If modeling MISO
%as complete states (modelmisowithfullstates=1), then for each scenario,
%for each MISO subregion, need to scale up that hourly profile so that the
%subregion's demand is equal to its state's demand, and then apply the
%growth/degrowth factor.
%Create array that will hold region name and proportional growth in demand
regionalgrowthindemand=mapofmisostatestoregions(:,mapipmregioncol);
regionalgrowthindemand{1,2}='GrowthInDemandTo2030(ProportionOf2012Demand)';
for scenariorow=1:size(demandscenarioforanalysis,1)
    currscenario=demandscenarioforanalysis(scenariorow,1);
    
    %SCALE REGION TO STATE DEMAND IN 2012 (IF NECESSARY)
    %If modeling state as complete states only, need to scale up hourly
    %profiles for subregion so that total annual demand of subregion equals
    %total annual demand of corresponding state. 
    if modelmisowithfullstates==1
        %For each subregion: 1) sum demand for subregion. 2) get 2013
        %pre-EE demand for corresponding state(s). 3) divide 1 by 2. 4)
        %multiply factor through hourly profile.
        %Note that ND + SD correspond to MIS_MAPP + MAP_WAUE now (MAP_WAUE
        %not included in other case b/c not in MIS). 
        nummisoregionsoriginally=size(demandmisoregions,2);
        nummisoregionsleft=nummisoregionsoriginally; %this variable will keep track of how many columns of MISO regions are left since some cols are deleted in for loop
        for misoregioncol=1:size(demandmisoregions,2)
            if misoregioncol<=nummisoregionsleft %make sure w/in bounds of remaining array (since delete some cols as go)
                %Get region name
                currmisoregion=demandmisoregions{1,misoregioncol};
                %Get states of region
                rowofcurrmisoregioninmap=find(strcmp(mapofmisostatestoregions(:,mapipmregioncol),currmisoregion));
                state1ofcurrmisoregion=mapofmisostatestoregions{rowofcurrmisoregioninmap,mapstate1col};
                state2ofcurrmisoregion=mapofmisostatestoregions{rowofcurrmisoregioninmap,mapstate2col};
                
                %Check if state has multiple regions associated with it (e.g.,
                %in MISO, IA has MIDA & IA). If so, combine these regions into
                %1.
                rowsofregionsinstate=find(strcmp(mapofmisostatestoregions(:,mapstate1col),state1ofcurrmisoregion));
                if size(rowsofregionsinstate,1)>1 %if more than 1 region assigned to state
                    %Get other region names
                    for j=2:size(rowsofregionsinstate,1) %get other rows, excludign one currently in
                        currrow=rowsofregionsinstate(j,1);
                        otherregion=mapofmisostatestoregions{currrow,mapipmregioncol};
                        %Add hourly demand of that region to this region
                        colofotherregiondemand=find(strcmp(demandmisoregions(1,:),otherregion));
                        hourlydemandofotherregion=cell2mat(demandmisoregions(2:end,colofotherregiondemand));
                        hourlydemandofthisregion=cell2mat(demandmisoregions(2:end,misoregioncol));
                        addedhourlydemands=hourlydemandofotherregion+hourlydemandofthisregion;
                        demandmisoregions(2:end,misoregioncol)=num2cell(addedhourlydemands);
                        %Delete column of other region
                        demandmisoregions(:,colofotherregiondemand)=[];
                        nummisoregionsleft=nummisoregionsleft-1;
                    end
                end
                
                %Get total annual demand of subregion.  Convert to GWh
                totalregiondemand=sum(cell2mat(demandmisoregions(2:end,misoregioncol)))/1000;
                
                %Now get 2013 pre-EE demand for corresponding state(s).
                if isnan(state2ofcurrmisoregion)
                    %Find row of state
                    rowofstatedemand=find(strcmp(demandbeforeee2013(:,1),state1ofcurrmisoregion));
                    totalstatedemand=demandbeforeee2013{rowofstatedemand,2};
                else
                    %Find row of states
                    rowofstatedemand1=find(strcmp(demandbeforeee2013(:,1),state1ofcurrmisoregion));
                    rowofstatedemand2=find(strcmp(demandbeforeee2013(:,1),state2ofcurrmisoregion));
                    totalstatedemand=demandbeforeee2013{rowofstatedemand1,2}+demandbeforeee2013{rowofstatedemand2,2};
                end
                
                %Divide total region demand by total state demand
                scalefactorregiontostate=totalstatedemand/totalregiondemand;
                
                %Scale up/down region demand profile
                demandmisoregions(2:end,misoregioncol)=num2cell(cell2mat(demandmisoregions(2:end,misoregioncol))*scalefactorregiontostate);
            end
        end
    end
    
    %SCALE FOR GROWTH/DEGROWTH IN GENERATION OVER TIME
    %Get demand growth/degrowth factor from 2012 to 2030 for each MISO
    %subregion, which is based on the factors for each corresponding state.
    for misoregioncol=1:size(demandmisoregions,2)
        %Get region name
        currmisoregion=demandmisoregions{1,misoregioncol};
        %Get states of region
        rowofcurrmisoregioninmap=find(strcmp(mapofmisostatestoregions(:,mapipmregioncol),currmisoregion));
        state1ofcurrmisoregion=mapofmisostatestoregions{rowofcurrmisoregioninmap,mapstate1col};
        state2ofcurrmisoregion=mapofmisostatestoregions{rowofcurrmisoregioninmap,mapstate2col};
        %Check if 2nd state is NaN
        if isnan(state2ofcurrmisoregion)
            %Just 1 state maps to region, so just use 1 state's data
            %Look up row of growth in demand for that state
            rowofdemandgrowth=find(strcmp(demandchangeproportions(:,1),state1ofcurrmisoregion));
            %Also get col of current scenario
            for z=1:size(demandchangeproportions,2)
                if demandchangeproportions{1,z}==currscenario
                    colofscenarioindemandchangeproportions=z;
                end
            end
            %Get demand growth
            demandgrowth=demandchangeproportions{rowofdemandgrowth,colofscenarioindemandchangeproportions};
        else
            %Look up row of growth in demand for that state
            row1ofdemandgrowth=find(strcmp(demandchangeproportions(:,1),state1ofcurrmisoregion));
            row2ofdemandgrowth=find(strcmp(demandchangeproportions(:,1),state2ofcurrmisoregion));
            %Also get col of current scenario
            for z=1:size(demandchangeproportions,2)
                if demandchangeproportions{1,z}==currscenario
                    colofscenarioindemandchangeproportions=z;
                end
            end
            %Get demand growths
            demandgrowth1=demandchangeproportions{row1ofdemandgrowth,colofscenarioindemandchangeproportions};
            demandgrowth2=demandchangeproportions{row2ofdemandgrowth,colofscenarioindemandchangeproportions};
            %Average growths
            demandgrowth=(demandgrowth1+demandgrowth2)/2;
        end
        %Save this to array w/ region data - have to find row for region
        %first
        rowofregioninregionalgrowth=find(strcmp(regionalgrowthindemand(:,1),currmisoregion));
        regionalgrowthindemand{rowofregioninregionalgrowth,1+scenariorow}=demandgrowth;
    end
        
    %NOW MULTIPLY MISO SUBREGIONAL DEMANDS BY APPROPRIATE EE GROWTH FACTOR
    %Create array for scaled demand data
    demandmisoregionsscaled=demandmisoregions;
    demandmisoregionsscaled(1,:)=demandmisoregions(1,:);
    for misoregioncol=1:size(demandmisoregions,2)
        currmisoregion=demandmisoregions{1,misoregioncol};
        currregionalgrowthindemandrow=find(strcmp(regionalgrowthindemand(:,1),currmisoregion));
        regionalgrowthindemandcol=1+scenariorow;
        currdemandgrowthfactor=regionalgrowthindemand{currregionalgrowthindemandrow,regionalgrowthindemandcol};
        for demandmisoregionsrow=2:size(demandmisoregions,1)
            %Save scaled data to demandmisoregionsscaled
            demandmisoregionsscaled{demandmisoregionsrow,misoregioncol}=...
                demandmisoregions{demandmisoregionsrow,misoregioncol}+...
                demandmisoregions{demandmisoregionsrow,misoregioncol}*currdemandgrowthfactor;
        end
    end
    
    %SUM VALUES FROM MISO SUBREGIONS TO TOTAL MISO DEMAND
    %Extract demand values for each MISO region
    demandmisoregionsvalues=cell2mat(demandmisoregionsscaled(2:end,:));
    %Sum MISO regions
    demandmisototalvalues=sum(demandmisoregionsvalues,2);
    
    %% IF USING NLDC, SUBTRACT WIND & SOLAR & HYDRO GENERATION
%     solarratingfactors,windcapacityfactors,hydroratingfactors
    if usenldc==1 || removehydrofromdemand==1
        %Define function to get PLEXOS name for units (how units are named
        %in the wind & solar & hydro rating factor cells)
        createplexosobjname = @(arraywithdata,orisidcol,unitidcol,rowofinfo) strcat(arraywithdata{rowofinfo,orisidcol},...
            '-',arraywithdata{rowofinfo,unitidcol});
    
        if usenldc==1
            %Get wind and solar plants
            windunits=find(strcmp(futurepowerfleetfull(:,fleetfueltypecol),'Wind'));
            solarunits=find(strcmp(futurepowerfleetfull(:,fleetfueltypecol),'Solar'));
            
            %For each plant, get row in fleet; get capacity; multiply by rating
            %factor/100 to get hourly generation; subtract from total demand.
            windhourlygen=windcapacityfactors; %use structure of windcapacityfactors cell as framework to store hourly gen
            for windctr=1:size(windunits,1)
                currrow=windunits(windctr);
                %Get PLEXOS name of unit
                currplexosid=createplexosobjname(futurepowerfleetfull,fleetorisidcol,fleetunitidcol,currrow);
                %Get capacity
                currcapacity=futurepowerfleetfull{currrow,fleetcapacitycol};
                %Now look up column of current unit in wind rating factors
                ratingfactorscol=find(strcmp(windcapacityfactors(1,:),currplexosid));
                %Isolate RFs
                currratingfactors=cell2mat(windcapacityfactors(2:end,ratingfactorscol));
                %Multiply RFs/100 by capacity
                currhourlygen=currratingfactors/100*currcapacity;
                %Store values
                windhourlygen(2:end,ratingfactorscol)=num2cell(currhourlygen);
            end
            %Sum hourly wind gen
            totalhourlywindgen=sum(cell2mat(windhourlygen(2:end,2:end)),2);
            
            solarhourlygen=solarratingfactors; %use structure of windcapacityfactors cell as framework to store hourly gen
            for solarctr=1:size(solarunits,1)
                currrow=solarunits(solarctr);
                %Get PLEXOS name of unit
                currplexosid=createplexosobjname(futurepowerfleetfull,fleetorisidcol,fleetunitidcol,currrow);
                %Get capacity
                currcapacity=futurepowerfleetfull{currrow,fleetcapacitycol};
                %Now look up column of current unit in wind rating factors
                ratingfactorscol=find(strcmp(solarratingfactors(1,:),currplexosid));
                %Isolate RFs
                currratingfactors=cell2mat(solarratingfactors(2:end,ratingfactorscol));
                %Multiply RFs/100 by capacity
                currhourlygen=currratingfactors/100*currcapacity;
                %Store values
                solarhourlygen(2:end,ratingfactorscol)=num2cell(currhourlygen);
            end
            %Sum hourly solar gen
            totalhourlysolargen=sum(cell2mat(solarhourlygen(2:end,2:end)),2);
        else
            totalhourlywindgen=0;
            totalhourlysolargen=0;
        end
        
        if removehydrofromdemand==1
            %Get hydro plants
            hydrounits=find(strcmp(futurepowerfleetfull(:,fleetfueltypecol),'Hydro'));
            
            %For hydro, will need to expand each month. Use repmat
            hydrohourlygen=zeros(8761,size(hydroratingfactors,1)-1);
            %Also create array w/ # days in each month
            numdaysmonth=[1,31;2,28;3,31;4,30;5,31;6,30;7,31;8,31;9,30;10,31;11,30;12,31];
            for hydroctr=1:size(hydrounits,1)
                annualhourlygen=[];
                currrow=hydrounits(hydroctr);
                %Get ORIS ID & capacity
                curroris=str2num(futurepowerfleetfull{currrow,fleetorisidcol});
                currcapac=futurepowerfleetfull{currrow,fleetcapacitycol};
                %Get row in hydro rating factors
                rfrow=find(hydroratingfactors(:,1)==curroris);
                %Now, for each month, get generation, replicate, and subtract
                %out
                for monthctr=2:size(hydroratingfactors,2)
                    %Get monthly RF
                    monthlyrf=hydroratingfactors(rfrow,monthctr)/100;
                    %Get monthly hourly gen
                    monthlyhourlygen=monthlyrf*currcapac;
                    %Now replicate generation for # hours in month
                    numhoursinmonth=numdaysmonth(monthctr-1,2)*24;
                    hourlygen=repmat(monthlyhourlygen,numhoursinmonth,1);
                    %Now stack up w/ prior hourlygen
                    annualhourlygen=[annualhourlygen;hourlygen];
                end
                hydrohourlygen(1,hydroctr)=curroris;
                hydrohourlygen(2:end,hydroctr)=annualhourlygen;
            end
            totalhourlyhydrogen=sum(hydrohourlygen(2:end,:),2);
        end
        
        %Now subtract out wind, solar & hydro generation
        demandmisototalvaluesstored=demandmisototalvalues;
        demandmisototalvalues=demandmisototalvalues-totalhourlywindgen-totalhourlysolargen-totalhourlyhydrogen;
    end
    
    %% CONVERT DEMAND DATA TO PLEXOS-ACCEPTABLE FORMAT
    %This is same format as demand files given with the IPM
    %(year, month, day going down, hours across top). So, format by
    %importing random PLEXOS load data, and replacing generation data.
    if strcmp(pc,'work')
        plexosdemandformatfile='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\LoadDataForPLEXOSTemplate.xlsx';
    elseif strcmp(pc,'personal')
        plexosdemandformatfile='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\LoadDataForPLEXOSTemplate.xlsx';
    end
    [~,~,plexosdemandformat]=xlsread(plexosdemandformatfile,'LoadDataForPLEXOSTemplate');
    %Remove leap year day
    monthcol=find(strcmp(plexosdemandformat(1,:),'Month'));
    daycol=find(strcmp(plexosdemandformat(1,:),'Day'));
    yearcol=find(strcmp(plexosdemandformat(1,:),'Year'));
    for i=1:size(plexosdemandformat,1)
        if plexosdemandformat{i,monthcol}==2
            if plexosdemandformat{i,daycol}==29
                leapyearrowtoremove=i;
            end
        end
    end
    plexosdemandformat(leapyearrowtoremove,:)=[];
    clear leapyearrowtoremove;
    
    %First hour column is column 4
    hour1col=4;
    day1col=2; %first col is headers
    
    %Copy demand format to new cell
    misodemandplexosformat=plexosdemandformat;
    
    %Change years to 2030
    for i=2:size(misodemandplexosformat,1)
        misodemandplexosformat{i,yearcol}=2030;
    end
    
    %Replace demand values
    demandmisoctr=1;
    for i=2:size(misodemandplexosformat,1)
        for j=hour1col:size(misodemandplexosformat,2)
            misodemandplexosformat{i,j}=demandmisototalvalues(demandmisoctr,1);
            demandmisoctr=demandmisoctr+1;
        end
    end
    
    %WRITE DEMAND DATA
    if strcmp(pc,'work')
        directorytowritedemand='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles\';
    elseif strcmp(pc,'personal')
        directorytowritedemand='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles\';
    end
%     filenametowritedemand=strcat('CPPPLEXOSDemand',num2str(currscenario),'EEScalarPt',...
%         num2str(10*scaleenergyefficiencysavings),'NLDC',num2str(usenldc),'.csv');
    filenametowritedemand=strcat('CPPPLEXOSDemand',num2str(currscenario),'EEScalarPt',...
        num2str(10*scaleenergyefficiencysavings),'.csv');
    if usenldc==1
        filenametowritedemand(end-3:end)='';
        filenametowritedemand=strcat(filenametowritedemand,'NLDC1.csv');
    end
    fullfilenametosave=strcat(directorytowritedemand,filenametowritedemand);
    cell2csv(fullfilenametosave,misodemandplexosformat);
    
    %Save name of demand data object and its file location for function
    %output; this output is inserted into the Excel file for importing to
    %PLEXOS. Output will have as many rows as there are scenarios - since
    %outputting 1 MISO-wide demand file per scenario.
    demanddataobjnames{scenariorow,1}=strcat('MISOIPMScenario',num2str(currscenario),'DemandFile');
    demandfilenames{scenariorow,1}=strcat('DataFiles\',filenametowritedemand);
end

