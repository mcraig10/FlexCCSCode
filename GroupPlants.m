%Michael Craig
%October 9, 2015
%This script groups together oil, LF gas and possibly NGCT generators to
%reduce fleet size.

function [futurepowerfleetforplexos] = GroupPlants(futurepowerfleetforplexos)

%% FUEL AND PLANT TYPES TO GROUP
%All LF Gas are Landfill Gas plant type. Of 431 oil generators, 425 are CT.
%Don't mess w/ O/G Steam since included in CPP. 
fuelandplanttypestogroup={'Oil','Combustion Turbine';'LF Gas','Landfill Gas';...
    'NaturalGas','Combustion Turbine';'MSW','Municipal Solid Waste'};
fuelcol=1; planttypecol=2;

%HR bins for grouping heat rates. Visually inspected HR and capacities of
%plants, and grouped plants so as to maintain diversity in HRs. 
oilhrbins=[1,10000,12000,16000,20000,99999]; %so <1000, 1000-1200, 1200-1600, 1600-2000, 2000+
lfgashrbins=[1,14000,18000,20000,99999]; %so <1.4, 1.4-1.8, 1.8-2, 2+. 
ngcthrbins=[18000,20000,22000,24000,99999]; %so 18-20k,20-22k,22-24k,24k+. NO BIN for <18k. 
mswhrbins=[1,10000,20000,99999];

%Capacity cutoff for grouping plants. Trying to cut down fleet size, so
%best way to do that without fiddling too much with fleet composition is by
%getting rid of the smallest plants. Vast majority of oil CTs are <50 MW in size,
%and all LF gas plants are <50 MW in size. 
oilcapaccutoff=50;
lfgascapaccutoff=50;
ngctcapaccutoff=50;
mswcapaccutoff=50; %this includes all MSW plants

%% GET COLUMN NUMBERS
[parseddataorisidcol,parseddataunitidcol,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);
vomcol=find(strcmp(futurepowerfleetforplexos(1,:),'VOMPerMWhCalculated'));
fomcol=find(strcmp(futurepowerfleetforplexos(1,:),'FOMCost'));
plantnamecol=find(strcmp(futurepowerfleetforplexos(1,:),'PlantName'));
noxemsratecol=find(strcmp(futurepowerfleetforplexos(1,:),'NOxEmsRate(kg/mwh)'));
so2emsratecol=find(strcmp(futurepowerfleetforplexos(1,:),'SO2EmsRate(kg/mwh)'));
co2emsratecol=find(strcmp(futurepowerfleetforplexos(1,:),'CO2EmsRate(kg/mwh)'));
fuelpricecol=find(strcmp(futurepowerfleetforplexos(1,:),'FuelPrice($/GJ)'));
noxpricecol=find(strcmp(futurepowerfleetforplexos(1,:),'NOxPrice($/kg)'));
so2pricecol=find(strcmp(futurepowerfleetforplexos(1,:),'SO2Price($/kg)'));

%% GET MAX ORIS ID BEFORE BEGIN
orisids=[];
for i=2:size(futurepowerfleetforplexos,1)
    orisids=[orisids;str2num(futurepowerfleetforplexos{i,parseddataorisidcol})];
end
maxorisid=max(orisids);

%% GROUP PLANTS
for i=1:size(fuelandplanttypestogroup,1)
    %Get curr fuel & plant type
    currfueltype=fuelandplanttypestogroup{i,fuelcol};
    currplanttype=fuelandplanttypestogroup{i,planttypecol};
    
    %Get relevant parameters defined above depending on fuel type
    if strcmp(currfueltype,'Oil')
        hrbins=oilhrbins;
        capaccutoff=oilcapaccutoff;
    elseif strcmp(currfueltype,'LF Gas')
        hrbins=lfgashrbins;
        capaccutoff=lfgascapaccutoff;
    elseif strcmp(currfueltype,'NaturalGas')
        hrbins=ngcthrbins;
        capaccutoff=ngctcapaccutoff;
    elseif strcmp(currfueltype,'MSW')
        hrbins=mswhrbins;
        capaccutoff=mswcapaccutoff;
    end
    
    %Find rows w/ matching fuel & plant type
    fleetrows=find(strcmp(futurepowerfleetforplexos(:,parseddatafueltypecol),currfueltype) & ...
        strcmp(futurepowerfleetforplexos(:,parseddataplanttypecol),currplanttype));
    
    %Isolate rows
    matchinggens=futurepowerfleetforplexos(fleetrows,:);
    
    %Get capacities 
    capacs=cell2mat(matchinggens(:,parseddatacapacitycol));
    
%     %Look at capacs and HRs
%     hist(capacs,60)  
%     %sum(capacs<5) %183 plants <5 MW in size, 267 < 10 MW, 353 < 25 MW
%     figure
%     hist(heatrates,60)
%     sum(heatrates>15000) %139 plants >15k HR     
%     figure
%     scatter(capacs,heatrates)    

    %Throw out rows with higher capacity than cutoff
    capacbelowcutoff=(capacs<=capaccutoff);
    matchinggensmeetcapac=matchinggens(capacbelowcutoff,:);
    fleetrowsmeetcapac=fleetrows(capacbelowcutoff);
    
    %Get HRs of remaining plants
    heatrates=cell2mat(matchinggensmeetcapac(:,parseddataheatratecol));
    
    %Get rows of plants that also have HR b/wn min & max of bin; these
    %units are eliminated from fleet at end
    lowesthr=min(hrbins); highesthr=max(hrbins);
    hrsbetweenminandmaxhr=(heatrates>lowesthr & heatrates<highesthr);
    fleetrowsmeetcapacandhr=fleetrowsmeetcapac(hrsbetweenminandmaxhr);
    
    %For each HR bin, find matching plants, create new plant, then delete
    %old plants.    
    for hrctr=1:(size(hrbins,2)-1) %last bin is 99999
        minhr=hrbins(hrctr);
        maxhr=hrbins(hrctr+1);
        
        %Find matching HRs
        matchinghrs=(heatrates>minhr & heatrates<maxhr);
        gensmatchinghr=matchinggensmeetcapac(matchinghrs,:);
        
        %Add generator to end of fleet
        newrow=size(futurepowerfleetforplexos,1)+1;
        futurepowerfleetforplexos{newrow,parseddatafueltypecol}=currfueltype;
        futurepowerfleetforplexos{newrow,parseddataplanttypecol}=currplanttype;
        futurepowerfleetforplexos{newrow,parseddatastatecol}='MISO';
        if strcmp(currfueltype,'Oil')
            futurepowerfleetforplexos{newrow,plantnamecol}='AggregatedOilCT';
            futurepowerfleetforplexos{newrow,parseddatafossilunitcol}='Fossil';
        elseif strcmp(currfueltype,'LF Gas')
            futurepowerfleetforplexos{newrow,plantnamecol}='AggregatedLFGas';
            futurepowerfleetforplexos{newrow,parseddatafossilunitcol}='Non-Fossil';
        elseif strcmp(currfueltype,'NaturalGas')
            futurepowerfleetforplexos{newrow,plantnamecol}='AggregatedNGCT';
            futurepowerfleetforplexos{newrow,parseddatafossilunitcol}='Fossil';
        elseif strcmp(currfueltype,'MSW')
            futurepowerfleetforplexos{newrow,plantnamecol}='AggregatedMSW';
            futurepowerfleetforplexos{newrow,parseddatafossilunitcol}='Non-Fossil';
        end
        maxorisid=maxorisid+1;
        futurepowerfleetforplexos{newrow,parseddataorisidcol}=num2str(maxorisid); %ORIS IDs are ins tring format
        futurepowerfleetforplexos{newrow,parseddataunitidcol}=num2str(1); %Unit IDs are in string format
        
        %Sum capacities
        capacsofcurrunits=cell2mat(gensmatchinghr(:,parseddatacapacitycol));
        sumofcapacs=sum(capacsofcurrunits);
        futurepowerfleetforplexos{newrow,parseddatacapacitycol}=sumofcapacs;
        
        %Get capacity-weighted HR
        hrsofcurrunits=cell2mat(gensmatchinghr(:,parseddataheatratecol));
        capacweightedhr=sum(hrsofcurrunits.*(capacsofcurrunits/sumofcapacs));
        futurepowerfleetforplexos{newrow,parseddataheatratecol}=capacweightedhr;
        
        %Get capacity-weighted emissions rates
        noxemsrates=cell2mat(gensmatchinghr(:,noxemsratecol));
        so2emrates=cell2mat(gensmatchinghr(:,so2emsratecol));
        co2emrates=cell2mat(gensmatchinghr(:,co2emsratecol));
        capacweightnox=sum(noxemsrates.*(capacsofcurrunits/sumofcapacs));
        capacweightso2=sum(so2emrates.*(capacsofcurrunits/sumofcapacs));
        capacweightco2=sum(co2emrates.*(capacsofcurrunits/sumofcapacs));
        futurepowerfleetforplexos{newrow,noxemsratecol}=capacweightnox;
        futurepowerfleetforplexos{newrow,so2emsratecol}=capacweightso2;
        futurepowerfleetforplexos{newrow,co2emsratecol}=capacweightco2;
        
        %Get emissions-weighted NOx & SO2 prices (emissions weight = by
        %total emissions = by capacity*emissions rate)
        noxems=cell2mat(gensmatchinghr(:,noxemsratecol)).*capacsofcurrunits;
        so2ems=cell2mat(gensmatchinghr(:,so2emsratecol)).*capacsofcurrunits;
        noxprices=cell2mat(gensmatchinghr(:,noxpricecol));
        so2prices=cell2mat(gensmatchinghr(:,so2pricecol));
        emsweightednoxprice=sum(noxprices.*noxems/sum(noxems));
        if sum(so2ems)==0
            emsweightedso2price=0;
        else
            emsweightedso2price=sum(so2prices.*so2ems/sum(so2ems));
        end
        futurepowerfleetforplexos{newrow,noxpricecol}=emsweightednoxprice;
        futurepowerfleetforplexos{newrow,so2pricecol}=emsweightedso2price;
        
        %Get capacity-weighted FOM
        fomsofcurrunits=cell2mat(gensmatchinghr(:,fomcol));
        capacweightedfom=sum(fomsofcurrunits.*(capacsofcurrunits/sumofcapacs));
        futurepowerfleetforplexos{newrow,fomcol}=capacweightedfom;        
        
        %Add VOM (same for all units, but take capac-weighted avg anyways)
        vomvals=cell2mat(gensmatchinghr(:,vomcol));
        capacweightvom=sum(vomvals.*(capacsofcurrunits/sumofcapacs));
        futurepowerfleetforplexos{newrow,vomcol}=capacweightvom;
        
        %Add fuel price (same for all units, but take capac-weighted avg anyways)
        fuelpricevals=cell2mat(gensmatchinghr(:,fuelpricecol));
        capacweightfuelprice=sum(fuelpricevals.*(capacsofcurrunits/sumofcapacs));
        futurepowerfleetforplexos{newrow,fuelpricecol}=capacweightfuelprice;
        
        %CHECKS
%         capacweightvom-gensmatchinghr{1,vomcol}
%         capacweightfuelprice-gensmatchinghr{1,fuelpricecol}
    end
    
    %Delete old rows
    futurepowerfleetforplexos(fleetrowsmeetcapacandhr,:)=[];   
end




