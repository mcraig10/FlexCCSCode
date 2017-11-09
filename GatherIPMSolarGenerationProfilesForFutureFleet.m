%Michael Craig, 27 May 2015
%This script takes in a power fleet, isolates the solar generation
%facilities, and creates hourly solar generation profiles for each
%facility. Hourly generation data is obtained from the EPA's IPM. Current
%data used is for v.5.13, see http://www.epa.gov/airmarkets/programs/ipm/psmodel.html
%As of 5/27/15, assuming that all solar plants are solar PV.

function [csvfilenamewithsolargenprofiles,futurepowerfleetforplexos]=...
    GatherIPMSolarGenerationProfilesForFutureFleet(...
    futurepowerfleetforplexos,compliancescenario, pc)

%% GET COLUMN NUMBERS OF DATA IN futurepowerplantfleet
[parseddataorisidcol,parseddataunitidcol,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);

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

%% IMPORT HOURLY SOLAR GENERATION DATA
if strcmp(pc,'work')
    solargenfilename='C:\Users\mtcraig\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\table4_28.xlsx';
elseif strcmp(pc,'personal')
    solargenfilename='C:\Users\mcraig10\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\table4_28.xlsx';
end
[~,~,solargendata]=xlsread(solargenfilename,'Solar Photovoltaic');

%Eliminate empty rows at top by finding data headers
headersrow=find(strcmp(solargendata(:,1),'Region Name'));
solargendata(1:(headersrow-1),:)=[];

%Get column numbers of data in solar generation data
solargenregioncol=find(strcmp(solargendata(1,:),'Region Name'));
solargenstatecol=find(strcmp(solargendata(1,:),'State Name'));
solargenclasscol=find(strcmp(solargendata(1,:),'Solar Class'));
solargenhour1col=find(strcmp(solargendata(1,:),'Hour01'));
solargenhour24col=find(strcmp(solargendata(1,:),'Hour24'));
solargenseasoncol=find(strcmp(solargendata(1,:),'Season'));

%% GET SOLAR GENERATION PROFILES
%For each solar plant:
%1) Isolate relevant rows of data based on IPM region and state (note that
%region is largely irrelevant here - states that are included in many
%regions have very very similar capacity factors between regions).
%2) Throw out all but 1 class (since all the same for solar PV).
%3) Calculate capacity factor by dividing given generation data [kWh] by 1
%MW.
%4) Rating factor to PLEXOS is input as %; so convert capacity factor to %.
%5) Add rating factor for generator to cell array
%6) Save cell array with hourly solar generation for each plant
solarratingfactors={'DateTime'};
%Need to add date strings to solarratingfactors array. Do so by importing
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
%Loop over solar plants
for i=2:size(solarpowerplants,1)
    %Step 1: isolate rows
    %Get state & region of power plant
    currstate=solarpowerplants{i,parseddatastatecol};
    currregion=solarpowerplants{i,parseddataregioncol};
    %Power plant state is given as full name, but in solar gen is
    %abbreviated, so use function to convert.
    currstateabbrev=ConvertStateNameToAbbrev(currstate);
    %Get rows of data for that state & region
    solargenrows=find(strcmp(solargendata(:,solargenregioncol),currregion) & ...
        strcmp(solargendata(:,solargenstatecol),currstateabbrev));
    
    %Step 2: through out all but 1 class
    %Just take top 2 rows, which are for the highest class of solar
    %resource (all classes have same resources anyways)
    solargenrows=solargenrows(1:2);
    solargendataforplant=solargendata(solargenrows,:);
    
    %Step 3 + 4: calculate capacity factor, convert to rating factor (%)
    %Hourly generation values are in kWh for a 1 MW plant; so just divide
    %value by 1000 to get capacity factor
    %Convert cell array to mat.
    summerrow=find(strcmp(solargendataforplant(:,solargenseasoncol),'Summer'));
    winterrow=find(strcmp(solargendataforplant(:,solargenseasoncol),'Winter'));
    solargensummer=cell2mat(solargendataforplant(summerrow,solargenhour1col:solargenhour24col));
    solargenwinter=cell2mat(solargendataforplant(winterrow,solargenhour1col:solargenhour24col));
    %Now divide generation by 1000, then convert to rating factor by
    %multiplying by 100
    solargensummer=solargensummer/1000*100;
    solargenwinter=solargenwinter/1000*100;
    %Expand capacity factors for each hour in each season. DL, in EJ paper,
    %uses summer for May - September. Use that here, with winter making up
    %remainder.
    daysinjanthruapr=31+28+31+30;
    daysinmaythrusept=31+30+31+31+30;
    daysinoctthrudec=30+31+31;
    solargenyear=repmat(solargenwinter,1,daysinjanthruapr);
    solargenyear=[solargenyear,repmat(solargensummer,1,daysinmaythrusept)];
    solargenyear=[solargenyear,repmat(solargenwinter,1,daysinoctthrudec)];
    solargenyear=solargenyear'; %flip
    
    %Step 5: add rating factor to array
    %Convert rating factors to cell, add ORIS ID to top, then append to
    %array.
    currplantorisid=solarpowerplants{i,parseddataorisidcol};
    currplantorisid=strcat(currplantorisid,'-'); %Generator name must be as in PLEXOS: 'ORISID-'
    solargenyeartosave=vertcat(currplantorisid,num2cell(solargenyear));
    %Combine values
    solarratingfactors=horzcat(solarratingfactors,solargenyeartosave);
    clear solargenyear solargenyeartosave;    
end

%% SAVE FILE WITH SOLAR GENERATION PROFILES
if strcmp(pc,'work')
    directorytowritedemand='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles\';
elseif strcmp(pc,'personal')
    directorytowritedemand='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles\';
end
filenametowritedemand=strcat('SolarGenerationProfilesIPM',compliancescenario,'.csv');
fullfilenametosave=strcat(directorytowritedemand,filenametowritedemand);
cell2csv(fullfilenametosave,solarratingfactors);

%% OUTPUT DATA FILE NAME AND GENERATOR IDS FOR PROPERTIES
%Make CSV file name in PLEXOS file: DataFiles\...
csvfilenamewithsolargenprofiles=strcat('DataFiles\',filenametowritedemand);
generatoridsinsolarfile=solarratingfactors(1,2:end);






