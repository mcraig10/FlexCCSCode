%Michael Craig
%November 4, 2015
%Function obtains interval generation and reserves data for each flexible
%and normal CCS unit, as well as aggregate values for all units, for a
%given scenario.

function [windcurtailment, solarcurtailment, windcurtailed, solarcurtailed]  = ...
    AnalyzeWindAndSolarCurtailment(server,scenarioname,basedirforflatfiles)

%% KEY PARAMETERS
%Indicate whether running on server ( 1 = yes)
% server=0;

%Scenario name
% scenarioname='CPPEEPt5FlxCCS0MW2000WndMW0Rmp1Grp1MSL0NLDC0Vnt1';

%% PLEXOS OUTPUT FILE NAMES
%Give base directory for PLEXOS output
% if server==0
% %     basedirforflatfiles='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output';
%     basedirforflatfiles='C:\Users\mcraig10\Desktop\FakeOutputForMATLABTests';
% elseif server==1
%     basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output';
% end

%Set folder name w/ model output
plexosoutputfolder=scenarioname;

%Set PLEXOS dir
plexosoutputdir=fullfile(basedirforflatfiles,plexosoutputfolder);

%% MATLAB FLEET FILE NAMES
%Give directory and name of MATLAB fleet files
if server==0
    dirformatlabfleet='C:\Users\mcraig10\Desktop\EPP Research\Matlab\Fleets';
elseif server==1
    dirformatlabfleet='C:\Users\mtcraig\Desktop\EPP Research\Matlab\Fleets';
end

%Set fleet file name
matlabfleetname=strcat(scenarioname,'.mat');

%Load futurepowerfleetforplexos
load(fullfile(dirformatlabfleet,matlabfleetname),'futurepowerfleetforplexos');

%% RATING FACTOR FILE NAMES
if server==0
    dirratingfactors='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles';
elseif server==1
    dirratingfactors='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles';
end

%Get labels from scenario name
[flexccsval,ccsmwval,windmwval]=GetLabelsFromFileName(scenarioname);

%WIND AND SOLAR RATING FACTORS FILE NAMES
windrffile=strcat('WindGenProfilesMassFlexCCS',num2str(flexccsval),...
    'CCS',num2str(ccsmwval),'Wind',num2str(windmwval),'GrpRE1.csv');
solarrffile=strcat('SolarGenProfilesMassFlexCCS',num2str(flexccsval),...
    'CCS',num2str(ccsmwval),'Wind',num2str(windmwval),'GrpRE1.csv');

%% GET FLEET COLUMNS
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

%% GET WIND AND SOLAR GENERATOR
windrow=find(strcmp(futurepowerfleetforplexos(:,fleetfueltypecol),'Wind'));
solarrow=find(strcmp(futurepowerfleetforplexos(:,fleetfueltypecol),'Solar'));

windoris=futurepowerfleetforplexos{windrow,fleetorisidcol};
solaroris=futurepowerfleetforplexos{solarrow,fleetorisidcol};

windcapac=futurepowerfleetforplexos{windrow,fleetcapacitycol};
solarcapac=futurepowerfleetforplexos{solarrow,fleetcapacitycol};

windgenname=strcat(windoris,'-');
solargenname=strcat(solaroris,'-');

%% GET WIND AND SOLAR RATING FACTORS
[~,~,windrfsdata]=xlsread(fullfile(dirratingfactors,windrffile),windrffile(1:31));
[~,~,solarrfsdata]=xlsread(fullfile(dirratingfactors,solarrffile),solarrffile(1:31));

%% GET MAX POSSIBLE WIND AND SOLAR GENERATION
%Wind
windrfs=cell2mat(windrfsdata(2:end,2));
hourlymaxgenwind=windcapac*windrfs/100;
maxwindgen=sum(hourlymaxgenwind);

%Solar
solarrfs=cell2mat(solarrfsdata(2:end,2));
hourlymaxgensolar=solarcapac*solarrfs/100;
maxsolargen=sum(hourlymaxgensolar);

%% NOW GET PLEXOS OUTPUT FOR ANNUAL GENERATION BY WIND AND SOLAR UNITS

%% IMPORT ID2NAME FILE AND GET PLEXOS ID OF WIND AND SOLAR
%Import file
[~,~,id2name]=xlsread(fullfile(plexosoutputdir,'id2name.csv'),'id2name');

%Get column #s of id2name. id col has id #; name col has GEN-ORIS ID. 
classcol=find(strcmp(id2name(1,:),'class'));
plexosidcol=find(strcmp(id2name(1,:),'id'));
unitnamecol=find(strcmp(id2name(1,:),'name'));

%Get PLEXOS IDs
windplexosidrow=find(strcmp(id2name(:,unitnamecol),windgenname));
solarplexosidrow=find(strcmp(id2name(:,unitnamecol),solargenname));
windplexosid=id2name{windplexosidrow,plexosidcol};
solarplexosid=id2name{solarplexosidrow,plexosidcol};

%% OPEN FISCAL YEAR GENERATION VALUES FOR BOTH GENERATORS AND EXTRACT DATA
fiscalyeardir=fullfile(plexosoutputdir,'fiscal year');

%Wind
windgenfile=strcat('ST Generator(',num2str(windplexosid),').Generation');
windgendata=ExtractDataPLEXOSAnnual(fiscalyeardir,windgenfile);
windgen=windgendata{2,4}*1000; %scale up from GWh to MWh

%Solar
solargenfile=strcat('ST Generator(',num2str(solarplexosid),').Generation');
solargendata=ExtractDataPLEXOSAnnual(fiscalyeardir,solargenfile);
solargen=solargendata{2,4}*1000; %scale up from GWh to MWh

%% GET CURTAILMENT AND CURTAILED GENERATION
% MWh
windcurtailed=maxwindgen-windgen; 
solarcurtailed=maxsolargen-solargen; 

% Percent
windcurtailment=windcurtailed/maxwindgen*100;
solarcurtailment=solarcurtailed/maxsolargen*100;








