%Michael Craig
%1/18/15
%EMISSIONS RATE ADDITION SCRIPT
%This function imports a cell array w/ a power system fleet, and then adds
%emissions rate columsn to the end of that fleet. 
%For plants w/ emissions & generation data, emissions rates are calculated
%by dividing total annual emissions by total annual electricity generation,
%except for coal plants. This approach implicitly accepts any heat rate
%modifications done inside IPM. So, for coal plants, an assumed 6% HR
%improvement will implicitly be included in an emissions rate estimated as
%above. Thus, for coal plants, I adjust their emissions rates upwards by 6%
%, then re-adjust downard by an input defined hr improvement. 
%For plants w/ no emissions data, a fleet-wide capacity-weighted average
%emissions rate on the basis of lb/heat input for generators w/ same fuel
%and plant type is calculated, and then heat rates of each generators are
%used to calculate unit-specific emissions rates.  
%NOTE: emissions rates for oil CTs & O/G Steam turbines are hardcoded
%below.

function [futurepowerfleetforplexos] = AddEmissionsRatesToFleet...
    (futurepowerfleetforplexos, hrimprovement, hrimprovementassumedbyepa)

%Get data columns of interest
[parseddataorisidcol,parseddataunitidcol,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);

%Identify columns w/ aggregate emissions and electricity generation data
co2emissionscol=find(strcmp(futurepowerfleetforplexos(1,:),'CO2Total'));
noxemissionscol=find(strcmp(futurepowerfleetforplexos(1,:),'NOXTotal'));
so2emissionscol=find(strcmp(futurepowerfleetforplexos(1,:),'SO2Total'));
elecgencol=find(strcmp(futurepowerfleetforplexos(1,:),'GWhTotal'));
heatinputcol=find(strcmp(futurepowerfleetforplexos(1,:),'FuelUseTotal'));
%Emissions values are given in MTons (1000 short tons).

%Add columns to end of fleet for emissions rates
noxemsratecol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,noxemsratecol}='NOxEmsRate(kg/mwh)';
so2emsratecol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,so2emsratecol}='SO2EmsRate(kg/mwh)';
co2emsratecol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,co2emsratecol}='CO2EmsRate(kg/mwh)';

%Need to handle plants that have no generation and therefore no emissions.
%Do this by using fleet-wide emission rate averages calculated
%as emissions over heat INPUT - this will account for different heat
%rates of different facilities. For coal, would need to control for
%CTs and what not, but there would only be very few coal plants with no generation
%under Option 1, so set each one to average emissions rate of all coal
%plants. (In MISO, 0 coal plants that don't generate any power).
%Same for NGCCs (in MISO, no NGCCs don't generate power). Then lots of oil & gas
%CTs & O/G Steam turbines, so set those to fleet-wide averages. For
%these plants, don't need to worry about control technologies since most
%plants don't use any CTs.


%% PLANTS WITH GENERATION
%Loop through fleet and calculate emissions rates, ignoring plants that
%don't generate anything for now
tontokg=907.185;
for i=2:size(futurepowerfleetforplexos,1)
    %If no generation at plant, set emissions rate to zero, else calculate
    %emissions rate.
    if futurepowerfleetforplexos{i,elecgencol}==0
        futurepowerfleetforplexos{i,noxemsratecol}=0;
        futurepowerfleetforplexos{i,so2emsratecol}=0;
        futurepowerfleetforplexos{i,co2emsratecol}=0;
    else 
        %Emissions given in 1000s short tons (=Mton). Generation in GWh.
        %Dividing two values gives Mton/GWh = ton/MWh. Convert to kg/MWh
        %with factor of 1 ton = 907.185 kg. So multiply by 907.185.
        futurepowerfleetforplexos{i,noxemsratecol}=...
            futurepowerfleetforplexos{i,noxemissionscol}/futurepowerfleetforplexos{i,elecgencol}*tontokg;
        futurepowerfleetforplexos{i,so2emsratecol}=...
            futurepowerfleetforplexos{i,so2emissionscol}/futurepowerfleetforplexos{i,elecgencol}*tontokg;
        futurepowerfleetforplexos{i,co2emsratecol}=...
            futurepowerfleetforplexos{i,co2emissionscol}/futurepowerfleetforplexos{i,elecgencol}*tontokg;
    end
    
    %For coal plants, if have HR Improvement retrofit, modify emissions rates by increasing to negate 6% HR
    %improvement assumption, then re-adjust downwards for input HR
    %improvement assumption. 
    if strcmp(futurepowerfleetforplexos{i,parseddatafueltypecol},'Coal')
        if isempty(findstr(futurepowerfleetforplexos{i,parseddataretrofitcol},'Heat Rate Improvement'))==0
            %Adjust emissions rates upwards by dividing by
            %1-hrimprovementassumedbyepa, then re-multiplying by
            %1-hrimprovement (what we want to set it to)
            futurepowerfleetforplexos{i,noxemsratecol}=...
                (futurepowerfleetforplexos{i,noxemsratecol}/(1-hrimprovementassumedbyepa))*(1-hrimprovement);
            futurepowerfleetforplexos{i,so2emsratecol}=...
                (futurepowerfleetforplexos{i,so2emsratecol}/(1-hrimprovementassumedbyepa))*(1-hrimprovement);
            futurepowerfleetforplexos{i,co2emsratecol}=...
                (futurepowerfleetforplexos{i,co2emsratecol}/(1-hrimprovementassumedbyepa))*(1-hrimprovement);
        end
    end
end


%% PLANTS WITHOUT GENERATION
%Now get fleet-wide capacity-weighted average values by fuel and plant type. Calculate
%average emission rate based on fuel input, i.e. emission factor. Will then
%multiply by heat rate to get emission rate.
%First, get unique list of fuel types. Then isolate plants of that fuel
%type. Then get unique plant types for that fuel type. Then, for each
%unique plant type, isolate data, isolate emission rate values greater than
%zero, and then average them.
uniquefueltypes=unique(futurepowerfleetforplexos(2:end,parseddatafueltypecol));
lbtokg=.453592;
%Iterate through fuel types
for i=1:size(uniquefueltypes,1)
    currfueltype=uniquefueltypes(i);
    %Check to make sure fuel type is not wind, solar, geothermal or nuclear
    %(b/c emissions rates are 0 for everything).
    if strcmp(currfueltype,'Wind')==0 &  strcmp(currfueltype,'Solar')==0 & strcmp(currfueltype,'Nuclear')==0 &  ...
            strcmp(currfueltype,'Geothermal')==0 & strcmp(currfueltype,'Hydro')==0
        %Isolate plants of fuel type
        plantsoffueltype=futurepowerfleetforplexos(find(strcmpi(futurepowerfleetforplexos(:,parseddatafueltypecol),currfueltype)),:);
        %Check if any plants have a zero power generation value in current set
        tempelecgen=cell2mat(plantsoffueltype(:,elecgencol));
        if min(tempelecgen)==0 %only need to get fleet-wide averages if a plant is missing a CO2 emissions rate
            %Get plant types
            uniqueplanttypes=unique(plantsoffueltype(:,parseddataplanttypecol));
            %Iterate over plant types
            for j=1:size(uniqueplanttypes,1)
                currplanttype=uniqueplanttypes(j);
                %Isolate plant types
                %If coal-to-gas retrofit, has NG fuel type & Coal Steam
                %plant type; want to use NGCT emissions rates for these
                %units.
                if strcmp(currfueltype,'NaturalGas') && strcmp(currplanttype,'Coal Steam')
                    plantsofplanttype=plantsoffueltype(find(strcmpi(plantsoffueltype(:,parseddataplanttypecol),'O/G Steam')),:);
                else
                    plantsofplanttype=plantsoffueltype(find(strcmpi(plantsoffueltype(:,parseddataplanttypecol),currplanttype)),:);
                end
                %Check if any plants in curr plant type have zero emissions
                %rate.
                tempelecgen=cell2mat(plantsofplanttype(:,elecgencol));
                if min(tempelecgen)==0
                    %Check if oil - oil CTs & O/G Steam turbines do not generate any
                    %power in Option 1, so need to get their emissions rates from
                    %another source. Use AP-42 emissions factors for
                    %Stationary Gas Turbines that are Distillate-Oil Fired
                    %(Table 3.1-1 for NOx, Table 3.1-2a for CO2 & SO2, EPA,
                    %AP-42). 
                    if strcmpi(currfueltype,'Oil')
                        %Note that this groups CTs & O/G Steam turbines
                        %together.
                        %Values are in lb/MMBTU for uncontrolled turbines.
                        avgnoxemrates=8.8E-1;
                        avgco2emrates=157; 
                        avgso2emrates=3.3E-2; %see footnote h
                        %Convert values from lb/MMBTU to kg/Btu: 
                        %lb/MMBtu * 0.45 kg/lb * MMBtu/1E6Btu
                        avgnoxemrates=avgnoxemrates*lbtokg/1E6;
                        avgco2emrates=avgco2emrates*lbtokg/1E6; 
                        avgso2emrates=avgso2emrates*lbtokg/1E6;     
                    else
                        %Get capacity-weighted average emissions rates for those plant types.
                        %Need to calculate emissions rates as total NOx
                        %emissions / total fuel input. Want value in
                        %kg/Btu (since HR which will be used below is in
                        %Btu/kWh).
                        %Units: 1000 short tons/TBtu = short ton/GBtu * 907
                        %kg/short ton = kg/GBtu * GBtu/1E9 Btu
                        
                        %Calculate capacity weights
                        tempheatinput=cell2mat(plantsofplanttype(:,heatinputcol));
                        tempcapacity=cell2mat(plantsofplanttype(:,parseddatacapacitycol));
                        rowstokeep=tempheatinput>0; %eliminate rows without any heat input - don't want them in average
                        tempcapacity=tempcapacity(rowstokeep);
                        temptotalcapacity=sum(tempcapacity);
                        capacityweights=tempcapacity/temptotalcapacity;
                        
                        %Calculate capacity-weighted average.
                        tempnoxems=cell2mat(plantsofplanttype(:,noxemissionscol));
                        tempnoxemratesinput=tempnoxems./tempheatinput;
                        tempnoxemratesinput=tempnoxemratesinput(rowstokeep);                         
                        if isempty(tempnoxemratesinput)
                            avgnoxemrates=0;
                        else
                            avgnoxemrates=sum(capacityweights.*tempnoxemratesinput);
                        end
                        avgnoxemrates=avgnoxemrates*tontokg/1E9; %kg/Btu
                        
                        tempso2ems=cell2mat(plantsofplanttype(:,so2emissionscol));
                        tempso2emratesinput=tempso2ems./tempheatinput;
                        tempso2emratesinput=tempso2emratesinput(rowstokeep); %remove zeros
                        if isempty(tempso2emratesinput)
                            avgso2emrates=0;
                        else
                            avgso2emrates=sum(capacityweights.*tempso2emratesinput);
                        end
                        avgso2emrates=avgso2emrates*tontokg/1E9; %kg/Btu
                        
                        tempco2ems=cell2mat(plantsofplanttype(:,co2emissionscol));
                        tempco2emratesinput=tempco2ems./tempheatinput;
                        tempco2emratesinput=tempco2emratesinput(rowstokeep); %remove zeros
                        if isempty(tempco2emratesinput)
                            avgco2emrates=0;
                        else
                            avgco2emrates=sum(capacityweights.*tempco2emratesinput);
                        end
                        avgco2emrates=avgco2emrates*tontokg/1E9; %kg/Btu
                    end
                    
                    %Now replace emissions rates of plants w/out emissions rates
                    %Get plants w/ current fuel & plant type
                    rowsinfuturefleet=find(strcmpi(futurepowerfleetforplexos(:,parseddatafueltypecol),currfueltype) & ...
                        strcmpi(futurepowerfleetforplexos(:,parseddataplanttypecol),currplanttype));
                    %Iterate over rows, check if zero power generation, and if
                    %so replace emissions rates. (Don't check emissions rates
                    %directly because sometimes, will have 0 SO2 emissions even
                    %though generated power - want to preserve this.)
                    for z=1:size(rowsinfuturefleet,1)
                        currrow=rowsinfuturefleet(z);
                        if futurepowerfleetforplexos{currrow,elecgencol}==0
                            %Need to convert emission factor from kg/Btu to
                            %kg/MWh using heat rate of plant.
                            %kg/Btu * Btu/kWh * 1000 kWh/MWh
                            currheatrate=futurepowerfleetforplexos{currrow,parseddataheatratecol};
                            futurepowerfleetforplexos{currrow,co2emsratecol}=avgco2emrates*currheatrate*1000;
                            futurepowerfleetforplexos{currrow,noxemsratecol}=avgnoxemrates*currheatrate*1000;
                            futurepowerfleetforplexos{currrow,so2emsratecol}=avgso2emrates*currheatrate*1000;
                        end
                    end
                end
            end
        end
    end
end




















