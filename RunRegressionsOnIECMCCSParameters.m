%Michael Craig
%18 September 2015
%This function imports CCS parameters obtained from the IECM and located in
%an Excel file, and then runs regressions between these parameters and
%either the base plant net heat rate or CCS plant net heat rate. Separate
%regressions are run for subbituminous and bituminous fuel. For more
%information on the IECM data, see the imported spreadsheet below.

function [lmnethrpenaltybit, lmcapacpenaltybit, lmssnethrpenaltybit, lmsscapacpenaltybit, ...
    lmeextraperestoresolventbit, lmegridpereco2capandregenbit, lmegridssperetostoreleanbit,regentoco2capeuseratiobit,...
    lmnethrpenaltysubbit, lmcapacpenaltysubbit, lmssnethrpenaltysubbit, lmsscapacpenaltysubbit, ...
    lmeextraperestoresolventsubbit, lmegridpereco2capandregensubbit, lmegridssperetostoreleansubbit,regentoco2capeuseratiosubbit]...
    = RunRegressionsOnIECMCCSParameters(pc)

%% IMPORT SPREADSHEET WITH DATA
if strcmp(pc,'work')
    ccsfiledir='C:\Users\mtcraig\Desktop\EPP Research\Flexible CCS Excel Model';
elseif strcmp(pc,'personal')
    ccsfiledir='C:\Users\mcraig10\Desktop\EPP Research\Flexible CCS Excel Model';
end
ccsfilename='FlexCCSExcelModel_17Sept2015.xlsx';
[~,~,ccsparamscell]=xlsread(fullfile(ccsfiledir,ccsfilename),'FLEXCCSPARAMETERS');

%% ISOLATE CLEAN PARAMETERS
%Two tables in this sheet; want the lower one, which has the parameters
%that I want isolated. Find first row of that table
firstrow=find(strcmp(ccsparamscell(:,1),'PARAMETER VALUES FOR MATLAB'))+1;
%Find last column of data
for colctr=1:size(ccsparamscell,2)
    if isnan(ccsparamscell{firstrow,colctr})
        lastcol=colctr-1; %was last column
        break
    end
end
%Find last row of data
for rowctr=firstrow:size(ccsparamscell,1)
    if isnan(ccsparamscell{rowctr,1})
        lastrow=rowctr-1; %was last column
        break
    end
end

%Isolate data in that table
ccsparams=ccsparamscell(firstrow:lastrow,1:lastcol); 

%% COLUMN HEADERS
% colnames={'E for Solvent to Capture CO2 from Fuel for To-Be-Stored Lean/E to Store Lean Solvent (MWh/MWh)';
%     'E to Regenerator/E to CO2Cap (MWh/MWh)';
%     'Net E to Grid / E to CO2 Cap+Regen (MWh/MWh)';
%     'Net E to Grid When Discharging Stored Lean/E Used to Store Lean Solvent (MWh/MWh)';
%     'CCS Net HR (Btu/kWh)';
%     'Base Plant Net HR (Btu/kWh)';
%     'CCS Net HR Penalty (%)';
%     'CCS Net Capacity Penalty (%)';
%     'CCS w/ Discharged Stored Lean Solvent Net HR Penalty (%)';
%     'CCS w/ Discharged Stored Lean Solvent Capacity Penalty (%)'};
    

%% RUN REGRESSIONS
%To make regressions, need to create tables of all interested variables.
%Need to do this for both types of fuel. So iterate over fuel types.
%For each regression, need to isolate variables of interest and store into
%table, then run reg. 
fueltypes=unique(ccsparams(2:end,1));
for fuelctr=1:size(fueltypes,1)
    currfuel=fueltypes{fuelctr};
    rowswithcurrfuel=find(strcmp(ccsparams(:,1),currfuel));
    
    %STORE E TO REGEN PER E TO CO2 CAP RATIO FOR EXPORT (NOT REGRESSION)
    regentoco2capcol=find(strcmp(ccsparams(1,:),'E to Regenerator/E to CO2Cap (MWh/MWh)'));
    ccsnethrcol=find(strcmp(ccsparams(1,:),'CCS Net HR (Btu/kWh)'));
    if strcmp(currfuel,'Bituminous')
        regentoco2capeuseratiobit=horzcat(vertcat(ccsparams(1,ccsnethrcol),ccsparams(rowswithcurrfuel,ccsnethrcol)),...
            vertcat(ccsparams(1,regentoco2capcol),ccsparams(rowswithcurrfuel,regentoco2capcol)));
    elseif strcmp(currfuel,'Subbituminous')
        regentoco2capeuseratiosubbit=horzcat(vertcat(ccsparams(1,ccsnethrcol),ccsparams(rowswithcurrfuel,ccsnethrcol)),...
            vertcat(ccsparams(1,regentoco2capcol),ccsparams(rowswithcurrfuel,regentoco2capcol)));
    end  

    %REGRESSIONS ON BASE (PRE-CCS) PLANT NET HR
    %CCS Net HR Penalty on Base Net HR
    indvar='Base Plant Net HR (Btu/kWh)'; %independent variable
    depvar='CCS Net HR Penalty (%)'; %dependent variable
    indvarcol=find(strcmp(ccsparams(1,:),indvar));
    depvarcol=find(strcmp(ccsparams(1,:),depvar));
    basenethr=cell2mat(ccsparams(rowswithcurrfuel,indvarcol));
    ccsnethrpenalty=cell2mat(ccsparams(rowswithcurrfuel,depvarcol));
    tbl=table(basenethr,ccsnethrpenalty);
    if strcmp(currfuel,'Bituminous')
        lmnethrpenaltybit=fitlm(tbl);
    elseif strcmp(currfuel,'Subbituminous')
        lmnethrpenaltysubbit=fitlm(tbl);
    end
    clear tbl;
    %Test val, subbit: 9807 -> 46.43%
     
    %CCS Capacity Penalty on Base Net HR
    indvar='Base Plant Net HR (Btu/kWh)'; %independent variable
    depvar='CCS Net Capacity Penalty (%)'; %dependent variable
    indvarcol=find(strcmp(ccsparams(1,:),indvar));
    depvarcol=find(strcmp(ccsparams(1,:),depvar));
    basenethr=cell2mat(ccsparams(rowswithcurrfuel,indvarcol));
    ccscapacpenalty=cell2mat(ccsparams(rowswithcurrfuel,depvarcol));
    tbl=table(basenethr,ccscapacpenalty);
    if strcmp(currfuel,'Bituminous')
        lmcapacpenaltybit=fitlm(tbl);
    elseif strcmp(currfuel,'Subbituminous')
        lmcapacpenaltysubbit=fitlm(tbl);
    end
    clear tbl;
    %Test val, subbit: 9807 ->  31.72%
    
    %CCS w/ SS Net HR Penalty on Base Net HR (SS=Solvent Storage, meaning
    %this is Net HR Penalty when discharging stored lean solvent.)
    indvar='Base Plant Net HR (Btu/kWh)'; %independent variable
    depvar='CCS w/ Discharged Stored Lean Solvent Net HR Penalty (%)'; %dependent variable
    indvarcol=find(strcmp(ccsparams(1,:),indvar));
    depvarcol=find(strcmp(ccsparams(1,:),depvar));
    basenethr=cell2mat(ccsparams(rowswithcurrfuel,indvarcol));
    ccsssnethrpenalty=cell2mat(ccsparams(rowswithcurrfuel,depvarcol));
    tbl=table(basenethr,ccsssnethrpenalty);
    if strcmp(currfuel,'Bituminous')
        lmssnethrpenaltybit=fitlm(tbl);
    elseif strcmp(currfuel,'Subbituminous')
        lmssnethrpenaltysubbit=fitlm(tbl);
    end
    clear tbl;
    %Test val, subbit: 9807 -> 4.31%
    
    %CCS w/ SS Capacity Penalty on Base Net HR
    indvar='Base Plant Net HR (Btu/kWh)'; %independent variable
    depvar='CCS w/ Discharged Stored Lean Solvent Capacity Penalty (%)'; %dependent variable
    indvarcol=find(strcmp(ccsparams(1,:),indvar));
    depvarcol=find(strcmp(ccsparams(1,:),depvar));
    basenethr=cell2mat(ccsparams(rowswithcurrfuel,indvarcol));
    ccsssnetcapacpenalty=cell2mat(ccsparams(rowswithcurrfuel,depvarcol));
    tbl=table(basenethr,ccsssnetcapacpenalty);
    if strcmp(currfuel,'Bituminous')
        lmsscapacpenaltybit=fitlm(tbl);
    elseif strcmp(currfuel,'Subbituminous')
        lmsscapacpenaltysubbit=fitlm(tbl);
    end
    clear tbl;
    %Test val, subbit: 9807 -> 4.15%
    
    %REGRESSIONS ON CCS PLANT NET HR
    %E for Extra Solvent per E Solvent Stored on CCS Net HR
    indvar='CCS Net HR (Btu/kWh)'; %independent variable
    depvar='E for Solvent to Capture CO2 from Fuel for To-Be-Stored Lean/E to Store Lean Solvent (MWh/MWh)'; %dependent variable
    indvarcol=find(strcmp(ccsparams(1,:),indvar));
    depvarcol=find(strcmp(ccsparams(1,:),depvar));
    ccsnethr=cell2mat(ccsparams(rowswithcurrfuel,indvarcol));
    eextraperestoresolvent=cell2mat(ccsparams(rowswithcurrfuel,depvarcol));
    tbl=table(ccsnethr,eextraperestoresolvent);
    if strcmp(currfuel,'Bituminous')
        lmeextraperestoresolventbit=fitlm(tbl);
    elseif strcmp(currfuel,'Subbituminous')
        lmeextraperestoresolventsubbit=fitlm(tbl);
    end
    clear tbl;
    %Test val, subbit: 14360 -> .41
        
    %E to Grid per E to CO2 Cap + Regen on CCS Net HR
    indvar='CCS Net HR (Btu/kWh)'; %independent variable
    depvar='Net E to Grid / E to CO2 Cap+Regen (MWh/MWh)'; %dependent variable
    indvarcol=find(strcmp(ccsparams(1,:),indvar));
    depvarcol=find(strcmp(ccsparams(1,:),depvar));
    ccsnethr=cell2mat(ccsparams(rowswithcurrfuel,indvarcol));
    egridpereco2capandregen=cell2mat(ccsparams(rowswithcurrfuel,depvarcol));
    tbl=table(ccsnethr,egridpereco2capandregen);
    if strcmp(currfuel,'Bituminous')
        lmegridpereco2capandregenbit=fitlm(tbl);
    elseif strcmp(currfuel,'Subbituminous')
        lmegridpereco2capandregensubbit=fitlm(tbl);
    end
    clear tbl;
    %Test val, subbit: 14360 -> 2.15
    
    %E to Grid w/ SS per E used to Store Lean on CCS Net HR
    indvar='CCS Net HR (Btu/kWh)'; %independent variable
    depvar='Net E to Grid When Discharging Stored Lean/E Used to Store Lean Solvent (MWh/MWh)'; %dependent variable
    indvarcol=find(strcmp(ccsparams(1,:),indvar));
    depvarcol=find(strcmp(ccsparams(1,:),depvar));
    ccsnethr=cell2mat(ccsparams(rowswithcurrfuel,indvarcol));
    egridssperetostorelean=cell2mat(ccsparams(rowswithcurrfuel,depvarcol));
    tbl=table(ccsnethr,egridssperetostorelean);
    if strcmp(currfuel,'Bituminous')
        lmegridssperetostoreleanbit=fitlm(tbl);
    elseif strcmp(currfuel,'Subbituminous')
        lmegridssperetostoreleansubbit=fitlm(tbl);
    end
    clear tbl;
    %Test val, subbit: 14360 -> 3.02
end













