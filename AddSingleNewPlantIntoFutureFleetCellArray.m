%Michael Craig
%January 21, 2015
%Script that adds new power plants into the future fleet cell array in the
%format of the CPP parsed file.

%Possible plant types in CPP Parsed File: 'Onshore Wind',...
function [powerplantfleet]=AddSingleNewPlantIntoFutureFleetCellArray(powerplantfleet,...
    planttype,state,capacity)

%Generic data for all new plants
yearval=2025;

%Data depending on plant type
if strcmp(planttype,'Onshore Wind')
    fossilunit='Non-Fossil';
    plantname='NewCREATEDWIND';
    fueltype='Wind';
elseif strcmp(planttype,'Solar PV')
    fossilunit='Non-Fossil';
    plantname='NewCREATEDSOLAR';
    fueltype='Solar';
elseif strcmp(planttype,'LF Gas')
    fueltype='LF Gas';
    fossilunit='Non-Fossil';
    plantname='NewCREATEDLFGAS';
else
    plantname='New';
end

%Get columns in data
[~,~,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(powerplantfleet);
parseddataplantnamecol=find(strcmp(powerplantfleet(1,:),'PlantName'));
parseddatayearcol=find(strcmp(powerplantfleet(1,:),'Year'));

%Add row to fleet array
powerplantfleet{end+1,parseddatastatecol}=state;
powerplantfleet{end,parseddataplanttypecol}=planttype;
powerplantfleet{end,parseddatafossilunitcol}=fossilunit;
powerplantfleet{end,parseddatayearcol}=yearval;
powerplantfleet{end,parseddatacapacitycol}=capacity;
powerplantfleet{end,parseddatafueltypecol}=fueltype;
powerplantfleet{end,parseddataplantnamecol}=plantname;

