%Michael Craig
%November 4, 2015
%Function takes in a file (scenario) name, then returns parameter values
%used to formulate other file names.

function [flexccsval,ccsmwval,windmwval,rampval,ventval,calcco2priceval,...
    sssizeval] = GetLabelsFromFileName(filename)

%GET LABELS FROM SCENARIO LABEL TO FORM RF FILE NAMES
%Flex or normal CCS
flexccslabel='FlxCCS';
flexccslabelspot=strfind(filename,flexccslabel);
flexccsvalspot=flexccslabelspot+size(flexccslabel,2);
flexccsval=filename(flexccsvalspot);

%CCS and wind capacity
mwlabel='MW';
mwlabelspots=strfind(filename,mwlabel);
%First MW is for CCS, second is for wind
ccsmwspot=mwlabelspots(1)+size(mwlabel,2);
windmwspot=mwlabelspots(2)+size(mwlabel,2);
%Need to also figure out how long each capacity goes
windlabel='Wnd';
windlabelspot=strfind(filename,windlabel);
ramplabel='Rmp';
ramplabelspot=strfind(filename,ramplabel);
%Get values
ccsmwval=filename(ccsmwspot:(windlabelspot-1));
windmwval=filename(windmwspot:(ramplabelspot-1));

%Scaled ramp rates
ramplabel='Rmp';
ramplabelspot=strfind(filename,ramplabel);
rampspot=ramplabelspot+size(ramplabel,2);
rampval=filename(rampspot);

%Vent
ventlabel='Vnt';
ventlabelspot=strfind(filename,ventlabel);
ventspot=ventlabelspot+size(ventlabel,2);
ventval=filename(ventspot);

%Whether calculate CO2 price
co2calculatepricelabel='CO2P';
co2calculatepricelabelspot=strfind(filename,co2calculatepricelabel);
co2calculatepricespot=co2calculatepricelabelspot+size(co2calculatepricelabel,2);
calcco2priceval=filename(co2calculatepricespot);

%WHether using 1hour SS tank size
sssizelabel='SSH1';
sssizelabelfound=strfind(filename,sssizelabel);
if isempty(sssizelabelfound)
    if strcmp(flexccsval,'1')
        sssizeval=2;
    else
        sssizeval=0;
    end
else
    sssizeval=1;
end








