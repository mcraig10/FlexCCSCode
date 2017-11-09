%Michael Craig
%January 21, 2015
%This script will, depending on an input parameter, add a set of new power
%plants to the set of existing power plants still operating in 2025
%according to the EPA's CPP Parsed File. First, the script separates out
%new plants in the CPP. Then, depending on the input parameter, it either:
%-Processes and adds those new CPP plants back in. This entails splitting
%up conventional units that are way too large, as well as aggregating new
%wind facilities and splitting them up into reasonably-sized wind farms.
%-Adds CCS facilities (not yet implemented)
%-Adds gas facilities (not yet implemented)

function [futurepowerplantfleet] = AddNewPlantsToFutureFleet(parseddataworetiredwadjustmentsiso, pc)
%templatefornewplantsinfuturefleet will be an indicator for which type of
%new fleet to add - NOT YET IMPLEMENTED

%% GET DATA COLUMNS OF INTEREST IN parseddataworetiredwadjustmentsiso
[parseddataorisidcol,parseddataunitidcol,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(parseddataworetiredwadjustmentsiso);

%% SEPARATE OLD FROM NEW PLANTS IN CPP PARSED FILE
%New plants are identified by not having an ORIS code - so ORIS column will
%be blank. 
parseddatanewplants=parseddataworetiredwadjustmentsiso(1,:);
parseddataexistingplants=parseddataworetiredwadjustmentsiso(1,:);
for i=2:size(parseddataworetiredwadjustmentsiso,1)
    if strcmp(parseddataworetiredwadjustmentsiso{i,parseddataorisidcol},'')
        parseddatanewplants(end+1,:)=parseddataworetiredwadjustmentsiso(i,:);
    else
        parseddataexistingplants(end+1,:)=parseddataworetiredwadjustmentsiso(i,:);
    end
end

%% DELETE NEW HYDRO FACILITIES
%IPM projects 2 GW of extra hydro; don't believe this is realistic, so
%delete.
hydrorows=find(strcmp(parseddatanewplants(:,parseddatafueltypecol),'Hydro'));
parseddatanewplants(hydrorows,:)=[];

%% PROCESS NEW CONVENTIONAL PLANTS
%The dataset has some very very large conventional plants (many GWs) and
%some very very small plants (0.04 MW). Need to filter out the tiny ones,
%say, <10 MW, and split up very large ones. MISO does not actually have any
%of the very large conventional plants, but will write code for it anyways.
%Set plant size limit at which plant is broken up, and size of plants into
%which it will be broken up.
plantsizelimit=800; plantsizetobedividedinto=250; 
%For tagging copied plants
parseddataplantnamecol=find(strcmp(parseddatanewplants(1,:),'PlantName'));
for i=size(parseddatanewplants,1):-1:1
    %Pick out fossil-fueled plants
    if strcmp(parseddatanewplants{i,parseddatafossilunitcol},'Fossil')
        %Eliminate new fossil fuel plants that are <10 MW
        if parseddatanewplants{i,parseddatacapacitycol}<10
            parseddatanewplants(i,:)=[];
            %Break up new plants that are > 800 MW into 250-MW plants (most
            %NGCCs recently built (per NEEDS) are between 150 & 300 MW).
        elseif parseddatanewplants{i,parseddatacapacitycol}>plantsizelimit
            %Get size of plant
            currplantcapacity=parseddatanewplants{i,parseddatacapacitycol};
            %Determine # of new plants. Evenly divide "remaining" capacity
            %(i.e., remainder of division) amongst all plants.
            numnewplants=floor(currplantcapacity/plantsizetobedividedinto);
            capacofnewplants=plantsizetobedividedinto+...
                rem(currplantcapacity,plantsizetobedividedinto)/numnewplants;
            %Copy current row to create new plants. First shift rows down
            parseddatanewplants(i+(numnewplants-1):end+(numnewplants-1),:) = parseddatanewplants(i:end,:);
            for j=0:(numnewplants-1)
                %Now add in rows as duplicates of current row. Start with
                %current row in order to change capacity
                parseddatanewplants(i+j,:) = parseddatanewplants(i,:);
                parseddatanewplants{i+j,parseddatacapacitycol}=capacofnewplants; %change capac
                parseddatanewplants{i+j,parseddataplantnamecol}='NewCOPY'; %tag as copy
            end
        end
    end
end


%% PROCESS NEW WIND PLANTS
%Many very small wind farms in the same state are constructed by IPM. I
%want to aggregate these farms by state, and then, if necessary, re-divide
%them into reasonably-sized wind farms.
totalnewwindcapacitybystate=unique(parseddatanewplants(2:end,parseddatastatecol));
totalnewwindcapacitybystate{1,2}={}; %initialize second column
for i=size(parseddatanewplants,1):-1:1
    if strcmp(parseddatanewplants{i,parseddatafueltypecol},'Wind')  %pick out wind plants, determine total capacity
        staterowinwindcapacarray=find(strcmp(totalnewwindcapacitybystate(:,1),parseddatanewplants{i,parseddatastatecol}));
        if isempty(totalnewwindcapacitybystate{staterowinwindcapacarray,2})
            totalnewwindcapacitybystate{staterowinwindcapacarray,2}=...
                parseddatanewplants{i,parseddatacapacitycol};
        else
            totalnewwindcapacitybystate{staterowinwindcapacarray,2}=...
                totalnewwindcapacitybystate{staterowinwindcapacarray,2}+...
                parseddatanewplants{i,parseddatacapacitycol};
        end
        %Eliminate row
        parseddatanewplants(i,:)=[];
    end
end

windfarmsizelimit=500; %size at which total wind capacity is divided
windfarmsizetobedividedinto=250; %size into which total wind capacity is divided if necessary
%Now add new wind plants back into future fleet array
for i=1:size(totalnewwindcapacitybystate,1)
    %Get current total state wind capacity and current state
    currstatewindcapac=totalnewwindcapacitybystate{i,2};
    currstate=totalnewwindcapacitybystate{i,1};
    %If there's wind capacity in state, need to add plants; if not, just
    %don't do anything, so no wind plants will be added to fleet from that
    %state.
    if isempty(currstatewindcapac)==0 %if not empty
        %If wind capacity in 1 state needs to be divided up
        if currstatewindcapac>windfarmsizelimit
            %Determine # of new plants. Evenly divide "remaining" capacity
            %(i.e., remainder of division) amongst all plants.
            numnewplants=floor(currstatewindcapac/windfarmsizetobedividedinto);
            capacofnewplants=windfarmsizetobedividedinto+...
                rem(currstatewindcapac,windfarmsizetobedividedinto)/numnewplants;
            %Create new rows
            for j=0:(numnewplants-1)
                [parseddatanewplants]=AddSingleNewPlantIntoFutureFleetCellArray(parseddatanewplants,...
                    'Onshore Wind',currstate,capacofnewplants);
            end
        else %if wind capacity is enough for 1 farm
            %Add new row
            [parseddatanewplants]=AddSingleNewPlantIntoFutureFleetCellArray(parseddatanewplants,...
                'Onshore Wind',currstate,currstatewindcapac);
        end
    end
end

%% ASSIGN HEAT RATES TO NEW CONVENTIONAL PLANTS
%Use IPM generic plant data (Table 4-13 in IPM documentation):
if strcmp(pc,'work')
    ipmgenericplantdatafilename='C:\Users\mtcraig\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\GenericPowerPlantCharacteristicsDataIPM.xlsx';
elseif strcmp(pc,'personal')
    ipmgenericplantdatafilename='C:\Users\mcraig10\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\GenericPowerPlantCharacteristicsDataIPM.xlsx';
end
[~,~,ipmgenericplantdata]=xlsread(ipmgenericplantdatafilename,'Sheet1');
%Row 1 = eliminate. Col 1 = 'Plant Type', col 2 = 'Size (MW)', col 3 =
%'Heat Rate (BTU/kWh)', Col 6 = 'Var O&M (2011$/mwh)'
%Eliminate row 1
ipmgenericplantdata(1,:)=[];
%Get cols
ipmgenericplantdataplanttypecol=find(strcmp(ipmgenericplantdata(1,:),'Plant Type'));
ipmgenericplantdataheatratecol=find(strcmp(ipmgenericplantdata(1,:),'Heat Rate (BTU/kWh)'));
ipmgenericplantdatavaromcol=find(strcmp(ipmgenericplantdata(1,:),'Var O&M (2011$/mwh)'));
% %CPP parsed file new plant plant types
% cppplanttypes={'Coal Steam'; 'IGCC';'Landfill Gas';'Combined Cycle';'Biomass';'Combustion Turbine'};

%EPA IPM plant type names - matched up names in ipmgenericplantdatafilename
%with the above CPP plant type names.
%Step through new plants and match up to IPM plant types.
parseddatavomcol=find(strcmp(parseddatanewplants(1,:),'VOMPerMWhCalculated'));
for i=1:size(parseddatanewplants,1)
    currplanttype=parseddatanewplants{i,parseddataplanttypecol};
    %If unit is one of the CPP plant types looking for
    if find(strcmp(ipmgenericplantdata(:,ipmgenericplantdataplanttypecol),currplanttype))
        cppplanttyperow=find(strcmp(ipmgenericplantdata(:,ipmgenericplantdataplanttypecol),currplanttype));
        %Set parameters
        parseddatanewplants{i,parseddataheatratecol}=ipmgenericplantdata{cppplanttyperow,ipmgenericplantdataheatratecol};
        parseddatanewplants{i,parseddatavomcol}=ipmgenericplantdata{cppplanttyperow,ipmgenericplantdatavaromcol};
    end
end


%% ASSIGN FAKE ORIS IDS TO ALL UNITS AND UNIT ID OF 1
%Max ORIS ID for existing plants is 83846. So start assigning ORIS IDs at
%100000.
currorisid=100000;
for i=2:size(parseddatanewplants,1)
    %Add ORIS
    parseddatanewplants{i,parseddataorisidcol}=num2str(currorisid);
    currorisid=currorisid+1;
    %Add unit ID 
    parseddatanewplants{i,parseddataunitidcol}='1';
end


%% COMBINE OLD AND NEW PLANTS TO CREATE POWER PLANT FLEET
%Only include 2:end of second guy so don't get double header
futurepowerplantfleet=vertcat(parseddataexistingplants,parseddatanewplants(2:end,:));




