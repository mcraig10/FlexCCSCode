%Michael Craig
%January 21, 2015
%This script creates wind generation profile for import to PLEXOS based on
%total wind capacity in the future fleet. Wind generation profiles are
%obtained from NREL's Eastern Wind Dataset. 


function [csvfilenamewithwindgenprofiles,futurepowerfleetforplexos,generatoridsinwindfile,windcapacityfactors]=...
    GatherWindGenerationProfilesFromNRELDataForFutureFleet(futurepowerfleetforplexos, compliancescenario,...
    mwwindtoadd, mwccstoadd, flexibleccs, usenldc, groupwindandsolarplants, pc)

%% PARAMETERS
%Set limit on wind farm size that can be adpoted - eastern wind dataset
%includes farms >1 GW, but unrealistic.
maxwindfarmsize=400; %MW

%% GET COLUMN NUMBERS OF DATA IN futurepowerplantfleet
[parseddataorisidcol,parseddataunitidcol,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);

%% ISOLATE WIND POWER PLANTS
%Cell array to hold wind power plants
windpowerplants=futurepowerfleetforplexos(1,:);
for i=2:size(futurepowerfleetforplexos,1)
    if strcmp(futurepowerfleetforplexos{i,parseddatafueltypecol},'Wind')
        windpowerplants(end+1,:)=futurepowerfleetforplexos(i,:);        
    end
end

%% SUM WIND POWER IN EACH STATE
totalwindcapacitybystate=unique(windpowerplants(2:end,parseddatastatecol));
totalwindcapacitybystate{1,2}={}; %initialize second column
for i=size(windpowerplants,1):-1:2
    staterowinwindcapacarray=find(strcmp(totalwindcapacitybystate(:,1),windpowerplants{i,parseddatastatecol}));
    if isempty(totalwindcapacitybystate{staterowinwindcapacarray,2})
        totalwindcapacitybystate{staterowinwindcapacarray,2}=...
            windpowerplants{i,parseddatacapacitycol};
    else
        totalwindcapacitybystate{staterowinwindcapacarray,2}=...
            totalwindcapacitybystate{staterowinwindcapacarray,2}+...
            windpowerplants{i,parseddatacapacitycol};
    end
end

%% ADD WIND POWER CAPACITY (IF ANY)
%Input desired capacity of wind to be added in: mwwindtoadd
%Add by dividing value equally among all states, and adding to capacities
%of existing wind in each state in array totalwindcapacitybystate.
mwwindtoaddeachstate=mwwindtoadd/size(totalwindcapacitybystate,1); %no header
totalwindcapacitybystatesaved=totalwindcapacitybystate;
totalwindcapacitybystate(:,2)=num2cell(cell2mat(totalwindcapacitybystate(:,2))+mwwindtoaddeachstate);

%% DETERMINE WIND GENERATION SITES
%File names
if strcmp(pc,'work')
    winddatadir='C:\Users\mtcraig\Desktop\EPP Research\Databases\Eastern Wind Dataset';
    winddatawritedir='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\Wind Generation Profiles';
elseif strcmp(pc,'personal')
    winddatadir='C:\Users\mcraig10\Desktop\EPP Research\Databases\Eastern Wind Dataset';
    winddatawritedir='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\Wind Generation Profiles';
end
winddatasetsummaryname='eastern_wind_dataset_site_summary.xlsx';
%Wind data set summary headers: SiteNumber	State	LON	LAT	ELEV	Capacity (MW)	NET_CF	IEC Class	Region

%Open data summary
[~,~,winddatasummary]=xlsread(strcat(winddatadir,'\',winddatasetsummaryname),'Onshore_Sites');
winddatasummarystatecol=find(strcmp(winddatasummary(1,:),'State'));
winddatasummarysitenumbercol=find(strcmp(winddatasummary(1,:),'SiteNumber'));
winddatasummarycapacitycol=find(strcmp(winddatasummary(1,:),'Capacity (MW)'));
winddatasummarycfcol=find(strcmp(winddatasummary(1,:),'NET_CF'));
%For each state, select plants in NREL in decreasing order of Net CF until
%meet capacity in state
listofwindfarmsperstate=winddatasummary(1,:);
winddatasummaryoriginalcapacitycol=size(listofwindfarmsperstate,2)+1;
listofwindfarmsperstate{1,winddatasummaryoriginalcapacitycol}='Original Farm Capac in NREL Dataset (MW)';
for i=1:size(totalwindcapacitybystate,1)
    currstate=totalwindcapacitybystate{i,1};
    currstatecapac=totalwindcapacitybystate{i,2};
    %Get a list of wind sites in that state, ordered with decreasing CF
    windsitesinstate=winddatasummary(find(strcmp(winddatasummary(:,winddatasummarystatecol),currstate)),:);
    windsitesinstatesorted=sortrows(windsitesinstate,-winddatasummarycfcol);
    %Go row by row and add a wind farm until currstatecapac is depleted
    rowctr=1;
    while currstatecapac>0
        %Get capacity of current wind farm
        currfarmcapac=windsitesinstatesorted{rowctr,winddatasummarycapacitycol};
        %Save original data farm size from NREL dataset (need later)
        listofwindfarmsperstate{end+1,end}=currfarmcapac;
        %Limit wind farm capac to max
        if currfarmcapac>maxwindfarmsize
            currfarmcapac=maxwindfarmsize;
        end
        %If capac < remaining capacity, use full farm. 
        if currfarmcapac<currstatecapac
            %Subtract farm's capac from state capac
            currstatecapac=currstatecapac-currfarmcapac;
            %Add farm to array; replace capac w/ currfarmcapac to account
            %for truncating currfarmcapac above.
            listofwindfarmsperstate(end,1:end-1)=windsitesinstatesorted(rowctr,:);
            listofwindfarmsperstate{end,winddatasummarycapacitycol}=currfarmcapac;
        else %if capac of farm > remaining state capac, cut off farm
            %Save wind farm, then replace capac w/ whatever is left in
            %state
            listofwindfarmsperstate(end,1:end-1)=windsitesinstatesorted(rowctr,:);
            listofwindfarmsperstate{end,winddatasummarycapacitycol}=currstatecapac;
            currstatecapac=0; %set curr state capca to 0 so exit while loop
        end
        rowctr=rowctr+1;
    end
end

%% REPLACE WIND PLANTS IN POWER FLEET WITH NEW WIND PLANTS
%Append a fake ORIS ID to end of listofwindfarmsperstate; delete all wind
%farms in futurepowerfleetforplexos array; insert new wind plants at end.
%Delete existing wind farms.
windfarmrows=find(strcmp(futurepowerfleetforplexos(:,parseddatafueltypecol),'Wind'));
futurepowerfleetforplexos(windfarmrows,:)=[];

%Determine which ORIS ID to start at.
maxorisid=str2num(futurepowerfleetforplexos{end,parseddataorisidcol});
originalmaxorisid=maxorisid; %save in case grouping wind plants below
%Add column for ORIS ID in listofwindfarmsperstate
listofwindfarmsperstateorisidcol=size(listofwindfarmsperstate,2)+1;
listofwindfarmsperstate{1,listofwindfarmsperstateorisidcol}='ORISIDCreated';
%Loop through list of wind farms to add per state and add them to power
%fleet array.
for i=2:size(listofwindfarmsperstate,1)
    %Get state & capacity of current plant
    currstate=listofwindfarmsperstate{i,winddatasummarystatecol};
    currplantcapac=listofwindfarmsperstate{i,winddatasummarycapacitycol};
    [futurepowerfleetforplexos]=AddSingleNewPlantIntoFutureFleetCellArray(futurepowerfleetforplexos,...
        'Onshore Wind',currstate,currplantcapac);
    currorisid=maxorisid+i-1;
    futurepowerfleetforplexos{end,parseddataorisidcol}=num2str(currorisid); %increase ORIS ID each plant
    futurepowerfleetforplexos{end,strcmp(futurepowerfleetforplexos(1,:),'VOMPerMWhCalculated')}=0;%Add a 0 value in Variable O&M column 
    %Add ORIS ID to end of listofwindfarmsperstate array - will be used
    %later
    listofwindfarmsperstate{i,listofwindfarmsperstateorisidcol}=num2str(currorisid);
end


%% GET WIND GENERATION PROFILES
%Now need to get actual wind generation profiles from site-specific files.
%Files are named: "SITE_xxxxx.csv" where xxxxx is the site # w/ leading
%0's. 
%Each file has two lines of info at top; remove this. Then have headers:
%DATE TIME(UTC) SPEED80M(M/S) NETPOWER(MW). DATE is in YEARMONTHDAY. Years
%are stacked: so all 2004, all 2005, all 2006, some 2007. Time is in UTC,
%which I need to convert to CST. UTC is 6 hours ahead of CST. Generation
%data is given in 10-minute increments that I have to downscale.
%Want average hourly generation data averaged across 2004-2006. 
%Store data in a CSV file, saving the name for input to PLEXOS.
%PLAN: create new array, downscale data to hourly, average data, convert data to time zone, then
%save CSV to PLEXOS & store CSV name in a cell array.
%Get columns of wind site data
sitewinddatadatecol=1; sitewinddatahourcol=2; sitewinddatapowercol=4;
%Also create columns for to-be-created array to hold scaled down data
sitewinddatadownscaledyearcol=1; sitewinddatadownscaledmonthcol=2;
sitewinddatadownscaleddaycol=3; sitewinddatadownscaledhourcol=4; sitewinddatadownscaledgencol=5;
%Load mapping array from UTC to CST. Map has original year month day hour in first 4 columns, and then
%mapped year month day hour in last 4 columns.
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
windcapacityfactors={'DateTime'}; %initialize array w/ header of 1st column
windcapacityfactors=vertcat(windcapacityfactors,datestr); 
windcapacityfactorsdateinfo=windcapacityfactors;
clear datestr yearofdata mapofutctocstwindtime;
%Set parameter for # of samples in an hour in wind data set
numhourlysamples=6; 
for i=2:size(listofwindfarmsperstate,1)
    sitenum=listofwindfarmsperstate{i,winddatasummarysitenumbercol};    
    %Need to insert leading zeros in site num
    sitenumstr=sprintf('%05d',sitenum);
    csvnametoload=strcat('SITE_',sitenumstr,'.csv');
    if strcmp(pc,'work')
        csvfiletoload=strcat('C:\Users\mtcraig\Desktop\EPP Research\Databases\Eastern Wind Dataset\',...
            csvnametoload);
    elseif strcmp(pc,'personal')
        csvfiletoload=strcat('C:\Users\mcraig10\Desktop\EPP Research\Databases\Eastern Wind Dataset\',...
            csvnametoload);    
    end
    %Load wind data, starting at row 4 (exclude headers)
    sitewinddata=csvread(csvfiletoload,3); %offset by 3 rows, so row 4 = row 1
    %Check if first row is correct; if not, print message
    if sitewinddata(1,sitewinddatahourcol)~=10
        'FirstColOfWindDataNotRight';
    end
    %Eliminate leap year data (2004)
    [rowsofleapyear,~]=find(sitewinddata(:,1)==20040229); %get rows of feb 29 2004
    rowsofleapyear=rowsofleapyear+1; %add 1 to rows because first row of feb 29 2004 is actually feb 28 2004; also first hour in mar 1 2004 is feb 29
    sitewinddata(rowsofleapyear,:)=[]; %remove rows
    sitewinddata(sitewinddata(:,1)==20040229,1)=20040301;%Now have a single 20040229 row left for hour 0 on that day - change this to 20040301 for continuity
    
    %Create new array to hold downscaled data.
    sitewinddatadownscaled=[]; sitewinddatadownscaledctr=1;
    %Downscale data - generation in 10 min increments. Average over hours.
    for j=1:numhourlysamples:size(sitewinddata,1)
        %Pull out year, month, day and save into array
        datestr=num2str(sitewinddata(j,sitewinddatadatecol));
        sitewinddatadownscaled(sitewinddatadownscaledctr,sitewinddatadownscaledyearcol)=str2num(datestr(1:4)); %yr
        sitewinddatadownscaled(sitewinddatadownscaledctr,sitewinddatadownscaledmonthcol)=str2num(datestr(5:6)); %mo
        sitewinddatadownscaled(sitewinddatadownscaledctr,sitewinddatadownscaleddaycol)=str2num(datestr(7:8)); %day
        %Wind site data time given in minutes, starting at 10. Get hour of
        %first row in day (will always end in 10 so ceil will work always
        %here).
        sitewinddatadownscaled(sitewinddatadownscaledctr,sitewinddatadownscaledhourcol)=ceil(sitewinddata(j,sitewinddatahourcol)/100); 
        %Calculate average generation in that hour
        sitewinddatadownscaled(sitewinddatadownscaledctr,sitewinddatadownscaledgencol)=mean(sitewinddata(j:(j+numhourlysamples-1),sitewinddatapowercol));
        sitewinddatadownscaledctr=sitewinddatadownscaledctr+1;
    end
    
    %Shift generation column up by 6 units, which is the same as rolling back
    %clock 6 hours (CST -> UCT)
    timeshiftback=6;
    sitewinddatadownscaledconverted=sitewinddatadownscaled;
    sitewinddatadownscaledconverted(1:(end-timeshiftback),sitewinddatadownscaledgencol)=...
        sitewinddatadownscaledconverted((1+timeshiftback):end,sitewinddatadownscaledgencol);
    
    %Now need to average across years - do so by creating array w/
    %month/day, put data side-by-side for years, and then average rows.
    yearstoaverage=[2004;2005;2006];
    averagingarray=[];
    for j=1:size(yearstoaverage,1)
        averagingarray(:,end+1)=...
            sitewinddatadownscaledconverted(sitewinddatadownscaledconverted(:,sitewinddatadownscaledyearcol)==yearstoaverage(j),sitewinddatadownscaledgencol);
    end
    averagewindgen=mean(averagingarray,2);
    
    %Need to get total capacity of wind farm to determine rating
    windsitecapac=listofwindfarmsperstate{i,winddatasummaryoriginalcapacitycol};
    averagesitecapacityfactor=averagewindgen/windsitecapac*100; %make it a %
    
    %Save values in array w/ header of generator name
    %Generator name must be as in PLEXOS: 'ORISID-'
    tempcapacityfactors{1,1}=strcat(listofwindfarmsperstate{i,listofwindfarmsperstateorisidcol},'-'); 
    tempcapacityfactors=vertcat(tempcapacityfactors,num2cell(averagesitecapacityfactor));
    
    %Combine windcapacityfactors with tempcapacityfactors
    windcapacityfactors=horzcat(windcapacityfactors,tempcapacityfactors);
    clear tempcapacityfactors;
end

%% COMBINE WIND UNITS INTO SINGLE GENERATOR
%If combining wind generators into single generator, then get all wind
%plants, calculate new joint RF, and then delete old units and add 1 new
%unit
createplexosobjname = @(arraywithdata,orisidcol,unitidcol,rowofinfo) strcat(arraywithdata{rowofinfo,orisidcol},...
        '-',arraywithdata{rowofinfo,unitidcol});
if groupwindandsolarplants==1
    %Get wind plants
    windunitrows=find(strcmp(futurepowerfleetforplexos(:,parseddatafueltypecol),'Wind'));
    
    %For each plant, get row in fleet; get capacity; multiply by rating
    %factor/100 to get hourly generation; subtract from total demand.
    windhourlygen=windcapacityfactors; %use structure of windcapacityfactors cell as framework to store hourly gen
    runningwindcapacity=0;
    for windctr=1:size(windunitrows,1)
        currrow=windunitrows(windctr);
        %Get PLEXOS name of unit
        currplexosid=createplexosobjname(futurepowerfleetforplexos,parseddataorisidcol,parseddataunitidcol,currrow);
        %Get capacity
        currcapacity=futurepowerfleetforplexos{currrow,parseddatacapacitycol};
        %Add capacity to running total
        runningwindcapacity=runningwindcapacity+currcapacity;
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
    %Get total RF from total capacity
    totalhourlywindrfs=totalhourlywindgen/runningwindcapacity*100;
    
    %Delete old units
    futurepowerfleetforplexos(windunitrows,:)=[];
    %Add new unit
    [futurepowerfleetforplexos]=AddSingleNewPlantIntoFutureFleetCellArray(futurepowerfleetforplexos,...
        'Onshore Wind','MISO',runningwindcapacity);
    currorisid=num2str(originalmaxorisid+1);
    futurepowerfleetforplexos{end,parseddataorisidcol}=currorisid; 
    futurepowerfleetforplexos{end,strcmp(futurepowerfleetforplexos(1,:),'VOMPerMWhCalculated')}=0; %Add a 0 value in Variable O&M column
    
    %Create properly-formatted rating factor array
    %Generator name must be as in PLEXOS: 'ORISID-'
    tempcapacityfactors{1,1}=strcat(currorisid,'-');
    tempcapacityfactors=vertcat(tempcapacityfactors,num2cell(totalhourlywindrfs));
    windcapacityfactors=horzcat(windcapacityfactorsdateinfo,tempcapacityfactors);
end

%% SAVE FILE WITH WIND GENERATION PROFILES
if strcmp(pc,'work')
    dirtowritewind='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles\';
elseif strcmp(pc,'personal')
    dirtowritewind='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles\';
end
filenametowritewind=strcat('WindGenProfiles',compliancescenario,'FlexCCS',num2str(flexibleccs),'CCS',num2str(mwccstoadd),...
    'Wind',num2str(mwwindtoadd),'GrpRE',num2str(groupwindandsolarplants),'.csv');
fullfilenametosave=strcat(dirtowritewind,filenametowritewind);
if usenldc==0
    cell2csv(fullfilenametosave,windcapacityfactors);
end
%% OUTPUT DATA FILE NAME AND GENERATOR IDS FOR PROPERTIES
%Make CSV file name in PLEXOS file: DataFiles\...
csvfilenamewithwindgenprofiles=strcat('DataFiles\',filenametowritewind);
generatoridsinwindfile=windcapacityfactors(1,2:end);










