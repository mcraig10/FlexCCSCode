
reservecostsall={'FlexCCS','CCSMW','ActualCCSMW','ActualSSMW','WindMW','AllowVent','ScaleRamp','CalcCO2Price',...
    'Res1','Res2','Res3','Res4'};
flexcolalldata=find(strcmp(reservecostsall(1,:),'FlexCCS'));
ccsmwcolalldata=find(strcmp(reservecostsall(1,:),'CCSMW'));
actualccsmwcolalldata=find(strcmp(reservecostsall(1,:),'ActualCCSMW'));
actualssmwcolalldata=find(strcmp(reservecostsall(1,:),'ActualSSMW'));
windmwcolalldata=find(strcmp(reservecostsall(1,:),'WindMW'));
ventcolalldata=find(strcmp(reservecostsall(1,:),'AllowVent'));
rampcolalldata=find(strcmp(reservecostsall(1,:),'ScaleRamp'));
calcco2pricealldata=find(strcmp(reservecostsall(1,:),'CalcCO2Price'));
res1col=find(strcmp(reservecostsall(1,:),'Res1'));
res2col=find(strcmp(reservecostsall(1,:),'Res2'));
res3col=find(strcmp(reservecostsall(1,:),'Res3'));
res4col=find(strcmp(reservecostsall(1,:),'Res4'));

%% ITERATE THROUGH FOLDERS (DIFFERENT RUNS)
for folderctr=1:size(foldernames,1)
    %Set current folder name
    currfolder=foldernames{folderctr};
    currfolderdir=fullfile(basedirforflatfiles,currfolder);
    
    %Set folder name w/ fiscal year data
    fiscalyeardir=fullfile(currfolderdir,'fiscal year');
    
    %% GET RELEVANT PARAMETERS FROM FOLDER NAME
    [flexccsval,ccsmwval,windmwval,rampval,ventval,calcco2priceval]=GetLabelsFromFileName(currfolder);
        
%% RESERVES OUTPUT
    %Reserve cost [ST Reserve(*).Cost]
    %Reserves provision [ST Reserve(*).Provision]
    %Want to add up costs for all reserves, of which there are 4.
    reservecosttotal=0; reserveprovisiontotal=0;
    res1=0; res2=0; res3=0; res4=0; diffres=[];
    for reserveid=1:4
        reservecostfile=strcat('ST Reserve(',num2str(reserveid),').Cost');
        reservecostdata=ExtractDataPLEXOSAnnual(fiscalyeardir,reservecostfile);
        reservecost=reservecostdata{2,4}*scaleresults;
        reservecosttotal=reservecosttotal+reservecost;
        
        if reserveid==1
            res1=reservecost;
        elseif reserveid==2
            res2=reservecost;
        elseif reserveid==3
            res3=reservecost;
        else
            res4=reservecost;
        end
        
        reserveprovisionfile=strcat('ST Reserve(',num2str(reserveid),').Provision');
        reserveprovisiondata=ExtractDataPLEXOSAnnual(fiscalyeardir,reserveprovisionfile);
        reserveprovision=reserveprovisiondata{2,4}*scaleresults;
        reserveprovisiontotal=reserveprovisiontotal+reserveprovision;
    end
    diffres=[diffres;reservecosttotal-res1-res2-res3-res4];
    
    %% STORE OUTPUT
    newrow=size(reservecostsall,1)+1;
    reservecostsall{newrow,flexcolalldata}=flexccsval;
    reservecostsall{newrow,ccsmwcolalldata}=ccsmwval;
    if (strcmp(ccsmwval,'8000')) actualccsmwtemp='5754'; 
        if (strcmp(flexccsval,'1')) actualssmwtemp='7866'; else actualssmwtemp='0'; end;
    elseif (strcmp(ccsmwval,'4000')) actualccsmwtemp='3026'; 
        if (strcmp(flexccsval,'1')) actualssmwtemp='4088'; else actualssmwtemp='0'; end;
    elseif (strcmp(ccsmwval,'2000')) actualccsmwtemp='1554';
        if (strcmp(flexccsval,'1')) actualssmwtemp='2073'; else actualssmwtemp='0'; end;
    else actualccsmwtemp='0'; actualssmwtemp='0';
    end
    
    reservecostsall{newrow,actualccsmwcolalldata}=actualccsmwtemp;
    reservecostsall{newrow,actualssmwcolalldata}=actualssmwtemp;
    reservecostsall{newrow,windmwcolalldata}=windmwval;
    reservecostsall{newrow,ventcolalldata}=ventval;
    reservecostsall{newrow,rampcolalldata}=rampval;
    reservecostsall{newrow,calcco2pricealldata}=calcco2priceval;
    reservecostsall{newrow,res1col}=res1;
    reservecostsall{newrow,res2col}=res2;
    reservecostsall{newrow,res3col}=res3;
    reservecostsall{newrow,res4col}=res4;
end