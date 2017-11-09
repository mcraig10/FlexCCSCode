%Michael Craig
%March 22, 2015

%This function adds min stable level parameter to generator fleet
function [futurepowerplantfleet] = AddMaxRampDownUCParameter...
    (futurepowerplantfleet,rowsinphorumucparams,phorumpropertynamecol,phorumpropertyvaluecol,...
    fleetrow,usescaledramprates)

%Get column result will be stored in 
fleetcol=find(strcmp(futurepowerplantfleet(1,:),'Max Ramp Down'));
%Get row of max ramp up in PHORUM parameters passed in; look up 'Max Ramp
%Up' if using unscaled PHORUM values (usescaledramprates=0) and 'Scaled Max
%Ramp Up' if using scaled PHORUM values (usescaledramprates=1). 
if usescaledramprates==0
    datarow=find(strcmp(rowsinphorumucparams(:,phorumpropertynamecol),...
        'Max Ramp Down'));
elseif usescaledramprates==1
    datarow=find(strcmp(rowsinphorumucparams(:,phorumpropertynamecol),...
        'Scaled Max Ramp Down'));
end

%Get capacity of plant
plantcapacitycol=find(strcmp(futurepowerplantfleet(1,:),'Capacity'));
plantcapacity=futurepowerplantfleet{fleetrow,plantcapacitycol};

%Get value of max ramp down by multiplying percentage by capacity value and
%then dividing by 60 minutes/hour to get units of MW/min.
futurepowerplantfleet{fleetrow,fleetcol}=rowsinphorumucparams{datarow,...
    phorumpropertyvaluecol}/100*plantcapacity/60;

            
            
            