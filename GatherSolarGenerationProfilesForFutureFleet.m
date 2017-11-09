%Michael Craig, 29 May 2015
%This script functions similarly as the wind profiles script - it takes a
%capacity of solar plants in a state, maps it to plants in NREL's solar integration
%datasets in order of decreasing capacity factor, and then takes the hourly
%solar profile.

%INPUTS: power fleet, compliance scenario (Option 1, Base Case, etc.)
%OUTPUTS: CSV file name that contains the solar generation profiles (input
%to PLEXOS), and the power fleet
function [csvfilenamewithsolargenprofiles,futurepowerfleetforplexos,solarratingfactors] = ...
    GatherSolarGenerationProfilesForFutureFleet(...
    futurepowerfleetforplexos,compliancescenario,mwwindtoadd, mwccstoadd, flexibleccs, usenldc, groupwindandsolarplants, pc)

%% PARAMETERS
%Set max solar farm size
maxsolarfarmsize=100;

%% GET COLUMN NUMBERS OF DATA IN futurepowerplantfleet
[parseddataorisidcol,parseddataunitidcol,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);
%Also get state col
parseddatastatecol=find(strcmp(futurepowerfleetforplexos(1,:),'StateName'));

%% ISOLATE SOLAR POWER PLANTS
solarpowerplants=futurepowerfleetforplexos(1,:);
for i=2:size(futurepowerfleetforplexos,1)
    if strcmp(futurepowerfleetforplexos{i,parseddatafueltypecol},'Solar')
        solarpowerplants(end+1,:)=futurepowerfleetforplexos(i,:);        
    end
end

%Get plant types
solarplanttypes=unique(solarpowerplants(2:end,parseddataplanttypecol));
if size(solarplanttypes,1)>=3 %>=3 b/c have 1 row for headers & 1 row for solar PV
    'Unaccounted For Solar Plant Type, See GatherSolarGeneration...'
end


%% GET TOTAL SOLAR CAPACITY BY STATE
stateswithsolar=unique(solarpowerplants(2:end,parseddatastatecol));
statesolarcapac={'State','Capac'};
for i=1:size(stateswithsolar,1)
    currstate=stateswithsolar{i,1};
    staterows=find(strcmp(solarpowerplants(:,parseddatastatecol),currstate));
    statecapac=sum(cell2mat(solarpowerplants(staterows,parseddatacapacitycol)));
    statesolarcapac=vertcat(statesolarcapac,{currstate,statecapac});
end


%% IMPORT NREL DATASET SOLAR PLANT DATA
%NREL hourly solar generation profiles are located in the master folder:
if strcmp(pc,'work')
    solarmasterfolder='C:\Users\mtcraig\Desktop\EPP Research\Databases\NRELSolarPVData';
elseif strcmp(pc,'personal')
    solarmasterfolder='C:\Users\mcraig10\Desktop\EPP Research\Databases\NRELSolarPVData';
end
%Each state has its own folder with files. There are 3 types of files:
%actual 5-minute generation, day ahead 60-minute generation, and 4 hour
%ahead 60-minute generation. I want actual generation. 

%Using the script CalculateCapacityFactorsOfPlants... script. That
%script goes through every solar file (right now, as of 5/29/15, for the 5
%states in MISO that have solar plants) and calculates the capacity factor
%for each, then sorts the solar plants in each state by descending capacity
%factor. I want to import the output from this script,
%SolarCapacityFactorsNRELMISO.csv
solarcffilename='SolarCapacityFactorsNRELMISO.csv';
[~,~,solarplantdata]=xlsread(fullfile(solarmasterfolder,solarcffilename));
%col 1 = state, col 2 = file name, col 3 = cf, col 4 = plant size
solardatastatecol=find(strcmp(solarplantdata(1,:),'State'));
solardatafilecol=find(strcmp(solarplantdata(1,:),'File'));
solardatacfcol=find(strcmp(solarplantdata(1,:),'CF'));
solardataplantsizecol=find(strcmp(solarplantdata(1,:),'PlantSize'));


%% SELECT SOLAR PLANTS TO BUILD IN ORDER OF DECREASING CF
%For each state, select plants in NREL in decreasing order of Net CF until
%meet capacity in state.
listofsolarfarmsperstate=solarplantdata(1,:);
listofsolarfarmsperstateoriginalcapacitycol=size(listofsolarfarmsperstate,2)+1;
listofsolarfarmsperstate{1,listofsolarfarmsperstateoriginalcapacitycol}='OriginalPlantSize(MW)';
for i=2:size(statesolarcapac,1)
    %Get state name & capacity
    currstate=statesolarcapac{i,1};
    currstatecapac=statesolarcapac{i,2};
    %Convert state name to full name from abbrev., since use full name in
    %fleet
    currstate=ConvertStateNameToAbbrev(currstate);
    %Get a list of wind sites in that state - already ordered in decreasing
    %CF
    solarplantsinstate=solarplantdata(find(strcmp(solarplantdata(:,solardatastatecol),currstate)),:);
    %Go row by row and add a wind farm until currstatecapac is depleted
    rowctr=1;
    while currstatecapac>0
        %Get capacity of current solar farm
        currfarmcapac=solarplantsinstate{rowctr,solardataplantsizecol};
        %Save original data farm size from NREL dataset (need later)
        listofsolarfarmsperstate{end+1,end}=currfarmcapac;
        %Limit wind farm capac to max
        if currfarmcapac>maxsolarfarmsize
            currfarmcapac=maxsolarfarmsize;
        end
        %If capac < remaining capacity, use full farm. 
        if currfarmcapac<currstatecapac
            %Subtract farm's capac from state capac
            currstatecapac=currstatecapac-currfarmcapac;
            %Add farm to array; replace capac w/ currfarmcapac to account
            %for truncating currfarmcapac above.
            listofsolarfarmsperstate(end,1:end-1)=solarplantsinstate(rowctr,:);
            listofsolarfarmsperstate{end,solardataplantsizecol}=currfarmcapac;
        else %if capac of farm > remaining state capac, cut off farm
            %Save solar farm, then replace capac w/ whatever is left in
            %state
            listofsolarfarmsperstate(end,1:end-1)=solarplantsinstate(rowctr,:);
            listofsolarfarmsperstate{end,solardataplantsizecol}=currstatecapac;
            currstatecapac=0; %set curr state capca to 0 so exit while loop
        end
        rowctr=rowctr+1;
    end
end


%% REPLACE SOLAR PLANTS IN POWER FLEET WITH NEW SOLAR PLANTS
%Append a fake ORIS ID to end of listofsolarfarmsperstate; delete all solar
%farms in futurepowerfleetforplexos array; insert new solar plants at end.
%Delete existing solar farms.
solarplantrows=find(strcmp(futurepowerfleetforplexos(:,parseddatafueltypecol),'Solar'));
futurepowerfleetforplexos(solarplantrows,:)=[];

%Determine which ORIS ID to start at.
maxorisid=str2num(futurepowerfleetforplexos{end,parseddataorisidcol});
originalmaxorisid=maxorisid; %save for use below if grouping together wind & sola rplants
%Add column for ORIS ID in listofwindfarmsperstate
listofsolarfarmsperstateorisidcol=size(listofsolarfarmsperstate,2)+1;
listofsolarfarmsperstate{1,listofsolarfarmsperstateorisidcol}='ORISIDCreated';
%Loop through list of solar farms to add per state and add them to power
%fleet array.
for i=2:size(listofsolarfarmsperstate,1)
    %Get state & capacity of current plant
    currstate=listofsolarfarmsperstate{i,solardatastatecol};
    currplantcapac=listofsolarfarmsperstate{i,solardataplantsizecol};
    %Change state from abbreviation to full name
    currstate=ConvertStateAbbrevToName(currstate);
    [futurepowerfleetforplexos]=AddSingleNewPlantIntoFutureFleetCellArray(futurepowerfleetforplexos,...
        'Solar PV',currstate,currplantcapac);
    currorisid=maxorisid+i-1;
    futurepowerfleetforplexos{end,parseddataorisidcol}=num2str(currorisid); %increase ORIS ID each plant
    futurepowerfleetforplexos{end,strcmp(futurepowerfleetforplexos(1,:),'VOMPerMWhCalculated')}=0;%Add a 0 value in Variable O&M column 
    %Add ORIS ID to end of listofsolarfarmsperstate array - will be used later
    listofsolarfarmsperstate{i,listofsolarfarmsperstateorisidcol}=num2str(currorisid);
end


%% NOW GET HOURLY SOLAR GENERATION PROFILES
%Steps: 1) For each plant, get state & filename, then open that file
%2) Calculate hourly capacity factors - need to downscale power generation
%3) Save hourly capacity factors as new column, with ORIS ID as header, to
%array

%Also need to set up array w/ appropriate date info - do that here
solarratingfactors={'DateTime'};
%Need to add date strings to solarratingfactors array. Do so by using
%below function - don't use output besides from for creating vector of
%dates.
%Load mapping array from UTC to CST. Map has original year month day hour in first 4 columns, and then
%mapped year month day hour in last 4 columns. 
if strcmp(pc,'work')
    winddatadir='C:\Users\mtcraig\Desktop\EPP Research\Databases\Eastern Wind Dataset';
elseif strcmp(pc,'personal')
    winddatadir='C:\Users\mcraig10\Desktop\EPP Research\Databases\Eastern Wind Dataset';
end
[mapofutctocstwindtime]=CreateTableForConvertingUTCtoCST(winddatadir);
%Initialize array that will hold capacity factor info w/ date data from mapofutctocstwindtime
%mapofutctocstwindtime columsn 5-8 have date data w/ hour 0 in place of 24,
%which is what I need for PLEXOS. So, use those columns, and take data from
%second row of 2004 data (i.e., hour 1 (=12:01AM-1:00AM) on january 1).
rowsof2004dates=find(mapofutctocstwindtime(:,5)==2004);
secondrowof2004data=rowsof2004dates(2,1); clear rowsof2004dates;
yearofdata=mapofutctocstwindtime(secondrowof2004data:(8760+secondrowof2004data-1),5:8);
datestr=strcat(num2str(yearofdata(:,2)),'/',num2str(yearofdata(:,3)),'/',num2str(2030),{' '},num2str(yearofdata(:,4)),':00');
%Need to change final datestr value by increasing year to 2031 (since using
%0:00 convention, which means final hour in 2030 is 1/1/2031 0:00).
datestr(end,1)=strcat(num2str(yearofdata(end,2)),'/',num2str(yearofdata(end,3)),'/',num2str(2031),{' '},num2str(yearofdata(end,4)),':00');
solarratingfactors=vertcat(solarratingfactors,datestr); 
solarratingfactorsdateinfo=solarratingfactors;
%Now for each solar plant, get hourly capacity factors
for i=2:size(listofsolarfarmsperstate,1)
    %Get file name and plant size and state for current plant
    currfilename=listofsolarfarmsperstate{i,solardatafilecol};
    currplantoriginalsize=listofsolarfarmsperstate{i,listofsolarfarmsperstateoriginalcapacitycol};
    currstate=listofsolarfarmsperstate{i,solardatastatecol};

    %Read in file - col 1 = local time, col 2 = generation (MW)
    [~,~,plantdata]=xlsread(fullfile(solarmasterfolder,currstate,currfilename));
    %Downscale 5-minute data to hourly data
    plantgen=cell2mat(plantdata(2:end,2));
    hourlyplantgen=zeros(8760,1); hourlyplantgenctr=1;
    for genctr=1:12:size(plantgen,1) %jump forward in icnrements of 12 to get to new hour
        hourlyplantgen(ceil(genctr/12),1)=mean(plantgen(genctr:(genctr+11)));
    end
    %Get hourly CF - need it in % for PLEXOS (Rating Factor)
    hourlycf=hourlyplantgen/currplantoriginalsize*100; 
          
    %Save hourly CF to CSV w/ other hourly CFs
    tempcapacityfactors{1,1}=strcat(listofsolarfarmsperstate{i,listofsolarfarmsperstateorisidcol},'-');
    tempcapacityfactors=vertcat(tempcapacityfactors,num2cell(hourlycf));
    %Combine solarratingfactors with tempcapacityfactors
    solarratingfactors=horzcat(solarratingfactors,tempcapacityfactors);
    clear tempcapacityfactors;
end

%% COMBINE SOLAR UNITS INTO SINGLE GENERATOR
%If combining solar generators into single generator, then get all solar
%plants, calculate new joint RF, and then delete old units and add 1 new
%unit
createplexosobjname = @(arraywithdata,orisidcol,unitidcol,rowofinfo) strcat(arraywithdata{rowofinfo,orisidcol},...
        '-',arraywithdata{rowofinfo,unitidcol});
if groupwindandsolarplants==1
    %Get wind plants
    solarunitrows=find(strcmp(futurepowerfleetforplexos(:,parseddatafueltypecol),'Solar'));
    
    %For each plant, get row in fleet; get capacity; multiply by rating
    %factor/100 to get hourly generation; subtract from total demand.
    solarhourlygen=solarratingfactors; %use structure of solarratingfactors cell as framework to store hourly gen
    runningsolarcapacity=0;
    for solarctr=1:size(solarunitrows,1)
        currrow=solarunitrows(solarctr);
        %Get PLEXOS name of unit
        currplexosid=createplexosobjname(futurepowerfleetforplexos,parseddataorisidcol,parseddataunitidcol,currrow);
        %Get capacity
        currcapacity=futurepowerfleetforplexos{currrow,parseddatacapacitycol};
        %Add capacity to running total
        runningsolarcapacity=runningsolarcapacity+currcapacity;
        %Now look up column of current unit in wind rating factors
        ratingfactorscol=find(strcmp(solarratingfactors(1,:),currplexosid));
        %Isolate RFs
        currratingfactors=cell2mat(solarratingfactors(2:end,ratingfactorscol));
        %Multiply RFs/100 by capacity
        currhourlygen=currratingfactors/100*currcapacity;
        %Store values
        solarhourlygen(2:end,ratingfactorscol)=num2cell(currhourlygen);
    end
    %Sum hourly gen
    totalhourlysolargen=sum(cell2mat(solarhourlygen(2:end,2:end)),2);
    %Get total RF from total capacity
    totalhourlysolarrfs=totalhourlysolargen/runningsolarcapacity*100;
    
    %Delete old units
    futurepowerfleetforplexos(solarunitrows,:)=[];
    %Add new unit
    [futurepowerfleetforplexos]=AddSingleNewPlantIntoFutureFleetCellArray(futurepowerfleetforplexos,...
        'Solar PV','MISO',runningsolarcapacity);
    currorisid=num2str(originalmaxorisid+1);
    futurepowerfleetforplexos{end,parseddataorisidcol}=currorisid; 
    futurepowerfleetforplexos{end,strcmp(futurepowerfleetforplexos(1,:),'VOMPerMWhCalculated')}=0; %Add a 0 value in Variable O&M column
    
    %Create properly-formatted rating factor array
    %Generator name must be as in PLEXOS: 'ORISID-'
    tempcapacityfactors{1,1}=strcat(currorisid,'-');
    tempcapacityfactors=vertcat(tempcapacityfactors,num2cell(totalhourlysolarrfs));
    solarratingfactors=horzcat(solarratingfactorsdateinfo,tempcapacityfactors);
end


%% SAVE FILE WITH SOLAR GENERATION PROFILES
if strcmp(pc,'work')
    directorytowrite='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles\';
elseif strcmp(pc,'personal')
    directorytowrite='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles\';
end
filenametowrite=strcat('SolarGenProfiles',compliancescenario,'FlexCCS',num2str(flexibleccs),'CCS',num2str(mwccstoadd),...
    'Wind',num2str(mwwindtoadd),'GrpRE',num2str(groupwindandsolarplants),'.csv');
fullfilenametosave=strcat(directorytowrite,filenametowrite);
if usenldc==0
    cell2csv(fullfilenametosave,solarratingfactors);
end

%% OUTPUT DATA FILE NAME AND GENERATOR IDS FOR PROPERTIES
%Make CSV file name in PLEXOS file: DataFiles\...
csvfilenamewithsolargenprofiles=strcat('DataFiles\',filenametowrite);











