%Michael Craig, Jan 23 2016
%FUNCTION: Calculates hourly spinning requirements using the NREL formula
%of 3% of daily max load + 5% of hourly wind generation. 

function [reservefileobjname, reservefilenameforplexos] = CalculateHourlyNRELReserveRequirement...
    (futurepowerfleetfull, windcapacityfactors, pc, mwwindtoadd, demandfilenames)

%% GET COLUMN NUMBERS
[fleetorisidcol,fleetunitidcol,fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol,fleetregioncol,fleetstatecol,fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol, fleetpumpunitscol, fleetpumpeffcol, fleetpumploadcol,...
    fleetccsretrofitcol,fleettruesscapacitycol,fleetaffectedegucol,fleethrpenaltycol,...
    fleetcapacpenaltycol,fleetsshrpenaltycol,fleetsscapacpenaltycol,fleeteextraperestorecol,...
    fleeteregenpereco2capcol,fleetegridpereco2capandregencol,fleetegriddischargeperestorecol,...
    fleetnoxpricecol,fleetso2pricecol,fleetso2groupcol,fleetco2emsrateforedcol,...
    fleetso2emsrateforedcol,fleetnoxemsrateforedcol,fleethrforedcol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetfull);

%% CREATE FUNCTION FOR CREATING PLEXOS GENERATOR OBJECT NAME
%Name generators in PLEXOS as: ORISID-UNITID
createplexosobjname = @(arraywithdata,orisidcol,unitidcol,rowofinfo) strcat(arraywithdata{rowofinfo,orisidcol},...
        '-',arraywithdata{rowofinfo,unitidcol});

%% SET NREL REQUIREMENT VALUES
percentofhourlywindgeneration=5;
percentofmaxdailyload=3;

%% CALCULATE 5% HOURLY WIND GENERATION
%First get wind units in fleet
windunits=find(strcmp(futurepowerfleetfull(:,fleetfueltypecol),'Wind'));
windhourlygentemp=zeros(size(windcapacityfactors,1)-1,1); %remove 1 for header
%Now for each wind unit, get CF, multiply by wind capacity, and add
%to hourly gen
for windrows=1:size(windunits,1)
    currwindrow=windunits(windrows);
    %Wind unit capacity
    windunitcapacity=futurepowerfleetfull{currwindrow,fleetcapacitycol};
    %Wind PLEXOS name
    windunitplexosname=createplexosobjname(futurepowerfleetfull,fleetorisidcol,fleetunitidcol,currwindrow);
    %Wind CFs col
    windunitcfscol=find(strcmp(windcapacityfactors(1,:),windunitplexosname));
    %Isolate wind CFs
    windunitcfs=cell2mat(windcapacityfactors(2:end,windunitcfscol));
    %Total hourly gen
    windunithourlygen=windunitcapacity*windunitcfs/100;
    %Add values
    windhourlygentemp=windhourlygentemp+windunithourlygen;
end
clear windunithourlygen

%Take 5% of hourly wind generation
reservesforhourlywindgen=windhourlygentemp*percentofhourlywindgeneration/100;

%% GET 3% MAX DAILY LOAD
%Import demand file
%Demand file directory
if strcmp(pc,'work')
    demanddir='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles';
elseif strcmp(pc,'personal')
    demanddir='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles';
end
%Demand file name - has DataFiles\ at front and .csv at end
%Get original file name and remove DataFiles\
demandfilenameoriginal=demandfilenames{1};
letterstoremove=length('DataFiles\');
demandfilename=demandfilenameoriginal(letterstoremove+1:end);
%Now do manipulations to get sheet name. First remove .csv
sheetname=demandfilename(1:end-4);
%See if has NLDC in name - if so, need to shorten sheet name by 1 letter
if findstr(demandfilename,'NLDC')
    sheetname=sheetname(1:end-1);
end
[~,~,alldemand]=xlsread(fullfile(demanddir,demandfilename),sheetname);

%Get hourly demand
hourlydemand=cell2mat(alldemand(2:end,4:end));

%Get max demand in each day
dailymaxdemand=max(hourlydemand,[],2);

%Convert max demand in each day to hourly max demand
dailymaxdemandeachhour=[];
for i=1:size(dailymaxdemand,1)
    currdailymaxdemand=dailymaxdemand(i);
    dailymaxdemandeachhour=[dailymaxdemandeachhour;repmat(currdailymaxdemand,24,1)];
end

%Take 3% of max daily load
reservesformaxdailyload=dailymaxdemandeachhour*percentofmaxdailyload/100;

%% ADD 3% MAX DAILY LOAD + 5% HOURLY WIND
hourlynrelreserves=reservesformaxdailyload+reservesforhourlywindgen;

%% FORMAT ARRAY W/ HOURLY RESERVES
%FORMAT LIKE DEMAND
if strcmp(pc,'work')
    plexosdemandformatfile='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\LoadDataForPLEXOSTemplate.xlsx';
elseif strcmp(pc,'personal')
    plexosdemandformatfile='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\LoadDataForPLEXOSTemplate.xlsx';
end
[~,~,plexosreservesformat]=xlsread(plexosdemandformatfile,'LoadDataForPLEXOSTemplate');
%Remove leap year day
monthcol=find(strcmp(plexosreservesformat(1,:),'Month'));
daycol=find(strcmp(plexosreservesformat(1,:),'Day'));
yearcol=find(strcmp(plexosreservesformat(1,:),'Year'));
for i=1:size(plexosreservesformat,1)
    if plexosreservesformat{i,monthcol}==2
        if plexosreservesformat{i,daycol}==29
            leapyearrowtoremove=i;
        end
    end
end
plexosreservesformat(leapyearrowtoremove,:)=[];
clear leapyearrowtoremove;

%First hour column is column 4
hour1col=4;
day1col=2; %first col is headers

%Change years to 2030
for i=2:size(plexosreservesformat,1)
    plexosreservesformat{i,yearcol}=2030;
end

%Fill in values
%Replace demand values
reservesctr=1;
for i=day1col:size(plexosreservesformat,1)
    for j=hour1col:size(plexosreservesformat,2)
        plexosreservesformat{i,j}=hourlynrelreserves(reservesctr,1);
        reservesctr=reservesctr+1;
    end
end

%FORMAT LIKE HOURLY WIND RATING FACTORS
% %Now create file w/ that data - use same format as
% %windcapacityfactors file, so copy over first column, except need
% %to shift date values down by 1 and insert in first row '1/1/2030
% %0:00'. For some reason, 0:00 is first hour for reserves, but 1:00
% %is first hour for wind. (Checked extensively on 1/20/16).
% nrelspinreqfilehours=windcapacityfactors(:,1);
% %Shift
% nrelspinreqfilehours(3:end)=nrelspinreqfilehours(2:end-1);
% nrelspinreqfilehours{2}=' 1/ 1/2030  0:00';
% %Add reserve requirement values
% nrelspinrequirementcell=num2cell(nrelspinrequirement);
% nrelspinrequirementcell=vertcat(nameofreserveobj,nrelspinrequirementcell);
% plexosreservesformat=horzcat(nrelspinreqfilehours,nrelspinrequirementcell); clear nrelspinreqfilehours nrelspinrequirementcell

%% SAVE FILE
if strcmp(pc,'work')
    directorytowritedemand='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles\';
elseif strcmp(pc,'personal')
    directorytowritedemand='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles\';
end
reservefileobjname=strcat('NRELHourlySpinReserveReq',num2str(mwwindtoadd),'File');
reservefilename=strcat(reservefileobjname,'.csv');
reservefilenameforplexos=strcat('DataFiles\',reservefilename);
fullfilenametosave=strcat(directorytowritedemand,reservefilename);
cell2csv(fullfilenametosave,plexosreservesformat);
