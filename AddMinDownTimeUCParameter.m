%Michael Craig
%March 22, 2015

%This function adds min stable level parameter to generator fleet
function [futurepowerplantfleet] = AddMinDownTimeUCParameter...
    (futurepowerplantfleet,rowsinphorumucparams,phorumpropertynamecol,phorumpropertyvaluecol,...
    fleetrow)

%Get column result will be stored in 
mindowntimecol=find(strcmp(futurepowerplantfleet(1,:),'Min Down Time'));
%Get row of min stable level in PHORUM parameters passed in
mindowntimerow=find(strcmp(rowsinphorumucparams(:,phorumpropertynamecol),...
    'Min Down Time'));

%Get capacity of plant
plantcapacitycol=find(strcmp(futurepowerplantfleet(1,:),'Capacity'));
plantcapacity=futurepowerplantfleet{fleetrow,plantcapacitycol};

%Get value of min down time
futurepowerplantfleet{fleetrow,mindowntimecol}=rowsinphorumucparams{mindowntimerow,...
    phorumpropertyvaluecol};

            
            
            