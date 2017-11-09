%% GET GENERATION
%DISCHARGE
ssdischargecols=[];
for i=1:size(flexccsgen,2)
    if strfind(flexccsgen{1,i},'Discharge')
        ssdischargecols=[ssdischargecols;i];
    end
end
ssdischargegen=sum(cell2mat(flexccsgen(2:end,ssdischargecols')),2);
ssdischargedata=flexccsgen(:,ssdischargecols');

%CHARGING
sspumpcols=[];
for i=1:size(flexccsgen,2)
    if strfind(flexccsgen{1,i},'PumpDummy')
        sspumpcols=[sspumpcols;i];
    end
end
sspumpgen=sum(cell2mat(flexccsgen(2:end,sspumpcols')),2);
sspumpdata=flexccsgen(:,sspumpcols');

%VENTING
ventingcols=[];
for i=1:size(flexccsgen,2)
    if strfind(flexccsgen{1,i},'Venting')
        ventingcols=[ventingcols;i];
    end
end
ssventinggen=sum(cell2mat(flexccsgen(2:end,ventingcols')),2);
ssventingdata=flexccsgen(:,ventingcols');

%VENT WHILE CHARGING
ssventwhenchargecols=[];
for i=1:size(flexccsgen,2)
    if strfind(flexccsgen{1,i},'VentWhenCharge')
        ssventwhenchargecols=[ssventwhenchargecols;i];
    end
end
ssventwhenchargegen=sum(cell2mat(flexccsgen(2:end,ssventwhenchargecols')),2);
ssventwhenchargedata=flexccsgen(:,ssventwhenchargecols');


%% GET RESERVES



%% GET CHARGE & DISCHARGE PROFILES FOR UNITS SEPARATELY
ssdischargeandpumpbygen={};
for i=1:size(ccsretrofitrows,1)
    currfleetrow=ccsretrofitrows(i);
    
    %Get ORIS & unit IDs
    curroris=futurepowerfleetforplexos{currfleetrow,fleetorisidcol};
    currunitid=futurepowerfleetforplexos{currfleetrow,fleetunitidcol};
    
    %Find associated pump dummy units
    basegenname=strcat(curroris,'-',currunitid);
    pumpdummy1genname=strcat(basegenname,'SSPumpDummy1');
    pumpdummy2genname=strcat(basegenname,'SSPumpDummy2');
    
    %Find associated discharge units
    dischargedummy1genname=strcat(basegenname,'SSDischargeDummy1');
    dischargedummy2genname=strcat(basegenname,'SSDischargeDummy2');
    
    %Get columns in flexccsgen
    discharge1col=find(strcmp(flexccsgen(1,:),dischargedummy1genname));
    discharge2col=find(strcmp(flexccsgen(1,:),dischargedummy2genname));
    pumpdummy1col=find(strcmp(flexccsgen(1,:),pumpdummy1genname));
    pumpdummy2col=find(strcmp(flexccsgen(1,:),pumpdummy2genname));
    
    %Combine
    dischargecols=[discharge1col,discharge2col];
    pumpdummycols=[pumpdummy1col,pumpdummy2col];
    
    %Sum and store discharge and pump values
    ssdischargetemp=sum(cell2mat(flexccsgen(2:end,dischargecols)),2);
    sspumptemp=sum(cell2mat(flexccsgen(2:end,pumpdummycols)),2);
    
    %Save values
    ssdischargetostore={};
    ssdischargetostore=vertcat(strcat(basegenname,'Discharge'),num2cell(ssdischargetemp));
    sspumptostore={};
    sspumptostore=vertcat(strcat(basegenname,'Pump'),num2cell(sspumptemp));
    ssdischargeandpumpbygen=horzcat(ssdischargeandpumpbygen,ssdischargetostore,sspumptostore);
end

%PLOT
for i=1:2:size(ssdischargeandpumpbygen,2)
    currgenname=ssdischargeandpumpbygen{1,i};
    currgenname=currgenname(1:(length(currgenname)-9));
    startday=9;
    endday=13;
    dischargevals=cell2mat(ssdischargeandpumpbygen((24*startday+1+1):(24*endday+1),i)); %add 1 to go to next day, add 1 b/c of header. for last day don't add 1 b/c don't need to go to next day
    pumpvals=cell2mat(ssdischargeandpumpbygen((24*startday+1+1):(24*endday+1),i+1));
    bothvals=horzcat(dischargevals,pumpvals);
    
    figure
    bar(bothvals)
    title(currgenname)
    legend('Discharge','Pump')
    numdays=endday-startday;
    ax = gca;
    xlabels=[1:12:((endday-startday)*24)];
    set(ax,'XTick',xlabels)
end

%% GET WIND GENERATION
%GET WIND GENERATION
windrow=find(strcmp(futurepowerfleetforplexos(:,fleetfueltypecol),'Wind'));
windoris=futurepowerfleetforplexos{windrow,fleetorisidcol};
windname=strcat(windoris,'-');

%Get ID
windrowinplexos=find(strcmp(id2name(:,unitnamecol),windname));
windplexosid=id2name{windrowinplexos,plexosidcol};

%Now get interval generationdat
intervalgencsvnamebase=strcat('ST Generator(',num2str(windplexosid),').Generation');
intervalgencsvname=strcat(intervalgencsvnamebase,'.csv');
[~,~,windintervalgeneration]=xlsread(fullfile(intervaldir,intervalgencsvname),intervalgencsvnamebase);


windgenvals=cell2mat(windintervalgeneration(2:end,intervalcsvhour1col:end));

%Compile values
genvals={windname};
for j=1:size(windgenvals,1)
    genvals=vertcat(genvals,num2cell(windgenvals(j,:))');
end
%Save values
windgen=horzcat(flexccsgen,genvals); clear genvals



[~,~,demand]=xlsread('C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\DataFiles\CPPPLEXOSDemand1EEScalarPt5NLDC0.csv',...
    'CPPPLEXOSDemand1EEScalarPt5NLDC');
alldemand=[];
for i=2:size(demand,1)
    rowtoget=i;
    coltoget=4:27;
    currdemand=cell2mat(demand(rowtoget,coltoget))';
    alldemand=[alldemand;currdemand];    
end
            







