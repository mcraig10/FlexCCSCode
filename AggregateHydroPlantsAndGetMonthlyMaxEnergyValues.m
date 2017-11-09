%Michael Craig
%March 17, 2015
%Function that combines hydro generators into a single plant and matches
%each plant to monthly maximum energy value (calculated in
%AnalyzeEIA923HydroMonthlyGeneration script). 

%INPUTS: future fleet, compliance scenario indicator, whether model hydro
%w/ monthly max energy or capacity factors (monthly max energy if = 1)

function [futurepowerfleetforplexos,maxmonthlyenergy,hydroratingfactors]=...
    AggregateHydroPlantsAndGetMonthlyMaxEnergyValues...
    (futurepowerfleetforplexos,compliancescenario,modelhydrowithmonthlymaxenergy, pc)

%Get data columns of interest
[parseddataorisidcol,parseddataunitidcol,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(futurepowerfleetforplexos);

%% AGGREGATE HYDRO GENERATORS TO PLANT LEVEL
%Find hydro generators
hydrogeneratorrows=find(strcmp('Hydro',futurepowerfleetforplexos(:,parseddataplanttypecol))); %use planttype to avoid pumped storage facilities
tempfuturepowerfleetforplexos=[futurepowerfleetforplexos,num2cell(1:size(futurepowerfleetforplexos,1))']; %add row tags
%Isolate hydro generator rows
hydrogenerators=tempfuturepowerfleetforplexos(hydrogeneratorrows,:); %use temp array to get row #s in there too
%Now get ORIS IDs of hydro generators
hydroorisids=hydrogenerators(:,parseddataorisidcol);
%Get unique ORIS IDs
hydroorisidsunique=unique(hydroorisids);

%For each unique ORIS ID, maintain first row of information (which contains
%stuff like non-fossil, etc.) and add capacity of other generators. Don't
%need to worry about info attached to generators otherwise - have
%eliminated retired units, location is preserved,
%non-fossil/fueltype/prime-mover is preserved.
rowstodelete=[];
for i=1:size(hydroorisidsunique,1)
    %Rows for plant in futurepowerfleetforplexos
    currrows=find(strcmp(hydrogenerators(:,parseddataorisidcol),hydroorisidsunique{i,1}));
    %Loop through rows, aggregating capacity and adding row # to deletion
    %list
    plantcapac=hydrogenerators{currrows(1),parseddatacapacitycol}; %initialize to first row
    for j=2:size(currrows,1) %start @ 2 so preserve first row
        %Add capac
        plantcapac=plantcapac+hydrogenerators{currrows(j),parseddatacapacitycol};
        %Add row number to list of rows for deletion
        rowstodelete=[rowstodelete;hydrogenerators{currrows(j),end}];
    end
    %Now store plant capacity in first row in futurepowerfleet
    firstrowinfuturepowerfleet=hydrogenerators{currrows(1),end};
    futurepowerfleetforplexos{firstrowinfuturepowerfleet,parseddatacapacitycol}=plantcapac;
end
%Now eliminate rows marked for deletion
futurepowerfleetforplexos(rowstodelete,:)=[];


%% IMPORT MAX MONTHLY ENERGY
%Import max monthly energy data
if strcmp(pc,'work')
    tempdir='C:\Users\mtcraig\Desktop\EPP Research\Databases\EIAForm923\2008to2013CompiledFiles\AggregatedData\';
elseif strcmp(pc,'personal')
    tempdir='C:\Users\mcraig10\Desktop\EPP Research\Databases\EIAForm923\2008to2013CompiledFiles\AggregatedData\';
end
maxmonthlyenergy=csvread(strcat(tempdir,'AverageMISOMonthlyHydroNetElecGen2008to2013',compliancescenario,'.csv')); clear tempdir;
%Format: row 1 = header (0, then # of month), then data starts on row 2.
%col 1 = ORIS ID, cols 2->12 are monthly max energy.

%% FIND PLANTS WITHOUT MAX MONTHLY ENERGY
%See how many plants in futurepowerfleetforplexos don't have
%monthly max energy data (should be all)
%Match plants up w/ whether have monthly max energy or not
checkplantsformaxenergy=[];
for i=1:size(hydroorisidsunique,1)
    currorisid=str2num(hydroorisidsunique{i,1});
    checkplantsformaxenergy(end+1,1)=currorisid;
    foundmatch=0;
    for j=1:size(maxmonthlyenergy,1)
        if currorisid==maxmonthlyenergy(j,1)
            foundmatch=1;
        end
    end
    checkplantsformaxenergy(end,2)=foundmatch;
end
%One plant doesn't have max monthly energy data - 83632. 
%Get capacity of plants
for i=1:size(checkplantsformaxenergy,1)
    orisstr=num2str(checkplantsformaxenergy(i,1));
    futurefleetrow=find(strcmp(orisstr,futurepowerfleetforplexos(:,parseddataorisidcol)));
    checkplantsformaxenergy(i,3)=futurepowerfleetforplexos{futurefleetrow,parseddatacapacitycol};
end

%% ADD MAX MONTHLY ENERGY FOR PLANTS WITHOUT IT
%Find plants w/out monthly max energy data (2nd col in
%checkplantsformaxenergy), then find plants w/ capacity closest to them,
%and use their monthly max energy values.
%Find plants w/ missing capacity.
plantswithmissingcapacity=checkplantsformaxenergy(find(checkplantsformaxenergy(:,2)==0),:);
%Now find plant w/ closest capacity for each plant, and save monthly max
%energy.
for i=1:size(plantswithmissingcapacity,1)
    currplantoris=plantswithmissingcapacity(i,1);
    currplantcapac=plantswithmissingcapacity(i,2);
    %Throw out current plant from checkplants array
    checkplantsformaxenergywithoutcurrplant=checkplantsformaxenergy;
    checkplantsformaxenergywithoutcurrplant(find(checkplantsformaxenergywithoutcurrplant(:,1)==currplantoris),:)=[];
    %Get diffs in capacs
    tempcapacdiffs=checkplantsformaxenergywithoutcurrplant(:,3)-currplantcapac;
    %Get min diff capac
    [mindiffcapac,mindiffcapacrow]=min(abs(tempcapacdiffs));
    %Get that plant's ORIS
    mindiffcapacoris=checkplantsformaxenergywithoutcurrplant(mindiffcapacrow,1);
    %Now get that plant's monthly max energy
    monthlymaxenergyforplant=find(maxmonthlyenergy(:,1)==mindiffcapacoris);
    monthlymaxenergyforplant=maxmonthlyenergy(monthlymaxenergyforplant,:);
    %now add a row to final array for that plant
    maxmonthlyenergy(end+1,:)=monthlymaxenergyforplant;
    %Replace ORIS ID
    maxmonthlyenergy(end,1)=currplantoris;
end

%% CALCULATE RATING FACTORS (%) OF HYDRO PLANTS BY MONTH
%If modelhydrowithmonthlymaxenergy=0, then will use monthly capacity factors
%for hydro, which can be derived from each plant's capacity and their
%monthly max energy vlaues imported above.
%To get CFs, for each plant:
%1) Get plant's capacity and determine total possible monthly generation
%2) For each month, get CF of monthly max energy vs. possible production
%3) Cap CFs at 1
%Format CF matrix w/ months going across top, ORIS IDs down, just like
%monthlymaxenergy array. Also, PLEXOS wants rating factors in %.
if modelhydrowithmonthlymaxenergy==0 %not model w/ monthly max
   hydroratingfactors=zeros(size(maxmonthlyenergy,1),size(maxmonthlyenergy,2)); %add 1 for header
   hydroratingfactors(1,:)=maxmonthlyenergy(1,:); %first row = month headers
%    hydroratingfactors(2:end,1)=cellfun(@str2num,hydroorisidsunique); %down first col are ORIS IDs
   hydroratingfactors(:,1)=maxmonthlyenergy(:,1); %down first col are ORIS IDs
   for i=2:size(hydroratingfactors,1)
       currorisid=num2str(hydroratingfactors(i,1));%convert to string for comparison to futurefleet
       %Get capacity
       fleetrow=find(strcmp(currorisid,futurepowerfleetforplexos(:,parseddataorisidcol)));
       plantcapac=futurepowerfleetforplexos{fleetrow,parseddatacapacitycol};
       %Get max monthly energy values
       maxmonthenergyrow=find(maxmonthlyenergy(:,1)==str2num(currorisid));
       maxmonthlyenergyvalues=maxmonthlyenergy(maxmonthenergyrow,2:end); %skip 1st col, which has ORIS ID
       %Get CF by dividing monthly max energy values by total possible
       %generation in that month
       daysinmonth=[31,28,31,30,31,30,31,31,30,31,30,31];
       rfs=zeros(1,12);
       for j=1:size(daysinmonth,2)
           currmaxmonthlyenergy=maxmonthlyenergyvalues(j);
           %Total possible gen = days/month * hours/day * MW
           totalpossgen=daysinmonth(j)*24*plantcapac;
           rfs(j)=currmaxmonthlyenergy/totalpossgen*100; %conver to rating factor in %
           %Cap RF at 100%
           if rfs(j)>100
               rfs(j)=100;
           end
       end
       hydroratingfactors(i,2:end)=rfs; %add 1 b/c of header
   end
else %just need to initialize empty cell array to pass out  
    hydroratingfactors=[];
end



%% LOOK AT CAPACITY FACTORS OF PLANTS
% %Given the capacity of each hydro unit, can estimate its capacity factor
% %from its max monthyl energy generation. 
% %First, do this on annual basis.
% annualgenerationofplants=sum(maxmonthlyenergy(2:end,2:end),2);
% %Combine with ORIS ID
% annualgenerationofplants=horzcat(maxmonthlyenergy(2:end,1),annualgenerationofplants);
% %Get capacity for ORIS ID
% for i=1:size(annualgenerationofplants,1)
%     orisstr=num2str(annualgenerationofplants(i,1));
%     futurefleetrow=find(strcmp(orisstr,futurepowerfleetforplexos(:,parseddataorisidcol)));
%     annualgenerationofplants(i,3)=futurepowerfleetforplexos{futurefleetrow,parseddatacapacitycol};
% end
% %Calculate annual total possible generation, then capacity factor
% annualgenerationofplants(:,4)=annualgenerationofplants(:,3)*24*365; %annual
% annualgenerationofplants(:,5)=annualgenerationofplants(:,2)./annualgenerationofplants(:,4);
% figure; bar(annualgenerationofplants(:,5)); axis([0 150 0 5]); 
% title('Capacity Factor of Hydro Plants');
% %Now get monthly total possible generation, and compare to monthly max
% %energy
% annualgenerationofplants(:,6)=annualgenerationofplants(:,3)*24*30;
% monthlycapacityfactors=maxmonthlyenergy(2:end,2:end)./annualgenerationofplants(:,6);












