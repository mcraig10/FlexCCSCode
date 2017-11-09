%Michael Craig
%20 March 2015
%Function takes in a given power fleet, matches each generator to a set of
%UC parameters that are based on PHORUM data, and outputs the fleet with
%those UC parameters added in columns at the end.
%INPUTS: fleet, usescaledramprates (indicates whether to use scaled or
%unscaled PHORUM ramp rates), includeminloadCTmswLFGASfwaste (indicates
%whether include min stable load on CTs, MSW, lf gas, & f waste plants)

function [futurepowerplantfleet] = AddUCParametersToFleet...
    (futurepowerplantfleet, usescaledramprates, includeminloadCTmswLFGASfwaste, pc)

%% IMPORT PHORUM DATA
%File name for PHORUM parameters
if strcmp(pc,'work')
    phorumfiledir='C:\Users\mtcraig\Desktop\EPP Research\Databases\PHORUM\';
elseif strcmp(pc,'personal')
    phorumfiledir='C:\Users\mcraig10\Desktop\EPP Research\Databases\PHORUM\';
end
phorumfilename='PHORUMUCParameters13July2015.xlsx';
%Import PHORUM data
[~,~,phorumucparams]=xlsread(strcat(phorumfiledir,phorumfilename),'Sheet1');
clear phorumfiledir phorumfilename;

%% GET COLUMNS OF PHORUM FILE DATA
phorumfuelcol=find(strcmp(phorumucparams(1,:),'Fuel'));
phorumplantcol=find(strcmp(phorumucparams(1,:),'PlantType'));
phorumlowerplantsizecol=find(strcmp(phorumucparams(1,:),'LowerPlantSizeLimit'));
phorumupperplantsizecol=find(strcmp(phorumucparams(1,:),'UpperPlantSizeLimit'));
phorumpropertynamecol=find(strcmp(phorumucparams(1,:),'PropertyName'));
phorumpropertyvaluecol=find(strcmp(phorumucparams(1,:),'PropertyValue'));
phorumunitscol=find(strcmp(phorumucparams(1,:),'PropertyUnits'));

%% ADD COLUMNS TO FLEET ARRAY
futurepowerplantfleet(1,end+1)={'Min Stable Level'};
futurepowerplantfleet(1,end+1)={'Start Cost'};
futurepowerplantfleet(1,end+1)={'Min Down Time'};
futurepowerplantfleet(1,end+1)={'Max Ramp Up'};
futurepowerplantfleet(1,end+1)={'Max Ramp Down'};

%% GET FUEL AND PLANT TYPE AND CAPACITY ROWS FROM FLEET ARRAY
fleetfuelcol=find(strcmp(futurepowerplantfleet(1,:),'FuelType'));
fleetplanttypecol=find(strcmp(futurepowerplantfleet(1,:),'PlantType'));
fleetcapacitycol=find(strcmp(futurepowerplantfleet(1,:),'Capacity'));

%% MATCH PLANTS TO UC PARAMETERS
%For each row in futurepowerplantfleet, get UC parameters
for fleetrow=2:size(futurepowerplantfleet,1) %first row = headers
    rowfuel=futurepowerplantfleet{fleetrow,fleetfuelcol};
    rowplanttype=futurepowerplantfleet{fleetrow,fleetplanttypecol};
    rowcapacity=futurepowerplantfleet{fleetrow,fleetcapacitycol};
    %First find matching fuel rows. Have some coal-to-gas units that have
    %NG fuel & Coal Steam plant type. Want to assign these UC parameters
    %for coal units. Therefore find rows matching Coal fuel type.
    if strcmp(rowfuel,'NaturalGas') && strcmp(rowplanttype,'Coal Steam')
        %Artificially set fuel type as Coal
        matchingfuelrows=find(strcmp('Coal',phorumucparams(:,phorumfuelcol))); 
    else
        matchingfuelrows=find(strcmp(rowfuel,phorumucparams(:,phorumfuelcol)));
    end
    matchingrows=phorumucparams(matchingfuelrows,:);
%% LF GAS, MSW, FWASTE, NUCLEAR, HYDRO, BIOMASS, SOLAR, WIND, PET. COKE, NON-FOSSIL, GEOTHERMAL
    if strcmp(rowfuel,'LF Gas') || strcmp(rowfuel,'MSW') || strcmp(rowfuel,'Fwaste') || ...
            strcmp(rowfuel,'Nuclear') || strcmp(rowfuel,'Hydro') || strcmp(rowfuel,'Solar') ...
            || strcmp(rowfuel,'Wind') || strcmp(rowfuel,'Non-Fossil') || strcmp(rowfuel,'Biomass') ...
            || strcmp(rowfuel,'Pet. Coke') || strcmp(rowfuel,'Geothermal')
        %For some fuels, plant type & size not matter for any UC parameter:
        %LF Gas, MSW, Nuclear, Hydro, Fwaste, so just go through parameters
        %and assign values.
        %ADD MIN STABLE LEVEL
        futurepowerplantfleet=AddMinStableLevelUCParameter...
            (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
            phorumpropertyvaluecol,fleetrow,includeminloadCTmswLFGASfwaste);
        %ADD START COST
        futurepowerplantfleet=AddStartCostUCParameter...
            (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
            phorumpropertyvaluecol,fleetrow,includeminloadCTmswLFGASfwaste);
        %ADD MIN DOWN TIME
        futurepowerplantfleet=AddMinDownTimeUCParameter...
            (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
            phorumpropertyvaluecol,fleetrow);
        %ADD RAMP UP AND DOWN
        futurepowerplantfleet=AddMaxRampUpUCParameter...
            (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
            phorumpropertyvaluecol,fleetrow,usescaledramprates);
        futurepowerplantfleet=AddMaxRampDownUCParameter...
            (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
            phorumpropertyvaluecol,fleetrow,usescaledramprates);
        
%% NATURAL GAS
%There are some coal-to-gas retrofits; don't want to include them here
%(will treat them as coal units below), therefore filter out those units)
    elseif strcmp(rowfuel,'NaturalGas') && strcmp(rowplanttype,'Coal Steam')==0
        %ADD MIN STABLE LEVEL
        futurepowerplantfleet=AddMinStableLevelUCParameter...
            (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
            phorumpropertyvaluecol,fleetrow,includeminloadCTmswLFGASfwaste);
        
        %Test for CT vs CC vs O/G Steam
        if strcmpi(rowplanttype,'O/G Steam')
            %Isolate O/G Steam rows
            ogsteamrows=find(strcmpi(matchingrows(:,phorumplantcol),'O/G Steam'));
            matchingrows=matchingrows(ogsteamrows,:);
            %ADD START COST
            futurepowerplantfleet=AddStartCostUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,includeminloadCTmswLFGASfwaste);
            %ADD MIN DOWN TIME
            futurepowerplantfleet=AddMinDownTimeUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow);
            %ADD RAMP UP AND DOWN
            futurepowerplantfleet=AddMaxRampUpUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,usescaledramprates);
            futurepowerplantfleet=AddMaxRampDownUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,usescaledramprates);
            
        elseif strcmp(rowplanttype,'Combustion Turbine')
            %Isolate CT rows
            ctrows=find(strcmp(matchingrows(:,phorumplantcol),'Combustion Turbine'));
            matchingrows=matchingrows(ctrows,:);
            %ADD START COST
            futurepowerplantfleet=AddStartCostUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,includeminloadCTmswLFGASfwaste);
            %ADD RAMP UP AND DOWN
            futurepowerplantfleet=AddMaxRampUpUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,usescaledramprates);
            futurepowerplantfleet=AddMaxRampDownUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,usescaledramprates);
            
            %ADD MIN DOWN TIME
            %Get cutoff capacities
            mindowntimerows=find(strcmp(matchingrows(:,phorumpropertynamecol),'Min Down Time'));
            mindowntimerows=matchingrows(mindowntimerows,:);
            capacities=[];
            for j=1:size(mindowntimerows,1)
                lowercapac=mindowntimerows{j,phorumlowerplantsizecol};
                uppercapac=mindowntimerows{j,phorumupperplantsizecol};
                capacities=vertcat(capacities,[lowercapac,uppercapac]);
            end %capacities is ordered largest to smallest
            %Find where coal plant falls
            currplantcapacity=futurepowerplantfleet{fleetrow,fleetcapacitycol};
            correctsizerow=currplantcapacity>=capacities(:,1) & currplantcapacity<capacities(:,2);
            matchingrowsmindowntime=mindowntimerows(correctsizerow,:);
            %Now add min down time
            futurepowerplantfleet=AddMinDownTimeUCParameter...
                (futurepowerplantfleet,matchingrowsmindowntime,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow);
            
        elseif strcmp(rowplanttype,'Combined Cycle')
            %Isolate CC rows
            ccrows=find(strcmp(matchingrows(:,phorumplantcol),'Combined Cycle'));
            matchingrows=matchingrows(ccrows,:);
            %ADD START COST
            futurepowerplantfleet=AddStartCostUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,includeminloadCTmswLFGASfwaste);
            %ADD MIN DOWN TIME
            futurepowerplantfleet=AddMinDownTimeUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow);
            
            %ADD RAMP UP AND DOWN
            %Get cutoff capacities (same for ramp up & down as well as scaled & unscaled, so just use ramp up unscaled)
            if usescaledramprates==0
                maxrampuprows=find(strcmp(matchingrows(:,phorumpropertynamecol),'Max Ramp Up'));
                maxrampdownrows=find(strcmp(matchingrows(:,phorumpropertynamecol),'Max Ramp Down'));
            elseif usescaledramprates==1
                maxrampuprows=find(strcmp(matchingrows(:,phorumpropertynamecol),'Scaled Max Ramp Up'));
                maxrampdownrows=find(strcmp(matchingrows(:,phorumpropertynamecol),'Scaled Max Ramp Down'));
            end
            maxrampuprows=matchingrows(maxrampuprows,:);
            maxrampdownrows=matchingrows(maxrampdownrows,:);
            capacities=[];
            %Size cutoffs for ramp up & down are the same, so only do this
            %once arbitrarily for up ramp.
            for j=1:size(maxrampuprows,1)
                lowercapac=maxrampuprows{j,phorumlowerplantsizecol};
                uppercapac=maxrampuprows{j,phorumupperplantsizecol};
                capacities=vertcat(capacities,[lowercapac,uppercapac]);
            end %capacities is ordered largest to smallest
            %Find where coal plant falls
            currplantcapacity=futurepowerplantfleet{fleetrow,fleetcapacitycol};
            correctsizerow=currplantcapacity>=capacities(:,1) & currplantcapacity<capacities(:,2);
            matchingrowsrampup=maxrampuprows(correctsizerow,:);
            matchingrowsrampdown=maxrampdownrows(correctsizerow,:);
            %Now add max ramp up & down
            futurepowerplantfleet=AddMaxRampUpUCParameter...
                (futurepowerplantfleet,matchingrowsrampup,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,usescaledramprates);
            futurepowerplantfleet=AddMaxRampDownUCParameter...
                (futurepowerplantfleet,matchingrowsrampdown,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,usescaledramprates);
        end
        
%% OIL
    elseif strcmp(rowfuel,'Oil')
        %ADD MIN STABLE LEVEL
        futurepowerplantfleet=AddMinStableLevelUCParameter...
            (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
            phorumpropertyvaluecol,fleetrow,includeminloadCTmswLFGASfwaste);
        
        %Test for CT vs O/G Steam
        if strcmp(rowplanttype,'Combustion Turbine') %plant size matters sometimes
            %Isolate CT rows
            ctrows=find(strcmp(matchingrows(:,phorumplantcol),'Combustion Turbine'));
            matchingrows=matchingrows(ctrows,:);
            %ADD START COST
            futurepowerplantfleet=AddStartCostUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,includeminloadCTmswLFGASfwaste);
            %ADD RAMP UP AND DOWN
            futurepowerplantfleet=AddMaxRampUpUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,usescaledramprates);
            futurepowerplantfleet=AddMaxRampDownUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,usescaledramprates);
            
            %ADD MIN DOWN TIME
            %Get cutoff capacities
            mindowntimerows=find(strcmp(matchingrows(:,phorumpropertynamecol),'Min Down Time'));
            mindowntimerows=matchingrows(mindowntimerows,:);
            capacities=[];
            for j=1:size(mindowntimerows,1)
                lowercapac=mindowntimerows{j,phorumlowerplantsizecol};
                uppercapac=mindowntimerows{j,phorumupperplantsizecol};
                capacities=vertcat(capacities,[lowercapac,uppercapac]);
            end %capacities is ordered largest to smallest
            %Find where coal plant falls
            currplantcapacity=futurepowerplantfleet{fleetrow,fleetcapacitycol};
            correctsizerow=currplantcapacity>=capacities(:,1) & currplantcapacity<capacities(:,2);
            matchingrowsmindowntime=mindowntimerows(correctsizerow,:);
            %Now add min down time
            futurepowerplantfleet=AddMinDownTimeUCParameter...
                (futurepowerplantfleet,matchingrowsmindowntime,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow);
            
        elseif strcmpi(rowplanttype,'O/G Steam')
            %Isolate O/G Steam rows
            ogsteamrows=find(strcmpi(matchingrows(:,phorumplantcol),'O/G Steam'));
            matchingrows=matchingrows(ogsteamrows,:);
            %ADD START COST
            futurepowerplantfleet=AddStartCostUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,includeminloadCTmswLFGASfwaste);
            %ADD MIN DOWN TIME
            futurepowerplantfleet=AddMinDownTimeUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow);
            %ADD RAMP UP AND DOWN
            futurepowerplantfleet=AddMaxRampUpUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,usescaledramprates);
            futurepowerplantfleet=AddMaxRampDownUCParameter...
                (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
                phorumpropertyvaluecol,fleetrow,usescaledramprates);
        end
%% COAL
%Include coal-to-gas retrofits here, which have NG fuel type & Coal Steam
%plant type
    elseif strcmp(rowfuel,'Coal') || (strcmp(rowfuel,'NaturalGas') && strcmp(rowplanttype,'Coal Steam'))
        %ADD MIN STABLE LEVEL
        futurepowerplantfleet=AddMinStableLevelUCParameter...
            (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
            phorumpropertyvaluecol,fleetrow,includeminloadCTmswLFGASfwaste);
        %ADD START COST
        futurepowerplantfleet=AddStartCostUCParameter...
            (futurepowerplantfleet,matchingrows,phorumpropertynamecol,...
            phorumpropertyvaluecol,fleetrow,includeminloadCTmswLFGASfwaste);
        
        %ADD MIN DOWN TIME
        %Get cutoff capacities
        mindowntimerows=find(strcmp(matchingrows(:,phorumpropertynamecol),'Min Down Time'));
        mindowntimerows=matchingrows(mindowntimerows,:);
        capacities=[];
        for j=1:size(mindowntimerows,1)
            lowercapac=mindowntimerows{j,phorumlowerplantsizecol};
            uppercapac=mindowntimerows{j,phorumupperplantsizecol};
            capacities=vertcat(capacities,[lowercapac,uppercapac]);
        end %capacities is ordered largest to smallest
        %Find where coal plant falls
        currplantcapacity=futurepowerplantfleet{fleetrow,fleetcapacitycol};
        correctsizerow=currplantcapacity>=capacities(:,1) & currplantcapacity<capacities(:,2);
        matchingrowsmindowntime=mindowntimerows(correctsizerow,:);
        %Now add min down time
        futurepowerplantfleet=AddMinDownTimeUCParameter...
            (futurepowerplantfleet,matchingrowsmindowntime,phorumpropertynamecol,...
            phorumpropertyvaluecol,fleetrow);
        
        %ADD RAMP UP AND DOWN
        %Get cutoff capacities (same for ramp up & down as well as scaled & unscaled, so just use ramp up unscaled)
        if usescaledramprates==0
            maxrampuprows=find(strcmp(matchingrows(:,phorumpropertynamecol),'Max Ramp Up'));
            maxrampdownrows=find(strcmp(matchingrows(:,phorumpropertynamecol),'Max Ramp Down'));
        elseif usescaledramprates==1
            maxrampuprows=find(strcmp(matchingrows(:,phorumpropertynamecol),'Scaled Max Ramp Up'));
            maxrampdownrows=find(strcmp(matchingrows(:,phorumpropertynamecol),'Scaled Max Ramp Down'));
        end
        maxrampuprows=matchingrows(maxrampuprows,:);
        maxrampdownrows=matchingrows(maxrampdownrows,:);
        capacities=[];
        %Size cutoffs for ramp up & down are the same, so only do this
        %once arbitrarily for up ramp.
        for j=1:size(maxrampuprows,1)
            lowercapac=maxrampuprows{j,phorumlowerplantsizecol};
            uppercapac=maxrampuprows{j,phorumupperplantsizecol};
            capacities=vertcat(capacities,[lowercapac,uppercapac]);
        end %capacities is ordered largest to smallest
        %Find where coal plant falls
        currplantcapacity=futurepowerplantfleet{fleetrow,fleetcapacitycol};
        correctsizerow=currplantcapacity>=capacities(:,1) & currplantcapacity<capacities(:,2);
        matchingrowsrampup=maxrampuprows(correctsizerow,:);
        matchingrowsrampdown=maxrampdownrows(correctsizerow,:);
        %Now add max ramp up & down
        futurepowerplantfleet=AddMaxRampUpUCParameter...
            (futurepowerplantfleet,matchingrowsrampup,phorumpropertynamecol,...
            phorumpropertyvaluecol,fleetrow,usescaledramprates);
        futurepowerplantfleet=AddMaxRampDownUCParameter...
            (futurepowerplantfleet,matchingrowsrampdown,phorumpropertynamecol,...
            phorumpropertyvaluecol,fleetrow,usescaledramprates);

%% FUEL TYPE NOT INCLUDED IN UC PARAMETERS FILE    
    else
        'WARNING: UC PARAMETERS MISSING FOR A FUEL TYPE (SHOWN BELOW)!'
        rowfuel
    end
end

%% SET RUN UP AND RUN DOWN RATES 
%AS OF AUGUST 5, 2015, DON'T USE RUN UP AND DOWN RATES IN MODEL.
%Problem in PLEXOS is that run up & run down rates are only enforced if the
%run up and run down rate is < min stable load. Otherwise, the default UC
%formulation is used, in which a generator starting up can reach min load +
%1 hour of ramping. With the scaled-up ramp rates, run up and run down
%rates weren't even being used at all anyways because all plant types can
%reach their min load within an hour, meaning run up & down rates were not
%included in the formulation. The exception here is nuclear, but I'd rather
%treat nuclear w/ min load + ramp rate than run up rate. 

% %PLEXOS by default allows plants to ramp up from off and down to off
% %instantaneously; thus, a plant that starts up can reach its min load + its
% %max ramp rate in 1 hour. The same applies for shutting down.
% %Run Up Rate and Run Down Rate override this behavior for start ups & shut
% %downs by defining a max rate the plant can ramp at when starting up or
% %shutting down. David Luke Oates in his paper on wind and coal cycling sets
% %the max power generation a plant can reach at start-up to the max of its
% %lower operating limit (min load) or ramp up value. I do the same here.
% %RunUpRate=max(MinLoad,MaxRampUp). RunDownRate=max(MinLoad,MaxRampDown).
% %The only exception to this is for nuclear plants - I set their Run Up &
% %Down Rates to their ramp rates, since taking a nuclear plant from 0 to 90%
% %capacity is unrealistic.
% %Run up & down rates are defined as MW/min., just like the ramp rates.
% 
% 
% %Get columns for run up & down rates and capac and ramp up/down cols for
% %calculation
% runupratecol=find(strcmp(futurepowerplantfleet(1,:),'Run Up Rate'));
% rundownratecol=find(strcmp(futurepowerplantfleet(1,:),'Run Down Rate'));
% minstablelevelcol=find(strcmp(futurepowerplantfleet(1,:),'Min Stable Level'));
% rampupcol=find(strcmp(futurepowerplantfleet(1,:),'Max Ramp Up'));
% rampdowncol=find(strcmp(futurepowerplantfleet(1,:),'Max Ramp Down'));
% fueltypecol=find(strcmp(futurepowerplantfleet(1,:),'FuelType'));
% 
% %Set values in for loop
% for i=2:size(futurepowerplantfleet,1)
%     %Test if nuclear plant - if nuke, then set run up & down values to
%     %ramps, else use max of ramp & min load values.
%     if strcmp(futurepowerplantfleet{i,fueltypecol},'Nuclear')
%         futurepowerplantfleet{i,runupratecol}=futurepowerplantfleet{i,rampupcol};
%         futurepowerplantfleet{i,rundownratecol}=futurepowerplantfleet{i,rampdowncol};
%     else
%         %Need value in MW/min. Ramp rates already in MW/min., so adjust
%         %minstablelevel value to MW/min. by dividing by 60 mins/hr.
%         minstablelevelconverted=futurepowerplantfleet{i,minstablelevelcol}/60;
%         %Now compare values
%         futurepowerplantfleet{i,runupratecol}=max(minstablelevelconverted,...
%             futurepowerplantfleet{i,rampupcol});
%         futurepowerplantfleet{i,rundownratecol}=max(minstablelevelconverted,...
%             futurepowerplantfleet{i,rampdowncol});
%     end
% end






