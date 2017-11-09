%Michael Craig
%November 22, 2015
%This script takes in capital cost values for wind, normal CCS, and
%flexible CCS, and outputs annualized capital cost values.

%Calculate annualized capital cost value with annuity factor:
%Annuity factor = P/A = (1-(1+i)^-n)/i
%Then divide total capital cost by annuity factor to get annual value. Or:
%P/(P/A) = A

function [annualizedwindcapitalcost, annualizednormalccscapitalcost, ...
    annualizedflexibleccscapitalcost] = GetAnnualizedCapitalCostValues()

%% SET CAPITAL COST VALUES FOR WIND, NORMAL CCS AND FLEXIBLE CCS
%See Capital Costs\SummaryOfComplianceCosts.xlsx.
%Values are in 2011$/kW. 
windcapitalcosts=[1330,0,2269]; windcapitalcosts(2)=(windcapitalcosts(1)+windcapitalcosts(3))/2;%min/max
normalccscapitalcosts=[924,2000,6910]; %min/best guess/max
solventstoragecapitalcosts=[6.52,32,107]; %min/best guess/max. %this is additional cost to normal CCS

%% GET FLEXIBLE CCS CAPITAL COST
%Flex CCS capital cost = normal CCS capital cost + solvent storage capital
%cost
flexccscapitalcosts=normalccscapitalcosts+solventstoragecapitalcosts;

%% SET DISCOUNT RATE AND LIFESPAN OF CAPITAL INVESTMENTS
discountrate=.065; 
lifespan=20; %years

%% CALCULATE ANNUITY FACTOR
annuityfactor=(1-(1+discountrate)^(-lifespan))/discountrate;

%% ANNUALIZED CAPITAL COSTS
annualizedwindcapitalcost=windcapitalcosts/annuityfactor;
annualizednormalccscapitalcost=normalccscapitalcosts/annuityfactor;
annualizedflexibleccscapitalcost=flexccscapitalcosts/annuityfactor;


