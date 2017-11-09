%Michael Craig
%December 17, 2015

%This script analyzes hourly day-ahead cleared energy and AS offers in
%MISO, and figures out a capacity-weighted proportion of AS offer price to
%energy offer price.
%To run this script, need to have energy & reserve DA files for same days
%in both folders.

%% SET WHETHER ON WORK OR PERSONAL LAPTOP
pc='work' %'work' or 'personal'

%% SET DIRECTORIES
if strcmp(pc,'personal')
    energydir='C:\Users\mcraig10\Desktop\EPP Research\MISO Reserves Info\EnergyOfferAndReserveOfferData\LargerAnalysis25Jan2016\EnergyDA';
    reservedir='C:\Users\mcraig10\Desktop\EPP Research\MISO Reserves Info\EnergyOfferAndReserveOfferData\LargerAnalysis25Jan2016\ReserveDA';
elseif strcmp(pc,'work')
    energydir='C:\Users\mtcraig\Desktop\EPP Research\MISO Reserves Info\EnergyOfferAndReserveOfferData\LargerAnalysis25Jan2016\EnergyDA';
    reservedir='C:\Users\mtcraig\Desktop\EPP Research\MISO Reserves Info\EnergyOfferAndReserveOfferData\LargerAnalysis25Jan2016\ReserveDA';
end

%% SET WHETHER TO USE ENERGY OFFER BAND 1 OR 2
%Energy offers in MISO provided in multiple bands; this parameter indicates
%whether use offer price from band 1 or 2. 
energyofferband=2; %1 or 2

%% ISOLATE ENERGY FILES
energyfilesandfolders=dir(energydir);
%Remove first 2 entries - always . and ..
energyfiles=energyfilesandfolders;
energyfiles(1:2,:)=[];
%Isolate file names
energyfilenames={};
for i=1:size(energyfiles,1)
    energyfilenames=vertcat(energyfilenames,energyfiles(i).name);
end


%% LOOP THROUGH FILES
%For each file, open energy & AS files, store unit values, and then get
%proportion.
getcolnum = @(data,colname) find(strcmp(data(1,:),colname));
energyandreserveoffers={'Unit','Capacity','EnergyOffer','RegOffer','SpinOffer','SuppOffer'};
resultsunitcol=getcolnum(energyandreserveoffers,'Unit');
resultscapaccol=getcolnum(energyandreserveoffers,'Capacity');
resultsenergyoffercol=getcolnum(energyandreserveoffers,'EnergyOffer');
resultsregoffercol=getcolnum(energyandreserveoffers,'RegOffer');
resultsspinoffercol=getcolnum(energyandreserveoffers,'SpinOffer');
resultssuppoffercol=getcolnum(energyandreserveoffers,'SuppOffer');
for i=1:size(energyfilenames,1)
    currenergyfilename=energyfilenames{i};
    %Isolate day info
    endofdate=findstr(currenergyfilename,'_da');
    currday=currenergyfilename(1:endofdate-1);
    %Now put together reserve file name
    currreservefilenamebase=strcat(currday,'_asm_da_co');
    currreservefilename=strcat(currreservefilenamebase,'.csv');
    
    %Open energy and reserve files
    [~,~,energydata]=xlsread(fullfile(energydir,currenergyfilename),currenergyfilename(1:(end-4))); %end-4 to chop off '.csv' at end
    [~,~,reservedata]=xlsread(fullfile(reservedir,currreservefilename),currreservefilenamebase);
    
    %Get columns of data
    energyunitcol=getcolnum(energydata,'Unit Code');
    energydatecol=getcolnum(energydata,'Date/Time Beginning (EST)');
    if energyofferband==1
        energyoffercol=getcolnum(energydata,'Price1');
    elseif energyofferband==2
        energyoffercol=getcolnum(energydata,'Price2');
    end
    energycapac1col=getcolnum(energydata,'MW1');
    energycapaccols=[energycapac1col:2:(energycapac1col+18)];
    
    reserveunitcol=getcolnum(reservedata,'Unit Code');
    reservedatecol=getcolnum(reservedata,'Date/Time Beginning (EST)');
    reserveoffercolreg=getcolnum(reservedata,'RegulationOffer Price');
    reserveoffercolspin=getcolnum(reservedata,'SpinningOffer Price');
    reserveoffercolsupp=getcolnum(reservedata,'OnlineSupplementalOffer');
    
    %Isolate all units & dates in energydata
    allunits=energydata(2:end,energyunitcol);
    alldates=energydata(2:end,energydatecol);
    
    %Function to get all reserve rows matching energy rows
    getreserverowsfunc = @(unit,date) find(([reservedata{2:end,reserveunitcol}]==unit)' & ...
        strcmp(reservedata(2:end,reservedatecol),date))+1;
    matchingreserverows=cellfun(getreserverowsfunc, allunits, alldates,'UniformOutput',true);
    
    %Get energy and reserve offers
    offerenergy=cell2mat(energydata(2:end,energyoffercol));
    offerreg=cell2mat(reservedata(matchingreserverows,reserveoffercolreg));
    offerspin=cell2mat(reservedata(matchingreserverows,reserveoffercolspin));
    offersupp=cell2mat(reservedata(matchingreserverows,reserveoffercolsupp));
           
    %Get capacities of units (max values of energy offers)
    energycapacs=cell2mat(energydata(2:end,energycapaccols));
    maxcapacs=max(energycapacs,[],2);
    
    %Combine values - CHECK SAME AS energyandreserveoffers
    combinedvalues=[cell2mat(allunits),maxcapacs,offerenergy,offerreg,offerspin,offersupp];
    
    %Eliminate zero energy offer rows and NaN energy offer rows
    zerorows=find(combinedvalues(:,3)<=0);
    combinedvalues(zerorows,:)=[];
    nanrows=find(isnan(combinedvalues(:,3))==1);
    combinedvalues(nanrows,:)=[];

    %Add data to large array
    energyandreserveoffers=vertcat(energyandreserveoffers,num2cell(combinedvalues));
end

%% GET CAPACITY-WEIGHTED PROPORTION
%Isolate values
offersenergy=cell2mat(energyandreserveoffers(2:end,resultsenergyoffercol));
offersreg=cell2mat(energyandreserveoffers(2:end,resultsregoffercol));
offersspin=cell2mat(energyandreserveoffers(2:end,resultsspinoffercol));
offerssupp=cell2mat(energyandreserveoffers(2:end,resultssuppoffercol));
capacs=cell2mat(energyandreserveoffers(2:end,resultscapaccol));
capacwts=capacs/sum(capacs);

%GET PROPORTIONS
%Eliminate NaN rows from each reserve; also remove those same rows from
%energy so can divide, and from capacwts.

%Regulation
regnans=find(isnan(offersreg)==1);
offersenergyforreg=offersenergy;
offersenergyforreg(regnans,:)=[];
offersreg(regnans,:)=[];
capacwtsreg=capacwts;
capacwtsreg(regnans,:)=[];
regtoenergy=offersreg./offersenergyforreg;
regtoenergyavg=sum(regtoenergy.*capacwtsreg);

%Spinning
spinnans=find(isnan(offersspin)==1);
offersenergyforspin=offersenergy;
offersenergyforspin(spinnans,:)=[];
offersspin(spinnans,:)=[];
capacwtsspin=capacwts;
capacwtsspin(spinnans,:)=[];
spintoenergy=offersspin./offersenergyforspin;
spintoenergyavg=sum(spintoenergy.*capacwtsspin);

%Supplemental
suppnans=find(isnan(offerssupp)==1);
offersenergyforsupp=offersenergy;
offersenergyforsupp(suppnans,:)=[];
offerssupp(suppnans,:)=[];
capacwtssupp=capacwts;
capacwtssupp(suppnans,:)=[];
supptoenergy=offerssupp./offersenergyforsupp;
supptoenergyavg=sum(supptoenergy.*capacwtssupp);

%REPORT RESULTS
regtoenergyavg
spintoenergyavg
supptoenergyavg

%% OLD CODE
% %For each row in energy data, get unit code, date/time beginning,
% %offer price (Band 1), and maximum capacity in any energy offer bands
% %(which approximates the capacity of the unit that we'll use for a
% %cpaacity-weighted proportion). Then find matching AS offer prices.
% for energyrow=2:size(energydata,1)
%     %Get unit & date
%     currunit=energydata{energyrow,energyunitcol};
%     currdate=energydata{energyrow,energydatecol};
%     
%     %Get energy offer
%     offerenergy=energydata{energyrow,energyoffercol};
%     
%     %Some energy offer values are zero - skip rest if so
%     if offerenergy>0
%         %Find row in reserve data
%         reserverow=find(([reservedata{2:end,reserveunitcol}]==currunit)' & ...
%             strcmp(reservedata(2:end,reservedatecol),currdate))+1; %add 1 since doing 2:end
%         
%         %Get all reserve offers
%         offerreg=reservedata{reserverow,reserveoffercolreg};
%         offerspin=reservedata{reserverow,reserveoffercolspin};
%         offersupp=reservedata{reserverow,reserveoffercolsupp};
%         
%         %Get capacity (= max capacity in all energy offer capac bands)
%         energycapacs=cell2mat(energydata(energyrow,energycapaccols));
%         maxcapac=max(energycapacs);
%         
%         %Store capacity, energy offer, reserve offers
%         newrow=size(energyandreserveoffers,1)+1;
%         energyandreserveoffers{newrow,resultsunitcol}=currunit;
%         energyandreserveoffers{newrow,resultscapaccol}=maxcapac;
%         energyandreserveoffers{newrow,resultsenergyoffercol}=offerenergy;
%         energyandreserveoffers{newrow,resultsregoffercol}=offerreg;
%         energyandreserveoffers{newrow,resultsspinoffercol}=offerspin;
%         energyandreserveoffers{newrow,resultssuppoffercol}=offersupp;
%         
%     end
% end








