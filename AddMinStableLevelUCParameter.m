%Michael Craig
%March 22, 2015

%This function adds min stable level parameter to generator fleet
function [futurepowerplantfleet] = AddMinStableLevelUCParameter...
    (futurepowerplantfleet,rowsinphorumucparams,phorumpropertynamecol,phorumpropertyvaluecol,...
    fleetrow,includeminloadCTmswLFGASfwaste)

%Get columns of futurepowerplantfleet array
fleetfuelcol=find(strcmp(futurepowerplantfleet(1,:),'FuelType'));
fleetplanttypecol=find(strcmp(futurepowerplantfleet(1,:),'PlantType'));

%Get column result will be stored in 
minstablelevelcol=find(strcmp(futurepowerplantfleet(1,:),'Min Stable Level'));
%Get row of min stable level in PHORUM parameters passed in
minstablelevelrow=find(strcmp(rowsinphorumucparams(:,phorumpropertynamecol),...
    'Min Stable Level'));

%Get min stable level value
minstablelevel=rowsinphorumucparams{minstablelevelrow,phorumpropertyvaluecol}/100;

%If includeminloadCTmswLFGASfwaste=1, then include min stable load on all
%plants. If = 0, then set min stable load of all CTs, MSW, LF Gas, and
%Fwaste plants to zero.
if includeminloadCTmswLFGASfwaste==0
    currfueltype=futurepowerplantfleet{fleetrow,fleetfuelcol};
    currplanttype=futurepowerplantfleet{fleetrow,fleetplanttypecol};
    if strcmp(currfueltype,'MSW') || strcmp(currfueltype,'LF Gas') || ...
            strcmp(currfueltype,'Fwaste') || strcmp(currplanttype,'Combustion Turbine')
        minstablelevel=0;
    end
end
    

%Get capacity of plant
plantcapacitycol=find(strcmp(futurepowerplantfleet(1,:),'Capacity'));
plantcapacity=futurepowerplantfleet{fleetrow,plantcapacitycol};

%Save MSL value by multiplying fraction by plant capacity
futurepowerplantfleet{fleetrow,minstablelevelcol}=minstablelevel*plantcapacity;

            
            
            