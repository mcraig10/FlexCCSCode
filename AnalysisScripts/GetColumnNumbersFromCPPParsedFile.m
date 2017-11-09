%Michael Craig
%January 21, 2015
%This script gets the column numbers of various columns of interest in the
%parsed file from the CPP.

function [fleetorisidcol,fleetunitidcol,fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol,fleetregioncol,fleetstatecol,fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol, fleetpumpunitscol, fleetpumpeffcol, fleetpumploadcol,...
    fleetccsretrofitcol,fleettruesscapacitycol,fleetaffectedegucol,fleethrpenaltycol,...
    fleetcapacpenaltycol,fleetsshrpenaltycol,fleetsscapacpenaltycol,fleeteextraperestorecol,...
    fleeteregenpereco2capcol,fleetegridpereco2capandregencol,fleetegriddischargeperestorecol,...
    fleetnoxpricecol,fleetso2pricecol,fleetso2groupcol]=...
    GetColumnNumbersFromCPPParsedFile(parsedfiledata)

fleetorisidcol=find(strcmp(parsedfiledata(1,:),'ORISCode'));
fleetunitidcol=find(strcmp(parsedfiledata(1,:),'UnitID'));
fleetfueltypecol=find(strcmp(parsedfiledata(1,:),'FuelType'));
fleetheatratecol=find(strcmp(parsedfiledata(1,:),'HeatRate'));
fleetcapacitycol=find(strcmp(parsedfiledata(1,:),'Capacity'));
fleetplanttypecol=find(strcmp(parsedfiledata(1,:),'PlantType'));
fleetretrofitcol=find(strcmp(parsedfiledata(1,:),'RetrofitSO2NOxControls'));
fleetregioncol=find(strcmp(parsedfiledata(1,:),'RegionName'));
fleetstatecol=find(strcmp(parsedfiledata(1,:),'StateName'));
fleetfossilunitcol=find(strcmp(parsedfiledata(1,:),'FossilUnit'));
fleetmindowntimecol=find(strcmp(parsedfiledata(1,:),'Min Down Time'));
fleetstartcostcol=find(strcmp(parsedfiledata(1,:),'Start Cost'));
fleetmaxrampupcol=find(strcmp(parsedfiledata(1,:),'Max Ramp Up'));
fleetmaxrampdowncol=find(strcmp(parsedfiledata(1,:),'Max Ramp Down'));
fleetminloadcol=find(strcmp(parsedfiledata(1,:),'Min Stable Level'));
fleetrunupratecol=find(strcmp(parsedfiledata(1,:),'Run Up Rate'));
fleetrundownratecol=find(strcmp(parsedfiledata(1,:),'Run Down Rate'));
fleetnoxemsratecol=find(strcmp(parsedfiledata(1,:),'NOxEmsRate(kg/mwh)'));
fleetso2emsratecol=find(strcmp(parsedfiledata(1,:),'SO2EmsRate(kg/mwh)'));
fleetco2emsratecol=find(strcmp(parsedfiledata(1,:),'CO2EmsRate(kg/mwh)'));
fleetfuelpricecol=find(strcmp(parsedfiledata(1,:),'FuelPrice($/GJ)'));
fleetpumpunitscol=find(strcmp(parsedfiledata(1,:),'Pump Units'));
fleetpumpeffcol=find(strcmp(parsedfiledata(1,:),'Pump Efficiency (%)'));
fleetpumploadcol=find(strcmp(parsedfiledata(1,:),'Pump Load (MW)'));
fleetccsretrofitcol=find(strcmp(parsedfiledata(1,:),'CCS Retrofit'));
fleettruesscapacitycol=find(strcmp(parsedfiledata(1,:),'True SS Capacity (MW)'));
fleetaffectedegucol=find(strcmp(parsedfiledata(1,:),'Affected EGU CPP'));
fleethrpenaltycol=find(strcmp(parsedfiledata(1,:),'CCS HR Penalty (%)'));
fleetcapacpenaltycol=find(strcmp(parsedfiledata(1,:),'CCS Capacity Penalty (%)'));
fleetsshrpenaltycol=find(strcmp(parsedfiledata(1,:),'CCS SS HR Penalty (%)'));
fleetsscapacpenaltycol=find(strcmp(parsedfiledata(1,:),'CCS SS Capacity Penalty (%)'));
fleeteextraperestorecol=find(strcmp(parsedfiledata(1,:),'E for Extra Solvent per E Used to Store Lean Solvent (MMWh/MWh)'));
fleeteregenpereco2capcol=find(strcmp(parsedfiledata(1,:),'E to Regenerator per E to CO2 Capture (MWh/MWh)'));
fleetegridpereco2capandregencol=find(strcmp(parsedfiledata(1,:),'E to Grid per E to CO2 Capture and Regenerator (MMWh/MWh)'));
fleetegriddischargeperestorecol=find(strcmp(parsedfiledata(1,:),'E to Grid per E Used to Store Lean Solvent (MMWh/MWh)'));
fleetnoxpricecol=find(strcmp(parsedfiledata(1,:),'NOxPrice($/kg)'));
fleetso2pricecol=find(strcmp(parsedfiledata(1,:),'SO2Price($/kg)'));
fleetso2groupcol=find(strcmp(parsedfiledata(1,:),'SO2CSAPRGroup'));








