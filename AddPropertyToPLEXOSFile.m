%Michael Craig
%January 18, 2015
%Script for adding row(s) of information to the Property sheet in a file
%for importing to PLEXOS

function [propertiesdata] = AddPropertyToPLEXOSFile(propertiesdata,parentclass,childclass,parentobj,...
    childobj, propertyname, propertyvalue, filename, scenarioname, datefrom, dateto)

%Get collection based on childclass
if strcmp(childclass,'Fuel')
    collection='Fuels';
elseif strcmp(childclass,'Generator')
    collection='Generators';
elseif strcmp(childclass,'Node')
    collection='Nodes';
elseif strcmp(childclass,'Data File')
    collection='Data Files';
    propertyvalue=0; 
elseif strcmp(childclass,'Zone')
    collection='Zones';
elseif strcmp(childclass,'Emission')
    collection='Emissions';
elseif strcmp(childclass,'Reserve')
    collection='Reserves';
elseif strcmp(childclass,'Constraint')
    collection='Constraints';
elseif strcmp(childclass,'Storage')
    collection='Storages';
elseif strcmp(childclass,'Region')
    collection='Regions';
else
    collection=childclass; %works for zone & region at least
end

%Set property value to 0 and final column to 0 if setting up a datafile 
if strcmp(propertyname,'Filename') 
    propertyvalue=0;
end
%Also set property value to 0 if setting up a Zone-Load association. Need
%to filter out 'Region' load entries, since input a load value of -1 for
%regions and want that property value to be passed through.
if strcmp(propertyname,'Load') && strcmp(childclass,'Region')==0
    propertyvalue=0;
end

if strcmp(propertyname,'Production Rate')==0 %if not production rate
    %Add row to bottom of propertiesdata
    propertyrow=size(propertiesdata,1)+1;

    propertiesdata{propertyrow,1}=parentclass; %parent class
    propertiesdata{propertyrow,2}=childclass; %child class
    propertiesdata{propertyrow,3}=collection; %collection
    propertiesdata{propertyrow,4}=parentobj; %parent obj
    propertiesdata{propertyrow,5}=childobj; %child obj
    propertiesdata{propertyrow,6}=propertyname; %property
    propertiesdata{propertyrow,7}=1; %band ID
    propertiesdata{propertyrow,8}=propertyvalue; %value
    %units
    if strcmp(propertyname,'Max Capacity') || strcmp(propertyname,'Min Stable Level') || ...
            strcmp(propertyname,'Min Stable Level')
        propertiesdata{propertyrow,9}='MW';
    elseif strcmp(propertyname,'Max Ramp Up') || strcmp(propertyname,'Max Ramp Down')
        propertiesdata{propertyrow,9}='MW/min.';
    elseif strcmp(propertyname,'Heat Rate')
        propertiesdata{propertyrow,9}='GJ/MWh';
    elseif strcmp(propertyname,'Load') || strcmp(propertyname,'Load Participation Factor') || ...
            strcmp(propertyname,'Filename')
        propertiesdata{propertyrow,9}='-';
    elseif strcmp(propertyname,'VO&M Charge')
        propertiesdata{propertyrow,9}='$/MWh';
    elseif strcmp(propertyname,'Start Cost')
        propertiesdata{propertyrow,9}='$';
    elseif strcmp(propertyname,'Rating Factor')
        propertiesdata{propertyrow,9}='%';
    elseif strcmp(propertyname,'Min Down Time')
        propertiesdata{propertyrow,9}='hrs';
    elseif strcmp(propertyname,'Max Energy Month')
        propertiesdata{propertyrow,9}='GWh';
    elseif strcmp(propertyname,'Fuel Price')
        propertiesdata{propertyrow,9}='$/GJ';
    elseif strcmp(propertyname,'Timeframe')%reserves
        propertiesdata{propertyrow,9}='sec';
    elseif strcmp(propertyname,'Min Provision')%reserves
        propertiesdata{propertyrow,9}='MW';
    elseif strcmp(propertyname,'Type')%reserves
        propertiesdata{propertyrow,9}='-';
    elseif strcmp(propertyname,'Pump Units') || strcmp(propertyname,'Units')
        propertiesdata{propertyrow,9}='-';
    elseif strcmp(propertyname,'Pump Load')
        propertiesdata{propertyrow,9}='MW';
    elseif strcmp(propertyname,'Pump Efficiency')
        propertiesdata{propertyrow,9}='%';
    elseif strcmp(propertyname,'Max Volume')
        propertiesdata{propertyrow,9}='GWh';
    elseif strcmp(propertyname,'Initial Volume')
        propertiesdata{propertyrow,9}='GWh';
    elseif strcmp(propertyname,'End Effects Method')
        propertiesdata{propertyrow,9}='-';
    elseif strcmp(propertyname,'Offer Price')
        propertiesdata{propertyrow,9}='$/MW';
    elseif strcmp(propertyname,'Offer Quantity')
        propertiesdata{propertyrow,9}='MW';
    end
    propertiesdata{propertyrow,10}=datefrom; %date from
    propertiesdata{propertyrow,11}=dateto; %date to
    propertiesdata{propertyrow,15}=filename;
    propertiesdata{propertyrow,16}=scenarioname;
    if strcmp(propertyname,'Max Energy Month')
        propertiesdata{propertyrow,18}=3; %period type ID - set to 3 for Max Energy Month
    else
        %Add blank cell at end so propertiesdata is correct size
        propertiesdata{propertyrow,18}=[];
    end
else
    %If production (emission) rate, adding in values for each emissions rate at once, 
    %so need to  loop over values. Values are passed in as: [NOx, SO2, CO2]
    for i=1:size(propertyvalue,1)
        %Add row to bottom of propertiesdata
        propertyrow=size(propertiesdata,1)+1;
        
        propertiesdata{propertyrow,1}=parentclass; %parent class
        propertiesdata{propertyrow,2}=childclass; %child class
        propertiesdata{propertyrow,3}=collection; %collection
        if i==1
            propertiesdata{propertyrow,4}='NOx'; %parent obj - here, name of emission
        elseif i==2
            propertiesdata{propertyrow,4}='SO2';
        else
            %Here, determine whether hsould add CO2 or CO2CPP based on
            %parent object name which is passed in as a dummy
            propertiesdata{propertyrow,4}=parentobj;
        end
        propertiesdata{propertyrow,5}=childobj; %child obj
        propertiesdata{propertyrow,6}=propertyname; %property
        propertiesdata{propertyrow,7}=1; %band ID
        propertiesdata{propertyrow,8}=propertyvalue(i); %value
        %units
        propertiesdata{propertyrow,9}='kg/MWh';
        propertiesdata{propertyrow,10}=datefrom; %date from
        propertiesdata{propertyrow,11}=dateto; %date to
        propertiesdata{propertyrow,15}=filename;
        propertiesdata{propertyrow,16}=scenarioname;
        %Add blank cell at end so propertiesdata is correct size
        propertiesdata{propertyrow,18}=[];
    end
end


