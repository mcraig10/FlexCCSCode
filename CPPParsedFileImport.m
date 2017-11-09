%Michael Craig
%1/18/15
%PARSED FILE IMPORT SCRIPT

function [parseddataworetiredwadjustmentsiso] = CPPParsedFileImport...
    (compliancescenario,hrimprovement,modelmisowithfullstates,pc)

%This script will import the parsed file for the CPP. It will conduct some
%processing of this file - remove retirements, adjust heat rates to account
%for retrofits, etc. - to create a 2025 fleet.

%% IMPORT FILES
if strcmp(pc,'work')
    parseddir='C:\Users\mtcraig\Desktop\EPP Research\Databases\EPA IPM Final Clean Power Plan Files\ParsedFiles';
elseif strcmp(pc,'personal')
    parseddir='C:\Users\mtcraig\Desktop\EPP Research\Databases\EPA IPM Final Clean Power Plan Files\ParsedFiles';
end
if strcmp(compliancescenario,'Mass')
    parsedfile=fullfile(parseddir,'ParsedMassFinal2030.xlsx');
    [~,~,parseddataall]=xlsread(parsedfile,'ParsedFile_Mass-Based_2030');
elseif strcmp(compliancescenario,'Base');
    parsedfile=fullfile(parseddir,'ParsedBaseFinal2030.xlsx');
    [~,~,parseddataall]=xlsread(parsedfile,'ParsedFile_Base Case_2030');
end

%Get data columns of interest
[parseddataorisidcol,parseddataunitidcol,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(parseddataall);
%For this script, also need whether retrofit scrubber is wet or dry (to
%figure out HR penalty) - in column 'Post Combustion Control (Scrubber:
%Wet/Dry)'. This is filled out for retrofits.
parseddatascrubbertypecol=find(strcmp(parseddataall(1,:),'Post Combustion Control (Scrubber: Wet/Dry)'));


%% ELIMINATE RETIREMENTS FROM DATASET
%Have word 'Retirement' in retrofit column. Preceded with Nuke, Coal, etc.
parseddataworetired=parseddataall;
rowstoremove=[];
for i=size(parseddataworetired,1):-1:2
    %Findstr returns integer if it finds the string (i.e., if plant is retired). If string isn't
    %found (if plant isn't retired), returns empty array. 
    if isempty(findstr(parseddataworetired{i,parseddataretrofitcol},'Retirement'))==0
        rowstoremove(end+1,1)=i;
    end
end
parseddataworetired(rowstoremove,:)=[];


%% ELIMINATE ENERGY EFFCIIENCY FROM DATASET
%Parsed file for final rule has some untis w/ EE - labeled as 'New Energy
%Efficiency'
eerows=find(strcmp(parseddataworetired(:,parseddataplanttypecol),'New Energy Efficiency'));
parseddataworetired(eerows,:)=[];

%% ELIMINATE IMPORT FROM DATASET
%1 plant w/ plantype 'Import'
importrows=find(strcmp(parseddataworetired(:,parseddataplanttypecol),'Import'));
parseddataworetired(importrows,:)=[];

%% REDUCE HEAT RATE TO ACCOUNT FOR RETROFIT TECHNOLOGIES OR HEAT RATE IMPROVEMENTS
%Reduce heat rate to account for retrofit technologies. IPM defines heat
%rate penalty such that:
%NHR = OHR / (1 - HRPenalty)    where OHR = old heat rate & NHR = new heat
%rate. In other words, "the unit's heat rate is scaled up such that a
%comparable reduction in the new higher heat rate yields the original heat
%rate."

%IPM Documentation lists HR penalty for scrubber (wet & dry) ~ 1.6%; for SCR varies by HR; for SNCR
%0.78%. ACI (Hg control) impacts depend on existing / added other control
%techs; IPM page 5-23, Table 5-14). DSI impacts are on page 5-31, Table
%5-17). See Tables 5-3 and 5-6 for scrubber & SCR data. 
%Also account for heat rate improvement. In Option 1 analysis, HR improvement is
%modeled in IPM at 6% - use that value here. (See IPM CPP supplemental
%documentation.)
hrpenaltyscr=[9000 .54/100; 10000 .56/100; 11000 .59/100]; %col 1 = HR, col 2 = % HR penalty. Table 5-6.
hrpenaltysncr=0.78/100; %Table 5-6, same for all heat rates & capacities
%For scrubber penalties, values given for LSFO (wet) and LSD (dry). Most
%scrubbers in Parsed file are wet, so use data for wet (LSFO) scrubber.
hrpenaltyscrubberwet=[9000 1.53/100; 10000 1.70/100; 11000 1.87/100]; %LSFO, Table 5-3
hrpenaltyscrubberdry=[9000 1.20/100; 10000 1.33/100; 11000 1.47/100]; %LSD, Table 5-3
%ACI penalties depend on other control techs. For now, ignore additional
%baghouse.
hrpenaltyaciwithexistingesp=[9000 .1/100; 10000 .11/100; 11000 .12/100];
hrpenaltyaciwithexistingbaghouse=[9000 .04/100; 10000 .04/100; 11000 .05/100];
hrpenaltyaciwithadditionalbaghouse=[9000 .64/100; 10000 .65/100; 11000 .65/100]; %never used
%For ACI, also need to look at Baghouse Retrofit column; other retrofit
%column only lists Mercury Control, but this can be done thorugh non-ACI
%means, and ACI is only listed in Baghouse column. Also need EMFControls
%column to see if FF or ESP already installed.
baghouseretrofitcol=find(strcmp(parseddataworetired(1,:),'Baghouse Retrofit (in conjunction with either dry FGD, ACI+Toxecon, and/or DSI)'));
emfcontrolcol=find(strcmp(parseddataworetired(1,:),'EMFControls'));
%DSI penalty assumes bituminous coal
hrpenaltydsi=[9000 .65/100; 10000 .72/100; 11000 .79/100];
parseddataworetiredwadjustments=parseddataworetired;
%For each generator, check if has any retrofits; for each retrofit, adjust
%HR.
for i=2:size(parseddataworetiredwadjustments,1)
    if isempty(findstr(parseddataworetiredwadjustments{i,parseddataretrofitcol},'SCR'))==0
        currhr=parseddataworetiredwadjustments{i,parseddataheatratecol}; %include this in each if statement so use updated HR if have multiple techs.
        %Need to match plant HR to closest HR for determining penalty. Do
        %this by finding distance between currhr and each HR in penalty
        %array, and min abs val is the one we want.
        [~,temprow]=min(abs(hrpenaltyscr(:,1)-currhr)); %temprow is the index of the min value, i.e. closest HR
        currhrpenalty=hrpenaltyscr(temprow,2);
        parseddataworetiredwadjustments{i,parseddataheatratecol}=...
            parseddataworetiredwadjustments{i,parseddataheatratecol}*(1+currhrpenalty);
    end
    if isempty(findstr(parseddataworetiredwadjustments{i,parseddataretrofitcol},'SNCR'))==0
        currhr=parseddataworetiredwadjustments{i,parseddataheatratecol};
        parseddataworetiredwadjustments{i,parseddataheatratecol}=...
            parseddataworetiredwadjustments{i,parseddataheatratecol}*(1+hrpenaltysncr);
    end
    if isempty(findstr(parseddataworetiredwadjustments{i,parseddataretrofitcol},'Scrubber'))==0
        %Varies by HR, so match HR. See SCR above for explanation.
        currhr=parseddataworetiredwadjustments{i,parseddataheatratecol};
        %If dry scrubber
        if isempty(findstr(parseddataworetiredwadjustments{i,parseddatascrubbertypecol},'Dry'))==0
            [~,temprow]=min(abs(hrpenaltyscrubberdry(:,1)-currhr)); 
            currhrpenalty=hrpenaltyscrubberdry(temprow,2);
        elseif isempty(findstr(parseddataworetiredwadjustments{i,parseddatascrubbertypecol},'Wet'))==0 %wet scrubber
            [~,temprow]=min(abs(hrpenaltyscrubberwet(:,1)-currhr));
            currhrpenalty=hrpenaltyscrubberwet(temprow,2);
        else
            'Unaccounted for Scrubber Type! See CPPParsedFileImport script'
        end
        parseddataworetiredwadjustments{i,parseddataheatratecol}=...
            parseddataworetiredwadjustments{i,parseddataheatratecol}*(1+currhrpenalty);
    end
    if isempty(findstr(parseddataworetiredwadjustments{i,parseddataretrofitcol},'DSI'))==0
        currhr=parseddataworetiredwadjustments{i,parseddataheatratecol};
        [~,temprow]=min(abs(hrpenaltydsi(:,1)-currhr)); %temprow is the index of the min value, i.e. closest HR
        currhrpenalty=hrpenaltydsi(temprow,2);
        parseddataworetiredwadjustments{i,parseddataheatratecol}=...
            parseddataworetiredwadjustments{i,parseddataheatratecol}*(1+currhrpenalty);
    end
    if isempty(findstr(parseddataworetiredwadjustments{i,baghouseretrofitcol},'ACI'))==0 %ACI
        currhr=parseddataworetiredwadjustments{i,parseddataheatratecol};
        %Figure out row of HR penalty array here, b/c all three arrays for
        %ACI have same HR values, so only need code once.
        [~,temprow]=min(abs(hrpenaltyaciwithexistingesp(:,1)-currhr)); %temprow is the index of the min value, i.e. closest HR
        %Now test for 3 pollution control cases
        if isempty(findstr(parseddataworetiredwadjustments{i,emfcontrolcol},'ESP'))==0 %ESP already installed
            currhrpenalty=hrpenaltyaciwithexistingesp(temprow,2);
        elseif isempty(findstr(parseddataworetiredwadjustments{i,emfcontrolcol},'Baghouse'))==0 %Fabric Filter already installed
            currhrpenalty=hrpenaltyaciwithexistingbaghouse(temprow,2);
        else %install additional baghouse
            currhrpenalty=hrpenaltyaciwithadditionalbaghouse(temprow,2);
        end
        parseddataworetiredwadjustments{i,parseddataheatratecol}=...
            parseddataworetiredwadjustments{i,parseddataheatratecol}*(1+currhrpenalty);
    end
    if isempty(findstr(parseddataworetiredwadjustments{i,parseddataretrofitcol},'Heat Rate Improvement'))==0
        currhr=parseddataworetiredwadjustments{i,parseddataheatratecol};
        parseddataworetiredwadjustments{i,parseddataheatratecol}=...
            parseddataworetiredwadjustments{i,parseddataheatratecol}*(1-hrimprovement);
    end
end

%% CALCULATE VARIABLE O&M PER MWH
%Need to add a column in the parsed file for this - add at very end. This
%will be a variable O&M value in $/MWh. Calculate by dividing 'VOMCostTotal'
%(million$/yr),  which is total VOM cost for entire year (winter + summer),
%with 'GWhTotal', which is projected generation by unit during year.
%Add column. Exclude wind and solar from calculation.
vomcalculatedcolumnlabel='VOMPerMWhCalculated';
parseddataworetiredwadjustments{1,end+1}=vomcalculatedcolumnlabel;
%Get columns for calc
vomcalculatedcol=find(strcmp(parseddataworetiredwadjustments(1,:),vomcalculatedcolumnlabel));
vomtotalcol=find(strcmp(parseddataworetiredwadjustments(1,:),'VOMCostTotal'));
gwhtotalcol=find(strcmp(parseddataworetiredwadjustments(1,:),'GWhTotal'));
for i=2:size(parseddataworetiredwadjustments,1)
    if strcmp(parseddataworetiredwadjustments{i,parseddatafueltypecol},'Wind')==0 ||...
            strcmp(parseddataworetiredwadjustments{i,parseddatafueltypecol},'Solar')==0
        %If plant actually has generation data. (If plant has generation
        %data but no VOM data, will assume VOM = 0.)
        if parseddataworetiredwadjustments{i,gwhtotalcol}>0
            vomtotal=parseddataworetiredwadjustments{i,vomtotalcol};
            gwhtotal=parseddataworetiredwadjustments{i,gwhtotalcol};
            %Calculation: VOM(million$/yr)/GWh(GWh)*1GWh/1000MWh*1E6$/million$
            parseddataworetiredwadjustments{i,vomcalculatedcol}=vomtotal/gwhtotal*1E6/1E3;
        end
    end
end

%% ADD VOM DATA FOR PLANTS WITHOUT GENERATION DATA
%Now add VOM for plants w/out generation data
for i=2:size(parseddataworetiredwadjustments,1)
    if strcmp(parseddataworetiredwadjustments{i,parseddatafueltypecol},'Wind')==0 ||...
            strcmp(parseddataworetiredwadjustments{i,parseddatafueltypecol},'Solar')==0
        %If plant has no generation data
        if parseddataworetiredwadjustments{i,gwhtotalcol}==0
            %Find rows of same fuel and plant type
            currfuel=parseddataworetiredwadjustments{i,parseddatafueltypecol};
            currplanttype=parseddataworetiredwadjustments{i,parseddataplanttypecol};
            %There are four coal plants in dataset w/out fuel type listed
            %for some reason - fill it in here. Also O/G Steam
            %turbines w/out fuel type given (set to Oil). Also Combined Cycle plants
            %w/out fuel type given (set to NaturalGas). There's also a CT
            %plant w/out a fuel type given - assume it's NG.
            if strcmp(currfuel,'') & strcmp(currplanttype,'Coal Steam')
                currfuel='Coal';
            elseif strcmp(currfuel,'') & strcmpi(currplanttype,'O/G Steam')
                currfuel='Oil';
            elseif strcmp(currfuel,'') & strcmp(currplanttype,'Combined Cycle')
                currfuel='NaturalGas';
            elseif strcmp(currfuel,'') & strcmp(currplanttype,'Combustion Turbine')
                currfuel='NaturalGas';
            end
            %There are also no Oil O/G Steam turbines that actually
            %generate any power, so use Oil CT values instead. There is
            %also a single Oil CC plant - use Gas CC values instead. There
            %is also a Coal Steam plant w/ NaturalGas fuel type listed; set
            %VOM value to that for Coal Steam plants by setting fuel type
            %to Coal.
            if strcmp(currfuel,'Oil') & strcmpi(currplanttype,'O/G Steam')
                currplanttype='Combustion Turbine';
            elseif strcmp(currfuel,'Oil') & strcmp(currplanttype,'Combined Cycle')
                currfuel='NaturalGas';
            elseif strcmp(currfuel,'NaturalGas') & strcmp(currplanttype,'Coal Steam')
                currfuel='Coal';
            end
            samefuelandplantrows=find(strcmpi(currfuel,parseddataworetiredwadjustments(:,parseddatafueltypecol)) & ...
                strcmpi(currplanttype,parseddataworetiredwadjustments(:,parseddataplanttypecol)));
            %Get calculated VOM for those rows
            calcdvomforsamerows=cell2mat(parseddataworetiredwadjustments(samefuelandplantrows,vomcalculatedcol));
            %Remove zeros
            calcdvomforsamerows(calcdvomforsamerows(:,1)==0,:)=[];
            %Calculate average calculated VOM
            meancalcvom=mean(calcdvomforsamerows);
            %Store value
            parseddataworetiredwadjustments{i,vomcalculatedcol}=meancalcvom;
        end
    end
end


%% ISOLATE MISO PLANTS
%Have two ways to model MISO: just as EPA regions in MISO (MIS_) (modelmisowithfullstates=0), 
%or as full states that are mostly in MISO (modelmisowithfullstates=1). If
%doing the former, isolate plants that are in regions starting in MIS_. If
%doing the latter, isolate plants in the states that are in the following
%Excel file:
if strcmp(pc,'work')
    mapofmisoregionstostatesfilename='C:\Users\mtcraig\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\MapIPMMISORegionsToStates.xlsx';
elseif strcmp(pc,'personal')
    mapofmisoregionstostatesfilename='C:\Users\mcraig10\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\MapIPMMISORegionsToStates.xlsx';
end
[~,~,mapofmisostatestoregions]=xlsread(mapofmisoregionstostatesfilename,'Sheet1');
mapstate1col=find(strcmp(mapofmisostatestoregions(1,:),'State 1'));
mapstate2col=find(strcmp(mapofmisostatestoregions(1,:),'State 2'));
statesinmiso=vertcat(mapofmisostatestoregions(2:end,mapstate1col),mapofmisostatestoregions(2:end,mapstate2col));
%Create new array for only MISO generators and store headers.
parseddataworetiredwadjustmentsiso=parseddataworetiredwadjustments(1,:);
if modelmisowithfullstates==0
    %MISO RegionNames: MIS_***   
    for i=2:size(parseddataworetiredwadjustments,1)
        if strcmp(parseddataworetiredwadjustments{i,parseddataregioncol}(1:3),'MIS')==1 %if first 3 letters are MIS
            parseddataworetiredwadjustmentsiso(end+1,:)=parseddataworetiredwadjustments(i,:);
        end
    end
else
    for i=2:size(parseddataworetiredwadjustments,1)
        if find(strcmp(statesinmiso,parseddataworetiredwadjustments{i,parseddatastatecol})) %if first 3 letters are MIS
            parseddataworetiredwadjustmentsiso(end+1,:)=parseddataworetiredwadjustments(i,:);
        end
    end
end

%% FILL IN MISSING FUEL TYPES AND MODIFY TIRES FUEL TYPE
%10/30/15: 
%3 O/G Steam units have missing fuel type. Assign them oil fuel type.
%1 unit has 'Tires' fuel type. CO2 ems rate is very high, so set as Coal.

%O/G Steam units w/out fuel type
nofueltyperows=find(strcmp(parseddataworetiredwadjustmentsiso(:,parseddatafueltypecol),''));
if strcmp(parseddataworetiredwadjustmentsiso(nofueltyperows,parseddataplanttypecol),'O/G Steam')
    for i=1:size(nofueltyperows,1)
        currrow=nofueltyperows(i);
        parseddataworetiredwadjustmentsiso{currrow,parseddatafueltypecol}='Oil';
    end
else
    'Missing fuel types not O/G Steam units!'
end

%Tires unit
tiresunit=find(strcmp(parseddataworetiredwadjustmentsiso(:,parseddatafueltypecol),'Tires'));
parseddataworetiredwadjustmentsiso{tiresunit,parseddataplanttypecol}='Coal Steam';
parseddataworetiredwadjustmentsiso{tiresunit,parseddatafueltypecol}='Coal';


%% CHANGE UNIT ID OF DUPLICATE ORISID-UNITID GENERATORS
%Some generators have the same ORIS & unit ID, which makes problems in
%PLEXOS. Find and eliminate these units. Need to exclude generators w/
%empty ORIS+unit ID
%Get existing units
newgensrows=find(strcmp(parseddataworetiredwadjustmentsiso(:,parseddataorisidcol),''));
existinggens=parseddataworetiredwadjustmentsiso;
%Add original row # to existinggens
rownumcol=size(existinggens,2)+1;
for i=1:size(existinggens,1)
    existinggens{i,rownumcol}=i;
end
existinggens(newgensrows,:)=[];
%Combine ORIS & unit IDs of existing units
orisandunitid=[existinggens(2:end,parseddataorisidcol),existinggens(2:end,parseddataunitidcol)];
orisandunitidcombined=strcat(orisandunitid(:,1),'-',orisandunitid(:,2));
%Get unique IDs
uniqueentries=unique(orisandunitidcombined);
%Find rows of them
rowsofuniques=[];
for i=1:size(uniqueentries,1)
    %Get # of times the entry occurs in array
    rowofentries=find(strcmp(orisandunitidcombined(:,1),uniqueentries(i,1)));
    %If it's repeated, have found a duplicate; change second instance
    if size(rowofentries,1)>1
        %Add a 'dupX' to end of unit ID, where X is # of duplicates (e.g.,
        %if 3 copies, then put dup1 and dup2 on them)
        for j=2:size(rowofentries,1)
            currrow=rowofentries(j,1)+1;
            rowinoriginalarray=existinggens{currrow,rownumcol};
            parseddataworetiredwadjustmentsiso{rowinoriginalarray,parseddataunitidcol}=...
                strcat(parseddataworetiredwadjustmentsiso{rowinoriginalarray,parseddataunitidcol},...
                'dup',num2str(j));
        end
    end
end