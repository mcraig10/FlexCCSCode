%Michael Craig
%1/18/15
%FUEL PRICE ADDITION SCRIPT
%This function imports a cell array w/ a power system fleet, and then adds
%fuel price columns to the end of that fleet. As of 1 April 2015, I am
%calculating fuel prices for the future CPP fleet with aggregate
%fuel expenditure and heat input data provided in EPA's Parsed Files. 
%NOTE: emissions rates for oil CTs & O/G Steam turbines are hardcoded
%below.

function [futurepowerfleetforplexos] = AddFuelPricesToFleet(futurepowerfleetforplexos)

%Get data columns of interest
[parseddataorisidcol,parseddataunitidcol,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);

%Identify columns w/ aggregate fuel use (TBtu) and fuel cost (million $) data
fuelcostcol=find(strcmp(futurepowerfleetforplexos(1,:),'FuelCostTotal'));
fuelusecol=find(strcmp(futurepowerfleetforplexos(1,:),'FuelUseTotal'));

%Add column to end of fleet for fuel cost
fuelopcostcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,fuelopcostcol}='FuelPrice($/GJ)';
%PLEXOS takes in fuel price as $/GJ; will need to convert data from parsed
%file

%Need to handle plants that have no generation and therefore no fuel costs.
%Do this by using fleet-wide averages. 

%Loop through fleet and calculate fuel prices, ignoring plants that
%don't generate anything for now.
mmbtutogj=0.9748; %$/MMBTU * MMBTU/GJ = $/GJ. 1 GJ = 0.947 MMBTU.
for i=2:size(futurepowerfleetforplexos,1)
    %If no generation at plant, set emissions rate to zero, else calculate
    %emissions rate.
    if futurepowerfleetforplexos{i,fuelusecol}==0
        futurepowerfleetforplexos{i,fuelopcostcol}=0;
    else 
        %Fuel use given in TBtu, fuel cost in million $. Dividing the two
        %yields $/MMBTU. Then convert to $/GJ using factor above.
        futurepowerfleetforplexos{i,fuelopcostcol}=...
            futurepowerfleetforplexos{i,fuelcostcol}/...
            futurepowerfleetforplexos{i,fuelusecol}*mmbtutogj;
    end
end

%Now get fleet-wide capacity-weighted average fuel prices by fuel and plant type.
%First, get unique list of fuel types. Then isolate plants of that fuel
%type. Then get unique plant types for that fuel type. Then, for each
%unique plant type, isolate data, isolate operational fuel cost values greater than
%zero, and then get their capacity-weighted average.
uniquefueltypes=unique(futurepowerfleetforplexos(2:end,parseddatafueltypecol));
%Iterate through fuel types
for i=1:size(uniquefueltypes,1)
    currfueltype=uniquefueltypes(i);
    %Check to make sure fuel type is not wind or solar (0 fuel price).
    if strcmp(currfueltype,'Wind')==0 &  strcmp(currfueltype,'Solar')==0
        %Isolate plants of fuel type
        plantsoffueltype=futurepowerfleetforplexos(find(strcmp(futurepowerfleetforplexos(:,parseddatafueltypecol),currfueltype)),:);
        %Check if any plants have a zero fuel use value in current set
        tempfuelusegen=cell2mat(plantsoffueltype(:,fuelusecol));
        if min(tempfuelusegen)==0 %only need to get fleet-wide averages if a plant is missing a fuel price
            %Check if oil - oil CTs & O/G Steam turbines do not generate any
            %power in Option 1, so need to get their fuel costs from
            %another source.
            %If oil, use hard-coded fuel price value.
            %If not oil, calculate rates below.
            if strcmp(currfueltype,'Oil')
                avgfuelopcosts=25*mmbtutogj;
                %Fuel price from DL's thesis, page 203, Table D-2 (capacity-weighted
                %average fuel prices from IPM v.5.13). Value given
                %in $/MMBTU. Confirmed this value in parsed file on
                %5/26/15.
            else
                %Get capacity-weighted average fuel prices for those plant types
                %Pull out fuel op costs and find rows with values >0, and
                %throw out values = 0
                tempfuelopcosts=cell2mat(plantsoffueltype(:,fuelopcostcol));
                rowstokeep=tempfuelopcosts>0;
                tempfuelopcosts=tempfuelopcosts(tempfuelopcosts>0); %remove zeros
                %Get capacity weightings
                tempcapacity=cell2mat(plantsoffueltype(:,parseddatacapacitycol));
                tempcapacity=tempcapacity(rowstokeep);
                temptotalcapacity=sum(tempcapacity);
                capacityweights=tempcapacity/temptotalcapacity;
                if isempty(tempfuelopcosts) %if no plants have non-zero fuel cost, indicates 0 fuel cost
                    avgfuelopcosts=0;
                else
                    avgfuelopcosts=sum(capacityweights.*tempfuelopcosts);
                end
            end
            
            %Now replace fuel prices of plants w/out fuel price data.
            %Get plants w/ current fuel type
            rowsinfuturefleet=find(strcmp(futurepowerfleetforplexos(:,parseddatafueltypecol),currfueltype));
            %Iterate over rows, check if zero fuel use, and if
            %so replace fuel price.
            for z=1:size(rowsinfuturefleet,1)
                currrow=rowsinfuturefleet(z);
                if futurepowerfleetforplexos{currrow,fuelusecol}==0
                    futurepowerfleetforplexos{currrow,fuelopcostcol}=avgfuelopcosts;
                end
            end
        end
    elseif strcmp(currfueltype,'Wind') || strcmp(currfueltype,'Solar') %if wind or solar
        rowsinfuturefleet=find(strcmp(futurepowerfleetforplexos(:,parseddatafueltypecol),currfueltype));
        %For wind and solar plants 
        for z=1:size(rowsinfuturefleet,1)
            currrow=rowsinfuturefleet(z);
            futurepowerfleetforplexos{currrow,fuelopcostcol}=0;
        end
    end
end




















