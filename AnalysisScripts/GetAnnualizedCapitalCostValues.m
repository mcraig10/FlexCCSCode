%Michael Craig
%November 22, 2015
%This script takes in capital cost values for wind, normal CCS, and
%flexible CCS, and outputs annualized capital cost values.

%Calculate annualized capital cost value with annuity factor:
%Annuity factor = P/A = (1-(1+i)^-n)/i
%Then divide total capital cost by annuity factor to get annual value. Or:
%P/(P/A) = A

function [annualizedwindcapitalcost, annualizednormalccscapitalcost, ...
    annualizedsscapitalcost, windannuityfactor, ccsannuityfactor] = GetAnnualizedCapitalCostValues()

%% SET CAPITAL COST VALUES FOR WIND, NORMAL CCS AND FLEXIBLE CCS
%See Capital Costs\SummaryOfComplianceCosts.xlsx.
%Values are in 2011$/kW. Sources: 
%Wind: EPA, EIA, Lazard (also agrees w/ LBNL 2014)
%CCS: IECM + NETL 2013, EPRI 2007
%SS: Wijk, Versteeg & Oates, Dahlia
windcapitalcosts=[1330,0,2269]; windcapitalcosts(2)=(windcapitalcosts(1)+windcapitalcosts(3))/2;%min/max
normalccscapitalcosts=[1155,0,1378]; normalccscapitalcosts(2)=(normalccscapitalcosts(1)+normalccscapitalcosts(3))/2;%min/max 
solventstoragecapitalcostsperhour=[6.52,32,107]/2; %[$M/kWnet/hrtank] %min/best guess/max. %this is additional cost to normal CCS
%NOTE: above value is given for each houru of solvent storage; values
%in matrix are for 2 hours, which is value calculated in Excel file
%referenced above.

%% GET FLEXIBLE CCS CAPITAL COST
% %Flex CCS capital cost = normal CCS capital cost + solvent storage capital
% %cost
% flexccscapitalcosts=normalccscapitalcosts+solventstoragecapitalcosts;

%% SET DISCOUNT RATE AND LIFESPAN OF CAPITAL INVESTMENTS
discountrate=.07; %OMB DR for public benefits projects. 
windlifespan=20; %years
ccslifespan=30;

%% CALCULATE ANNUITY FACTOR
windannuityfactor=(1-(1+discountrate)^(-windlifespan))/discountrate;
ccsannuityfactor=(1-(1+discountrate)^(-ccslifespan))/discountrate;

%% ANNUALIZED CAPITAL COSTS
annualizedwindcapitalcost=windcapitalcosts/windannuityfactor;
annualizednormalccscapitalcost=normalccscapitalcosts/ccsannuityfactor;
annualizedsscapitalcost=solventstoragecapitalcostsperhour/ccsannuityfactor;


