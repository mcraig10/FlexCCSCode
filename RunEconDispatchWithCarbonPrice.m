%Michael Craig, 3 June 2015
%This function runs a simple linear programming economic dispatch on an
%input fleet for a given annual net demand profile and carbon price. The
%economic dispatch is run hourly for the entire year. It then calculates
%the emissions mass and rate. The emissions rate is calculated per the
%Clean Power Plan.

%INPUTS: plant fleet, net demand, carbon price to test
%OUTPUTS: emissions mass and emissions rate given dispatching of plants
function [emissionsmasscppaffectedegu] = RunEconDispatchWithCarbonPrice(futurepowerfleetforecondispatch,...
    hourlynetdemand,carbonprice)

%% SET LINPROG OPTIONS
edoptions=optimset('Display','off');

%% GET COLUMNS OF FUTURE POWER FLEET
[fleetorisidcol, fleetunitidcol, fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol, fleetregioncol, fleetstatecol, fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol, fleetpumpunitscol, fleetpumpeffcol, fleetpumploadcol,...
    fleetccsretrofitcol,fleettruesscapacitycol,fleetaffectedegucol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforecondispatch);
fleetnoxpricecol=find(strcmp(futurepowerfleetforecondispatch(1,:),'NOxPrice($/kg)'));
fleetso2pricecol=find(strcmp(futurepowerfleetforecondispatch(1,:),'SO2Price($/kg)'));
fleetco2emsrateforedcol=find(strcmp(futurepowerfleetforecondispatch(1,:),'CO2EmsRateForED'));
fleetnoxemsrateforedcol=find(strcmp(futurepowerfleetforecondispatch(1,:),'NOxEmsRateForED'));
fleetso2emsrateforedcol=find(strcmp(futurepowerfleetforecondispatch(1,:),'SO2EmsRateForED'));
fleethrforedcol=find(strcmp(futurepowerfleetforecondispatch(1,:),'HRForED'));
fleetvomforedcol=find(strcmp(futurepowerfleetforecondispatch(1,:),'VOMForED'));

%% CALCULATE OPERATING COSTS OF PLANTS (INC. CO2 PRICE ONLY ON AFFECTED EGUS)
%Operating cost = HR*FuelPrice + VOM + CO2EmsRate*CO2Price
%Operating cost = [Btu/kWh]*[$/GJ]+[$/MWh]+[kg/MWh]*[$/ton]
%With unit adjustments: Op Cost =
%[Btu/kWh]*[$/GJ]*[1.055E-6GJ/Btu]*[1000kWh/MWh]+[kg/MWh]*[$/ton]*[ton/907.185kg]
% ---> $/MWh + $/MWh + $/MWh
gjtobtu=1.055E-6;
tontokg=907.185;

%Get HR, fuel price, VOM, and emissions rates for plants. Need to account
%for zeros in planthrs. Pull HR & emission rate values from columsn for
%economic dispatch - these have appropriate data for flexible CCS units,
%and otherwise are equal to true emission rate columns. 
planthrs=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleetforecondispatch,fleethrforedcol);
plantfuelprices=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleetforecondispatch,fleetfuelpricecol);
plantvoms=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleetforecondispatch,fleetvomforedcol);
plantco2emrates=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleetforecondispatch,fleetco2emsrateforedcol);
plantaffectedunitcpp=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleetforecondispatch,fleetaffectedegucol);
plantnoxprices=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleetforecondispatch,fleetnoxpricecol);
plantnoxemrates=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleetforecondispatch,fleetnoxemsrateforedcol);
plantso2prices=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleetforecondispatch,fleetso2pricecol);
plantso2emrates=ReturnColumnOfDataWithZerosForMissingEntries(futurepowerfleetforecondispatch,fleetso2emsrateforedcol);

%Get operating costs. Including affectedunit 1/0 indicator will zero out
%CO2 price if not an affected unit.
operatingcosts=planthrs.*plantfuelprices*gjtobtu*1000 + plantvoms + plantco2emrates.*carbonprice/tontokg.*plantaffectedunitcpp+...
    plantnoxemrates.*plantnoxprices+plantso2emrates.*plantso2prices;

%% SET UPPER AND LOWER CAPACITY VALUES
mincapacs=zeros(size(planthrs,1),1);
maxcapacs=cell2mat(futurepowerfleetforecondispatch(2:end,fleetcapacitycol));

%% CREATE A-MATRIX FOR DEMAND
numplants=size(planthrs,1);
demandAeq=ones(1,numplants); 

%% RUN ECONOMIC DISPATCH
%For each hour, solve for generation
numhours=size(hourlynetdemand,1);
%Save results in plantgenallhrs - each column = 1 hour, and each row = a
%generator.
plantgenallhrs=zeros(numplants,numhours);
totalcostallhrs=zeros(1,numhours);
exitmsgallhrs=zeros(1,numhours);
for hr=1:numhours
    %Get demand for current hour
    currdemand=hourlynetdemand(hr);
    demandbeq=currdemand;
    
    %Run LP
    [plantgenhr,totalcostval,exitmsg]=linprog(operatingcosts,[],[],demandAeq,demandbeq,mincapacs,maxcapacs,[],edoptions);
    
    %Save answers
    plantgenallhrs(:,hr)=plantgenhr;
    totalcostallhrs(:,hr)=totalcostval;
    exitmsgallhrs(:,hr)=exitmsg;
end
%Sum total annual generation by each generator
totalplantgenallhrs=sum(plantgenallhrs,2); %sum across rows

%Add total annual generation by each generator to end of futurepowerfleetforecondispatch
futurepowerfleetforecondispatch(1,end+1)={'TotalAnnualGen(MWh)'};
totalannualgencol=find(strcmp(futurepowerfleetforecondispatch(1,:),'TotalAnnualGen(MWh)'));
futurepowerfleetforecondispatch(2:end,totalannualgencol)=num2cell(totalplantgenallhrs);


%% CALL FUNCTION THAT CALCULATES EMISSIONS MASS FROM AFFECTED EGUS
%Call function that outputs emissions mass (kg) per final CPP for affected
%EGUs.
[emissionsmasscppaffectedegu] = CalculateCPPEmissionsMass(futurepowerfleetforecondispatch);
















