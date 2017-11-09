%Michael Craig
%November 4, 2015
%Function obtains interval generation and reserves data for each flexible
%and normal CCS unit, as well as aggregate values for all units, for a
%given scenario.

%% KEY PARAMETERS
%Indicate whether running on server ( 1 = yes)
server=0;

%Scenario name
scenarioname='CPPEEPt5FlxCCS0MW2000WndMW0Rmp1Grp1MSL0NLDC0Vnt1';

%% PLEXOS OUTPUT FILE NAMES
%Give base directory for PLEXOS output
if server==0
%     basedirforflatfiles='C:\Users\mcraig10\Desktop\EPP Research\PLEXOS\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output';
    basedirforflatfiles='C:\Users\mcraig10\Desktop\FakeOutputForMATLABTests';
elseif server==1
    basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output';
end

%Set folder name w/ model output
plexosoutputfolder=scenarioname;

%Set PLEXOS dir
plexosoutputdir=fullfile(basedirforflatfiles,plexosoutputfolder);

%% MATLAB FLEET FILE NAMES
%Give directory and name of MATLAB fleet files
if server==0
    dirformatlabfleet='C:\Users\mcraig10\Desktop\EPP Research\Matlab\Fleets';
elseif server==1
    dirformatlabfleet='C:\Users\mtcraig\Desktop\EPP Research\Matlab\Fleets';
end

%Set fleet file name
matlabfleetname=strcat(scenarioname,'.mat');

%Load futurepowerfleetforplexos
load(fullfile(dirformatlabfleet,matlabfleetname),'futurepowerfleetforplexos');

%% GET FLEET COLUMNS
[fleetorisidcol,fleetunitidcol,fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol,fleetregioncol,fleetstatecol,fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol, fleetpumpunitscol, fleetpumpeffcol, fleetpumploadcol,...
    fleetccsretrofitcol,fleettruesscapacitycol,fleetaffectedegucol,fleethrpenaltycol,...
    fleetcapacpenaltycol,fleetsshrpenaltycol,fleetsscapacpenaltycol,fleeteextraperestorecol,...
    fleeteregenpereco2capcol,fleetegridpereco2capandregencol,fleetegriddischargeperestorecol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);

%% IMPORT ID2NAME FILE
%Import file
[~,~,id2name]=xlsread(fullfile(plexosoutputdir,'id2name.csv'),'id2name');

%Get column #s of id2name. id col has id #; name col has GEN-ORIS ID. 
classcol=find(strcmp(id2name(1,:),'class'));
plexosidcol=find(strcmp(id2name(1,:),'id'));
unitnamecol=find(strcmp(id2name(1,:),'name'));

%Isolate 'Generator' class rows
genrows=find(strcmp(id2name(:,classcol),'Generator'));
id2namegens=id2name(genrows,:);

%% OPEN RANDOM INTERVAL FILE TO GET YEAR/MONTH/DAY FORMAT
%First, get col info for interval data
intervaldir=fullfile(plexosoutputdir,'interval');
[~,~,randfile]=xlsread(strcat(intervaldir,'\ST Generator(1).Generation.csv'),'ST Generator(1).Generation');
intervalcsvyearcol=find(strcmp(randfile(1,:),'YEAR'));
intervalcsvmonthcol=find(strcmp(randfile(1,:),'MONTH'));
intervalcsvdaycol=find(strcmp(randfile(1,:),'DAY'));
intervalcsvhour1col=intervalcsvdaycol+1;
numhours=(size(randfile,1)-1)*24;
yearinfocol={'Year'};
monthinfocol={'Month'};
dayinfocol={'Day'};
hourinfocol={'Hour'};
for i=2:size(randfile,1)
    yearinfocol=vertcat(yearinfocol,num2cell(repmat(randfile{i,intervalcsvyearcol},24,1)));
    monthinfocol=vertcat(monthinfocol,num2cell(repmat(randfile{i,intervalcsvmonthcol},24,1)));
    dayinfocol=vertcat(dayinfocol,num2cell(repmat(randfile{i,intervalcsvdaycol},24,1)));
    hourinfocol=vertcat(hourinfocol,num2cell(1:24)');
end
dateinfo=horzcat(yearinfocol,monthinfocol,dayinfocol,hourinfocol);

%% FIND CCS GENERATORS USING RETROFIT COL
ccsretrofitdata=cell2mat(futurepowerfleetforplexos(2:end,fleetccsretrofitcol));
ccsretrofitrows=find(ccsretrofitdata==1)+1; %shift forward 1 since doing 2:end in prior line

%% GET GENERATION AND RESERVES BY EACH COMPONENT FOR EACH FLEX CCS UNIT
%Initialize results arrays for interval data
flexccsgen=dateinfo;
flexccsregraise=dateinfo;
flexccsraise=dateinfo;
flexccsreglower=dateinfo;
flexccsreplace=dateinfo;

%Initialize results array for aggregate values
flexccstotalresults={'Unit','ElecGen(MW)','RegRaise(MW)','RegLower(MW)','Raise(MW)','Replace(MW)'};
unitcoltotalresults=find(strcmp(flexccstotalresults(1,:),'Unit'));
gencoltotalresults=find(strcmp(flexccstotalresults(1,:),'ElecGen(MW)'));
regraisecoltotalresults=find(strcmp(flexccstotalresults(1,:),'RegRaise(MW)'));
reglowercoltotalresults=find(strcmp(flexccstotalresults(1,:),'RegLower(MW)'));
raisecoltotalresults=find(strcmp(flexccstotalresults(1,:),'Raise(MW)'));
replacecoltotalresults=find(strcmp(flexccstotalresults(1,:),'Replace(MW)'));

for unitctr=1:size(ccsretrofitrows,1)
    currfleetrow=ccsretrofitrows(unitctr);
    
    %Get ORIS & unit IDs
    curroris=futurepowerfleetforplexos{currfleetrow,fleetorisidcol};
    currunitid=futurepowerfleetforplexos{currfleetrow,fleetunitidcol};
    
    %Find associated generators
    basegenname=strcat(curroris,'-',currunitid);
    solvgenname=strcat(basegenname,'ContinuousSolvent');
    pump1genname=strcat(basegenname,'SSPump1');
    pump2genname=strcat(basegenname,'SSPump2');
    dischargedummy1genname=strcat(basegenname,'SSDischargeDummy1');
    dischargedummy2genname=strcat(basegenname,'SSDischargeDummy2');
    pumpdummy1genname=strcat(basegenname,'SSPumpDummy1');
    pumpdummy2genname=strcat(basegenname,'SSPumpDummy2');
    ventgenname=strcat(basegenname,'Venting');
    ventchargegenname=strcat(basegenname,'SSVentWhenCharge');
    %Get rows in PLEXOS files
    basegenrow=find(strcmp(id2namegens(:,unitnamecol),basegenname));
    contsolvrow=find(strcmp(id2namegens(:,unitnamecol),solvgenname));
    pump1row=find(strcmp(id2namegens(:,unitnamecol),pump1genname));
    pump2row=find(strcmp(id2namegens(:,unitnamecol),pump2genname));
    discharge1row=find(strcmp(id2namegens(:,unitnamecol),dischargedummy1genname));
    discharge2row=find(strcmp(id2namegens(:,unitnamecol),dischargedummy2genname));
    pumpdummy1row=find(strcmp(id2namegens(:,unitnamecol),pumpdummy1genname));
    pumpdummy2row=find(strcmp(id2namegens(:,unitnamecol),pumpdummy2genname));
    ventrow=find(strcmp(id2namegens(:,unitnamecol),ventgenname));
    ventchargerow=find(strcmp(id2namegens(:,unitnamecol),ventchargegenname));
    %Combine rows
    flexccsnames={basegenname;solvgenname;pump1genname;pump2genname;...
        dischargedummy1genname;dischargedummy2genname;pumpdummy1genname;...
        pumpdummy2genname;ventgenname;ventchargegenname};
    %Make sure order of gen rows here is same as names above!
    flexccsgenrows=vertcat(basegenrow,contsolvrow,pump1row,pump2row,...
        discharge1row,discharge2row,pumpdummy1row,pumpdummy2row,...
        ventrow,ventchargerow);
    
    %GET INTERVAL GENERATION AND RESERVES FOR ALL UNITS****************
    %For each row, find PLEXOS ID
    %Then open CSV
    %Then save data to cell array. 1 for generation, another for each
    %reserves.
    %Column header = name. Rest of rows = data
    for genctr=1:size(flexccsgenrows,1)
        %Find PLEXOS ID
        currgenrow=flexccsgenrows(genctr);
        currplexosid=id2namegens{currgenrow,plexosidcol};
        currgenname=flexccsnames{genctr};
        
        %Open CSVs
        %Generation
        intervalgencsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Generation');
        intervalgencsvname=strcat(intervalgencsvnamebase,'.csv');
        [~,~,currintervalgeneration]=xlsread(fullfile(intervaldir,intervalgencsvname),intervalgencsvnamebase);
        
        %Raise reserve
        intervalraisereservecsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Raise Reserve');
        intervalraisereservecsvname=strcat(intervalraisereservecsvnamebase,'.csv');
        if length(intervalraisereservecsvnamebase)>31
            intervalraisereservecsvnamebase=intervalraisereservecsvnamebase(1:31);
        end
        [~,~,currintervalraisereserves]=xlsread(fullfile(intervaldir,intervalraisereservecsvname),intervalraisereservecsvnamebase);
        
        %Reg raise reserve
        intervalregraisereservecsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Regulation Raise Reserve');
        intervalregraisereservecsvname=strcat(intervalregraisereservecsvnamebase,'.csv');
        if length(intervalregraisereservecsvnamebase)>31
            intervalregraisereservecsvnamebase=intervalregraisereservecsvnamebase(1:31);
        end
        [~,~,currintervalregraisereserves]=xlsread(fullfile(intervaldir,intervalregraisereservecsvname),intervalregraisereservecsvnamebase);
        
        %Reg lower reserve
        intervalreglowerreservecsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Regulation Lower Reserve');
        intervalreglowerreservecsvname=strcat(intervalreglowerreservecsvnamebase,'.csv');
        if length(intervalreglowerreservecsvnamebase)>31
            intervalreglowerreservecsvnamebase=intervalreglowerreservecsvnamebase(1:31);
        end
        [~,~,currintervalreglowerreserves]=xlsread(fullfile(intervaldir,intervalreglowerreservecsvname),intervalreglowerreservecsvnamebase);
        
        %Replacement reserve
        intervalreplacereservecsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Replacement Reserve');
        intervalreplacereservecsvname=strcat(intervalreplacereservecsvnamebase,'.csv');
        if length(intervalreplacereservecsvnamebase)>31
            intervalreplacereservecsvnamebase=intervalreplacereservecsvnamebase(1:31);
        end
        [~,~,currintervalreplacereserve]=xlsread(fullfile(intervaldir,intervalreplacereservecsvname),intervalreplacereservecsvnamebase);
        
        %Get generation and reserve values - need to go across a row and get each hour,
        %then down.
        intervalgenvalues=cell2mat(currintervalgeneration(2:end,intervalcsvhour1col:end));
        intervalraisereservevalues=cell2mat(currintervalraisereserves(2:end,intervalcsvhour1col:end));
        intervalregraisereservevalues=cell2mat(currintervalregraisereserves(2:end,intervalcsvhour1col:end));
        intervalreglowerreservevalues=cell2mat(currintervalreglowerreserves(2:end,intervalcsvhour1col:end));
        intervalreplacereservevalues=cell2mat(currintervalreplacereserve(2:end,intervalcsvhour1col:end));
        
        %Compile values
        genvals={currgenname};
        raisevals={currgenname};
        regraisevals={currgenname};
        reglowervals={currgenname};
        replacevals={currgenname};
        for j=1:size(intervalgenvalues,1)
            genvals=vertcat(genvals,num2cell(intervalgenvalues(j,:))');
            raisevals=vertcat(raisevals,num2cell(intervalraisereservevalues(j,:))');
            regraisevals=vertcat(regraisevals,num2cell(intervalregraisereservevalues(j,:))');
            reglowervals=vertcat(reglowervals,num2cell(intervalreglowerreservevalues(j,:))');
            replacevals=vertcat(replacevals,num2cell(intervalreplacereservevalues(j,:))');
        end
        
        %Save values
        flexccsgen=horzcat(flexccsgen,genvals); clear genvals
        flexccsraise=horzcat(flexccsraise,raisevals); clear raisevals
        flexccsregraise=horzcat(flexccsregraise,regraisevals); clear regraisevals
        flexccsreglower=horzcat(flexccsreglower,reglowervals); clear reglowervals
        flexccsreplace=horzcat(flexccsreplace,replacevals); clear replacevals
        
        
        %GET TOTAL GENERATION AND RESERVES FOR ALL SOME UNITS
        %Want aggregate generation & reserves data for the base CCS,
        %discharge, and vent units. Sum interval data.
        if strcmp(currgenname,basegenname) || strcmp(currgenname,dischargedummy1genname) || ...
                strcmp(currgenname,dischargedummy2genname) || strcmp(currgenname,ventgenname)
            %Sum generation and reserve values
            totalgen=sum(cell2mat(genvals(2:end)));
            totalraise=sum(cell2mat(raisevals(2:end)));
            totalregraise=sum(cell2mat(regraisevals(2:end)));
            totalreglower=sum(cell2mat(reglowervals(2:end)));
            totalreplace=sum(cell2mat(replacevals(2:end)));
            
            %Save values
            newrow=unitctr+1; %unitctr tracks each new flex CCS gen; add 1 to accomodate header
            flexccstotalresults{newrow,unitcoltotalresults}=currgenname;
            flexccstotalresults{newrow,gencoltotalresults}=totalgen;
            flexccstotalresults{newrow,raisecoltotalresults}=totalraise;
            flexccstotalresults{newrow,regraisecoltotalresults}=totalregraise;
            flexccstotalresults{newrow,reglowercoltotalresults}=totalreglower;
            flexccstotalresults{newrow,replacecoltotalresults}=totalreplace;
        end
    end
end










%% CREATE PLOTS OF DATA
% %Find year/month/day/hour cols
% yearcol=find(strcmp(flexccsgen(1,:),'Year'));
% monthcol=find(strcmp(flexccsgen(1,:),'Month'));
% daycol=find(strcmp(flexccsgen(1,:),'Day'));
% 
% %Get first col of data
% firstcolofgendata=find(strcmp(flexccsgen(1,:),'Hour'))+1;
% %Get first & last row of data
% firstrowofgendata=2; lastrowofgendata=size(flexccsgen,1);
% flexccsnames={basegenname;solvgenname;pump1genname;pump2genname;...
%     dischargedummy1genname;dischargedummy2genname;pumpdummy1genname;...
%     pumpdummy2genname;ventgenname;ventchargegenname};
% 
% %Plot generation of all units
% gentoplot=cell2mat(flexccsgen(2:end,firstcolofgendata:end));
% figure
% plot(gentoplot,'LineWidth',3)
% set(gca,'FontSize',20);
% ylabel('Electricity Gen. (MWh)');
% xlabel('Date')
% set(gca,'XTick',[1 numhours]);
% firstdate={strcat(num2str(flexccsgen{firstrowofgendata,monthcol}),'/',...
%     num2str(flexccsgen{firstrowofgendata,daycol}),'/',...
%     num2str(flexccsgen{firstrowofgendata,yearcol}))};
% lastdate={strcat(num2str(flexccsgen{lastrowofgendata,monthcol}),'/',...
%     num2str(flexccsgen{lastrowofgendata,daycol}),'/',...
%     num2str(flexccsgen{lastrowofgendata,yearcol}))};
% set(gca,'XTickLabel',[firstdate,lastdate]);
% flexccsnamesforplot={'Base','Cont. Solvent','Pump 1','Pump 2','SS Discharge 1',...
%     'SS Discharge 2','Pump Dummy 1','Pump Dummy 2','Venting','Vent When Charge'};
% legend(flexccsnamesforplot,'FontSize',20)
% 
% %Plot generation of elec-gen'ing units
% gentoplot=cell2mat(flexccsgen(2:end,firstcolofgendata:end));
% figure
% plot(gentoplot,'LineWidth',3)
% set(gca,'FontSize',20);
% ylabel('Electricity Gen. (MWh)');
% xlabel('Date')
% set(gca,'XTick',[1 numhours]);
% firstdate={strcat(num2str(flexccsgen{firstrowofgendata,monthcol}),'/',...
%     num2str(flexccsgen{firstrowofgendata,daycol}),'/',...
%     num2str(flexccsgen{firstrowofgendata,yearcol}))};
% lastdate={strcat(num2str(flexccsgen{lastrowofgendata,monthcol}),'/',...
%     num2str(flexccsgen{lastrowofgendata,daycol}),'/',...
%     num2str(flexccsgen{lastrowofgendata,yearcol}))};
% set(gca,'XTickLabel',[firstdate,lastdate]);
% legend(flexccsnames,'FontSize',16)
% 
% %Plot reg raise of all units
% regraisetoplot=cell2mat(flexccsregraise(2:end,firstcolofgendata:end));
% figure
% plot(regraisetoplot,'LineWidth',2)
% set(gca,'FontSize',16);
% ylabel('Reg. Raise (MW)');
% xlabel('Date')
% set(gca,'XTick',[1 numhours]);
% firstdate={strcat(num2str(flexccsgen{firstrowofgendata,monthcol}),'/',...
%     num2str(flexccsgen{firstrowofgendata,daycol}),'/',...
%     num2str(flexccsgen{firstrowofgendata,yearcol}))};
% lastdate={strcat(num2str(flexccsgen{lastrowofgendata,monthcol}),'/',...
%     num2str(flexccsgen{lastrowofgendata,daycol}),'/',...
%     num2str(flexccsgen{lastrowofgendata,yearcol}))};
% set(gca,'XTickLabel',[firstdate,lastdate]);
% legend(flexccsnames,'FontSize',16)
% 
% %Plot raise of all units
% raisetoplot=cell2mat(flexccsraise(2:end,firstcolofgendata:end));
% figure
% plot(raisetoplot,'LineWidth',2)
% set(gca,'FontSize',16);
% ylabel('Spin. Raise (MW)');
% xlabel('Date')
% set(gca,'XTick',[1 numhours]);
% firstdate={strcat(num2str(flexccsgen{firstrowofgendata,monthcol}),'/',...
%     num2str(flexccsgen{firstrowofgendata,daycol}),'/',...
%     num2str(flexccsgen{firstrowofgendata,yearcol}))};
% lastdate={strcat(num2str(flexccsgen{lastrowofgendata,monthcol}),'/',...
%     num2str(flexccsgen{lastrowofgendata,daycol}),'/',...
%     num2str(flexccsgen{lastrowofgendata,yearcol}))};
% set(gca,'XTickLabel',[firstdate,lastdate]);
% legend(flexccsnames,'FontSize',16)
