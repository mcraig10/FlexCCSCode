
maindir='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\IPM Output\BaseRunWithoutCO2Price10Sept';
dirwithfleet='C:\Users\mtcraig\Desktop\EPP Research\Matlab\Fleets';
filewithfleetinfo='CPPOption1Demand1EEScalarPt5FlexCCS1MW0WindMW0.mat';

% %% LOOK AT PRICES
% %% ELECTRICITY PRICES
% [~,~,eleccprice]=xlsread(fullfile(maindir,'ElecPriceWithCPrice.csv'));
% [~,~,elecnocprice]=xlsread(fullfile(maindir,'ElecPriceNoCPrice.csv'));
% eleccprice=cell2mat(eleccprice(2:end,4:end));
% elecnocprice=cell2mat(elecnocprice(2:end,4:end));
% %Go from 365 days x 24 hours to 8760 hours x 1
% eleccpricets=[];
% for i=1:size(eleccprice,1)
%     eleccpricets=[eleccpricets;eleccprice(i,:)'];
% end
% elecnocpricets=[];
% for i=1:size(elecnocprice,1)
%     elecnocpricets=[elecnocpricets;elecnocprice(i,:)'];
% end
% %Get max prices w/out 10,000 cap
% caprows=(eleccpricets==10000);
% temp=eleccpricets;
% temp(caprows)=[];
% maxelecpricenocprice=max(temp); clear temp;
% %Plot
% figure
% subplot(2,1,1)
% plot(eleccpricets,'k');
% ylim([0 140]);
% subplot(2,1,2)
% plot(elecnocpricets,'b');
% ylim([0 140]);
% title('Electricity Price')
% 
% %% REG UP PRICES
% [~,~,eleccprice]=xlsread(fullfile(maindir,'RegUpPriceWithCPrice.csv'));
% [~,~,elecnocprice]=xlsread(fullfile(maindir,'RegUpPriceNoCPrice.csv'));
% eleccprice=cell2mat(eleccprice(2:end,4:end));
% elecnocprice=cell2mat(elecnocprice(2:end,4:end));
% %Go from 365 days x 24 hours to 8760 hours x 1
% eleccpricets=[];
% for i=1:size(eleccprice,1)
%     eleccpricets=[eleccpricets;eleccprice(i,:)'];
% end
% elecnocpricets=[];
% for i=1:size(elecnocprice,1)
%     elecnocpricets=[elecnocpricets;elecnocprice(i,:)'];
% end
% %Look at histogram of prices w/ 200 bins (if max=$10,000, that means each bin = $50) 
% % hist(eleccpricets,200)
% % %Get max prices w/out 10,000 cap
% % caprows=(eleccpricets==10000);
% % temp=eleccpricets;
% % temp(caprows)=[];
% % maxelecprice=max(temp); clear temp;
% %Plot
% figure
% subplot(2,1,1)
% plot(eleccpricets,'k');
% ylim([0 100]);
% subplot(2,1,2)
% plot(elecnocpricets,'b');
% ylim([0 100]);
% title('Reg Up Price')
% 
% %% REG DOWN PRICES
% [~,~,eleccprice]=xlsread(fullfile(maindir,'RegDownPriceWithCPrice.csv'));
% [~,~,elecnocprice]=xlsread(fullfile(maindir,'RegDownPriceNoCPrice.csv'));
% eleccprice=cell2mat(eleccprice(2:end,4:end));
% elecnocprice=cell2mat(elecnocprice(2:end,4:end));
% %Go from 365 days x 24 hours to 8760 hours x 1
% eleccpricets=[];
% for i=1:size(eleccprice,1)
%     eleccpricets=[eleccpricets;eleccprice(i,:)'];
% end
% elecnocpricets=[];
% for i=1:size(elecnocprice,1)
%     elecnocpricets=[elecnocpricets;elecnocprice(i,:)'];
% end
% %Look at histogram of prices w/ 200 bins (if max=$10,000, that means each bin = $50) 
% % hist(eleccpricets,200)
% % %Get max prices w/out 10,000 cap
% % caprows=(eleccpricets==10000);
% % temp=eleccpricets;
% % temp(caprows)=[];
% % maxelecprice=max(temp); clear temp;
% %Plot
% figure
% subplot(2,1,1)
% plot(eleccpricets,'k');
% ylim([0 10]);
% subplot(2,1,2)
% plot(elecnocpricets,'b');
% ylim([0 10]);
% title('Reg Down Price')
% 
% %% SPINNING PRICES
% [~,~,eleccprice]=xlsread(fullfile(maindir,'SpinPriceWithCPrice.csv'));
% [~,~,elecnocprice]=xlsread(fullfile(maindir,'SpinPriceNoCPrice.csv'));
% eleccprice=cell2mat(eleccprice(2:end,4:end));
% elecnocprice=cell2mat(elecnocprice(2:end,4:end));
% %Go from 365 days x 24 hours to 8760 hours x 1
% eleccpricets=[];
% for i=1:size(eleccprice,1)
%     eleccpricets=[eleccpricets;eleccprice(i,:)'];
% end
% elecnocpricets=[];
% for i=1:size(elecnocprice,1)
%     elecnocpricets=[elecnocpricets;elecnocprice(i,:)'];
% end
% %Look at histogram of prices w/ 200 bins (if max=$10,000, that means each bin = $50) 
% % hist(eleccpricets,200)
% % %Get max prices w/out 10,000 cap
% % caprows=(eleccpricets==10000);
% % temp=eleccpricets;
% % temp(caprows)=[];
% % maxelecprice=max(temp); clear temp;
% %Plot
% figure
% subplot(2,1,1)
% plot(eleccpricets,'k');
% ylim([0 100]);
% subplot(2,1,2)
% plot(elecnocpricets,'b');
% ylim([0 100]);
% title('Spinning Price')
% 
% %% SUPPLEMENTAL PRICES
% [~,~,eleccprice]=xlsread(fullfile(maindir,'SuppPriceWithCPrice.csv'));
% [~,~,elecnocprice]=xlsread(fullfile(maindir,'SuppPriceNoCPrice.csv'));
% eleccprice=cell2mat(eleccprice(2:end,4:end));
% elecnocprice=cell2mat(elecnocprice(2:end,4:end));
% %Go from 365 days x 24 hours to 8760 hours x 1
% eleccpricets=[];
% for i=1:size(eleccprice,1)
%     eleccpricets=[eleccpricets;eleccprice(i,:)'];
% end
% elecnocpricets=[];
% for i=1:size(elecnocprice,1)
%     elecnocpricets=[elecnocpricets;elecnocprice(i,:)'];
% end
% %Look at histogram of prices w/ 200 bins (if max=$10,000, that means each bin = $50) 
% % hist(eleccpricets,200)
% % %Get max prices w/out 10,000 cap
% % caprows=(eleccpricets==10000);
% % temp=eleccpricets;
% % temp(caprows)=[];
% % maxelecprice=max(temp); clear temp;
% %Plot
% figure
% subplot(2,1,1)
% plot(eleccpricets,'k');
% ylim([0 20]);
% subplot(2,1,2)
% plot(elecnocpricets,'b');
% ylim([0 20]);
% title('Supplemental Price')


%%
%% LOOK AT GENERATOR RESERVE PROVISION
%Want to see which generator is providing reserves
%IMPORT INPUT DATA TO PLEXOS FROM FLEET .MAT OUTPUT BY CREATEPLEXOSIMPORTFILE SCRIPT

load(fullfile(dirwithfleet,filewithfleetinfo));
%GET COLUMN NUMBERS OF FLEET DATA
[fleetorisidcol,fleetunitidcol,fleetfueltypecol,...
    fleetheatratecol, fleetcapacitycol,fleetplanttypecol,...
    fleetretrofitcol,fleetregioncol,fleetstatecol,fleetfossilunitcol,...
    fleetmindowntimecol, fleetstartcostcol, fleetminloadcol, fleetmaxrampupcol, ...
    fleetmaxrampdowncol, fleetrunupratecol, fleetrundownratecol,...
    fleetnoxemsratecol, fleetso2emsratecol, fleetco2emsratecol,...
    fleetfuelpricecol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);

%IMPORT MAPPING CSV
%Mapping CSV:
[~,~,id2name]=xlsread(fullfile(maindir,'id2name.csv'),'id2name');
%Get column #s of id2name. id col has id #; name col has GEN-ORIS ID. Only
%want class = 'Generator'.
classcol=find(strcmp(id2name(1,:),'class'));
idcol=find(strcmp(id2name(1,:),'id'));
namecol=find(strcmp(id2name(1,:),'name'));
%Isolate 'Generator' class rows
genrows=find(strcmp(id2name(:,classcol),'Generator'));
id2namegens=id2name(genrows,:);

% ADD ORIS-GENERATOR ID TO FUTUREPOWERFLEET
%In output from PLEXOS, generator IDs are given as: 'ORISID-GENID'. In
%futurepowerfleet array, don't have similar column. Need to concatenate
%ORIS and generator ID. Do that now.
orisgenidcol=size(futurepowerfleetforplexos,2)+1;
futurepowerfleetforplexos{1,orisgenidcol}='ORIS-GenID';
futurepowerfleetforplexos(2:end,orisgenidcol)=strcat(futurepowerfleetforplexos(2:end,fleetorisidcol),'-',futurepowerfleetforplexos(2:end,fleetunitidcol));

% IMPORT INTERVAL RESERVE PROVISION DATA
%E.g., if ran UC in hourly time steps, import hourly data
%Directory of daily gen files:
intervaldir=fullfile(maindir,'interval');

%Naming format of daily generation files: ST Generator(id).Generation
%In each file: YEAR MONTH DAY 1 2 3 4... (hours)      daily generation
%(MWh) is in each hour column
%Open random file to get col #s
% [~,~,randfile]=xlsread(strcat(intervaldir,'\ST Generator(1).Regulation Raise Reserve.csv'),'ST Generator(1).Regulation Rais');
[~,~,randfile]=xlsread(strcat(intervaldir,'\ST Generator(1).Generation.csv'),'ST Generator(1).Generation');
intervalcsvmonthcol=find(strcmp(randfile(1,:),'MONTH'));
intervalcsvdaycol=find(strcmp(randfile(1,:),'DAY'));
intervalcsvhour1col=intervalcsvdaycol+1; 
%No leading zeros in interval data, but still want number of days in analysis period
numdaysofdatainterval=size(randfile,1)-1;
numhoursofdatainterval=numdaysofdatainterval*24;
clear randfile;

%Initialize array w/ each fuel type
fueltypes=unique(futurepowerfleetforplexos(2:end,fleetfueltypecol));
genbyfueltypeinterval=['FuelType';fueltypes];
temp=num2cell(1:numhoursofdatainterval); temp=[temp;num2cell(zeros(size(fueltypes,1),numhoursofdatainterval))];
genbyfueltypeinterval=[genbyfueltypeinterval,temp]; clear temp;
fuelcolgenbyfueltype=find(strcmp(genbyfueltypeinterval(1,:),'FuelType'));
reservevalsbygen=zeros(8760,size(id2namegens,1));
%Iterate through generators
for i=1:size(id2namegens,1)
    %Get curr ORIS-GENID
    currunitid=id2namegens{i,namecol};
    %Get curr PLEXOS output ID
    currplexosid=id2namegens{i,idcol};
    %Test if unit ID has '/' in it - PLEXOS converts some generators (e.g.,
    %6035-11-1) into date strings (11/1/6035) b/c it thinks its a date.
    hasbackslash=findstr(currunitid,'/');
    if isempty(hasbackslash)==0 %if not empty, has a backslash so need to change around
        %Last 4 digits go first, then first digit, then first digit, then
        %middle digit
        slashpositions=findstr(currunitid,'/');
        newcurrunitid=currunitid(slashpositions(2)+1:end);
        newcurrunitid=strcat(newcurrunitid,'-',currunitid(1:slashpositions(1)-1));
        newcurrunitid=strcat(newcurrunitid,'-',currunitid(slashpositions(1)+1:slashpositions(2)-1));
        currunitid=newcurrunitid;
    end
    %Open CSV for that generator
%     intervalgencsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Regulation Raise Reserve');
    intervalgencsvnamebase=strcat('ST Generator(',num2str(currplexosid),').Generation');
    intervalgencsvname=strcat(intervalgencsvnamebase,'.csv');
%     [~,~,currintervalgeneration]=xlsread(fullfile(intervaldir,intervalgencsvname),intervalgencsvnamebase(1:31));%for regulation raise!
    [~,~,currintervalgeneration]=xlsread(fullfile(intervaldir,intervalgencsvname),intervalgencsvnamebase);    
    %Get Regulation Raise values - need to go across a row and get each hour,
    %then down. 
    intervalgenvalues=cell2mat(currintervalgeneration(2:end,intervalcsvhour1col:end));
    intervalgenvalueshorizontal=zeros(1,size(intervalgenvalues,1)*size(intervalgenvalues,2));
    for j=1:size(intervalgenvalues,1)
        intervalgenvalueshorizontal(1,((j-1)*24+1):(j*24))=intervalgenvalues(j,:);
    end
    %Save value for generator
    reservevalsbygen(:,i)=intervalgenvalueshorizontal';
    %Get fuel type of generator
    rowinfleet=find(strcmp(futurepowerfleetforplexos(:,orisgenidcol),currunitid));
    currfueltype=futurepowerfleetforplexos{rowinfleet,fleetfueltypecol};
    %Add gen values for current gen to gen values for curr fuel type
    rowingenbyfuelarray=find(strcmp(genbyfueltypeinterval(:,fuelcolgenbyfueltype),currfueltype));
    genbyfueltypeinterval(rowingenbyfuelarray,2:end)=num2cell(cell2mat(genbyfueltypeinterval(rowingenbyfuelarray,2:end))+...
        intervalgenvalueshorizontal);
end

%Reshuffle array so have baseload on bottom, peakers on top, etc.
%Nuclear, Geothermal, Fwaste, Biomass, MSW, LF Gas, Coal, NaturalGas, Non-Fossil, Wind,
%Solar, Hydro, Oil
desiredfuelorder={'Nuclear','Geothermal','Fwaste','Biomass','MSW','LF Gas','Coal','NaturalGas',...
    'Non-Fossil','Wind','Solar','Hydro','Oil'};
% desiredfuelorder={'Coal','Biomass','NaturalGas'};
%Go through genbyfueltype, save array to columns of new array w/ ordering
%of desiredfuelorder
genbyfueltypeintervalforplot=[];
for i=1:size(desiredfuelorder,2)
    currfuel=desiredfuelorder{i};
    rownum=find(strcmp(genbyfueltypeinterval(:,fuelcolgenbyfueltype),currfuel));
    genbyfueltypeintervalforplot=[genbyfueltypeintervalforplot,cell2mat(genbyfueltypeinterval(rownum,2:end))'];
end
%Now plot area
% %FOR RESERVES
% subplot(2,1,1)
% area(genbyfueltypeintervalforplot(1:1000,:)) 
% ylim([0 max(max(genbyfueltypeintervalforplot))]);
% title('Hours1-1000')
% subplot(2,1,2)
% area(genbyfueltypeintervalforplot(4000:5000,:)) 
% title('Hours4000-5000')
% set(gca,'FontSize',16); 
% set(gca,'XTick',[1 numhoursofdatainterval]); 
% % set(gca,'XTickLabel',{strcat(num2str(horizonstartmonth),'/',num2str(horizonstartday)),...
% %     strcat(num2str(horizonendmonth),'/',num2str(horizonendday))});
% ylim([0 max(max(genbyfueltypeintervalforplot))]);
% legend(desiredfuelorder,'FontSize',16)
% ylabel('Hourly Generation (MWh)'); xlabel('Day of Year')
%FOR ELECTRICITY GENERATION
area(genbyfueltypeintervalforplot) 
ylim([0 max(sum(genbyfueltypeintervalforplot,2))]);
title('Elec Gen By Hour, Base, CO2 Price on CPP Aff. Units')
set(gca,'FontSize',16); 
set(gca,'XTick',[1 numhoursofdatainterval]); 
% set(gca,'XTickLabel',{strcat(num2str(horizonstartmonth),'/',num2str(horizonstartday)),...
%     strcat(num2str(horizonendmonth),'/',num2str(horizonendday))});
legend(desiredfuelorder,'FontSize',16)
ylabel('Hourly Generation (MWh)'); xlabel('Day of Year')











