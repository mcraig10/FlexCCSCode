%Michael Craig, 28 May 2015
%This script downscales oil-fired generators to the plant level.
%Lots of oil-fired generators in IPM; for MISO, there are over 1,100
%oil-fired generators, 932 of which are less than 5 MW in size. (526 are
%between 1 and 2 MW, and 218 are less than 1 MW.) To shrink the model size,
%I downscale oil-fired generators to the plant level, of which there are
%351. Heat rates of oil-fired generators do not significantly differ within
%a plant; for most oil-fired plants, generator heat rates are identical, or
%vary by ~1000 or less Btu/kWh. Additionally, unit commitment parameters
%for oil-fired generators don't vary by size (i.e., assume a linear
%relationship between parameters and plant size), and external values of fuel prices and
%emissions rates are used for oil-fired generators, so there is no worry
%about having to average these (although they should be nearly the same for
%generators within a plant anyways). For these reasons, aggregating
%oil-fired generators to the plant level should not affect model accuracy. 

%Note that for oil-fired generators w/ a NOx CT (50 have a NOx CT; no other
%CTs are installed on any oil-fired generators), I don't downscale them.

%Procedure:
%1) Identify oil-fired generators
%2) Get unique ORIS IDs
%3) For each unique ORIS ID, get unique generators
%4) Preserve first generator and delete rest - that way, don't have to add
%a whole new row and copy over location and other information 
%5) To combine generators: add capacities, average heat rates, average VOM,
%('VOMPerMWhCalculated' col), average FOM ('FOMCost' col). 
%6) Delete extra generators
%7) Delete Unit ID of retained generator so don't get confused later, since
%it's no longer that particular unit.


function [futurepowerfleetforplexos] = DownscaleOilFiredGeneratorsToPlantLevel(futurepowerfleetforplexos)

%% GET DATA COLUMNS OF INTEREST IN parseddataworetiredwadjustmentsiso
[parseddataorisidcol,parseddataunitidcol,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);
%Also need VOM & FOM columns
vomcol=find(strcmp(futurepowerfleetforplexos(1,:),'VOMPerMWhCalculated'));
fomcol=find(strcmp(futurepowerfleetforplexos(1,:),'FOMCost'));
noxcontrolcol=find(strcmp(futurepowerfleetforplexos(1,:),'NOxControl'));

%% GET ROWS OF OIL-FIRED GENERATORS
rowsofoilgenerators=find(strcmp(futurepowerfleetforplexos(:,parseddatafueltypecol),'Oil'));

%% GET UNIQUE ORIS IDS OF OIL-FIRED GENERATORS
%Isolate ORIS IDs
oilorisids=futurepowerfleetforplexos(rowsofoilgenerators,parseddataorisidcol);
%Get unique ORIS IDs
uniqueoilorisids=unique(oilorisids);

%% DOWNSCALE GENERATORS
%Aggregate generators to plant level, excluding those with a NOx CT
%installed.
%Loop over unique ORIS IDs
rowstodelete=[];
for i=1:size(uniqueoilorisids,1)
    %Get current ORIS ID
    currorisid=uniqueoilorisids{i};
    %Find rows with same ORIS ID
    oilrowswithcurrorisid=rowsofoilgenerators(find(strcmp(futurepowerfleetforplexos(rowsofoilgenerators,parseddataorisidcol),currorisid)),:);
    %Get CTs of those oil-fired generators - if has a CT, want to drop row
    oilcts=futurepowerfleetforplexos(oilrowswithcurrorisid,noxcontrolcol);
    %Check which cells are empty (no CT), and for those cells, keep row
    nooilcts=cellfun(@isempty,oilcts);
    oilrowswithcurrorisid=oilrowswithcurrorisid(nooilcts);
    %Check if more than 1 generator; if not, then don't need to do anything
    %and move to next loop
    if size(oilrowswithcurrorisid,1)>1 %more than 1 generator
        %Get row # of first generator
        rowoffirstgenerator=oilrowswithcurrorisid(1);
        %Sum capacities of all generators at current plant
        gencapacities=cell2mat(futurepowerfleetforplexos(oilrowswithcurrorisid,parseddatacapacitycol));
        totalplantcapacity=sum(gencapacities);
        %Get capacity weights for averages
        capacityweights=gencapacities/totalplantcapacity;
        %Get avg HR
        genheatrates=cell2mat(futurepowerfleetforplexos(oilrowswithcurrorisid,parseddataheatratecol));
        avgheatrate=sum(capacityweights.*genheatrates);
        %Get capacity-weighted average FOM
        genfoms=cell2mat(futurepowerfleetforplexos(oilrowswithcurrorisid,fomcol));
        avgfom=sum(capacityweights.*genfoms);
        %Get capacity-weighted average VOM
        genvoms=cell2mat(futurepowerfleetforplexos(oilrowswithcurrorisid,vomcol));
        avgvom=sum(capacityweights.*genvoms);
        %Replace capacity, HR, VOM and FOM of first generator
        futurepowerfleetforplexos{rowoffirstgenerator,parseddatacapacitycol}=totalplantcapacity;
        futurepowerfleetforplexos{rowoffirstgenerator,parseddataheatratecol}=avgheatrate;
        futurepowerfleetforplexos{rowoffirstgenerator,vomcol}=avgvom;
        futurepowerfleetforplexos{rowoffirstgenerator,fomcol}=avgfom;
        %Delete unit ID of first generator
        futurepowerfleetforplexos{rowoffirstgenerator,parseddataunitidcol}='';
        %Save rows to delete later
        rowstodelete=vertcat(rowstodelete,oilrowswithcurrorisid(2:end)); %don't include first row - that's first generator!
    end
end

%Delete rows
futurepowerfleetforplexos(rowstodelete,:)=[]; 












