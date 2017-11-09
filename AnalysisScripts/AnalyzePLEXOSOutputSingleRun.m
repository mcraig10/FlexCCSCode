%Michael Craig, 15 June 2015
%This script analyzes copied-and-pasted output from PLEXOS. 
%June 15, 2015: calculates fleet-wide emissions rate and mass pursuant to
%CPP calculations.
%June 17: also added ability to create stacked area chart of daily
%generation
%Oct 11: added ability to pull out behavior just for flex CCS facility.

%% SET DEFAULT TEXT FOR FIGURES
set(0,'defaultAxesFontName', 'Times New Roman')
set(0,'defaultTextFontName', 'Times New Roman')

%% PARAMETERS
%Which reserve requirements to use
reserves='nrel' %'miso' or 'nrel'

%Whether testing CPP or CCS paper
ccspaper=1; %0 if CPP, 1 if CCS

%Whether to test lower limit
testlowerlimit=0; %0 or 1

%% FILE NAMES
%Folder name 
if ccspaper==0
    basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\ResultsNRELRes\CPPLimit';
else
    if testlowerlimit==1
        basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\CCSPaper\LwrLm';
    else
        basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\CCSPaper\CPP';
    end
end

%Folder name w/ PLEXOS output + MATLAB fleet name
% foldernamewithflatfiles='CPPEEPt5FlxCCS1MW4000WndMW0Rmp1MSL1Vnt0NRELRes';
% foldernamewithflatfiles='CPPEEPt5FlxCCS1MW2000WndMW0Rmp1MSL1Vnt0NRELRes';
if ccspaper==0
    foldernamewithflatfiles='CPPEEPt5FlxCCS1MW2000WndMW0Rmp1MSL1Vnt0NRELRes';
    filewithfleetinfo='CPPEEPt5FlxCCS1MW2000WndMW0Rmp1MSL1Vnt0NRELRes.mat';
else
    if testlowerlimit==1
        foldernamewithflatfiles='CPPEEPt5FlxCCS1MW2000WndMW0Rmp1MSL1Vnt0LwrLmtNRELRes24LA';
        filewithfleetinfo='CPPEEPt5FlxCCS1MW2000WndMW0Rmp1MSL1Vnt0LwrLmtNRELRes24LA.mat';
    else
        foldernamewithflatfiles='CPPEEPt5FlxCCS1MW2000WndMW0Rmp1MSL1Vnt0NRELRes24LA';
        filewithfleetinfo='CPPEEPt5FlxCCS1MW2000WndMW0Rmp1MSL1Vnt0NRELRes24LA.mat';
    end
end
dirofflatfiles=fullfile(basedirforflatfiles,foldernamewithflatfiles);

%Fleet .mat file directory
dirwithfleetinfo='C:\Users\mtcraig\Desktop\EPP Research\Matlab\Fleets';
load(fullfile(dirwithfleetinfo,filewithfleetinfo));

%% ANALYSIS TOGGLES
analyzeannualdata=1;
analyzedailydata=1;
analyzeintervalfleetdata=0;
checkreservesandgeneration=0;
analyzeflexccsdata=1;

%% OTHER PARAMETERS
%Horizon of PLEXOS run - used when pulling out interval and daily data
horizonstartmonth=1; 
horizonstartday=1;
horizonendmonth=12;
horizonendday=31;

%CPP emissions mass
cppemissionsmass=3.1362e+11;

%% CALCULATE FLEET-WIDE EMISSIONS RATE
%% IMPORT INPUT DATA TO PLEXOS FROM FLEET .MAT OUTPUT BY CREATEPLEXOSIMPORTFILE SCRIPT



%% GET COLUMN NUMBERS OF FLEET DATA
[fleetorisidcol,fleetunitidcol,fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol,fleetregioncol,fleetstatecol,fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol, fleetpumpunitscol, fleetpumpeffcol, fleetpumploadcol,...
    fleetccsretrofitcol,fleettruesscapacitycol,fleetaffectedegucol,fleethrpenaltycol,...
    fleetcapacpenaltycol,fleetsshrpenaltycol,fleetsscapacpenaltycol,fleeteextraperestorecol,...
    fleeteregenpereco2capcol,fleetegridpereco2capandregencol,fleetegriddischargeperestorecol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);


%% IMPORT MAPPING CSV
%Mapping CSV:
[~,~,id2name]=xlsread(fullfile(dirofflatfiles,'id2name.csv'),'id2name');
%Get column #s of id2name. id col has id #; name col has GEN-ORIS ID. Only
%want class = 'Generator'.
classcol=find(strcmp(id2name(1,:),'class'));
idcol=find(strcmp(id2name(1,:),'id'));
namecol=find(strcmp(id2name(1,:),'name'));
%Isolate 'Generator' class rows
genrows=find(strcmp(id2name(:,classcol),'Generator'));
id2namegens=id2name(genrows,:);


%% ADD ORIS-GENERATOR ID TO FUTUREPOWERFLEET
%In output from PLEXOS, generator IDs are given as: 'ORISID-GENID'. In
%futurepowerfleet array, don't have similar column. Need to concatenate
%ORIS and generator ID. Do that now.
orisgenidcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,orisgenidcol}='ORIS-GenID';
futurepowerfleetforplexos(2:end,orisgenidcol)=strcat(futurepowerfleetforplexos(2:end,fleetorisidcol),'-',futurepowerfleetforplexos(2:end,fleetunitidcol));


%% ANNUAL DATA*************************************************************
%**************************************************************************
%**************************************************************************

if analyzeannualdata==1
%% IMPORT ANNUAL GENERATION SUMMARY OUTPUT DATA FROM PLEXOS
%'fiscal year' folder has the total annual output from generators. Need to
%all import Excel file that maps between file ID and generator ID
%fiscal year dir:
fiscalyeardir=fullfile(dirofflatfiles,'fiscal year');

%Naming format of generation files: 'ST Generator(id).Generation.csv'
%Contents of generation files: YEAR MONTH DAY 1            col '1' has
%generation data.
yearcsvgencol=4;
yearcsvgenrow=2;

%Now, for each generator in mapping file, get corresponding
%futurepowerfleet generator, open CSV file, and save generation to new column labeled: TotalAnnualGen(MWh) 
%Note: need to convert from GWh (PLEXOS output) to MWh
totalannualgencol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos(1,totalannualgencol)={'TotalAnnualGen(MWh)'}; 
for i=1:size(id2namegens,1)
    %Get curr ORIS-GENID
    currunitid=id2namegens{i,namecol};
    %Get curr PLEXOS output ID
    currplexosid=id2namegens{i,idcol};
    %Test if unit ID has '/' in it - PLEXOS converts some generators (e.g.,
    %6035-11-1) into date strings (11/1/6035) b/c it thinks its a date.
    hasbackslash=findstr(currunitid,'/');
    if isempty(hasbackslash)==0 %if not empty, has a backslash so need to change around
        %Last 4 digits go first, then first digit, then first digit, then
        %middle digit
        slashpositions=findstr(currunitid,'/');
        newcurrunitid=currunitid(slashpositions(2)+1:end);
        newcurrunitid=strcat(newcurrunitid,'-',currunitid(1:slashpositions(1)-1));
        newcurrunitid=strcat(newcurrunitid,'-',currunitid(slashpositions(1)+1:slashpositions(2)-1));
        currunitid=newcurrunitid;
    end
    %Open CSV for that generator
    yeargencsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Generation');
    yeargencsvname=strcat(yeargencsvnamebase,'.csv');
    [~,~,curryeargeneration]=xlsread(fullfile(fiscalyeardir,yeargencsvname),yeargencsvnamebase);
    %Get generation value
    currgenerationvalue=curryeargeneration{yearcsvgenrow,yearcsvgencol};
    %Find row in futurepowerfleet for that generator
    rowinfleet=find(strcmp(futurepowerfleetforplexos(:,orisgenidcol),currunitid));
    %Add generation to end of that row
    futurepowerfleetforplexos{rowinfleet,totalannualgencol}=currgenerationvalue*1000;
end

end

if analyzedailydata==1
%% DAILY DATA**************************************************************
%**************************************************************************
%**************************************************************************
%**************************************************************************

%% PLOT DAILY GENERATION BY FUEL TYPE
%Directory of daily gen files:
dailydir=fullfile(dirofflatfiles,'day');

%Naming format of daily generation files: ST Generator(id).Generation
%In each file: YEAR MONTH DAY 1         col 1 has daily generation (GWh)
%Open random file to get col #s
[~,~,randfile]=xlsread(strcat(dailydir,'\ST Generator(1).Generation.csv'),'ST Generator(1).Generation');
dailycsvmonthcol=find(strcmp(randfile(1,:),'MONTH'));
dailycsvdaycol=find(strcmp(randfile(1,:),'DAY'));
dailycsvgencol=dailycsvdaycol+1; %gen col is 1 past day col 
%Establish time period of analysis - if run PLEXOS for less than one year,
%output CSVs have leading zeros for days before initial horizon. 
randfilemonths=cell2mat(randfile(2:end,dailycsvmonthcol));
randfiledays=cell2mat(randfile(2:end,dailycsvdaycol));
firstrowofdata=find(randfilemonths(:,1)==horizonstartmonth & ...
    randfiledays(:,1)==horizonstartday)+1; %add 1 b/c removed header before
%Also get # of days in time horizon, which runs from firstrowofdata to
%final row of random file
numdaysofdata=size(randfile,1)-firstrowofdata+1;
clear randfile randfilemonth randfiledays;

%Process: 1) initialize array w/ each fuel type
%2) for each generator:
%2a) open daily CSV file 
%2b) find fuel type for generator
%2c) add generation of that generator to fuel type generation

%Initialize array w/ each fuel type
fueltypes=unique(futurepowerfleetforplexos(2:end,fleetfueltypecol));
genbyfueltype=['FuelType';fueltypes];
temp=num2cell(1:numdaysofdata); temp=[temp;num2cell(zeros(size(fueltypes,1),numdaysofdata))];
genbyfueltype=[genbyfueltype,temp]; clear temp;
fuelcolgenbyfueltype=find(strcmp(genbyfueltype(1,:),'FuelType'));
%Iterate through generators
for i=1:size(id2namegens,1)
    %Get curr ORIS-GENID
    currunitid=id2namegens{i,namecol};
    %Get curr PLEXOS output ID
    currplexosid=id2namegens{i,idcol};
    %Test if unit ID has '/' in it - PLEXOS converts some generators (e.g.,
    %6035-11-1) into date strings (11/1/6035) b/c it thinks its a date.
    hasbackslash=findstr(currunitid,'/');
    if isempty(hasbackslash)==0 %if not empty, has a backslash so need to change around
        %Last 4 digits go first, then first digit, then first digit, then
        %middle digit
        slashpositions=findstr(currunitid,'/');
        newcurrunitid=currunitid(slashpositions(2)+1:end);
        newcurrunitid=strcat(newcurrunitid,'-',currunitid(1:slashpositions(1)-1));
        newcurrunitid=strcat(newcurrunitid,'-',currunitid(slashpositions(1)+1:slashpositions(2)-1));
        currunitid=newcurrunitid;
    end
    %Open CSV for that generator
    dailygencsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Generation');
    dailygencsvname=strcat(dailygencsvnamebase,'.csv');
    [~,~,currdaygeneration]=xlsread(fullfile(dailydir,dailygencsvname),dailygencsvnamebase);
    %Get generation values and flip them and convert to MWh. Generation
    %values don't begin in row 2 since if run PLEXOS for <1 year then have
    %leading zeros. 
    dailygenvalues=cell2mat(currdaygeneration(firstrowofdata:end,dailycsvgencol))'*1000;
    %Get fuel type of generator
    rowinfleet=find(strcmp(futurepowerfleetforplexos(:,orisgenidcol),currunitid));
    currfueltype=futurepowerfleetforplexos{rowinfleet,fleetfueltypecol};
    %Add gen values for current gen to gen values for curr fuel type
    rowingenbyfuelarray=find(strcmp(genbyfueltype(:,fuelcolgenbyfueltype),currfueltype));
    genbyfueltype(rowingenbyfuelarray,2:end)=num2cell(cell2mat(genbyfueltype(rowingenbyfuelarray,2:end))+...
        dailygenvalues);
end

%PLOT
% %First, see if any rows have 0 gen and eliminate them
% rowstoelim=[];
% for i=2:size(genbyfueltype,1)
%     rowmaxgen=max(cell2mat(genbyfueltype(i,2:end)));
%     if rowmaxgen==0
%         rowstoelim=[rowstoelim,i];
%     end
% end
% if isempty(rowstoelim)==0
%     genbyfueltype(rowstoelim,:)=[];
%     clear rowstoelim;
% end

%Reshuffle array so have baseload on bottom, peakers on top, etc.
%Nuclear, Geothermal, Fwaste, Biomass, MSW, LF Gas, Coal, NaturalGas, Non-Fossil, Wind,
%Solar, Hydro, Oil
desiredfuelorder={'Nuclear','Geothermal','Fwaste','Biomass','MSW','LF Gas','Coal','NaturalGas',...
    'Non-Fossil','Wind','Solar','Hydro','Oil'};
%Go through genbyfueltype, save array to columns of new array w/ ordering
%of desiredfuelorder
genbyfueltypeforplot=[];
for i=1:size(desiredfuelorder,2)
    currfuel=desiredfuelorder{i};
    rownum=find(strcmp(genbyfueltype(:,fuelcolgenbyfueltype),currfuel));
    genbyfueltypeforplot=[genbyfueltypeforplot,cell2mat(genbyfueltype(rownum,2:end))'];
end

%PLOT AREA
%If plot all days:
figure; 
area(genbyfueltypeforplot) 
set(gca,'FontSize',16); 
set(gca,'XTick',[1 numdaysofdata]); 
set(gca,'XTickLabel',{strcat(num2str(horizonstartmonth),'/',num2str(horizonstartday)),...
    strcat(num2str(horizonendmonth),'/',num2str(horizonendday))});
legend(desiredfuelorder,'FontSize',16)
ylabel('Daily Generation (MWh)'); xlabel('Day of Year')
%If plot subset of days:
% startingdaytoplot=firstrowofdata;
% numdaystoplot=365-startingdaytoplot;
% area(genbyfueltypeforplot(startingdaytoplot:end,:)) %182:end = July 1, 2030 to end of year
% set(gca,'FontSize',16); 
% set(gca,'XTick',[1 numdaystoplot]); 
% set(gca,'XTickLabel',{'July 1', 'December 1'});
% legend(desiredfuelorder,'FontSize',16)
% ylabel('Daily Generation (MWh)'); xlabel('Day of Year')

end


%% INTERVAL DATA***********************************************************
%**************************************************************************
%**************************************************************************

if analyzeintervalfleetdata==1
%% IMPORT INTERVAL GENERATION DATA
%E.g., if ran UC in hourly time steps, import hourly data
%Directory of daily gen files:
intervaldir=fullfile(dirofflatfiles,'interval');

%Naming format of daily generation files: ST Generator(id).Generation
%In each file: YEAR MONTH DAY 1 2 3 4... (hours)      daily generation
%(MWh) is in each hour column
%Open random file to get col #s
[~,~,randfile]=xlsread(strcat(intervaldir,'\ST Generator(1).Generation.csv'),'ST Generator(1).Generation');
intervalcsvmonthcol=find(strcmp(randfile(1,:),'MONTH'));
intervalcsvdaycol=find(strcmp(randfile(1,:),'DAY'));
intervalcsvhour1col=dailycsvdaycol+1; 
%No leading zeros in interval data, but still want number of days in analysis period
numdaysofdatainterval=size(randfile,1)-1;
numhoursofdatainterval=numdaysofdatainterval*24;
clear randfile;

%% PLOT INTERVAL GENERATION DATA
%Process: 1) initialize array w/ each fuel type
%2) for each generator:
%2a) open interval CSV file
%2b) find fuel type for generator
%2c) add generation of that generator to fuel type generation

%Initialize array w/ each fuel type
fueltypes=unique(futurepowerfleetforplexos(2:end,fleetfueltypecol));
genbyfueltypeinterval=['FuelType';fueltypes];
temp=num2cell(1:numhoursofdatainterval); temp=[temp;num2cell(zeros(size(fueltypes,1),numhoursofdatainterval))];
genbyfueltypeinterval=[genbyfueltypeinterval,temp]; clear temp;
fuelcolgenbyfueltype=find(strcmp(genbyfueltypeinterval(1,:),'FuelType'));
%Iterate through generators
for i=1:size(id2namegens,1)
    %Get curr ORIS-GENID
    currunitid=id2namegens{i,namecol};
    %Get curr PLEXOS output ID
    currplexosid=id2namegens{i,idcol};
    %Test if unit ID has '/' in it - PLEXOS converts some generators (e.g.,
    %6035-11-1) into date strings (11/1/6035) b/c it thinks its a date.
    hasbackslash=findstr(currunitid,'/');
    if isempty(hasbackslash)==0 %if not empty, has a backslash so need to change around
        %Last 4 digits go first, then first digit, then first digit, then
        %middle digit
        slashpositions=findstr(currunitid,'/');
        newcurrunitid=currunitid(slashpositions(2)+1:end);
        newcurrunitid=strcat(newcurrunitid,'-',currunitid(1:slashpositions(1)-1));
        newcurrunitid=strcat(newcurrunitid,'-',currunitid(slashpositions(1)+1:slashpositions(2)-1));
        currunitid=newcurrunitid;
    end
    %Open CSV for that generator
    intervalgencsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Generation');
    intervalgencsvname=strcat(intervalgencsvnamebase,'.csv');
    [~,~,currintervalgeneration]=xlsread(fullfile(intervaldir,intervalgencsvname),intervalgencsvnamebase);
    %Get generation values - need to go across a row and get each hour,
    %then down. 
    intervalgenvalues=cell2mat(currintervalgeneration(2:end,intervalcsvhour1col:end));
    intervalgenvalueshorizontal=zeros(1,size(intervalgenvalues,1)*size(intervalgenvalues,2));
    for j=1:size(intervalgenvalues,1)
        intervalgenvalueshorizontal(1,((j-1)*24+1):(j*24))=intervalgenvalues(j,:);
    end
    %Get fuel type of generator
    rowinfleet=find(strcmp(futurepowerfleetforplexos(:,orisgenidcol),currunitid));
    currfueltype=futurepowerfleetforplexos{rowinfleet,fleetfueltypecol};
    %Add gen values for current gen to gen values for curr fuel type
    rowingenbyfuelarray=find(strcmp(genbyfueltypeinterval(:,fuelcolgenbyfueltype),currfueltype));
    genbyfueltypeinterval(rowingenbyfuelarray,2:end)=num2cell(cell2mat(genbyfueltypeinterval(rowingenbyfuelarray,2:end))+...
        intervalgenvalueshorizontal);
end

%PLOT
% %First, see if any rows have 0 gen and eliminate them
% for i=2:size(genbyfueltypeinterval,1)
%     rowmaxgen=max(cell2mat(genbyfueltypeinterval(i,2:end)));
%     if rowmaxgen==0
%         rowstoelim=[rowstoelim,i];
%     end
% end
% if exist('rowstoelim')==1
%     genbyfueltypeinterval(rowstoelim,:)=[];
%     clear rowstoelim;
% end

%Reshuffle array so have baseload on bottom, peakers on top, etc.
%Nuclear, Geothermal, Fwaste, Biomass, MSW, LF Gas, Coal, NaturalGas, Non-Fossil, Wind,
%Solar, Hydro, Oil
desiredfuelorder={'Nuclear','Geothermal','Fwaste','Biomass','MSW','LF Gas','Coal','NaturalGas',...
    'Non-Fossil','Wind','Solar','Hydro','Oil'};
%Go through genbyfueltype, save array to columns of new array w/ ordering
%of desiredfuelorder
genbyfueltypeintervalforplot=[];
for i=1:size(desiredfuelorder,2)
    currfuel=desiredfuelorder{i};
    rownum=find(strcmp(genbyfueltypeinterval(:,fuelcolgenbyfueltype),currfuel));
    genbyfueltypeintervalforplot=[genbyfueltypeintervalforplot,cell2mat(genbyfueltypeinterval(rownum,2:end))'];
end
%Now plot area
area(genbyfueltypeintervalforplot) 
set(gca,'FontSize',16); 
set(gca,'XTick',[1 numhoursofdatainterval]); 
set(gca,'XTickLabel',{strcat(num2str(horizonstartmonth),'/',num2str(horizonstartday)),...
    strcat(num2str(horizonendmonth),'/',num2str(horizonendday))});
ylim([0 max(max(genbyfueltypeintervalforplot))]);
legend(desiredfuelorder,'FontSize',16)
ylabel('Hourly Generation (MWh)'); xlabel('Day of Year')


if checkreservesandgeneration==1
%% CHECK RESERVES + GENERATION <= CAPACITY FOR EACH PLANT IN EACH HOUR
%Initialize array w/ each generator
genids=unique(id2namegens(:,namecol));
genplusreservesbygenerator=['ORISGenID';genids];
temp=num2cell(1:numhoursofdatainterval); temp=[temp;num2cell(zeros(size(genids,1),numhoursofdatainterval))];
genplusreservesbygenerator=[genplusreservesbygenerator,temp]; clear temp;
%Iterate through generators
for i=1:size(id2namegens,1)
    %Get curr ORIS-GENID
    currunitid=id2namegens{i,namecol};
    %Get curr PLEXOS output ID
    currplexosid=id2namegens{i,idcol};
    %Test if unit ID has '/' in it - PLEXOS converts some generators (e.g.,
    %6035-11-1) into date strings (11/1/6035) b/c it thinks its a date.
    hasbackslash=findstr(currunitid,'/');
    if isempty(hasbackslash)==0 %if not empty, has a backslash so need to change around
        %Last 4 digits go first, then first digit, then first digit, then
        %middle digit
        slashpositions=findstr(currunitid,'/');
        newcurrunitid=currunitid(slashpositions(2)+1:end);
        newcurrunitid=strcat(newcurrunitid,'-',currunitid(1:slashpositions(1)-1));
        newcurrunitid=strcat(newcurrunitid,'-',currunitid(slashpositions(1)+1:slashpositions(2)-1));
        currunitid=newcurrunitid;
    end
    %Open generation and reserve CSV for that generator
    intervalgencsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Generation');
    intervalgencsvname=strcat(intervalgencsvnamebase,'.csv');
    [~,~,currintervalgeneration]=xlsread(fullfile(intervaldir,intervalgencsvname),intervalgencsvnamebase);
    intervalraisereservecsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Raise Reserve');
    intervalraisereservecsvname=strcat(intervalraisereservecsvnamebase,'.csv');
    if length(intervalraisereservecsvnamebase)>31
        intervalraisereservecsvnamebase=intervalraisereservecsvnamebase(1:31);
    end
    [~,~,currintervalraisereserves]=xlsread(fullfile(intervaldir,intervalraisereservecsvname),intervalraisereservecsvnamebase);
    if strcmp(reserves,'miso')
        intervalregraisereservecsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Regulation Raise Reserve');
        intervalregraisereservecsvname=strcat(intervalregraisereservecsvnamebase,'.csv');
        if length(intervalregraisereservecsvnamebase)>31
            intervalregraisereservecsvnamebase=intervalregraisereservecsvnamebase(1:31);
        end
        [~,~,currintervalregraisereserves]=xlsread(fullfile(intervaldir,intervalregraisereservecsvname),intervalregraisereservecsvnamebase(1:31)); %truncate b/c only 31 chars allowed in worksheet names
    end
    %Get generation and reserve values - need to go across a row and get each hour,
    %then down. 
    intervalgenvalues=cell2mat(currintervalgeneration(2:end,intervalcsvhour1col:end));
    intervalraisereservevalues=cell2mat(currintervalraisereserves(2:end,intervalcsvhour1col:end));
    if strcmp(reserves,'miso')
        intervalregraisereservevalues=cell2mat(currintervalregraisereserves(2:end,intervalcsvhour1col:end));
    end
    intervalgenplusreservesvalueshorizontal=zeros(1,size(intervalgenvalues,1)*size(intervalgenvalues,2));
    for j=1:size(intervalgenvalues,1) %gen and reserves have same format so do all at once
        if strcmp(reserves,'miso')
            intervalgenplusreservesvalueshorizontal(1,((j-1)*24+1):(j*24))=intervalgenvalues(j,:)+...
                intervalraisereservevalues(j,:)+intervalregraisereservevalues(j,:);
        elseif strcmp(reserves,'nrel')
            intervalgenplusreservesvalueshorizontal(1,((j-1)*24+1):(j*24))=intervalgenvalues(j,:)+...
                intervalraisereservevalues(j,:);
        end
    end
    %Save values along with generator name (b/c of units where - gets
    %convereted to /).
    genplusreservesbygenerator{i+1,1}=currunitid;
    genplusreservesbygenerator(i+1,2:end)=num2cell(intervalgenplusreservesvalueshorizontal);
end

%Now compare max value in each row to capacity of generator to see if any
%generator has generation + up reserves > capacity in any given hour.
genplusreservesgreaterthancapacity=repmat(2,size(genplusreservesbygenerator,1)-1,1); %use 2 as dummy value; subtract 1 from length b/c of header
for i=2:size(genplusreservesbygenerator,1)
    %Get max value of genplusreservesbygenerator
    maxval=max(cell2mat(genplusreservesbygenerator(i,2:end)));
    %Find row in futurepowerfleet of generator
    rowinfleet=find(strcmp(futurepowerfleetforplexos(:,orisgenidcol),genplusreservesbygenerator{i,1}));
    %Get capacity
    capactemp=futurepowerfleetforplexos{rowinfleet,fleetcapacitycol};
    %See if max value in row is > capacity. Add 0.01 as tolerance band;
    %values being compared are MW, so this is a tiny value, and there are 
    %some instances where maxval is 1E-8 above capactemp, which is
    %neglible.
    maxvalgreaterthancapac=(maxval-.01)>capactemp; 
    %Store value
    genplusreservesgreaterthancapacity(i-1,1)=maxvalgreaterthancapac;
end

end
end


%% ANALYZE FLEXIBLE CCS OPERATIONS*****************************************
%**************************************************************************
if analyzeflexccsdata==1
    %Import id2name file
    [~,~,id2name]=xlsread(fullfile(dirofflatfiles,'id2name.csv'),'id2name');
    %Get column #s of id2name. id col has id #; name col has GEN-ORIS ID. Only
    %want class = 'Generator'.
    classcol=find(strcmp(id2name(1,:),'class'));
    plexosidcol=find(strcmp(id2name(1,:),'id'));
    unitnamecol=find(strcmp(id2name(1,:),'name'));
    %Isolate 'Generator' class rows
    genrows=find(strcmp(id2name(:,classcol),'Generator'));
    id2namegens=id2name(genrows,:);

    %First, get col info for interval data
    intervaldir=fullfile(dirofflatfiles,'interval');
    [~,~,randfile]=xlsread(strcat(intervaldir,'\ST Generator(1).Generation.csv'),'ST Generator(1).Generation');
    intervalcsvyearcol=find(strcmp(randfile(1,:),'YEAR'));
    intervalcsvmonthcol=find(strcmp(randfile(1,:),'MONTH'));
    intervalcsvdaycol=find(strcmp(randfile(1,:),'DAY'));
    intervalcsvhour1col=intervalcsvdaycol+1; 
    numhours=(size(randfile,1)-1)*24;
    yearinfocol={'Year'};
    monthinfocol={'Month'};
    dayinfocol={'Day'};
    hourinfocol={'Hour'};
    for i=2:size(randfile,1)
        yearinfocol=vertcat(yearinfocol,num2cell(repmat(randfile{i,intervalcsvyearcol},24,1)));
        monthinfocol=vertcat(monthinfocol,num2cell(repmat(randfile{i,intervalcsvmonthcol},24,1)));
        dayinfocol=vertcat(dayinfocol,num2cell(repmat(randfile{i,intervalcsvdaycol},24,1)));
        hourinfocol=vertcat(hourinfocol,num2cell(1:24)');
    end
    dateinfo=horzcat(yearinfocol,monthinfocol,dayinfocol,hourinfocol);
    
    %Find flex CCS generators using retrofit col
    ccsretrofitdata=cell2mat(futurepowerfleetforplexos(2:end,fleetccsretrofitcol));
    ccsretrofitrows=find(ccsretrofitdata==1)+1; %shift forward 1 since doing 2:end in prior line

    %Initialize result arrays
    flexccsgen=dateinfo;
    flexccsregraise=dateinfo;
    flexccsraise=dateinfo;
    flexccsreglower=dateinfo;
    flexccsreplace=dateinfo;
    
    for unitctr=1:size(ccsretrofitrows,1)
        currfleetrow=ccsretrofitrows(unitctr);
        
        %Get ORIS & unit IDs
        curroris=futurepowerfleetforplexos{currfleetrow,fleetorisidcol};
        currunitid=futurepowerfleetforplexos{currfleetrow,fleetunitidcol};
        
        %Find associated generators
        basegenname=strcat(curroris,'-',currunitid);
        solvgenname=strcat(basegenname,'ContinuousSolvent');
        pump1genname=strcat(basegenname,'SSPump1');
        pump2genname=strcat(basegenname,'SSPump2');
        dischargedummy1genname=strcat(basegenname,'SSDischargeDummy1');
        dischargedummy2genname=strcat(basegenname,'SSDischargeDummy2');
        pumpdummy1genname=strcat(basegenname,'SSPumpDummy1');
        pumpdummy2genname=strcat(basegenname,'SSPumpDummy2');
        ventgenname=strcat(basegenname,'Venting');
        ventchargegenname=strcat(basegenname,'SSVentWhenCharge');
        %Get rows in PLEXOS files
        basegenrow=find(strcmp(id2namegens(:,unitnamecol),basegenname));
        contsolvrow=find(strcmp(id2namegens(:,unitnamecol),solvgenname));
        pump1row=find(strcmp(id2namegens(:,unitnamecol),pump1genname));
        pump2row=find(strcmp(id2namegens(:,unitnamecol),pump2genname));
        discharge1row=find(strcmp(id2namegens(:,unitnamecol),dischargedummy1genname));
        discharge2row=find(strcmp(id2namegens(:,unitnamecol),dischargedummy2genname));
        pumpdummy1row=find(strcmp(id2namegens(:,unitnamecol),pumpdummy1genname));
        pumpdummy2row=find(strcmp(id2namegens(:,unitnamecol),pumpdummy2genname));
        ventrow=find(strcmp(id2namegens(:,unitnamecol),ventgenname));
        ventchargerow=find(strcmp(id2namegens(:,unitnamecol),ventchargegenname));
        %Combine rows
        flexccsnames={basegenname;solvgenname;pump1genname;pump2genname;...
            dischargedummy1genname;dischargedummy2genname;pumpdummy1genname;...
            pumpdummy2genname;ventgenname;ventchargegenname};
        %Make sure order of gen rows here is same as names above!
        flexccsgenrows=vertcat(basegenrow,contsolvrow,pump1row,pump2row,...
            discharge1row,discharge2row,pumpdummy1row,pumpdummy2row,...
            ventrow,ventchargerow);
        
        %GET GENERATION OF ALL UNITS
        %For each row, find PLEXOS ID
        %Then open CSV
        %Then save data to cell array. 1 for generation, another for each
        %reserves. 
        %Column header = name. Rest of rows = data
        for genctr=1:size(flexccsgenrows,1)
            %Find PLEXOS ID
            currgenrow=flexccsgenrows(genctr);
            currplexosid=id2namegens{currgenrow,plexosidcol};
            currgenname=flexccsnames{genctr};
            
            %Open CSVs
            %Generation
            intervalgencsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Generation');
            intervalgencsvname=strcat(intervalgencsvnamebase,'.csv');
            [~,~,currintervalgeneration]=xlsread(fullfile(intervaldir,intervalgencsvname),intervalgencsvnamebase);
            
            %Raise reserve
            intervalraisereservecsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Raise Reserve');
            intervalraisereservecsvname=strcat(intervalraisereservecsvnamebase,'.csv');
            if length(intervalraisereservecsvnamebase)>31
                intervalraisereservecsvnamebase=intervalraisereservecsvnamebase(1:31);
            end
            [~,~,currintervalraisereserves]=xlsread(fullfile(intervaldir,intervalraisereservecsvname),intervalraisereservecsvnamebase);
           
            if strcmp(reserves,'miso')
                %Reg raise reserve
                intervalregraisereservecsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Regulation Raise Reserve');
                intervalregraisereservecsvname=strcat(intervalregraisereservecsvnamebase,'.csv');
                if length(intervalregraisereservecsvnamebase)>31
                    intervalregraisereservecsvnamebase=intervalregraisereservecsvnamebase(1:31);
                end
                [~,~,currintervalregraisereserves]=xlsread(fullfile(intervaldir,intervalregraisereservecsvname),intervalregraisereservecsvnamebase);
                
                %Replacement reserve
                intervalreplacereservecsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Replacement Reserve');
                intervalreplacereservecsvname=strcat(intervalreplacereservecsvnamebase,'.csv');
                if length(intervalreplacereservecsvnamebase)>31
                    intervalreplacereservecsvnamebase=intervalreplacereservecsvnamebase(1:31);
                end
                [~,~,currintervalreplacereserves]=xlsread(fullfile(intervaldir,intervalreplacereservecsvname),intervalreplacereservecsvnamebase);
                
                %Reg lower reserve
                intervalreglowerreservecsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Regulation Lower Reserve');
                intervalreglowerreservecsvname=strcat(intervalreglowerreservecsvnamebase,'.csv');
                if length(intervalreglowerreservecsvnamebase)>31
                    intervalreglowerreservecsvnamebase=intervalreglowerreservecsvnamebase(1:31);
                end
                [~,~,currintervalreglowerreserves]=xlsread(fullfile(intervaldir,intervalreglowerreservecsvname),intervalreglowerreservecsvnamebase);
            end
            
            %Get generation and reserve values - need to go across a row and get each hour,
            %then down.
            intervalgenvalues=cell2mat(currintervalgeneration(2:end,intervalcsvhour1col:end));
            intervalraisereservevalues=cell2mat(currintervalraisereserves(2:end,intervalcsvhour1col:end));
            if strcmp(reserves,'miso')
                intervalregraisereservevalues=cell2mat(currintervalregraisereserves(2:end,intervalcsvhour1col:end));
                intervalreglowerreservevalues=cell2mat(currintervalreglowerreserves(2:end,intervalcsvhour1col:end));
                intervalreplacereservevalues=cell2mat(currintervalreplacereserves(2:end,intervalcsvhour1col:end));
            end
            
            %Compile values
            genvals={currgenname};
            raisevals={currgenname};
            if strcmp(reserves,'miso')
                regraisevals={currgenname};
                replacevals={currgenname};
                reglowervals={currgenname};
            end
            for j=1:size(intervalgenvalues,1)
                genvals=vertcat(genvals,num2cell(intervalgenvalues(j,:))');
                raisevals=vertcat(raisevals,num2cell(intervalraisereservevalues(j,:))');
                if strcmp(reserves,'miso')
                    regraisevals=vertcat(regraisevals,num2cell(intervalregraisereservevalues(j,:))');
                    reglowervals=vertcat(reglowervals,num2cell(intervalreglowerreservevalues(j,:))');
                    replacevals=vertcat(replacevals,num2cell(intervalreplacereservevalues(j,:))');
                end
            end
            %Save values
            flexccsgen=horzcat(flexccsgen,genvals); clear genvals
            flexccsraise=horzcat(flexccsraise,raisevals); clear raisevals
            if strcmp(reserves,'miso')
                flexccsregraise=horzcat(flexccsregraise,regraisevals); clear regraisevals
                flexccsreglower=horzcat(flexccsreglower,reglowervals); clear reglowervals
                flexccsreplace=horzcat(flexccsreplace,replacevals); clear replacevals
            end
        end
    end
    
    %CREATE PLOTS OF DATA**************************************************
    %PLOT EACH GENERATOR COMPONENT SEPARATELY******************************
    %Find year/month/day/hour cols
    yearcol=find(strcmp(flexccsgen(1,:),'Year'));
    monthcol=find(strcmp(flexccsgen(1,:),'Month'));
    daycol=find(strcmp(flexccsgen(1,:),'Day'));
    
    %Get first col of data
    firstcolofgendata=find(strcmp(flexccsgen(1,:),'Hour'))+1;
    %Get first & last row of data
    firstrowofgendata=2; lastrowofgendata=size(flexccsgen,1);
    flexccsnames={basegenname;solvgenname;pump1genname;pump2genname;...
            dischargedummy1genname;dischargedummy2genname;pumpdummy1genname;...
            pumpdummy2genname;ventgenname;ventchargegenname};
    
%     %Plot generation of all units
%     gentoplot=cell2mat(flexccsgen(2:end,firstcolofgendata:end));
%     figure
%     plot(gentoplot,'LineWidth',3)
%     set(gca,'FontSize',20);
%     ylabel('Electricity Gen. (MWh)');
%     xlabel('Date')
%     set(gca,'XTick',[1 numhours]);
%     firstdate={strcat(num2str(flexccsgen{firstrowofgendata,monthcol}),'/',...
%         num2str(flexccsgen{firstrowofgendata,daycol}),'/',...
%         num2str(flexccsgen{firstrowofgendata,yearcol}))};
%     lastdate={strcat(num2str(flexccsgen{lastrowofgendata,monthcol}),'/',...
%         num2str(flexccsgen{lastrowofgendata,daycol}),'/',...
%         num2str(flexccsgen{lastrowofgendata,yearcol}))};
%     set(gca,'XTickLabel',[firstdate,lastdate]);
%     flexccsnamesforplot={'Base','Cont. Solvent','Pump 1','Pump 2','SS Discharge 1',...
%         'SS Discharge 2','Pump Dummy 1','Pump Dummy 2','Venting','Vent When Charge'};
%     legend(flexccsnamesforplot,'FontSize',20)
%     
%     %Plot generation of elec-gen'ing units
%     gentoplot=cell2mat(flexccsgen(2:end,firstcolofgendata:end));
%     figure
%     plot(gentoplot,'LineWidth',3)
%     set(gca,'FontSize',20);
%     ylabel('Electricity Gen. (MWh)');
%     xlabel('Date')
%     set(gca,'XTick',[1 numhours]);
%     firstdate={strcat(num2str(flexccsgen{firstrowofgendata,monthcol}),'/',...
%         num2str(flexccsgen{firstrowofgendata,daycol}),'/',...
%         num2str(flexccsgen{firstrowofgendata,yearcol}))};
%     lastdate={strcat(num2str(flexccsgen{lastrowofgendata,monthcol}),'/',...
%         num2str(flexccsgen{lastrowofgendata,daycol}),'/',...
%         num2str(flexccsgen{lastrowofgendata,yearcol}))};
%     set(gca,'XTickLabel',[firstdate,lastdate]);
%     legend(flexccsnames,'FontSize',16)
%     
%     %Plot reg raise of all units
%     regraisetoplot=cell2mat(flexccsregraise(2:end,firstcolofgendata:end));
%     figure
%     plot(regraisetoplot,'LineWidth',2)
%     set(gca,'FontSize',16);
%     ylabel('Reg. Raise (MW)');
%     xlabel('Date')
%     set(gca,'XTick',[1 numhours]);
%     firstdate={strcat(num2str(flexccsgen{firstrowofgendata,monthcol}),'/',...
%         num2str(flexccsgen{firstrowofgendata,daycol}),'/',...
%         num2str(flexccsgen{firstrowofgendata,yearcol}))};
%     lastdate={strcat(num2str(flexccsgen{lastrowofgendata,monthcol}),'/',...
%         num2str(flexccsgen{lastrowofgendata,daycol}),'/',...
%         num2str(flexccsgen{lastrowofgendata,yearcol}))};
%     set(gca,'XTickLabel',[firstdate,lastdate]);
%     legend(flexccsnames,'FontSize',16)
%     
%     %Plot raise of all units
%     raisetoplot=cell2mat(flexccsraise(2:end,firstcolofgendata:end));
%     figure
%     plot(raisetoplot,'LineWidth',2)
%     set(gca,'FontSize',16);
%     ylabel('Spin. Raise (MW)');
%     xlabel('Date')
%     set(gca,'XTick',[1 numhours]);
%     firstdate={strcat(num2str(flexccsgen{firstrowofgendata,monthcol}),'/',...
%         num2str(flexccsgen{firstrowofgendata,daycol}),'/',...
%         num2str(flexccsgen{firstrowofgendata,yearcol}))};
%     lastdate={strcat(num2str(flexccsgen{lastrowofgendata,monthcol}),'/',...
%         num2str(flexccsgen{lastrowofgendata,daycol}),'/',...
%         num2str(flexccsgen{lastrowofgendata,yearcol}))};
%     set(gca,'XTickLabel',[firstdate,lastdate]);
%     legend(flexccsnames,'FontSize',16)

    
    %PLOT A WEEK OF GENERATION, CHARGING AND RESERVES BY 55856-PC1********************************
    %Get columns of generator
    %Get gen names
    gennamebase='55856-PC1';
    gennamessdis1=strcat(gennamebase,'SSDischargeDummy1');
    gennamessdis2=strcat(gennamebase,'SSDischargeDummy2');
    gennamesspump1=strcat(gennamebase,'SSPumpDummy1');
    gennamesspump2=strcat(gennamebase,'SSPumpDummy2');
    %Base gen
    colbasegen=find(strcmp(flexccsgen(1,:),gennamebase));
    colbaseraise=find(strcmp(flexccsraise(1,:),gennamebase));
    %SS discharge 1
    colss1gen=find(strcmp(flexccsgen(1,:),gennamessdis1));
    colss1raise=find(strcmp(flexccsraise(1,:),gennamessdis1));
    %SS discharge 2
    colss2gen=find(strcmp(flexccsgen(1,:),gennamessdis2));
    colss2raise=find(strcmp(flexccsraise(1,:),gennamessdis2));
    %SS pump 1
    colsspump1gen=find(strcmp(flexccsgen(1,:),gennamesspump1));
    %SS pump 2
    colsspump2gen=find(strcmp(flexccsgen(1,:),gennamesspump2));
    %All units, MISO reserves
    if strcmp(reserves,'miso')
        colbaseregraise=find(strcmp(flexccsregraise(1,:),gennamebase));
        colbasereplace=find(strcmp(flexccsreplace(1,:),gennamebase));
        colss1regraise=find(strcmp(flexccsregraise(1,:),gennamessdis1));
        colss1replace=find(strcmp(flexccsreplace(1,:),gennamessdis1));
        colss2regraise=find(strcmp(flexccsregraise(1,:),gennamessdis2));   
        colss2replace=find(strcmp(flexccsreplace(1,:),gennamessdis2));
    end
    
    %Isolate data
    genbase=cell2mat(flexccsgen(2:end,colbasegen));
    raisebase=cell2mat(flexccsraise(2:end,colbaseraise));
    genss1=cell2mat(flexccsgen(2:end,colss1gen));
    raisess1=cell2mat(flexccsraise(2:end,colss1raise));
    genss2=cell2mat(flexccsgen(2:end,colss2gen));
    raisess2=cell2mat(flexccsraise(2:end,colss2raise));
    gensspump1=cell2mat(flexccsgen(2:end,colsspump1gen));
    gensspump2=cell2mat(flexccsgen(2:end,colsspump2gen));
    if strcmp(reserves,'miso')
        regraisebase=cell2mat(flexccsregraise(2:end,colbaseregraise));
        replacebase=cell2mat(flexccsreplace(2:end,colbasereplace));
        regraisess1=cell2mat(flexccsregraise(2:end,colss1regraise));
        replacess1=cell2mat(flexccsreplace(2:end,colss1replace));
        regraisess2=cell2mat(flexccsregraise(2:end,colss2regraise));
        replacess2=cell2mat(flexccsreplace(2:end,colss2replace));
    end
    
    %Combine SS data
    genss=genss1+genss2; raisess=raisess1+raisess2; 
    gensspump=gensspump1+gensspump2;
    if strcmp(reserves,'miso')
        regraisess=regraisess1+regraisess2; replacess=replacess1+replacess2;
    end
    
    %Combine all reserves from SS & base
    if strcmp(reserves,'miso')
        reservesallbase=raisebase+regraisebase+replacebase;
        reservesallss=raisess+regraisess+replacess;
    elseif strcmp(reserves,'nrel')
        reservesallbase=raisebase;
        reservesallss=raisess;
    end
    
    %Check if replace reserves are zero
    if strcmp(reserves,'miso')
        if max(replacebase)>1 || max(replacess)>1
            out='Replacement reserves provided by base or SS generator'
        end
    end
    
    %Pick two days in April - 26th & 27th 
    startinghour=116*24+1;
    ticklabels={'April 26','April 27', 'April 28'};
    numdaystoplot=2;
    numhourstoplot=numdaystoplot*24; 
    lasthour=startinghour+numhourstoplot;
    xvals=[startinghour:lasthour];
    %Some plotting info
    numticks=numdaystoplot+1;
    %Isolate data to plot
    gentoplotbase=genbase(startinghour:lasthour);
    gentoplotss=genss(startinghour:lasthour);
    gentoplotsspump=gensspump(startinghour:lasthour);
    reservetoplotbase=reservesallbase(startinghour:lasthour);
    reservetoplotss=reservesallss(startinghour:lasthour);    
       
    %Plot generation by base & SS discharge units
%     figure; plot(xvals,gentoplotbase,'k'); hold on; plot(xvals,gentoplotss,'--k')
%     xlim([startinghour lasthour])
%     set(gca,'fontsize',12); 
% %     lim=get(gca,'XLim'); 
%     set(gca,'XTick',linspace(startinghour,lasthour,numticks));
%     ax=gca; set(ax, 'XTickLabel',ticklabels); %set # x ticks
%     xlabel('Day of Year','fontsize',12); ylabel('Electricity Generation by Proxy Unit, Generator 55856-PC1 (MWh)','fontsize',12);
%     legend('Base','Solvent Storage');
    
    %Plot data - want 2 plots stacked vertically, top = gen by
    %charge/discharge/normal, bottom = all reserves combined by base/discharge
    figure; 
    subplot(2,1,1); hold on; plot(xvals,gentoplotbase,'k'); plot(xvals,gentoplotss,'--k')
    plot(xvals,gentoplotsspump,':k')
    xlim([startinghour lasthour])
    set(gca,'fontsize',12,'fontweight','bold'); 
    set(gca,'XTick',linspace(startinghour,lasthour,numticks));
    ax=gca; set(ax, 'XTickLabel',ticklabels); %set # x ticks
    xlabel('Day of Year','fontsize',12,'fontweight','bold'); 
    ylabeltemp={'Net Electricity Generated at Base or SS';...
        'Discharge Proxy Units or Energy Consumed at SS Charge';...
        'Proxy Unit of Generator 55856-PC1 (MWh)'};
    ylabel(ylabeltemp,'fontsize',12,'fontweight','bold');
    legend({'Base','SS Discharge','SS Charge'},'fontsize',12,'fontweight','bold');
    
    subplot(2,1,2); hold on; plot(xvals,reservetoplotbase,'k'); plot(xvals,reservetoplotss,'--k')
    xlim([startinghour lasthour])
    set(gca,'fontsize',12,'fontweight','bold'); 
    set(gca,'XTick',linspace(startinghour,lasthour,numticks));
    ax=gca; set(ax, 'XTickLabel',ticklabels); %set # x ticks
    ylabeltemp={'Total Reserves Provided by Proxy Units';...
        'of Generator 55856-PC1 (MWh)'};
    ylabel(ylabeltemp,'fontsize',12,'fontweight','bold');
    xlabel('Day of Year','fontsize',12,'fontweight','bold'); 
    legend({'Base','Solvent Storage'},'fontsize',12,'fontweight','bold');
    
   
    %PLOT 24-HOUR AGGREGATE GENERATION FROM SS DISCHARGE AND CHARGING FROM SS PUMP DUMMY***********
    %Get solvent storage discharge and pump cols
    ssdischargecols=[];
    sspumpcols=[];
    for i=1:size(flexccsgen,2)
        if strfind(flexccsgen{1,i},'SSDischarge')
            ssdischargecols=[ssdischargecols;i];
        elseif strfind(flexccsgen{1,i},'SSPumpDummy')
            sspumpcols=[sspumpcols;i];
        end
    end
    
    %Get generation values, throwing out first day
    firstdayhours=24;
    genallssdischargeunits=cell2mat(flexccsgen((2+firstdayhours):end,ssdischargecols));
    genallsspumpunits=cell2mat(flexccsgen((2+firstdayhours):end,sspumpcols));
    
    %Sum all values
    genallssdischargetotal=sum(genallssdischargeunits,2);
    genallsspumptotal=sum(genallsspumpunits,2);
    
    %Loop through, and save all 12-1am values in row 1, etc.
    genallssdischargehours1to24=zeros(24,1);
    genallsspumphours1to24=zeros(24,1);
    if size(genallssdischargetotal,1) ~= size(genallsspumptotal,1)
        warning='Pump and gen arrays not equal length'
    end
    for i=1:24:size(genallssdischargetotal,1)
        firsthour=i;
        lasthour=i+23;
        genallssdischargehours1to24=genallssdischargehours1to24+genallssdischargetotal(firsthour:lasthour);
        genallsspumphours1to24=genallsspumphours1to24+genallsspumptotal(firsthour:lasthour);
    end
    
    %Plot values: 24-hour discharge profile
    %Scale down values
    genallssunitscale=1E3; if (genallssunitscale==1E3) genallssunitscalelabel='GWh'; end;
    genallssdischargehours1to24scaled=genallssdischargehours1to24/genallssunitscale;
    genallsspumphours1to24scaled=genallsspumphours1to24/genallssunitscale;
    %Add zeros on either side of 24-hour profile so can plot with empt
    %yspace on each side
    genallssdischargehours1to24scaledwithzeros=[0;genallssdischargehours1to24scaled;0];
    genallsspumphours1to24scaledwithzeros=[0;genallsspumphours1to24scaled;0];
    barxvals=[0:size(genallssdischargehours1to24scaledwithzeros,1)-1]';
    
    %Plot
    figure; bar(barxvals,genallssdischargehours1to24scaledwithzeros); colormap gray
    xlim([0 size(genallssdischargehours1to24scaledwithzeros,1)]); set(gca,'fontsize',12,'fontweight','bold')
    set(gca,'XTick',linspace(0,size(genallssdischargehours1to24scaledwithzeros,1)-1,size(genallssdischargehours1to24scaledwithzeros,1))); %set tick mark at 1 itnerval
    set(gca,'XTickLabel',{'',linspace(1,24,24),''}); %set tick mark at 1 itnerval
    ylabel(['Electricity Generation when Discharging Stored Lean Solvent (',genallssunitscalelabel,')'],'fontsize',12,'fontweight','bold');
    xlabel('Hour of Day','fontsize',12,'fontweight','bold')
    
    %Plot values: 24-hour charge profile
    figure; bar(barxvals,genallsspumphours1to24scaledwithzeros); colormap gray
    xlim([0 size(genallssdischargehours1to24scaledwithzeros,1)]); set(gca,'fontsize',12,'fontweight','bold')
    set(gca,'XTick',linspace(0,size(genallssdischargehours1to24scaledwithzeros,1)-1,size(genallssdischargehours1to24scaledwithzeros,1))); %set tick mark at 1 itnerval
    set(gca,'XTickLabel',{'',linspace(1,24,24),''}); %set tick mark at 1 itnerval
    ylabel(['Energy Used in Charging Stored Lean Solvent (',genallssunitscalelabel,')'],'fontsize',12,'fontweight','bold');
    xlabel('Hour of Day','fontsize',12,'fontweight','bold')
    
    
    
    %PLOT 24-HOUR GENERATION FROM SS DISCHARGE AND CHARGING FROM SS PUMP FOR PARTICULAR UNIT***********
    %Get solvent storage discharge and pump cols
    unittoplot='55856-PC1';
    ssdischargecols=[];
    sspumpcols=[];
    for i=1:size(flexccsgen,2)
        if strfind(flexccsgen{1,i},'SSDischarge') & strfind(flexccsgen{1,i},unittoplot)
            ssdischargecols=[ssdischargecols;i];
        elseif strfind(flexccsgen{1,i},'SSPumpDummy') & strfind(flexccsgen{1,i},unittoplot)
            sspumpcols=[sspumpcols;i];
        end
    end
    
    %Get generation values, throwing out first day
    firstdayhours=24;
    genallssdischargeunits=cell2mat(flexccsgen((2+firstdayhours):end,ssdischargecols));
    genallsspumpunits=cell2mat(flexccsgen((2+firstdayhours):end,sspumpcols));
    
    %Sum all values
    genallssdischargetotal=sum(genallssdischargeunits,2);
    genallsspumptotal=sum(genallsspumpunits,2);
    
    %Loop through, and save all 12-1am values in row 1, etc.
    genallssdischargehours1to24=zeros(24,1);
    genallsspumphours1to24=zeros(24,1);
    if size(genallssdischargetotal,1) ~= size(genallsspumptotal,1)
        warning='Pump and gen arrays not equal length'
    end
    for i=1:24:size(genallssdischargetotal,1)
        firsthour=i;
        lasthour=i+23;
        genallssdischargehours1to24=genallssdischargehours1to24+genallssdischargetotal(firsthour:lasthour);
        genallsspumphours1to24=genallsspumphours1to24+genallsspumptotal(firsthour:lasthour);
    end
    
    %Plot values: 24-hour discharge profile
    %Scale down values
    genallssunitscale=1E3; if (genallssunitscale==1E3) genallssunitscalelabel='GWh'; end;
    genallssdischargehours1to24scaled=genallssdischargehours1to24/genallssunitscale;
    genallsspumphours1to24scaled=genallsspumphours1to24/genallssunitscale;
    %Add zeros on either side of 24-hour profile so can plot with empt
    %yspace on each side
    genallssdischargehours1to24scaledwithzeros=[0;genallssdischargehours1to24scaled;0];
    genallsspumphours1to24scaledwithzeros=[0;genallsspumphours1to24scaled;0];
    barxvals=[0:size(genallssdischargehours1to24scaledwithzeros,1)-1]';
    
    %Plot
    figure; bar(barxvals,genallssdischargehours1to24scaledwithzeros); colormap gray
    xlim([0 size(genallssdischargehours1to24scaledwithzeros,1)]); set(gca,'fontsize',12,'fontweight','bold')
    set(gca,'XTick',linspace(0,size(genallssdischargehours1to24scaledwithzeros,1)-1,size(genallssdischargehours1to24scaledwithzeros,1))); %set tick mark at 1 itnerval
    set(gca,'XTickLabel',{'',linspace(1,24,24),''}); %set tick mark at 1 itnerval
    ylabel(['Electricity Generation when Discharging Stored Lean Solvent (',genallssunitscalelabel,')'],'fontsize',12,'fontweight','bold');
    xlabel('Hour of Day','fontsize',12,'fontweight','bold')
    
    %Plot values: 24-hour charge profile
    figure; bar(barxvals,genallsspumphours1to24scaledwithzeros); colormap gray
    xlim([0 size(genallssdischargehours1to24scaledwithzeros,1)]); set(gca,'fontsize',12,'fontweight','bold')
    set(gca,'XTick',linspace(0,size(genallssdischargehours1to24scaledwithzeros,1)-1,size(genallssdischargehours1to24scaledwithzeros,1))); %set tick mark at 1 itnerval
    set(gca,'XTickLabel',{'',linspace(1,24,24),''}); %set tick mark at 1 itnerval
    ylabel(['Energy Used in Charging Stored Lean Solvent (',genallssunitscalelabel,')'],'fontsize',12,'fontweight','bold');
    xlabel('Hour of Day','fontsize',12,'fontweight','bold')
end

















