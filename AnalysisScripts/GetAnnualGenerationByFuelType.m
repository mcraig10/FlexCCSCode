%Michael Craig
%November 4, 2015
%Function obtains interval generation and reserves data for each flexible
%and normal CCS unit, as well as aggregate values for all units, for a
%given scenario.

function [annualgenerationbyfueltype]  = ...
    GetAnnualGenerationByFuelType(server,scenarioname,basedirforflatfiles)

%% PLEXOS OUTPUT FILE NAMES
%Set folder name w/ model output
plexosoutputfolder=scenarioname;

%Set PLEXOS dir
plexosoutputdir=fullfile(basedirforflatfiles,plexosoutputfolder);

%Get fiscal year dir
fiscalyeardir=fullfile(plexosoutputdir,'fiscal year');

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

%% GET ANNUAL GENERATION BY FUEL TYPE
%For each fuel type, look up generators of that fuel type, get annual
%genreation, and add
annualgenerationbyfueltype={'FuelType','Generation(MWh)';'Coal',0;
    'NaturalGas',0;'Oil',0;'Nuclear',0;'Fwaste',0;'LF Gas',0;
    'MSW',0;'Biomass',0;'Non-Fossil',0;'Wind',0;'Solar',0};

%Import id2name file
[~,~,id2name]=xlsread(fullfile(plexosoutputdir,'id2name.csv'),'id2name');
classcol=find(strcmp(id2name(1,:),'class'));
plexosidcol=find(strcmp(id2name(1,:),'id'));
unitnamecol=find(strcmp(id2name(1,:),'name'));

%Get generators in id2name file
genrows=find(strcmp(id2name(:,classcol),'Generator'));
%For each generator, open CSV, get reserves, also get offer price, then
%multiply.
for genctr=1:size(genrows,1)
    %GET GENERATION OF GENERATOR
    currrow=genrows(genctr);
    currplexosid=id2name{currrow,plexosidcol};
    currunitid=id2name{currrow,unitnamecol};

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
       
    genfilename=strcat('ST Generator(',num2str(currplexosid),').Generation');
    filecsv=strcat(genfilename,'.csv');
    gentemp=csvread(fullfile(fiscalyeardir,filecsv),1,3);
    gentempscaled=gentemp*1000;
    
    %GET FUEL TYPE OF GENERATOR
    dashposition=findstr(currunitid,'-');
    currorisid=currunitid(1:dashposition(1)-1);
    currgenid=currunitid(dashposition(1)+1:end);
    if isempty(currgenid)
        fleetrow=find(strcmp(futurepowerfleetforplexos(:,fleetorisidcol),currorisid));
    else
        fleetrow=find(strcmp(futurepowerfleetforplexos(:,fleetorisidcol),currorisid) & ...
            strcmp(futurepowerfleetforplexos(:,fleetunitidcol),currgenid));
    end
%     {genctr,currunitid,currorisid,currgenid,fleetrow}    
    currfueltype=futurepowerfleetforplexos{fleetrow,fleetfueltypecol};
    
    %ADD TO TOTAL
    totalrow=find(strcmp(annualgenerationbyfueltype(:,1),currfueltype));
    annualgenerationbyfueltype{totalrow,2}=annualgenerationbyfueltype{totalrow,2}+...
        gentempscaled;
end






