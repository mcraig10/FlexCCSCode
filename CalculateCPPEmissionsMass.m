%Michael Craig, 15 June 2015
%This script calculates the mass of CO2 emissions from affected EGUs as
%defined in the final CPP
%INPUTS: futurepowerfleet (generator info).
%OUTPUTS: emissionscppaffectedegu [kg]

function [emissionsmasscppaffectedegu] = CalculateCPPEmissionsMass(futurepowerfleet)

%% GENERAL APPROACH
%Calculate emissions mass of affected EGUs per final CPP. Affected EGUs
%emissions only count towards mass limit (final rule, page 882, 892). 
%Affected EGUs defined as:
%Coal, O/G Steam and NGCC plants >25 MW (final rule pg. 273). NOT NGCTs. 

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
    GetColumnNumbersFromCPPParsedFile(futurepowerfleet);
totalannualgencol=find(strcmp(futurepowerfleet(1,:),'TotalAnnualGen(MWh)'));


%% CALCULATE EMISSIONS MASS
%Affected EGUs already marked by fleetaffectedegucol. First isolate those
%generators
futurepowerfleet{1,fleetaffectedegucol}=5; %just set to some non-1 value
affectedegus=futurepowerfleet(cell2mat(futurepowerfleet(:,fleetaffectedegucol))==1,:);

%GET AFFECTED EGU GENERATION
affectedegugen=cell2mat(affectedegus(:,totalannualgencol));

%GET AFFECTED EGU EMISSIONS [kg/MWh * MWh]
affectedegusco2emrates=cell2mat(affectedegus(:,fleetco2emsrateforedcol));
emissionsmasscppaffectedegu=sum(affectedegusco2emrates.*affectedegugen);



