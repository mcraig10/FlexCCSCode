%Michael Craig
%23 Oct 2015
%This script adds NOx & SO2 price columsn to the fleet, based on values
%provided in CSAPR. Only applies these prices to affected units under
%CSAPR.

%CSAPR applicability: any stationary, FF-fired boiler or CT serving on or
%after 2005 & w/ nameplate capacity > 25 MW. FF = oil, coal, gas.

%Citations to applicability:
% pg 48385: NOx annual program: any stationary, FF-fired boiler or CT serving at any time on or after 2005 & w/ capacity >25MW
% 	CT defined as simple or combined cycle (48381)
% 	Fossil fuel = fossil fuel = NG, oil, coal (48383)
% pg 48438: SO2 group1  program: same definition as above
% page 48463: SO2 group 2 program: same definition as above

%INPUTS: Fleet, noxandso2prices (has values in $/kg)
function [futurepowerfleetforplexos] = AssignNOxAndSO2Prices(futurepowerfleetforplexos,noxandso2prices)

%% GET PRICES
noxpricerow=find(strcmp(noxandso2prices(:,1),'NOxCSAPR'));
noxprice=noxandso2prices{noxpricerow,2};
so21pricerow=find(strcmp(noxandso2prices(:,1),'SO2CSAPR1'));
so21price=noxandso2prices{so21pricerow,2};
so22pricerow=find(strcmp(noxandso2prices(:,1),'SO2CSAPR2'));
so22price=noxandso2prices{so22pricerow,2};

%% DEFINE PRICES BY STATE
%Values in $/kg
so2pricesandgroups={'North Dakota',0,0; 'South Dakota',0,0; 'Minnesota',so22price,2;'Iowa',so21price,1;'Missouri',so21price,1;...
    'Michigan',so21price,1;'Illinois',so21price,1;'Indiana',so21price,1;'Wisconsin',so21price,1}; %$/ton
noxprices={'North Dakota',0; 'South Dakota',0; 'Minnesota',noxprice;'Iowa',noxprice;'Missouri',noxprice;...
    'Michigan',noxprice;'Illinois',noxprice;'Indiana',noxprice;'Wisconsin',noxprice}; %$/ton


%% GET COLUMNS OF DATA
[fleetorisidcol, fleetunitidcol, fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol, fleetregioncol, fleetstatecol, fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol, fleetpumpunitscol, fleetpumpeffcol, fleetpumploadcol,...
    fleetccsretrofitcol,fleettruesscapacitycol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);

%% ADD COLUMNS FOR PRICES
noxpricecol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,noxpricecol}='NOxPrice($/kg)'; %convert below
futurepowerfleetforplexos(2:end,noxpricecol)=num2cell(zeros(size(futurepowerfleetforplexos,1)-1,1));
so2pricecol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,so2pricecol}='SO2Price($/kg)'; %convert below
futurepowerfleetforplexos(2:end,so2pricecol)=num2cell(zeros(size(futurepowerfleetforplexos,1)-1,1));
so2groupcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,so2groupcol}='SO2CSAPRGroup'; %convert below
futurepowerfleetforplexos(2:end,so2groupcol)=num2cell(zeros(size(futurepowerfleetforplexos,1)-1,1));

%% GET GENERATORS OF AFFECTED FUEL TYPE
%Affected units under CSAPR: oil, coal, gas units > 25 MW in capacity
fueltypesofaffectedegus={'Coal';'NaturalGas';'Oil'};
genswithfueltype=[];
for i=1:size(fueltypesofaffectedegus,1)
    currfuel=fueltypesofaffectedegus{i};
    genswithfueltypecurr=find(strcmp(futurepowerfleetforplexos(:,fleetfueltypecol),currfuel));
    genswithfueltype=[genswithfueltype;genswithfueltypecurr];
end

%% GET GENERATORS >25 MW
gencapacs=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleetforplexos,fleetcapacitycol);
gencapacs=[0;gencapacs]; %add 0 for first row
gensgreaterthan25mw=find(gencapacs>=25);

%% AGGREGATE AFFECTED UNITS
affectedegusrows=genswithfueltype(ismember(genswithfueltype,gensgreaterthan25mw)); %gives rows in first array that are in second

%% INSERT PRICE INTO COLUMNS OF AFFECTED UNITS
%For each affected unit, look up state, pull appropriate prices, then add
%to clumn
for i=1:size(affectedegusrows,1)
    currrow=affectedegusrows(i);
    currstate=futurepowerfleetforplexos{currrow,fleetstatecol};
    %Get price for state
    noxstaterow=find(strcmp(noxprices(:,1),currstate));
    noxprice=noxprices{noxstaterow,2};
    so2staterow=find(strcmp(so2pricesandgroups(:,1),currstate));
    so2price=so2pricesandgroups{so2staterow,2};
    %Also get SO2 group
    so2group=so2pricesandgroups{so2staterow,3};
    %Store prices
    futurepowerfleetforplexos{currrow,noxpricecol}=noxprice;
    futurepowerfleetforplexos{currrow,so2pricecol}=so2price;
    futurepowerfleetforplexos{currrow,so2groupcol}=so2group;
end


