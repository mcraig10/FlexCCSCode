%Michael Craig
%March 22, 2015

%This function adds start cost parameter to generator fleet
function [futurepowerplantfleet] = AddStartCostUCParameter...
    (futurepowerplantfleet,rowsinphorumucparams,phorumpropertynamecol,phorumpropertyvaluecol,...
    fleetrow,includeminloadCTmswLFGASfwaste)

%Get col numbers
fleetfuelcol=find(strcmp(futurepowerplantfleet(1,:),'FuelType'));
fleetplanttypecol=find(strcmp(futurepowerplantfleet(1,:),'PlantType'));

%Get column result will be stored in 
startcostcol=find(strcmp(futurepowerplantfleet(1,:),'Start Cost'));
%Get row of min stable level in PHORUM parameters passed in
startcostrow=find(strcmp(rowsinphorumucparams(:,phorumpropertynamecol),...
    'Start Cost'));

%Get start cost value
startcostval=rowsinphorumucparams{startcostrow,phorumpropertyvaluecol};

%If includeminloadCTmswLFGASfwaste=1, then include start cost on all
%plants. If = 0, then set start cost of all CTs, MSW, LF Gas, and
%Fwaste plants to zero.
if includeminloadCTmswLFGASfwaste==0
    currfueltype=futurepowerplantfleet{fleetrow,fleetfuelcol};
    currplanttype=futurepowerplantfleet{fleetrow,fleetplanttypecol};
    if strcmp(currfueltype,'MSW') || strcmp(currfueltype,'LF Gas') || ...
            strcmp(currfueltype,'Fwaste') || strcmp(currplanttype,'Combustion Turbine')
        startcostval=0;
    end
end

%Get capacity of plant
plantcapacitycol=find(strcmp(futurepowerplantfleet(1,:),'Capacity'));
plantcapacity=futurepowerplantfleet{fleetrow,plantcapacitycol};

%Get value of min stable level by multiplying multiplier by capacity value
futurepowerplantfleet{fleetrow,startcostcol}=startcostval*plantcapacity;

            
            
            