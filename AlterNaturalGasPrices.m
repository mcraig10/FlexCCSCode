%Michael Craig
%November 19, 2015
%This function takes in a fleet, atlers the NG prices in order to model a
%high or low NG price scenario, and then outputs that fleet.

function [futurepowerfleetforplexos] = AlterNaturalGasPrices(futurepowerfleetforplexos,ngpricescalar)

%% GET COLUMNS
[fleetorisidcol,fleetunitidcol,fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol,fleetregioncol,fleetstatecol,fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);

%% ISOLATE NATURAL GAS UNITS
ngrows=find(strcmp(futurepowerfleetforplexos(2:end,fleetfueltypecol),'NaturalGas'));

%% GET ALL FUEL PRICES
allfuelprices=cell2mat(futurepowerfleetforplexos(2:end,fleetfuelpricecol));

%% MODIFY FUEL PRICES
%Modify NG prices
ngfuelprices=allfuelprices(ngrows);
newngfuelprices=ngfuelprices*ngpricescalar;

%Replace NG prices in all fuel prices
newallfuelprices=allfuelprices;
newallfuelprices(ngrows)=newngfuelprices;

%Now put back in fleet cell
futurepowerfleetforplexos(2:end,fleetfuelpricecol)=num2cell(newallfuelprices);
