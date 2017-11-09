%Michael Craig
%November 4, 2015
%This script gathers annual data from multiple runs.

%% SET DEFAULT TEXT FOR FIGURES
set(0,'defaultAxesFontName', 'Times New Roman')
set(0,'defaultTextFontName', 'Times New Roman')

%% KEY PARAMETERS
%Indicate whether running on server ( 1 = yes)
server=1;

%Inidicate which types of plants to eliminate
elimnorampscaling=1;
elimventing=1;

%Indicate whether to test CPP or lower limit
testlowerlimit=0;

%Indicate whether to test lower ramp limits
testlowerramps=0;
%If testing lower ramps, not testing lower limit - need to set this param
%to 0 for later calculations.
if (testlowerramps==1) testlowerlimit=0; end;
if (testlowerramps==1) elimnorampscaling=0; end;

%Indicate whether to test MSL on all units
testmslonallunits=1;

%Indicate whether to make plots
plotdata=1;

%Number of days in analysis
numdaysinanalysis=364;

%% CONVERSION PARAMETER
kgtoton=907.185;

%% PLEXOS OUTPUT FILE NAMES
%Give base directory for PLEXOS output
if server==0
%     basedirforflatfiles='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output';
    basedirforflatfiles='C:\Users\mcraig10\Desktop\FakeOutputForMATLABTests';
elseif server==1
    if testmslonallunits==1
        basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\ResultsMSL';
    elseif testlowerlimit==0 && testlowerramps==0
        basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\Results';
    elseif testlowerlimit==0 && testlowerramps==1
        basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\ResultsNoRmpScl';
    elseif testlowerlimits==1
        basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\ResultsLowLim';
    end
end

%Alternatively, can get list of folders in basedirforflatfiles
filesandfolders=dir(basedirforflatfiles);
folderflags=[filesandfolders.isdir];
folders=filesandfolders(folderflags);
folders(1:2,:)=[]; %Remove first 2 folders - alwasy . and ..
foldernames={};
for i=1:size(folders,1)
    foldernames=vertcat(foldernames,folders(i).name);
end

%Set folders with model output that should be opened
% foldernames={'CPPEEPt5FlxCCS0MW0WndMW0Rmp1Grp1MSL0NLDC0';
%     'CPPEEPt5FlxCCS0MW0WndMW2500Rmp1Grp1MSL0NLDC0';
%     'CPPEEPt5FlxCCS0MW0WndMW6500Rmp1Grp1MSL0NLDC0';
%     'CPPEEPt5FlxCCS0MW8000WndMW0Rmp1Grp1MSL0NLDC0Vnt1';
%     'CPPEEPt5FlxCCS1MW2000WndMW0Rmp1Grp1MSL0NLDC0Vnt1';
%     'CPPEEPt5FlxCCS1MW8000WndMW0Rmp1Grp1MSL0NLDC0Vnt0';
%     'CPPEEPt5FlxCCS1MW8000WndMW0Rmp1Grp1MSL0NLDC0Vnt1'};

%% MATLAB FILE DIRECTORY
matfiledir='C:\Users\mtcraig\Desktop\EPP Research\Matlab\Fleets';

%% IMPORT CAPITAL COST DATA
[annualizedwindcapitalcost, annualizednormalccscapitalcost, ...
    annualizedsscapitalcost] = GetAnnualizedCapitalCostValues();

%% CREATE ARRAY TO STORE DATA
%All units are in thousands! So NSE = GWh, TotalGenCost = $1000's,
%CO2CPPProduction=1000 kgs
alldata={'FlexCCS','CCSMW','ActualCCSMW','ActualSSMW','WindMW','AllowVent','ScaleRamp','CalcCO2Price','NSE(MWh)','TotalGenCost($)','GenCost($)',...
    'EmissionsCost($)','CostToLoad($)','StartCost($)','CO2CPPProduction(kg)','ReserveCost($)','ReservesProcured(MWh)',...
    'WindCurtailment(%)','SolarCurtailment(%)','WindCurtailed(MWh)','SolarCurtailed(MWh)',...
    'TotalCCSBaseGen(MWh)','TotalCCSDischargeGen(MWh)','TotalCCSVentChargeGen(MWh)',...
    'TotalCCSVentGen(MWh)','TotalCCSPumpGen(MWh)',...
    'TotalCCSBaseReserves(MWh)','TotalCCSDischargeReserves(MWh)',...
    'TotalCCSVentChargeReserves(MWh)','TotalCCSVentReserves(MWh)','TotalCCSPumpReserves(MWh)'};
flexcolalldata=find(strcmp(alldata(1,:),'FlexCCS'));
ccsmwcolalldata=find(strcmp(alldata(1,:),'CCSMW'));
actualccsmwcolalldata=find(strcmp(alldata(1,:),'ActualCCSMW'));
actualssmwcolalldata=find(strcmp(alldata(1,:),'ActualSSMW'));
windmwcolalldata=find(strcmp(alldata(1,:),'WindMW'));
ventcolalldata=find(strcmp(alldata(1,:),'AllowVent'));
rampcolalldata=find(strcmp(alldata(1,:),'ScaleRamp'));
calcco2pricealldata=find(strcmp(alldata(1,:),'CalcCO2Price'));
nsecolalldata=find(strcmp(alldata(1,:),'NSE(MWh)'));
totalgencostcolalldata=find(strcmp(alldata(1,:),'TotalGenCost($)'));
gencostcolalldata=find(strcmp(alldata(1,:),'GenCost($)'));
emissionscostcolalldata=find(strcmp(alldata(1,:),'EmissionsCost($)'));
costtoloadcolalldata=find(strcmp(alldata(1,:),'CostToLoad($)'));
startcostcolalldata=find(strcmp(alldata(1,:),'StartCost($)'));
co2cppproductioncolalldata=find(strcmp(alldata(1,:),'CO2CPPProduction(kg)'));
reservecostcolalldata=find(strcmp(alldata(1,:),'ReserveCost($)'));
reserveprocuredcolalldata=find(strcmp(alldata(1,:),'ReservesProcured(MWh)'));
windcurtailmentcolalldata=find(strcmp(alldata(1,:),'WindCurtailment(%)'));
solarcurtailmentcolalldata=find(strcmp(alldata(1,:),'SolarCurtailment(%)'));
windcurtailedcolalldata=find(strcmp(alldata(1,:),'WindCurtailed(MWh)'));
solarcurtailedcolalldata=find(strcmp(alldata(1,:),'SolarCurtailed(MWh)'));
ccsbasegenalldata=find(strcmp(alldata(1,:),'TotalCCSBaseGen(MWh)'));
ccsdischargegenalldata=find(strcmp(alldata(1,:),'TotalCCSDischargeGen(MWh)'));
ccsventchargegenalldata=find(strcmp(alldata(1,:),'TotalCCSVentChargeGen(MWh)'));
ccsventgenalldata=find(strcmp(alldata(1,:),'TotalCCSVentGen(MWh)'));
ccspumpgenalldata=find(strcmp(alldata(1,:),'TotalCCSPumpGen(MWh)'));
ccsbasereservesalldata=find(strcmp(alldata(1,:),'TotalCCSBaseReserves(MWh)'));
ccsdischargereservesalldata=find(strcmp(alldata(1,:),'TotalCCSDischargeReserves(MWh)'));
ccsventchargereservesalldata=find(strcmp(alldata(1,:),'TotalCCSVentChargeReserves(MWh)'));
ccsventreservesalldata=find(strcmp(alldata(1,:),'TotalCCSVentReserves(MWh)'));
ccspumpreservesalldata=find(strcmp(alldata(1,:),'TotalCCSPumpReserves(MWh)'));

%Also hold CCS generation data across all runs
allccsgenandreserves={'FlexCCS','CCSMW','WindMW','AllowVent','ScaleRamp',...
    'GenName','GenMW','Gen(MWh)','RegUp(MWh)','RegDown(MWh)','Raise(MWh)','Replace(MWh)'};
flexcolccs=find(strcmp(allccsgenandreserves(1,:),'FlexCCS'));
ccsmwcolccs=find(strcmp(allccsgenandreserves(1,:),'CCSMW'));
windmwcolccs=find(strcmp(allccsgenandreserves(1,:),'WindMW'));
ventcolccs=find(strcmp(allccsgenandreserves(1,:),'AllowVent'));
rampcolccs=find(strcmp(allccsgenandreserves(1,:),'ScaleRamp'));
ccsnamecol=find(strcmp(allccsgenandreserves(1,:),'GenName'));
ccscapaccol=find(strcmp(allccsgenandreserves(1,:),'GenMW'));
ccsgencol=find(strcmp(allccsgenandreserves(1,:),'Gen(MWh)'));
ccsregupcol=find(strcmp(allccsgenandreserves(1,:),'RegUp(MWh)'));
ccsregdowncol=find(strcmp(allccsgenandreserves(1,:),'RegDown(MWh)'));
ccsraisecol=find(strcmp(allccsgenandreserves(1,:),'Raise(MWh)'));
ccsreplacecol=find(strcmp(allccsgenandreserves(1,:),'Replace(MWh)'));

%% ITERATE THROUGH FOLDERS (DIFFERENT RUNS)
for folderctr=1:size(foldernames,1)
    %Set current folder name
    currfolder=foldernames{folderctr};
    currfolderdir=fullfile(basedirforflatfiles,currfolder);
    
    %Set folder name w/ fiscal year data
    fiscalyeardir=fullfile(currfolderdir,'fiscal year');
    
    %% GET RELEVANT PARAMETERS FROM FOLDER NAME
    [flexccsval,ccsmwval,windmwval,rampval,ventval,calcco2priceval]=GetLabelsFromFileName(currfolder);
    
    %% LOAD ID CSV FILE
    [~,~,ids]=xlsread(fullfile(currfolderdir,'id2name.csv'),'id2name');
    idsidcol=find(strcmp(ids(1,:),'id'));
    idsnamecol=find(strcmp(ids(1,:),'name'));
    
    %% GATHER YEAR LONG DATA***********************************************
    %% REGION OUTPUT
    %Need to scale all results up by 1000
    scaleresults=1000;
    %Unserved energy [ST Zone(1).Unserved Energy]
    nsefilename='ST Zone(1).Unserved Energy';
    nsedata=ExtractDataPLEXOSAnnual(fiscalyeardir,nsefilename);
    nse=nsedata{2,4}*scaleresults;
    
    %Total generation cost [ST Zone(1).Total Generation Cost]
    totalgencostfile='ST Zone(1).Total Generation Cost';
    totalgencostdata=ExtractDataPLEXOSAnnual(fiscalyeardir,totalgencostfile);
    totalgencost=totalgencostdata{2,4}*scaleresults;
    
    %Generation cost [ST Zone(1).Generation Cost]
    gencostfile='ST Zone(1).Generation Cost';
    gencostdata=ExtractDataPLEXOSAnnual(fiscalyeardir,gencostfile);
    gencost=gencostdata{2,4}*scaleresults;
        
    %Emissions costs [ST Zone(1).Emissions Cost]
    emissionscostfile='ST Zone(1).Emissions Cost';
    emissionscostdata=ExtractDataPLEXOSAnnual(fiscalyeardir,emissionscostfile);
    emissionscost=emissionscostdata{2,4}*scaleresults;
    
    %Cost to load [ST Zone(1).Cost to Load]
    costtoloadfile='ST Zone(1).Cost to Load';
    costtoloaddata=ExtractDataPLEXOSAnnual(fiscalyeardir,costtoloadfile);
    costtoload=costtoloaddata{2,4}*scaleresults;
    
    %Startup cost [ST Zone(1).Generator Start & Shutdown Cost]
    startcostfile='ST Zone(1).Generator Start & Shutdown Cost';
    startcostdata=ExtractDataPLEXOSAnnual(fiscalyeardir,startcostfile);
    startcost=startcostdata{2,4}*scaleresults;
        
    %% EMISSIONS OUTPUT
    %CO2 emissions (CO2CPP) [ST Emission(*).Production]
    %Need to find which Emissions # is CO2CPP.
    co2cppidrow=find(strcmp(ids(:,idsnamecol),'CO2CPP'));
    co2cppid=ids{co2cppidrow,idsidcol};
    %Now create file name
    co2cppproductionfile=strcat('ST Emission(',num2str(co2cppid),').Production');
    co2cppproductiondata=ExtractDataPLEXOSAnnual(fiscalyeardir,co2cppproductionfile);
    co2cppproduction=co2cppproductiondata{2,4}*scaleresults;
    
    %% RESERVES OUTPUT
    %Reserve cost [ST Reserve(*).Cost]
    %Reserves provision [ST Reserve(*).Provision]
    %Want to add up costs for all reserves, of which there are 4.
    reservecosttotal=0; reserveprovisiontotal=0;
    for reserveid=1:4
        reservecostfile=strcat('ST Reserve(',num2str(reserveid),').Cost');
        reservecostdata=ExtractDataPLEXOSAnnual(fiscalyeardir,reservecostfile);
        reservecost=reservecostdata{2,4}*scaleresults;
        reservecosttotal=reservecosttotal+reservecost;
        
        reserveprovisionfile=strcat('ST Reserve(',num2str(reserveid),').Provision');
        reserveprovisiondata=ExtractDataPLEXOSAnnual(fiscalyeardir,reserveprovisionfile);
        reserveprovision=reserveprovisiondata{2,4}*scaleresults;
        reserveprovisiontotal=reserveprovisiontotal+reserveprovision;
    end
    
    %% WIND AND SOLAR CURTAILMENT
    %Curtailment = %, curtailed = MWh
    [windcurtailment, solarcurtailment, windcurtailed, solarcurtailed] = ...
        AnalyzeWindAndSolarCurtailment(server,currfolder,basedirforflatfiles);
       
    %% CCS GENERATION******************************************************
    %Get generation values for CCS facilities added, be it inflexible or
    %flexible. Can use fiscal year values for this. 
    %For inflexible CCS, just need ID of base plant.
    %For flexible CCS, want to separate out generation by base generator &
    %discharge generators & venting generators. 
    
    if str2num(ccsmwval)>0 
        %Need to identify flex CCS generators in fleet. To do that, need to
        %open up corresponding MAT file.
        matfilename=currfolder;
        load(fullfile(matfiledir,matfilename),'futurepowerfleetforplexos');
        
        %Get column #s
        ccsretrofitcol=find(strcmp(futurepowerfleetforplexos(1,:),'CCS Retrofit'));
        orisidcol=find(strcmp(futurepowerfleetforplexos(1,:),'ORISCode'));
        unitidcol=find(strcmp(futurepowerfleetforplexos(1,:),'UnitID'));
        capaccol=find(strcmp(futurepowerfleetforplexos(1,:),'Capacity'));
        
        %Get CCS retrofits
        ccsretrofitrows=find(cell2mat(futurepowerfleetforplexos(2:end,ccsretrofitcol))==1)+1; %add 1 since exclude first row
        ccsorisids=futurepowerfleetforplexos(ccsretrofitrows,orisidcol);
        ccsunitids=futurepowerfleetforplexos(ccsretrofitrows,unitidcol);      
        ccscapacities=futurepowerfleetforplexos(ccsretrofitrows,capaccol);
        
        %Now get actual generation values.
        ccsgenandreserves=allccsgenandreserves(1,:);
        
        %BASE UNITS (FLEXIBLE & INFLEXIBLE CCS)
        %For each CCS ID, get annual generation
        for i=1:size(ccsorisids,1)
            %Get base gen name
            basegenname=strcat(ccsorisids{i,1},'-',ccsunitids{i,1});
            
            %Get capacity
            basecapac=ccscapacities{i,1};
            
            %Find PLEXOS ID
            basegenplexosrow=find(strcmp(ids(:,idsnamecol),basegenname));
            plexosid=ids{basegenplexosrow,idsidcol};
            
            %Get generation & reserves data.
            %OUTPUTS: desired annual data (in MWh)
            %INPUTS: fiscal year dir, PLEXOS ID, type of data desired (in format: Gen,
            %RegUp, RegDown, Raise, Replace)
            [genval]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'Gen');
            [regupval]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'RegUp');
            [regdownval]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'RegDown');
            [raiseval]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'Raise');
            [replaceval]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'Replace');
            
            %Save values
            newrow=size(ccsgenandreserves,1)+1;
            ccsgenandreserves{newrow,flexcolccs}=flexccsval;
            ccsgenandreserves{newrow,ccsmwcolccs}=ccsmwval;
            ccsgenandreserves{newrow,windmwcolccs}=windmwval;
            ccsgenandreserves{newrow,ventcolccs}=ventval;
            ccsgenandreserves{newrow,rampcolccs}=rampval;
            ccsgenandreserves{newrow,ccsnamecol}=basegenname;
            ccsgenandreserves{newrow,ccscapaccol}=basecapac;
            ccsgenandreserves{newrow,ccsgencol}=genval;
            ccsgenandreserves{newrow,ccsregupcol}=regupval;
            ccsgenandreserves{newrow,ccsregdowncol}=regdownval;
            ccsgenandreserves{newrow,ccsraisecol}=raiseval;
            ccsgenandreserves{newrow,ccsreplacecol}=replaceval;
            %FLEXIBLE CCS UNITS
            if str2num(flexccsval)==1 %Flexible CCS
                %Get discharge & flex CCS units
                dischargedummy1genname=strcat(basegenname,'SSDischargeDummy1');
                dischargedummy2genname=strcat(basegenname,'SSDischargeDummy2');
                ventgenname=strcat(basegenname,'Venting');
                ventchargegenname=strcat(basegenname,'SSVentWhenCharge');
                pumpdummy1genname=strcat(basegenname,'SSPumpDummy1');
                pumpdummy2genname=strcat(basegenname,'SSPumpDummy2');
                
                %Want to save capacity of SSDischargeDummy1, so get it's
                %capacity here.
                discharge1unit=strcat(ccsunitids{i},'SSDischargeDummy1');
                discharge1row=find(strcmp(futurepowerfleetforplexos(:,orisidcol),ccsorisids{i}) & ...
                    strcmp(futurepowerfleetforplexos(:,unitidcol),discharge1unit));
                discharge1capac=futurepowerfleetforplexos{discharge1row,capaccol};
                
                %Get rows in PLEXOS files
                discharge1row=find(strcmp(ids(:,idsnamecol),dischargedummy1genname));
                discharge2row=find(strcmp(ids(:,idsnamecol),dischargedummy2genname));
                ventrow=find(strcmp(ids(:,idsnamecol),ventgenname));
                ventchargerow=find(strcmp(ids(:,idsnamecol),ventchargegenname));
                pump1row=find(strcmp(ids(:,idsnamecol),pumpdummy1genname));
                pump2row=find(strcmp(ids(:,idsnamecol),pumpdummy2genname));
                
                %Combine rows
                flexccsnames={dischargedummy1genname;dischargedummy2genname;...
                    ventgenname;ventchargegenname;pumpdummy1genname;pumpdummy2genname};
                flexccsrows=vertcat(discharge1row,discharge2row,ventrow,ventchargerow,pump1row,pump2row);
                
                %Now repeat process above for each flex CCS unit
                for flexctr=1:size(flexccsnames,1)               
                    %Get gen name
                    flexgenname=flexccsnames{flexctr};
                    plexosid=ids{flexccsrows(flexctr),idsidcol};
                    
                    %Save capacity if SSDischargeDummy1 but nothing if
                    %other unit
                    if (strfind(flexgenname,'DischargeDummy1')) savecapac=discharge1capac; else savecapac=[]; end;
                    
                    %Skip if second discharge or pump unit since included w/ first
                    if isempty(findstr(flexgenname,'DischargeDummy2')) && isempty(findstr(flexgenname,'PumpDummy2'))
                        %If DischargeDummy1 or PumpDummy1, remove '1' from end of name
                        %b/c will add together both discharge units.
                        if (findstr(flexgenname,'DischargeDummy1')) flexgenname=flexgenname(1:end-1); end;
                        if (findstr(flexgenname,'PumpDummy1')) flexgenname=flexgenname(1:end-1); end;
                        
                        %Get generation & reserves data.
                        %OUTPUTS: desired annual data (in MWh)
                        %INPUTS: fiscal year dir, PLEXOS ID, type of data desired (in format: Gen,
                        %RegUp, RegDown, Raise, Replace)
                        [genval]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'Gen');
                        [regupval]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'RegUp');
                        [regdownval]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'RegDown');
                        [raiseval]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'Raise');
                        [replaceval]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'Replace');
                        
                        %If discharge or pump unit, get other discharge or pump unit at same
                        %time and save values together.
                        if isempty(findstr(flexgenname,'DischargeDummy'))==0 || isempty(findstr(flexgenname,'PumpDummy'))==0
                            %Get PLEXOS ID of second discharge unit - next
                            %row
                            plexosid=ids{flexccsrows(flexctr+1),idsidcol};
                            
                            %Get generation & reserves data.
                            %OUTPUTS: desired annual data (in MWh)
                            %INPUTS: fiscal year dir, PLEXOS ID, type of data desired (in format: Gen,
                            %RegUp, RegDown, Raise, Replace)
                            [genval2]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'Gen');
                            [regupval2]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'RegUp');
                            [regdownval2]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'RegDown');
                            [raiseval2]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'Raise');
                            [replaceval2]=GetFiscalYearGeneratorData(fiscalyeardir,plexosid,'Replace');
                            
                            %Add values
                            genval=genval+genval2;
                            regupval=regupval+regupval2;
                            regdownval=regdownval+regdownval2;
                            raiseval=raiseval+raiseval2;
                            replaceval=replaceval+replaceval2;
                        end
                        
                        %Save values
                        newrow=size(ccsgenandreserves,1)+1;
                        ccsgenandreserves{newrow,flexcolccs}=flexccsval;
                        ccsgenandreserves{newrow,ccsmwcolccs}=ccsmwval;
                        ccsgenandreserves{newrow,windmwcolccs}=windmwval;
                        ccsgenandreserves{newrow,ventcolccs}=ventval;
                        ccsgenandreserves{newrow,rampcolccs}=rampval;
                        ccsgenandreserves{newrow,ccsnamecol}=flexgenname;
                        ccsgenandreserves{newrow,ccscapaccol}=savecapac;
                        ccsgenandreserves{newrow,ccsgencol}=genval;
                        ccsgenandreserves{newrow,ccsregupcol}=regupval;
                        ccsgenandreserves{newrow,ccsregdowncol}=regdownval;
                        ccsgenandreserves{newrow,ccsraisecol}=raiseval;
                        ccsgenandreserves{newrow,ccsreplacecol}=replaceval;
                    end
                end             
            end
        end
        clear futurepowerfleetforplexos;

        %Sum CCS generation & reserves. Want to sum separately for
        %discharge, vent, vent when charge, & base units.
        if str2num(flexccsval)==1
            %Isolate rows w/ text
            dischargerowstemp=strfind(ccsgenandreserves(:,ccsnamecol),'Discharge');
            ventchargerowstemp=strfind(ccsgenandreserves(:,ccsnamecol),'VentWhen');
            ventrowstemp=strfind(ccsgenandreserves(:,ccsnamecol),'Venting');
            pumprowstemp=strfind(ccsgenandreserves(:,ccsnamecol),'Pump');
            
            %Get rows for each
            dischargerows=(cellfun(@isempty,dischargerowstemp)==0);
            ventchargerows=(cellfun(@isempty,ventchargerowstemp)==0);
            ventrows=(cellfun(@isempty,ventrowstemp)==0);
            pumprows=(cellfun(@isempty,pumprowstemp)==0);
            
            %Remaining non-first row = base rows
            allflexrows=dischargerows==1 | ventchargerows==1 | ventrows==1 | pumprows==1;
            baserows=(allflexrows==0); baserows(1)=0; %set first row to zeor so not included
            
            %Now sum each set of rows
            totalccsgen=sum(cell2mat(ccsgenandreserves(baserows,ccsgencol)));
            totaldischargegen=sum(cell2mat(ccsgenandreserves(dischargerows,ccsgencol)));
            totalventchargegen=sum(cell2mat(ccsgenandreserves(ventchargerows,ccsgencol)));
            totalventgen=sum(cell2mat(ccsgenandreserves(ventrows,ccsgencol)));
            totalpumpgen=sum(cell2mat(ccsgenandreserves(pumprows,ccsgencol)));
            
            totalccsreserves=sum(sum(cell2mat(ccsgenandreserves(baserows,ccsregupcol:ccsreplacecol))));
            totaldischargereserves=sum(sum(cell2mat(ccsgenandreserves(dischargerows,ccsregupcol:ccsreplacecol))));
            totalventchargereserves=sum(sum(cell2mat(ccsgenandreserves(ventchargerows,ccsregupcol:ccsreplacecol))));
            totalventreserves=sum(sum(cell2mat(ccsgenandreserves(ventrows,ccsregupcol:ccsreplacecol))));
            totalpumpreserves=sum(sum(cell2mat(ccsgenandreserves(pumprows,ccsregupcol:ccsreplacecol))));
        elseif str2num(flexccsval)==0
            %For inflex CCS, just have base generator, so can just sum
            %reserves
            totalccsgen=sum(cell2mat(ccsgenandreserves(2:end,ccsgencol)));
            totaldischargegen=0;
            totalventchargegen=0;
            totalventgen=0;
            totalpumpgen=0;
            
            totalccsreserves=sum(sum(cell2mat(ccsgenandreserves(2:end,ccsregupcol:ccsreplacecol))));
            totaldischargereserves=0;
            totalventchargereserves=0;
            totalventreserves=0;
            totalpumpreserves=0;
        end
    %If no CCS facilities added to scenario, set all values that will be stored in alldata to zero.    
    else
        totalccsgen=0;
        totaldischargegen=0;
        totalventchargegen=0;
        totalventgen=0;
        totalpumpgen=0;
        
        totalccsreserves=0;
        totaldischargereserves=0;
        totalventchargereserves=0;
        totalventreserves=0;
        totalpumpreserves=0;
        
        ccsgenandreserves=[];
    end
    
    %% STORE OUTPUT
    newrow=size(alldata,1)+1;
    alldata{newrow,flexcolalldata}=flexccsval;
    alldata{newrow,ccsmwcolalldata}=ccsmwval;
    if (strcmp(ccsmwval,'8000')) actualccsmwtemp='5754'; 
        if (strcmp(flexccsval,'1')) actualssmwtemp='7866'; else actualssmwtemp='0'; end;
    elseif (strcmp(ccsmwval,'4000')) actualccsmwtemp='3026'; 
        if (strcmp(flexccsval,'1')) actualssmwtemp='4088'; else actualssmwtemp='0'; end;
    elseif (strcmp(ccsmwval,'2000')) actualccsmwtemp='1554';
        if (strcmp(flexccsval,'1')) actualssmwtemp='2073'; else actualssmwtemp='0'; end;
    else actualccsmwtemp='0'; actualssmwtemp='0';
    end
    alldata{newrow,actualccsmwcolalldata}=actualccsmwtemp;
    alldata{newrow,actualssmwcolalldata}=actualssmwtemp;
    alldata{newrow,windmwcolalldata}=windmwval;
    alldata{newrow,ventcolalldata}=ventval;
    alldata{newrow,rampcolalldata}=rampval;
    alldata{newrow,calcco2pricealldata}=calcco2priceval;
    alldata{newrow,nsecolalldata}=nse;
    alldata{newrow,totalgencostcolalldata}=totalgencost;
    alldata{newrow,gencostcolalldata}=gencost;
    alldata{newrow,emissionscostcolalldata}=emissionscost;
    alldata{newrow,costtoloadcolalldata}=costtoload;
    alldata{newrow,startcostcolalldata}=startcost;
    alldata{newrow,co2cppproductioncolalldata}=co2cppproduction;
    alldata{newrow,reservecostcolalldata}=reservecosttotal;
    alldata{newrow,reserveprocuredcolalldata}=reserveprovisiontotal;
    alldata{newrow,windcurtailmentcolalldata}=windcurtailment;
    alldata{newrow,solarcurtailmentcolalldata}=solarcurtailment;
    alldata{newrow,windcurtailedcolalldata}=windcurtailed;
    alldata{newrow,solarcurtailedcolalldata}=solarcurtailed;
    alldata{newrow,ccsbasegenalldata}=totalccsgen;
    alldata{newrow,ccsdischargegenalldata}=totaldischargegen;
    alldata{newrow,ccsventchargegenalldata}=totalventchargegen;
    alldata{newrow,ccsventgenalldata}=totalventgen;
    alldata{newrow,ccspumpgenalldata}=totalpumpgen;
    alldata{newrow,ccsbasereservesalldata}=totalccsreserves;
    alldata{newrow,ccsdischargereservesalldata}=totaldischargereserves;
    alldata{newrow,ccsventchargereservesalldata}=totalventchargereserves;
    alldata{newrow,ccsventreservesalldata}=totalventreserves;
    alldata{newrow,ccspumpreservesalldata}=totalpumpreserves;

    allccsgenandreserves=vertcat(allccsgenandreserves,ccsgenandreserves(2:end,:));
end

%% REMOVE PUMP GENERATION FROM ALLCCSGENANDRESERVES
allccsgenandreserveswithpump=allccsgenandreserves;
%Get pump rows
pumprowstemp=strfind(allccsgenandreserves(:,ccsnamecol),'Pump');
pumprows=(cellfun(@isempty,pumprowstemp)==0);
%Eliminate rows
allccsgenandreserves(pumprows,:)=[];

%% ADD TOTAL CAPITAL COSTS TO ALLDATA ARRAY
%alldata has capacity of CCS & wind. Multiply by annualized values to get
%total capital costs for each scenario.
%For solvent storage, need total capacity of flex CCS w/ discharging as
%well. 
%Isolate capacities of wind, CCS, & flex CCS. 
windcapacsalldata=[]; ccscapacsalldata=[]; sscapacsalldata=[];
for i=2:size(alldata,1)
    windcapacsalldata=[windcapacsalldata; str2num(alldata{i,windmwcolalldata})];
    ccscapacsalldata=[ccscapacsalldata; str2num(alldata{i,actualccsmwcolalldata})];
    sscapacsalldata=[sscapacsalldata; str2num(alldata{i,actualssmwcolalldata})];
end

%Add columsn fo capital cost data + fill in values. Do this by multiplying
%total installed capacity of eaach technology * annualized capital cost for
%low/mid/high values. Also need to multiply by 1000 b/c capital cost values
%are in $/netkW = $/netkW*1000kW/MW.
kwtomw=1000;
newcol=size(alldata,2)+1;
windlowcapcostcol=newcol;
alldata{1,windlowcapcostcol}='WindLowCapCost($)';
alldata(2:end,windlowcapcostcol)=num2cell(windcapacsalldata.*annualizedwindcapitalcost(1).*kwtomw);
newcol=size(alldata,2)+1;
windmidcapcostcol=newcol;
alldata{1,windmidcapcostcol}='WindMidCapCost($)';
alldata(2:end,windmidcapcostcol)=num2cell(windcapacsalldata.*annualizedwindcapitalcost(2).*kwtomw);
newcol=size(alldata,2)+1;
windhighcapcostcol=newcol;
alldata{1,windhighcapcostcol}='WindHighCapCost($)';
alldata(2:end,windhighcapcostcol)=num2cell(windcapacsalldata.*annualizedwindcapitalcost(3).*kwtomw);
newcol=size(alldata,2)+1;
normccslowcapcostcol=newcol;
alldata{1,normccslowcapcostcol}='NormCCSLowCapCost($)';
alldata(2:end,normccslowcapcostcol)=num2cell(ccscapacsalldata.*annualizednormalccscapitalcost(1).*kwtomw);
newcol=size(alldata,2)+1;
normccsmidcapcostcol=newcol;
alldata{1,normccsmidcapcostcol}='NormCCSMidCapCost($)';
alldata(2:end,normccsmidcapcostcol)=num2cell(ccscapacsalldata.*annualizednormalccscapitalcost(2).*kwtomw);
newcol=size(alldata,2)+1;
normccshighcapcostcol=newcol;
alldata{1,normccshighcapcostcol}='NormCCSHighCapCost($)';
alldata(2:end,normccshighcapcostcol)=num2cell(ccscapacsalldata.*annualizednormalccscapitalcost(3).*kwtomw);
newcol=size(alldata,2)+1;
sslowcapcostcol=newcol;
alldata{1,sslowcapcostcol}='SSLowCapCost($)';
alldata(2:end,sslowcapcostcol)=num2cell(sscapacsalldata.*annualizedsscapitalcost(1).*kwtomw);
newcol=size(alldata,2)+1;
ssmidcapcostcol=newcol;
alldata{1,ssmidcapcostcol}='SSMidCapCost($)';
alldata(2:end,ssmidcapcostcol)=num2cell(sscapacsalldata.*annualizedsscapitalcost(2).*kwtomw);
newcol=size(alldata,2)+1;
sshighcapcostcol=newcol;
alldata{1,sshighcapcostcol}='SSHighCapCost($)';
alldata(2:end,sshighcapcostcol)=num2cell(sscapacsalldata.*annualizedsscapitalcost(3).*kwtomw);
%Calculate flex CCS capital costs by adding costs of stored solvent w/
%normal CCS. 
newcol=size(alldata,2)+1;
flexccslowcapcostcol=newcol;
alldata{1,flexccslowcapcostcol}='FlexCCSLowCapCost($)';
alldata(2:end,flexccslowcapcostcol)=num2cell(cell2mat(alldata(2:end,normccslowcapcostcol))+cell2mat(alldata(2:end,sslowcapcostcol)));
newcol=size(alldata,2)+1;
flexccsmidcapcostcol=newcol;
alldata{1,flexccsmidcapcostcol}='FlexCCSMidCapCost($)';
alldata(2:end,flexccsmidcapcostcol)=num2cell(cell2mat(alldata(2:end,normccsmidcapcostcol))+cell2mat(alldata(2:end,ssmidcapcostcol)));
newcol=size(alldata,2)+1;
flexccshighcapcostcol=newcol;
alldata{1,flexccshighcapcostcol}='FlexCCSHighCapCost($)';
alldata(2:end,flexccshighcapcostcol)=num2cell(cell2mat(alldata(2:end,normccshighcapcostcol))+cell2mat(alldata(2:end,sshighcapcostcol)));

%% SLIM DOWN DATA PASSED FOR PLOTS
%Save original alldata
alldatasaved=alldata;

%Now slim down alldata to only have data we want
%Eliminate scenarios w/out scaled ramp rates and that allow venting
if elimventing==1
    rowstoremove=[];
    for i=2:size(alldata,1)
        if str2num(alldata{i,flexcolalldata})==1
            if str2num(alldata{i,ventcolalldata})==1
                rowstoremove=[rowstoremove;i];
            end
        end
    end
    alldata(rowstoremove,:)=[];
end

if elimnorampscaling==1
    rowstoremove=[];
    for i=2:size(alldata,1)
        if str2num(alldata{i,rampcolalldata})==0
            rowstoremove=[rowstoremove;i];
        end
    end
    alldata(rowstoremove,:)=[];
end

%% IF RUNNING LOWER LIMIT, NEED TO MOVE 13GW WIND ALLDATA ROW TO END OF WIND SCENARIOS
if testlowerlimit==1
    %Get row and save it
    wind13row=find(strcmp(alldata(:,windmwcolalldata),'13000'));
    saverow=alldata(wind13row,:);
    %Shift next two wind rows up
    alldata(wind13row,:)=alldata(wind13row+1,:);
    alldata(wind13row+1,:)=alldata(wind13row+2,:);
    %Add 13 GW row back in
    alldata(wind13row+2,:)=saverow;
end

%% PLOTS OF DATA***********************************************************
if plotdata==1

%% GET LABELS**************************************************************
%Create labels for plots. Format: FlexCCS*, CCS*, Wind*, Base, BaseNoRmp
graphlabels={};
for i=2:size(alldata,1)
    templabel='';
    tempwindcapac=str2num(alldata{i,windmwcolalldata});
    tempccscapac=str2num(alldata{i,ccsmwcolalldata});
    if tempccscapac==2000
        tempccslabel='1.5';
    elseif tempccscapac==4000
        tempccslabel='3';
    elseif tempccscapac==8000
        tempccslabel='5.8';
    end
    if str2num(alldata{i,calcco2pricealldata})==0
        templabel='Base';
    elseif str2num(alldata{i,ccsmwcolalldata})==0 && tempwindcapac==0
        templabel='Rdsptch';
        if str2num(alldata{i,rampcolalldata})==0
            templabel=strcat(templabel,'Rmp0');
%         elseif str2num(alldata{i,rampcolalldata})==1
%             templabel=strcat(templabel,'NoRmpSc');
        end
    elseif str2num(alldata{i,ccsmwcolalldata})>0
        if str2num(alldata{i,flexcolalldata})==1
            templabel='FCCS';
            templabel=strcat(templabel,num2str(tempccslabel));
            if str2num(alldata{i,ventcolalldata})==0
%                 templabel=strcat(templabel,'Vnt0');
            elseif str2num(alldata{i,ventcolalldata})==1
               templabel=strcat(templabel,'Vnt1'); 
            end
        elseif str2num(alldata{i,flexcolalldata})==0
            templabel='NCCS';
            templabel=strcat(templabel,num2str(tempccslabel));
        end
        if str2num(alldata{i,rampcolalldata})==0
            templabel=strcat(templabel,'Rmp0');
%         elseif str2num(alldata{i,rampcolalldata})==1
        end
    elseif str2num(alldata{i,windmwcolalldata})>0
        templabel='Wnd';
        templabel=strcat(templabel,num2str(tempwindcapac/1000));
    end
    %Add label
    graphlabels=vertcat(graphlabels,templabel);
end

%Get base case row
basecaserow=find(strcmp(alldata(:,calcco2pricealldata),'0'));
graphlabelsnobasecase=graphlabels; graphlabelsnobasecase(basecaserow-1)=[];

%% TOTAL COSTS*************************************************************
%Bar graph of total costs. Calculate total costs as GenCost + StartCost + ReserveCost
scalecosts=1E9; if (scalecosts==1E9) scalecostsstr='B'; end;
totalcosts=cell2mat(alldata(2:end,gencostcolalldata))+cell2mat(alldata(2:end,startcostcolalldata))+...
    cell2mat(alldata(2:end,reservecostcolalldata));
totalcostsscaled=totalcosts/scalecosts;
% figure; bar(totalcostsscaled)
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',graphlabels);
% ylabel(['Total Cost ($',scalecostsstr,')']); 

%Get total op cost diff from baseline
basecasetotalcost=totalcosts(basecaserow-1);
totalopcostdiff=(totalcosts-basecasetotalcost);
totalopcostdiffnobase=totalopcostdiff;
totalopcostdiffnobase(basecaserow-1)=[];

%Bar graph of total costs as % difference from baseline
totalcostdiffaspercent=totalopcostdiff/basecasetotalcost*100;
% figure; bar(totalcostdiffaspercent)
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',graphlabels);
% ylabel(['Percent Change of Total Cost from Base Case (%)']);

%Bar graph of cost components (GenCost, StartCost, ReserveCost)
costcols=[gencostcolalldata startcostcolalldata reservecostcolalldata];
costcollabels={'GenCost' 'StartCost' 'ReserveCost'};
costcomponents=cell2mat(alldata(2:end,costcols));
costcomponentsscaled=costcomponents/scalecosts;
% figure; bar(costcomponentsscaled,'stacked');
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',graphlabels);
% ylabel(['Cost ($',scalecostsstr,')']); 
% legend(costcollabels);

%Bar graph of cost components as difference from baseline
basecasecostcomponents=costcomponents(basecaserow-1,:);
basecasecostcomponentssized=repmat(basecasecostcomponents,size(costcomponents,1),1);
costcomponentchanges=costcomponents-basecasecostcomponentssized;
costcomponentchangesscaled=costcomponentchanges/scalecosts;
% figure; bar(costcomponentchangesscaled)
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',graphlabels);
% ylabel(['Cost - Base Case Cost (',scalecostsstr,')']);
% legend(costcollabels);

%Bar graph of cost components as percentage change from baseline
costcomponentchangespercent=costcomponentchanges./basecasecostcomponentssized*100;
% figure; bar(costcomponentchangespercent)
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',graphlabels);
% ylabel(['Percent Change from Base Case (%)']);
% legend(costcollabels);

%OPERATIONAL + CAPITAL COSTS
%Bar graph of operational + capital + total costs broken out
scalecosts=1E9; if (scalecosts==1E9) scalecostsstr='B'; end;
%Get capital costs
aggregatedlowcapcosts=cell2mat(alldata(2:end,windlowcapcostcol))+...
    cell2mat(alldata(2:end,normccslowcapcostcol))+cell2mat(alldata(2:end,sslowcapcostcol));
aggregatedmidcapcosts=cell2mat(alldata(2:end,windmidcapcostcol))+...
    cell2mat(alldata(2:end,normccsmidcapcostcol))+cell2mat(alldata(2:end,ssmidcapcostcol));
aggregatedhighcapcosts=cell2mat(alldata(2:end,windhighcapcostcol))+...
    cell2mat(alldata(2:end,normccshighcapcostcol))+cell2mat(alldata(2:end,sshighcapcostcol));
%Combine operational + capital costs
opandcapcostslow=[cell2mat(alldata(2:end,gencostcolalldata)),cell2mat(alldata(2:end,startcostcolalldata)),...
    cell2mat(alldata(2:end,reservecostcolalldata)),aggregatedlowcapcosts];
opandcapcostsmid=[cell2mat(alldata(2:end,gencostcolalldata)),cell2mat(alldata(2:end,startcostcolalldata)),...
    cell2mat(alldata(2:end,reservecostcolalldata)),aggregatedmidcapcosts];
opandcapcostshigh=[cell2mat(alldata(2:end,gencostcolalldata)),cell2mat(alldata(2:end,startcostcolalldata)),...
    cell2mat(alldata(2:end,reservecostcolalldata)),aggregatedhighcapcosts];
%Get base case vals
opandcapcostslowbase=opandcapcostslow(basecaserow-1,:);
opandcapcostsmidbase=opandcapcostsmid(basecaserow-1,:);
opandcapcostshighbase=opandcapcostshigh(basecaserow-1,:);
%Get diff from base case
opandcapcostsmiddiff=opandcapcostsmid-repmat(opandcapcostsmidbase,size(opandcapcostsmid,1),1);
%Calculate total values
totalopandcapcostslow=sum(opandcapcostslow,2);
totalopandcapcostsmid=sum(opandcapcostsmid,2);
totalopandcapcostshigh=sum(opandcapcostshigh,2);
%Get base case total costs
basecasetotalopandcapcostslow=totalopandcapcostslow(basecaserow-1);
basecasetotalopandcapcostsmid=totalopandcapcostsmid(basecaserow-1);
basecasetotalopandcapcostshigh=totalopandcapcostshigh(basecaserow-1);
%Get diffs in total costs
totalopandcapcostsdifflow=totalopandcapcostslow-basecasetotalopandcapcostslow;
totalopandcapcostsdiffmid=totalopandcapcostsmid-basecasetotalopandcapcostsmid;
totalopandcapcostsdiffhigh=totalopandcapcostshigh-basecasetotalopandcapcostshigh;
%Assign legend
opandcapcostslegend={'Generation','Start-up','Reserves','Capital','Total'};
%Scale values
opandcapcostslowscaled=opandcapcostslow/scalecosts;
opandcapcostsmidscaled=opandcapcostsmid/scalecosts;
opandcapcostshighscaled=opandcapcostshigh/scalecosts;
%Plot just for mid
figure; bar(opandcapcostsmidscaled,'stacked'); colormap gray
xlabel('Scenario','fontweight','bold'); ax=gca; set(ax, 'XTickLabel',graphlabels,'fontweight','bold');
ylabel(['Costs ($',scalecostsstr,')'],'fontweight','bold'); 
legend(opandcapcostslegend)

%Bar graph of total op + cap costs as difference from baseline for mid
totalopandcapcostsdiffscaled=totalopandcapcostsdiffmid/scalecosts;
% figure; bar(totalopandcapcostsdiffscaled)
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',graphlabels);
% ylabel(['Diff. in Total Op. + Cap. Cost from Base ($',scalecostsstr,')']); 

%Bar graph of total op + cap costs as components as diff from baseline
%Combine all values - just for mid for a plot
% opandcapcostsmidwithtotal=[opandcapcostsmiddiff totalopandcapcostsdiffscaled];
opandcapcostsmidwithtotal=[opandcapcostsmid totalopandcapcostsmid];
%Now get base row & subtract values
opandcapcostsmidwithtotalbase=opandcapcostsmidwithtotal(basecaserow-1,:);
opandcapcostsmidwithtotaldiff=opandcapcostsmidwithtotal-repmat(opandcapcostsmidwithtotalbase,size(opandcapcostsmidwithtotal,1),1);
%Remove base row
opandcapcostsmidwithtotaldiffnobase=opandcapcostsmidwithtotaldiff;
opandcapcostsmidwithtotaldiffnobase(basecaserow-1,:)=[];
opandcapcostsmidwithtotaldiffnobasescaled=opandcapcostsmidwithtotaldiffnobase/scalecosts;
figure; bar(opandcapcostsmidwithtotaldiffnobasescaled); colormap gray
xlabel('Scenario','fontsize',12,'fontweight','bold'); ax=gca; set(ax, 'XTickLabel',graphlabelsnobasecase);
ylabel(['Difference in Cost from Base Scenario ($',scalecostsstr,')'],'fontsize',12,'fontweight','bold'); 
legend(opandcapcostslegend,'fontsize',12); set(gca,'fontsize',12,'fontweight','bold')

%Bar graph of total op + cap costs as % diff from baseline
totalopandcapcostspercentdiff=totalopandcapcostsdiffmid/basecasetotalopandcapcostsmid*100;
% figure; bar(totalopandcapcostspercentdiff)
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',graphlabels);
% ylabel(['Percent Diff. in Total Op. + Cap. Cost from Base (%)']); 

%% NON-SERVED ENERGY*******************************************************
%Bar graph of NSE
nse=cell2mat(alldata(2:end,nsecolalldata));
% figure; 
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',graphlabels);
% ylabel('NSE (MWh)')

%% TOTAL CO2 CPP EMISSIONS*************************************************
%Bar graph of total CO2 emissions (w/ mass limit as line)
co2cppemissionsscale=kgtoton*1E6; if (co2cppemissionsscale==kgtoton*1E6) co2cppemissionsscalestr='Mtons'; end;
co2cppemissions=cell2mat(alldata(2:end,co2cppproductioncolalldata));
co2cppemissionsscaled=co2cppemissions/co2cppemissionsscale;
% figure; bar(co2cppemissionsscaled)
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',graphlabels);
% ylabel(['Total CPP CO2 Ems (',co2cppemissionsscalestr,')']);
%Now add line for CO2 mass limit
if testlowerlimit==0
    co2cppmasslimit=3.1362E11; co2cppmasslimitscaled=co2cppmasslimit/co2cppemissionsscale;
else
    co2cppmasslimit=2.2524e+11; co2cppmasslimitscaled=co2cppmasslimit/co2cppemissionsscale;
end
% xlimtemp=get(gca,'xlim');
% hold on; plot(xlimtemp,[co2cppmasslimitscaled co2cppmasslimitscaled],'r','LineWidth',2);

%Bar graph of total CO2 emissions as % of mass limit
co2cppemissionspercentofmasslimit=(co2cppemissions-co2cppmasslimit)./co2cppmasslimit*100;
figure; bar(co2cppemissionspercentofmasslimit); colormap gray;
xlabel('Scenario','fontsize',12,'fontweight','bold'); ax=gca; set(ax, 'XTickLabel',graphlabels);
ylabel('Percent Difference of CO2 Emissions from CPP Mass Limit','fontsize',12,'fontweight','bold')
set(gca,'fontsize',12,'fontweight','bold')

%BELOW code is for plotting x labels at 45 degree angle
% %Plot data
% figure; bar(co2cppemissionspercentofmasslimit); colormap gray;
% ylabel('Percent Difference of CO2 Emissions from CPP Mass Limit','fontsize',14)
% % Reduce the size of the axis so that all the labels fit in the figure.
% pos = get(gca,'Position');
% set(gca,'Position',[pos(1), .2, pos(3) .65])
% % Set the X-Tick locations so that every other month is labeled.
% Xt = [1:size(graphlabels,1)];
% Xl = [1 size(graphlabels,1)];
% set(gca,'XTick',Xt,'XLim',Xl);
% % Add the months as tick labels.
% ax = axis;    % Current axis limits
% axis(axis);    % Set the axis limit modes (e.g. XLimMode) to manual
% Yl = ax(3:4);  % Y-axis limits
% % Place the text labels
% t = text(Xt,Yl(1)*ones(1,length(Xt)),graphlabels,'fontsize',14);
% set(t,'HorizontalAlignment','right','VerticalAlignment','top', ...
%       'Rotation',45);
% % Remove the default labels
% set(gca,'XTickLabel','')
% % Get the Extent of each text object.  This
% % loop is unavoidable.
% for i = 1:length(t)
%   ext(i,:) = get(t(i),'Extent');
% end
% % Determine the lowest point.  The X-label will be
% % placed so that the top is aligned with this point.
% LowYPoint = min(ext(:,2))/sqrt(2);
% % Place the axis label at this point
% XMidPoint = Xl(1)+abs(diff(Xl))/2;
% tl = text(XMidPoint,LowYPoint,'X-Axis Label', ...
%           'VerticalAlignment','top', ...
%           'HorizontalAlignment','center','fontsize',14); %can use LowYPoint instead

%% COST-EFFECTIVENESS********************************************************
%Bar graph of $/ton CO2 emissions reductions relative to base case
%Get base caes emissions, then decreases in emissions.
basecaseco2cppemissions=alldata{basecaserow,co2cppproductioncolalldata};
co2cppemissionsreductions=basecaseco2cppemissions-co2cppemissions;
%Get base case total cost, then increases in costs.
basecasecost=totalcosts(basecaserow-1); %subtract 1 b/c don't have headers in totalcosts array
totalcostincreases=totalcosts-basecasecost;
%Remove base case (b/c can't divide by 0) (also remove from labels)
zerorow=find(totalcostincreases==0);
totalcostincreases(zerorow)=[]; co2cppemissionsreductions(zerorow)=[]; 
co2cppemissionsreductionsscaled=co2cppemissionsreductions/kgtoton; %tons
costperco2cppemissionsreduction=totalcostincreases./co2cppemissionsreductions;
% figure; bar(costperco2cppemissionsreduction)
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',graphlabelsnobasecase);
% ylabel(['Cost Per CPP CO2 Ems Reduced ($/kg)'])

%Cost-eff including op & cap costs
%Get zero row - same for all cap costs
totalopandcapcostsdiffzerorow=find(totalopandcapcostsdiffmid==0);
%Remove row from each set of total costs w/ diff cap cost estimates
totalopandcapcostsdiffnobaselow=totalopandcapcostsdifflow;
totalopandcapcostsdiffnobaselow(totalopandcapcostsdiffzerorow)=[];
totalopandcapcostsdiffnobasemid=totalopandcapcostsdiffmid;
totalopandcapcostsdiffnobasemid(totalopandcapcostsdiffzerorow)=[];
totalopandcapcostsdiffnobasehigh=totalopandcapcostsdiffhigh;
totalopandcapcostsdiffnobasehigh(totalopandcapcostsdiffzerorow)=[];
%Get cost-eff
opandcapcostperco2emsreduxscaledlow=totalopandcapcostsdiffnobaselow./co2cppemissionsreductions*kgtoton;
opandcapcostperco2emsreduxscaledmid=totalopandcapcostsdiffnobasemid./co2cppemissionsreductions*kgtoton;
opandcapcostperco2emsreduxscaledhigh=totalopandcapcostsdiffnobasehigh./co2cppemissionsreductions*kgtoton;
%Get x points for scatter plot
xvalsforscatter=[1:size(graphlabelsnobasecase,1)]';
%Plot
figure; scatter(xvalsforscatter,opandcapcostperco2emsreduxscaledhigh,'^','filled','k'); hold on;
scatter(xvalsforscatter,opandcapcostperco2emsreduxscaledmid,'s','filled','k'); 
scatter(xvalsforscatter,opandcapcostperco2emsreduxscaledlow,'o','filled','k');
if testlowerramps==1 || testmslonallunits==1
    numticks=size(graphlabelsnobasecase,1);
    L=get(gca,'XLim');
    set(gca,'XTick',linspace(L(1),L(2),numticks));
end
xlabel('Scenario','fontsize',12,'fontweight','bold'); ax=gca; set(ax, 'XTickLabel',graphlabelsnobasecase);
ylabel(['Cost per Ton of CO2 Emissions Reductions ($/ton)'],'fontsize',12,'fontweight','bold')
legend({'High Capital Cost','Mid Capital Cost','Low Capital Cost'},'fontsize',12,'fontweight','bold')
set(gca,'fontsize',12,'fontweight','bold')

%% CCS GENERATION AND RESERVES***********************************************
%Get CCS generation & reserve columns
ccsgencols=[ccsbasegenalldata ccsdischargegenalldata ccsventchargegenalldata ccsventgenalldata];
ccsreservecols=[ccsbasereservesalldata ccsdischargereservesalldata ccsventchargereservesalldata ccsventreservesalldata];
ccsgenandreservesscale=1E6; 
if (ccsgenandreservesscale==1E3) ccsgenandreservesscalestr='GWh'; elseif (ccsgenandreservesscale==1E6) ccsgenandreservesscalestr='TWh'; end;
ccsgenlabels={'Base','SSDis','VentCh','Vent'};
%Now get total generation and reserves
totalccsgeneration=sum(cell2mat(alldata(2:end,ccsgencols)),2);
totalccsreserves=sum(cell2mat(alldata(2:end,ccsreservecols)),2);
%Isolate CCS rows (& labels)
ccsrows=find(totalccsgeneration>0);
ccsrowslabels=graphlabels(ccsrows);
%Isolate & scale CCS generation & reserves
totalccsgenerationisolated=totalccsgeneration(ccsrows);
totalccsgenerationscaled=totalccsgenerationisolated/ccsgenandreservesscale;
totalccsreservesisolated=totalccsreserves(ccsrows);
totalccsreservesscaled=totalccsreservesisolated/ccsgenandreservesscale;

%Bar graph of total CCS generation and reserves
totalccsgenandresscaled=[totalccsgenerationscaled,totalccsreservesscaled];
totalccsgenandresscaledlegend={'Generation','Reserve Provision'};
figure; bar(totalccsgenandresscaled); colormap gray;
xlabel('Scenario','fontsize',12,'fontweight','bold'); ax=gca; set(ax, 'XTickLabel',ccsrowslabels);
ylabel(['Total CCS Electricity Generation or Reserve Provision (',ccsgenandreservesscalestr,')'],'fontsize',12,'fontweight','bold')
legend(totalccsgenandresscaledlegend,'fontsize',12,'fontweight','bold'); set(gca,'fontsize',12,'fontweight','bold')

%Bar graph of CCS generation by component. (Bar plots each row in a
%cluster. Can add legend.)
ccsgenerationbycomponent=cell2mat(alldata(2:end,ccsgencols));
if elimventing==1
    %Eliminate last 2 rows if eliminating venting
    ccsgenerationbycomponent(:,3:4)=[];
    componentlegend={'Base','Solvent Storage'};
else
    componentlegend={'Base','Solvent Storage','Vent','Vent when Charge'};
end
ccsgenerationbycomponentscaled=ccsgenerationbycomponent(ccsrows,:)/ccsgenandreservesscale;
% figure; bar(ccsgenerationbycomponentscaled); colormap gray
% xlabel('Scenario','fontsize',12); ax=gca; set(ax, 'XTickLabel',ccsrowslabels);
% ylabel(['CCS Electricity Generation by Proxy Unit (',ccsgenandreservesscalestr,')'],'fontsize',12)
% set(gca,'fontsize',12); legend(componentlegend,'fontsize',12);

%Bar graph of total CCS reserves.
% totalccsreserves=sum(cell2mat(alldata(2:end,ccsreservecols)),2);
% totalccsreservesisolated=totalccsreserves(ccsrows);
% totalccsreservesscaled=totalccsreservesisolated/ccsgenandreservesscale;
% figure; bar(totalccsreservesscaled); colormap gray
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',ccsrowslabels);
% ylabel(['Total CCS Reserves (',ccsgenandreservesscalestr,')'])

%Bar graph of CCS reserves by component.
ccsreservesbycomponent=cell2mat(alldata(2:end,ccsreservecols));
if elimventing==1
    %Eliminate last 2 rows if eliminating venting
    ccsreservesbycomponent(:,3:4)=[];
    componentlegend={'Base','Solvent Storage'};
else
    componentlegend={'Base','Solvent Storage','Vent','Vent when Charge'};
end
ccsreservesbycomponentscaled=ccsreservesbycomponent(ccsrows,:)/ccsgenandreservesscale;
% figure; bar(ccsreservesbycomponentscaled); colormap gray
% xlabel('Scenario','fontsize',12); ax=gca; set(ax, 'XTickLabel',ccsrowslabels);
% ylabel(['CCS Reserves by Proxy Unit (',ccsgenandreservesscalestr,')'],'fontsize',12)
% set(gca,'fontsize',12); legend(componentlegend,'fontsize',12);

%Bar graph of CCS reserves + generation by component
ccsresandgenbycompscaled=[ccsgenerationbycomponentscaled,ccsreservesbycomponentscaled];
templegend={'Elec. Gen., Base','Elec. Gen., Solvent Storage','Res. Prov., Base','Res. Prov., Solvent Storage'}; 
figure; bar(ccsresandgenbycompscaled); colormap gray
xlabel('Scenario','fontsize',12,'Color','k','fontweight','bold'); ax=gca; set(ax, 'XTickLabel',ccsrowslabels,'fontweight','bold');
ylabel(['CCS Electricity Generation Reserves by Proxy Unit (',ccsgenandreservesscalestr,')'],'fontsize',12,'Color','k','fontweight','bold')
set(gca,'fontsize',12); legend(templegend,'fontsize',12,'fontweight','bold');


%% GRAPHS OF AGGREGATE CAPACITY FACTORS**************************************
%Bar graph of capacity facator of all CCS plants for generation. Do this for
%generation against normal CCS capacity.
allccscapacities=[];
for (i=2:size(alldata,1)); allccscapacities=[allccscapacities;str2num(alldata{i,actualccsmwcolalldata})]; end;
allccscapacitiesisolated=allccscapacities(ccsrows);
maxgenccs=allccscapacitiesisolated.*24.*numdaysinanalysis;
capacityfactorsccsgen=totalccsgenerationisolated./maxgenccs;
% figure; bar(capacityfactorsccsgen); colormap gray
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',ccsrowslabels);
% ylabel(['Capac. Factor of Generation for all CCS Units'])

%Bar graph of capacity factor of all CCS plants for reserves. Do against
%normal CCS capacity.
capacityfactorsccsreserves=totalccsreservesisolated./maxgenccs;
% figure; bar(capacityfactorsccsreserves); 
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',ccsrowslabels);
% ylabel(['Capac. Factor of Reserves for all CCS Units'])

%Bar graph of CF of all CCS plants w.r.t. gen + reserves.
capacityfactorsccsgenandreserves=(totalccsgenerationisolated+totalccsreservesisolated)./maxgenccs;
figure; bar(capacityfactorsccsgenandreserves); colormap gray
xlabel('Scenario','fontsize',12,'fontweight','bold'); ax=gca; set(ax, 'XTickLabel',ccsrowslabels,'fontweight','bold');
ylabel(['Aggregate Capacity Factor for All CCS Units, Electricity Generation + Reserve Provision'],'fontsize',12,'fontweight','bold')
set(gca,'fontsize',12,'fontweight','bold')


%% PLANT-SPECIFIC CCS PLOTS************************************************
%Want to plot plant-specific generation & capacity factors. First, slim
%down by eliminating flex CCS scenarios in which we allow venting. Also
%eliminate rows w/ no ramp scaling.
allccsgenandreservessaved=allccsgenandreserves;
%Flex CCS + venting rows
rowstoelim=[];
for i=2:size(allccsgenandreserves,1)
    if strcmp(allccsgenandreserves{i,flexcolccs},'1')
        if str2num(allccsgenandreserves{i,ccsmwcolccs})>0
            if strcmp(allccsgenandreserves{i,ventcolccs},'1')
                rowstoelim=[rowstoelim;i];
            end
        end
    end
    if strcmp(allccsgenandreserves{i,rampcolccs},'0')
        rowstoelim=[rowstoelim;i];
    end
end
allccsgenandreserves(rowstoelim,:)=[];

%Get unique CCS generator names
uniqueccsnames=unique(allccsgenandreserves(2:end,ccsnamecol));
%Now strip out flex CCS components
flexccscomponents=[];
for i=1:size(uniqueccsnames,1)
    currgen=uniqueccsnames{i};
    if ~isempty(strfind(currgen,'Venting')) || ~isempty(strfind(currgen,'Discharge')) || ...
            ~isempty(strfind(currgen,'VentWhen')) || ~isempty(strfind(currgen,'Pump'))
        flexccscomponents=[flexccscomponents;i];
    end
end
uniqueccsnames(flexccscomponents,:)=[];

%Now, for each unique CCS name, store generation for all CCS components.
%So, want '4078', then generation @ 2gw normal ccs, 4 gw norm, 8 gw norm, 2
%gw flex, 4 gw flex, 8 gw flex.
%Initialize arrays
genbyccsandscenario={'CCSName','2GWFlex1','4GWFlex1','8GWFlex1','2GWFlex0','4GWFlex0','8GWFlex0'};
resbyccsandscenario={'CCSName','2GWFlex1','4GWFlex1','8GWFlex1','2GWFlex0','4GWFlex0','8GWFlex0'};
genandresbyccsandscenario={'CCSName','2GWFlex1','4GWFlex1','8GWFlex1','2GWFlex0','4GWFlex0','8GWFlex0'};
legendforplots={'Flex CCS 1.5 GW','Flex CCS 3 GW','Flex CCS 5.75 GW','Normal CCS 1.5 GW',...
    'Normal CCS 3 GW','Normal CCS 5.75 GW'};
for i=1:size(uniqueccsnames,1)
    %Get curr name
    currccsname=uniqueccsnames{i};
    %Add name to array and initilaize row to zeros
    newrownum=size(genbyccsandscenario,1)+1;
    genbyccsandscenario{newrownum,1}=currccsname;
    genbyccsandscenario(newrownum,2:end)=num2cell(zeros(1,size(genbyccsandscenario,2)-1));
    genandresbyccsandscenario{newrownum,1}=currccsname;
    genandresbyccsandscenario(newrownum,2:end)=num2cell(zeros(1,size(genandresbyccsandscenario,2)-1));
    resbyccsandscenario{newrownum,1}=currccsname;
    resbyccsandscenario(newrownum,2:end)=num2cell(zeros(1,size(resbyccsandscenario,2)-1));
        
    %Now find all rows with matching name - but want to exclude pump values
    matchingrowslogical=~cellfun('isempty',strfind(allccsgenandreserves(:,ccsnamecol),currccsname));
    %Now get row numbers
    matchingrows=find(matchingrowslogical==1);
    
    %Iterate through matching rows, get scenario info (norm vs. flex CCS,
    %capac CCS)
    for rowctr=1:size(matchingrows,1)
        currrow=matchingrows(rowctr);
        %Get flex CCS val
        flexccsval=allccsgenandreserves{currrow,flexcolccs}; %str
        %Get capac CCS
        ccsmwval=allccsgenandreserves{currrow,ccsmwcolccs}; %str
        %Combine into string that matches header in array
        headerstr=strcat(num2str(str2num(ccsmwval)/1000),'GWFlex',flexccsval);
        %Find appropriate column in array
        colinarray=find(strcmp(genbyccsandscenario(1,:),headerstr));
        
        %Get generation and reserves
        currgen=allccsgenandreserves{currrow,ccsgencol};
        currreserves=sum(cell2mat(allccsgenandreserves(currrow,ccsregupcol:ccsreplacecol)));
        
        %Add values to existing values in array
        genbyccsandscenario{newrownum,colinarray}=genbyccsandscenario{newrownum,colinarray}+currgen;
        resbyccsandscenario{newrownum,colinarray}=resbyccsandscenario{newrownum,colinarray}+currreserves;
        genandresbyccsandscenario{newrownum,colinarray}=genandresbyccsandscenario{newrownum,colinarray}+currgen+currreserves;
    end
end

%Now need to convert to capacity factors. 
cfforgenbyccsandscenario=genbyccsandscenario;
cfforgenandresbyccsandscenario=genandresbyccsandscenario;
for i=2:size(cfforgenbyccsandscenario,1)
    currccsname=cfforgenbyccsandscenario{i,1};
    %Find row in allccsgenandreserves for base generator
    allccsgenandreservesrow=find(strcmp(allccsgenandreserves(:,ccsnamecol),currccsname));
    %Just take 1st row and look up capacity (same in all rows)
    currbasecapac=allccsgenandreserves{allccsgenandreservesrow(1),ccscapaccol};
    %Now do same for SS generator
    currssccsname=strcat(currccsname,'SSDischargeDummy');
    allccsgenandreservesrowss=find(strcmp(allccsgenandreserves(:,ccsnamecol),currssccsname));
    currsscapac=allccsgenandreserves{allccsgenandreservesrowss(1),ccscapaccol};
    %Get max gen for each capacity
    maxbasegen=currbasecapac*24*numdaysinanalysis;
    maxssgen=currsscapac*24*numdaysinanalysis;
    %Get CFs by dividing by max gen. For generation, divide by base
    %capacity. For reserves & generation + reserve,s use SS value (so
    %CF<1). 
    cfforgenbyccsandscenario(i,2:end)=num2cell(cell2mat(cfforgenbyccsandscenario(i,2:end))/maxbasegen);
    cfforgenandresbyccsandscenario(i,5:7)=num2cell(cell2mat(cfforgenandresbyccsandscenario(i,5:7))/maxbasegen); %inflex
    cfforgenandresbyccsandscenario(i,2:4)=num2cell(cell2mat(cfforgenandresbyccsandscenario(i,2:4))/maxssgen); %flex
end
           
%PLOTS*********************************************************************
%Labels for x-axis are in first column (CCS names)
xlabelsccsunits=cfforgenandresbyccsandscenario(2:end,1)';

%Plot generation CFs
gencfs=cell2mat(cfforgenbyccsandscenario(2:end,2:end));
figure; bar(gencfs); colormap gray
ylabel('Capacity Factor for Electricity Generation','fontsize',12,'fontweight','bold'); 
xlabel('CCS Generator Name','fontsize',12,'fontweight','bold'); 
ax=gca; set(ax, 'XTickLabel',xlabelsccsunits,'fontweight','bold');
legend(legendforplots); set(gca,'fontsize',12,'fontweight','bold')

%Plot generation + reserve CFs
genandrescfs=cell2mat(cfforgenandresbyccsandscenario(2:end,2:end));
figure; bar(genandrescfs); ylabel('Capacity Factor for Electricity Generation + Reserves Provision','fontsize',12,'fontweight','bold'); colormap gray
xlabel('CCS Generator Name','fontsize',12,'fontweight','bold'); 
ax=gca; set(ax, 'XTickLabel',xlabelsccsunits,'fontweight','bold');
legend(legendforplots); set(gca,'fontsize',12,'fontweight','bold')

%% CALCULATE % OF SYSTEM PROCURED RESERVES FROM FLEXIBLE CCS
%Get total reserves from CCS by scenario
totalresfromccstemp=sum(cell2mat(resbyccsandscenario(2:end,2:end)),1);
%Save values
totalresfromccs=resbyccsandscenario(1,2:end); %steal headers
totalresfromccs=vertcat(totalresfromccs,num2cell(totalresfromccstemp)); clear totalresfromccstemp
%Now get total system reserves. Pick random alldata scenario - same in all
%instances.
totalsystemres=alldata{2,reserveprocuredcolalldata};
%Reserves as % of total system reserves
fracsysreservesfromccs=cell2mat(totalresfromccs(2,:))/totalsystemres;
%Plot values
% figure; bar(fracsysreservesfromccs); ylabel('Frac. of All Reserves Procured from CCS')
% xlabel('Scenario'); ax=gca; set(ax, 'XTickLabel',totalresfromccs(1,:));


%% CALCULATE BREAK-EVEN CAPITAL COSTS
%Calculate as:
%CEother * EmissionsFlex - OCFlex
%Set up results array:
breakevencapcosts={'Alternative Compliance Strategy','Breakeven Capital Cost at Low Capital Cost ($/kW)',...
    'Breakeven Capital Cost at Mid Capital Cost ($/kW)','Breakeven Capital Cost at High Capital Cost ($/kW)'};
flexccsscenarios={'FlxCCS1.5';'FlxCCS3';'FlxCCS5.8'};
normccsscenarios={'NrmCCS1.5';'NrmCCS3';'NrmCCS5.8'};
if testlowerlimit==0
    windscenarios={'Wnd2.5';'Wnd5.5';'Wnd6.5'};
else
    windscenarios={'Wnd3.5';'Wnd6.5';'Wnd13'};
end
breakevencapcosts(2:4,1)=windscenarios;
breakevencapcosts(5:7,1)=normccsscenarios;
breakevencapcostsredispatch={'Alternative Compliance Strategy','Breakeven Capital Cost at 2 GW Flexible CCS ($/kW)',...
    'Breakeven Capital Cost at 4 GW Flexible CCS ($/kW)','Breakeven Capital Cost at 8 GW Flexible CCS ($/kW)'};
breakevencapcostsredispatch{2,1}='Redispatch';
%For each flex CCS scenario, get operational cost & emissions. Then look up
%corresponding wind scenario & get its cost-effectiveness. Then calculate
%break-even capital cost.
for i=1:3
    currflexccsscenario=flexccsscenarios{i};
    currnormccsscenario=normccsscenarios{i};
    currwindscenario=windscenarios{i};
    %Get row of flex CCS and wind
    flexccsrow=find(strcmp(graphlabelsnobasecase(:,1),currflexccsscenario));
    normccsrow=find(strcmp(graphlabelsnobasecase(:,1),currnormccsscenario));
    windrow=find(strcmp(graphlabelsnobasecase(:,1),currwindscenario));
    redispatchrow=find(strcmp(graphlabelsnobasecase(:,1),'Rdsptch'));
    %Get op cost & emissions of flex CCS scenario
    currflexopcost=totalopcostdiffnobase(flexccsrow);
    currflexemissions=co2cppemissionsreductionsscaled(flexccsrow);
    %Get net CCS capacity in kW (originally given in MW)
    currccsnetcapackw=allccscapacitiesisolated(i)*1000;
    %For each capital value for wind & norm CCS, get cost-eff, calc break-even, & save
    %value
    saverowwind=find(strcmp(breakevencapcosts(:,1),currwindscenario));
    saverownormccs=find(strcmp(breakevencapcosts(:,1),currnormccsscenario));
    for capctr=1:3 %get cost-eff in $/ton
        if capctr==1
            currwindcosteff=opandcapcostperco2emsreduxscaledlow(windrow);
            currnormccscosteff=opandcapcostperco2emsreduxscaledlow(normccsrow);
        elseif capctr==2
            currwindcosteff=opandcapcostperco2emsreduxscaledmid(windrow); 
            currnormccscosteff=opandcapcostperco2emsreduxscaledmid(normccsrow);
        elseif capctr==3
            currwindcosteff=opandcapcostperco2emsreduxscaledhigh(windrow);
            currnormccscosteff=opandcapcostperco2emsreduxscaledhigh(normccsrow);
        end
        %Breakeven: $/ton * ton - $
        breakevenwind=currwindcosteff*currflexemissions-currflexopcost;
        breakevennormccs=currnormccscosteff*currflexemissions-currflexopcost;
        %Normalize for kW flexible CCS in scenario
        breakevenwindperkw=breakevenwind/currccsnetcapackw;
        breakevennormccsperkw=breakevennormccs/currccsnetcapackw;
        %Save value
        breakevencapcosts{saverowwind,capctr+1}=breakevenwindperkw;
        breakevencapcosts{saverownormccs,capctr+1}=breakevennormccsperkw;
    end
    %Get value & save for re-dispatch
    currredispatchcosteff=opandcapcostperco2emsreduxscaledlow(redispatchrow);
    breakevendispatch=currredispatchcosteff*currflexemissions-currflexopcost;
    breakevendispatchperkw=breakevendispatch/currccsnetcapackw;
    breakevencapcostsredispatch{2,i+1}=breakevendispatchperkw;
end



end


 








