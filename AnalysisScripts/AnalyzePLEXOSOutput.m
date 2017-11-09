%Michael Craig, 15 June 2015
%This script analyzes copied-and-pasted output from PLEXOS. 
%June 15, 2015: calculates fleet-wide emissions rate and mass pursuant to
%CPP calculations.
%June 17: also added ability to create stacked area chart of daily
%generation

%% PARAMETERS
%CPP compliance option
cppcomplianceoption=1;

%Demand scenario
demandscenariosforanalysis=1;

%Directory of Flat Files - change folder name
foldernamewithflatfiles='CPPEESclPt5FlxCCS1MW0WndMW0Rmp1Grp1LA';
basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output';
dirofflatfiles=fullfile(basedirforflatfiles,foldernamewithflatfiles);

%Directory w/ fleet info
dirwithfleetinfo='C:\Users\mtcraig\Desktop\EPP Research\Matlab\Fleets';

%Horizon of PLEXOS run - used when pulling out interval and daily data
horizonstartmonth=1; 
horizonstartday=1;
horizonendmonth=12;
horizonendday=31;

%% CALCULATE FLEET-WIDE EMISSIONS RATE
%% IMPORT INPUT DATA TO PLEXOS FROM FLEET .MAT OUTPUT BY CREATEPLEXOSIMPORTFILE SCRIPT
filewithfleetinfo=strcat('CPPEESclPt5FlxCCS1MW0WndMW0Rmp1Grp1.mat');
load(fullfile(dirwithfleetinfo,filewithfleetinfo));


%% GET COLUMN NUMBERS OF FLEET DATA
[fleetorisidcol,fleetunitidcol,fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol,fleetregioncol,fleetstatecol,fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol]=...
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

% %% CALL EMISSIONS RATE CALCULATION FUNCTION TO GET FLEET-WIDE CPP EMISSIONS RATE
% %Set econdispatchorplexos to 1 for PLEXOS output
% econdispatchorplexos=1;
% %Set windandsolargeneration to zero; no input since have wind and solar
% %generators in fleet array
% windandsolargeneration=0; 
% %Call function
% [cppemissionsrate, cppemissionsmass] = CalculateCPPEmissionsRateAndMass(econdispatchorplexos, ...
%     windandsolargeneration, demandscenariosforanalysis, futurepowerfleetforplexos);



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




%% INTERVAL DATA***********************************************************
%**************************************************************************
%**************************************************************************

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
    intervalregraisereservecsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Regulation Raise Reserve');
    intervalregraisereservecsvname=strcat(intervalregraisereservecsvnamebase,'.csv');
    if length(intervalregraisereservecsvnamebase)>31
        intervalregraisereservecsvnamebase=intervalregraisereservecsvnamebase(1:31);
    end
    [~,~,currintervalregraisereserves]=xlsread(fullfile(intervaldir,intervalregraisereservecsvname),intervalregraisereservecsvnamebase(1:31)); %truncate b/c only 31 chars allowed in worksheet names
    %Get generation and reserve values - need to go across a row and get each hour,
    %then down. 
    intervalgenvalues=cell2mat(currintervalgeneration(2:end,intervalcsvhour1col:end));
    intervalraisereservevalues=cell2mat(currintervalraisereserves(2:end,intervalcsvhour1col:end));
    intervalregraisereservevalues=cell2mat(currintervalregraisereserves(2:end,intervalcsvhour1col:end));
    intervalgenplusreservesvalueshorizontal=zeros(1,size(intervalgenvalues,1)*size(intervalgenvalues,2));
    for j=1:size(intervalgenvalues,1) %gen and reserves have same format so do all at once
        intervalgenplusreservesvalueshorizontal(1,((j-1)*24+1):(j*24))=intervalgenvalues(j,:)+...
            intervalraisereservevalues(j,:)+intervalregraisereservevalues(j,:);        
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

%% RANDOM OLD CHECKS

%% ISOLATE HYDRO GENERATION FOR CHECKING IF CAPACITY FACTORS WORKED
% hydrogenrow=find(strcmp(genbyfueltype(:,1),'Hydro'));
% hydrogen=genbyfueltype(hydrogenrow,:);

%% TEST IF ANY FUTUREPOWERFLEET ORIS-GENIDS HAVE '/' 
% includesbackslash=zeros(size(futurepowerfleetforplexos,1),1);
% for i=1:size(futurepowerfleetforplexos,1)
%     if findstr(futurepowerfleetforplexos{i,orisgenidcol},'/')
%         includesbackslash(i)=1;
%     end
% end
% %No ORIS-GENIDs have a backslash in them in futurepowerfleet.

%% FIND PLEXOS OUTPUT WITH A /
% includesbackslash=zeros(size(plexosoutput,1),1);
% for i=1:size(plexosoutput,1)
%     if findstr(plexosoutput{i,genidcol},'/')
%         includesbackslash(i)=1;
%     end
% end
% %Only output w/ a '/' are the generators whose names were converted to
% dates in outputting from PLEXOS and copying into Excel.





















