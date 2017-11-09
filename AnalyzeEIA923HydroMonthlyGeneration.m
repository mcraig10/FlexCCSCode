%Michael Craig
%March 13, 2015
%This file gathers EIA923 monthly net electricity generation for hydro
%plants in MISO from 2008-2013. It then analyzes these data to determine if
%there are any outliers in terms of max net generation in each month and
%outputs either the monthly maximum of these 6 years or the maximum of the
%non-outlier data. 

%% PARAMETERS
%Which CPP compliance scenario parsed file to import
compliancescenario='Mass';
% compliancescenario='Base';

%% AGGREGATE EIA923 DATA
%Import EIA923 data by iterating through list of files in folder
cd 'C:\Users\mtcraig\Desktop\EPP Research\Databases\EIAForm923\2008to2013CompiledFiles'
listoffiles=dir;
%Following array saves annual monthly generation for each plant. First col
%= plant, second col = year, 3-15 = months
hydrogeneration=[0,0,1,2,3,4,5,6,7,8,9,10,11,12];
for i=1:size(listoffiles,1)
    if listoffiles(i).isdir==0 %if current file is not another dir (. or ..)
        %Get file name
        currfilename=listoffiles(i).name;
        %Open Excel file, sheet 1: "Page 1 Generation and Fuel Data"
        [~,~,eia923data]=xlsread(currfilename,'Page 1 Generation and Fuel Data');
        %Get year of file
        for year=2008:2013
            yearstr=num2str(year);
            if isempty(findstr(currfilename,yearstr))==0 %if year 2008
                yearoffile=str2num(yearstr);
            end
        end
        %Each file has blank rows up top, but a different #. Need to find
        %overarching column header.   
        %Overarching column header for all sheets is "Electricity Net
        %Generation (MWh)". Subheaders are NetGen_MON, where MON is the
        %first 3 letters of the month. Some have all caps, others don't -
        %use strcmpi for case insensitive string comparison.
        %Ovearching column header is either in row 5 or 6 - test both.
        for j=1:size(eia923data,2)
            if strcmpi(eia923data(5,j),'Electricity Net Generation (MWh)')==1
                rowofoverarchingheader=5;
                colofoverarchingheader=j;
            elseif strcmpi(eia923data(6,j),'Electricity Net Generation (MWh)')==1
                rowofoverarchingheader=6;
                colofoverarchingheader=j;
            end
        end
        %Overarching column header is always at first col of subheaders,
        %which are either one or two rows below ovearching header. Find out
        %how many rows.
        if strcmpi(eia923data(1+rowofoverarchingheader,colofoverarchingheader),'NetGen_Jan')==1
            rowofsubheader=1+rowofoverarchingheader;
        else
            rowofsubheader=2+rowofoverarchingheader;
        end
        %Now have row & col for first month of net elec gen. Now iterate
        %through generators and for each hydro generator, pull monthly
        %generation data. Will stick subsequent years on the end. Header is
        %year and month #.
        %Find hydro generators: use Reported Prime Mover column. Also want
        %'Plant Id'. Row of these headers is same as rowofsubheader defined
        %above.
        for j=1:size(eia923data,2)
            tempstr=eia923data{rowofsubheader,j};
            if strcmpi(tempstr,'Plant Id')==1
                plantidcol=j;
            end
            if strcmpi(tempstr,'Reported Prime Mover')==1
                primemovercol=j;
            end
        end
        %Now get hydro generators, and for each hydro generator, store
        %generation data
        for j=1:size(eia923data,1)
            primemovertemp=eia923data{j,primemovercol};
            if strcmpi(primemovertemp,'HY')==1 %if hydro
                %Get plant ID
                plantidtemp=eia923data{j,plantidcol};
                %See if plant ID is already in array; if not, add it.
                [firstplantrow,~]=find(hydrogeneration(:,1)==plantidtemp);
                if isempty(firstplantrow) 
                    %Add rows for plants and years
                    firstrowtemp=size(hydrogeneration,1)+1;
                    hydrogeneration(firstrowtemp:firstrowtemp+5,1)=plantidtemp; %6 years of data, so create 6 rows
                    hydrogeneration(firstrowtemp:firstrowtemp+5,2)=2008:2013;
                    %Now add the data of current year
                    yearrow=yearoffile-2008; %2008 is lowest year; figuring out here how many rows down to go (if 2008, same row as firstplantrow) 
                    rowofdatatoadd=yearrow+firstrowtemp;
                    hydrogeneration(rowofdatatoadd,3:end)=[eia923data{j,colofoverarchingheader:colofoverarchingheader+11}];
                else
                    firstrowtemp=firstplantrow(1);
                    %Add data to year of data
                    yearrow=yearoffile-2008;
                    rowofdatatoadd=yearrow+firstrowtemp;
                    hydrogeneration(rowofdatatoadd,3:end)=[eia923data{j,colofoverarchingheader:colofoverarchingheader+11}];
                end
            end
        end
    end
end

%Write CSV with aggregated data
csvwrite('AggregatedData\AggregatedEIA923MonthlyHydroNetElecGen2008to2013.csv',hydrogeneration);

%% IMPORT FUTURE PLEXOS FLEET
%Import generators from 2030 fleet from CPP's Parsed File. Function below
%automatically gathers MISO generators.
cd 'C:\Users\mtcraig\Desktop\EPP Research\Matlab'
%Set parameters necessary for CPPParsedFileImport - see
%CreatePLEXOSFileImport for full description of parameters.
modelmisowithfullstates=1; %model MISO as full states, not as MIS_ regions from IPM
hrimprovement=.043; %HR improvement assumed by EPA (not really needed for this script's work, but is input to function)
[parseddataworetiredwadjustmentsiso] = CPPParsedFileImport(compliancescenario, hrimprovement, modelmisowithfullstates);

%This function reads in the output of the above function and isolates the
%new plants in the CPP from existing plants that are expected to still be
%operating in 2025. Then it adds on new plants to those existing plants
%depending on the input parameter.
[futurepowerfleetforplexos] = AddNewPlantsToFutureFleet(parseddataworetiredwadjustmentsiso);

%% ANALYZE MONTHLY HYDRO GENERATION
%Get hydro plant rows - 'PlantType','Hydro'
planttypecol=find(strcmp(futurepowerfleetforplexos(1,:),'PlantType'));
orisidcol=find(strcmp(futurepowerfleetforplexos(1,:),'ORISCode'));
hydroplantrows=find(strcmp(futurepowerfleetforplexos(:,planttypecol),'Hydro'));
hydroplantids=[];
for i=1:size(hydroplantrows,1)
    hydroplantids(end+1,1)=str2num(futurepowerfleetforplexos{hydroplantrows(i),orisidcol});
end
uniquehydroplantids=unique(hydroplantids);

%Isolate hydrogeneration for those plants
hydrogenerationformiso=hydrogeneration(1,:);
for i=1:size(uniquehydroplantids,1)
    %Get rows in hydrogeneration
    rowsinhydrogeneration=find(hydrogeneration(:,1)==uniquehydroplantids(i));
    rowstoadd=size(rowsinhydrogeneration,1);
    hydrogenerationformiso(end+1:end+rowstoadd,:)=hydrogeneration(rowsinhydrogeneration,:); 
end

%Create plots for each month that has value of each year for each generator
%stacked on top of one another. Also calculate percentage different among
%values. 
percentdiff=[];
figure
for month=1:12
    subplot(4,3,month)
    title(num2str(month));
    hold on
    %Skip to each generator
    ctr=1; %use this as index for plotting generators
    for row=2:6:size(hydrogenerationformiso,1)
        %Grab generation for given month (column) for each year (so next 5
        %rows)
        plot(ctr,hydrogenerationformiso(row:row+5,month+2),'.k','MarkerSize',6); %index to month+2 b/c have 2 extra columns of info up front
        
        %Calculate percent diff
        percentdiff(ctr,1)=hydrogenerationformiso(row,1);
        percentdiff(ctr,month+1)=(max(hydrogenerationformiso(row:row+5,month+2))...
            -min(hydrogenerationformiso(row:row+5,month+2)))/(min(hydrogenerationformiso(row:row+5,month+2)))*100;
        ctr=ctr+1;
    end
end

%Look at system-wide monthly values in each year
systemgeneration=zeros(6,13);
systemgeneration(:,1)=[2008:2013]';
%Go through each month
for month=1:12
    %Collect data for each year
    for row=2:size(hydrogenerationformiso,1)
        year=hydrogenerationformiso(row,2);
        rowinsystemgeneration=year-2008+1; %if year 2008, want row 1; if year 2013, want row 6
        systemgeneration(rowinsystemgeneration,month+1)=systemgeneration(rowinsystemgeneration,month+1)+...
            hydrogenerationformiso(row,month+2); %index by month+1 b/c first col is year
    end
end
figure
hold on
ctr=1;
for i=2:size(systemgeneration,2)
    plot(ctr,systemgeneration(:,i),'.k','MarkerSize',15);
    ctr=ctr+1;
end
title('System-Wide Hydro Generation Per Year'); xlabel('Month');
%Get system-wide annual values
systemgenerationperyear=sum(systemgeneration(:,2:end),2);
figure
plot(systemgenerationperyear,'.k')


%% GET AVERAGE MONTHLY VALUES AND SAVE THEM TO CSV
%Need to throw out zero values
%Desired CSV output: a net electricity generation value per month for each
%genreator. So generators going down, months across
hydrogenerationformisointerannualaverage=[0:12]; %column headers
%For each month, jump through generators and get average values
for month=1:12
    ctr=2; %use as index to hydrogenerationformisointerannualaverage
    %Skip to each generator
    for row=2:6:size(hydrogenerationformiso,1)
        %Get ORIS ID
        hydrogenerationformisointerannualaverage(ctr,1)=hydrogenerationformiso(row,1);
        %Isolate generation data. index month+1 b/c first col is generator ID, and then month+2 b/c
        %first 2 cols are gen & year
        currgendata=hydrogenerationformiso(row:row+5,month+2);
        %See if have any zeros in range of data
        if any(currgendata==0) %zeros - eliminate zeros then take average
            %Eliminate zeros
            currgendata(currgendata==0)=[];
        end
        %Get average of data
        hydrogenerationformisointerannualaverage(ctr,month+1)=mean(currgendata);
        
        ctr=ctr+1;
    end
end


%% COMPARE HYDRO PLANT CAPACITIES FROM 2008 TO 2013 AND IN FUTURE PLEXOS FLEET
%Already have PLEXOS fleet loaded - in futurepowerfleetforplexos
%Start by comparing 2008 to 2012, then 2012 to PLEXOS
%Fields: 2008: PLNTCODE, GENCODE, NAMEPLATE (maybe 'NAMEPLATE), PRIMEMOVER
%2013: Plant Code, Generator ID, Prime Mover, Nameplate Capacity (MW)
dirofeia860data='C:\Users\mtcraig\Desktop\EPP Research\Databases\EIA860_2008_and_2013\GenFiles';
[~,~,eia860data2008]=xlsread(strcat(dirofeia860data,'\','GenY08.xls'),'GenY08');
[~,~,eia860data2013]=xlsread(strcat(dirofeia860data,'\','3_1_Generator_Y2013.xlsx'),'Operable');
%Delete first row of 2013 data
eia860data2013(1,:)=[];

%Get columns for 2008 data
plantcol2008=find(strcmp(eia860data2008(1,:),'PLNTCODE'));
gencol2008=find(strcmp(eia860data2008(1,:),'GENCODE'));
capaccol2008=find(strcmp(eia860data2008(1,:),'NAMEPLATE'));
movercol2008=find(strcmp(eia860data2008(1,:),'PRIMEMOVER'));
%Get columns for 2013 data
plantcol2013=find(strcmp(eia860data2013(1,:),'Plant Code'));
gencol2013=find(strcmp(eia860data2013(1,:),'Generator ID'));
capaccol2013=find(strcmp(eia860data2013(1,:),'Nameplate Capacity (MW)'));
movercol2013=find(strcmp(eia860data2013(1,:),'Prime Mover'));
%Get columns for 2030 data
plantcol2030=find(strcmp(futurepowerfleetforplexos(1,:),'ORISCode'));
capaccol2030=find(strcmp(futurepowerfleetforplexos(1,:),'Capacity'));

%Extract plant ID & capacity for EIA860 data
eia860data2008plantandcapacity=horzcat(cell2mat(eia860data2008(2:end,plantcol2008)),...
    cell2mat(eia860data2008(2:end,capaccol2008)));
eia860data2013plantandcapacity=horzcat(cell2mat(eia860data2013(2:end,plantcol2013)),...
    cell2mat(eia860data2013(2:end,capaccol2013)));
%Extract the same for future fleet data. Here, ORIS coce is a string, so
%convert to num first
for i=2:size(futurepowerfleetforplexos,1)
    futurepowerfleetforplexos{i,plantcol2030}=str2num(futurepowerfleetforplexos{i,plantcol2030});
end
fleet2030plantandcapacity=horzcat(cell2mat(futurepowerfleetforplexos(2:end,plantcol2030)),...
        cell2mat(futurepowerfleetforplexos(2:end,capaccol2030)));

%For each plant, calculate total capacity
hydrocapacities2008and2013and2030=hydrogenerationformisointerannualaverage(:,1);
hydrocapacities2008and2013and2030(1,2:4)=[2008,2013,2030];
for i=2:size(hydrocapacities2008and2013and2030,1)
    %Find rows of plant
    rowsofplant2008=find(hydrocapacities2008and2013and2030(i,1)==eia860data2008plantandcapacity(:,1));
    rowsofplant2013=find(hydrocapacities2008and2013and2030(i,1)==eia860data2013plantandcapacity(:,1));
    rowsofplant2030=find(hydrocapacities2008and2013and2030(i,1)==fleet2030plantandcapacity(:,1));
    
    %Save sum of capacities
    hydrocapacities2008and2013and2030(i,2)=sum(eia860data2008plantandcapacity(rowsofplant2008,2));
    hydrocapacities2008and2013and2030(i,3)=sum(eia860data2013plantandcapacity(rowsofplant2013,2));
    hydrocapacities2008and2013and2030(i,4)=sum(fleet2030plantandcapacity(rowsofplant2030,2));
end

%Bar chart of capacities
bar(hydrocapacities2008and2013and2030(2:end,2:4));
%Get change from 2008 to 2013
hydrocapacities2013minus2008=hydrocapacities2008and2013and2030(2:end,3)-hydrocapacities2008and2013and2030(2:end,2);
%Bar chart of changes
figure; bar(hydrocapacities2013minus2008);title('2013 - 2008 Capac');
%Add capacity in 2013
hydrocapacities2013minus2008(:,2)=hydrocapacities2008and2013and2030(2:end,3);
figure; bar(hydrocapacities2013minus2008);title('2013 - 2008 Capac w/ 2013 Capac');
legend('2013-2008','2013')
%Change as proportion of size in 2013
hydrocapacities2013minus2008proportion=hydrocapacities2013minus2008(:,1)./hydrocapacities2008and2013and2030(2:end,3);
figure; bar(hydrocapacities2013minus2008proportion); title('2013-2008 / 2013 Capac');

%Get change from 2013 to 2030
hydrocapacities2030minus2013=hydrocapacities2008and2013and2030(2:end,4)-hydrocapacities2008and2013and2030(2:end,3);
%Bar chart of changes
figure; bar(hydrocapacities2030minus2013);title('2030 - 2013 Capac');
%Add capacity in 2030
hydrocapacities2030minus2013(:,2)=hydrocapacities2008and2013and2030(2:end,4);
figure; bar(hydrocapacities2030minus2013);title('2030 - 2013 Capac w/ 2030 Capac');
legend('2030-2013','2030')

%Results of analysis: most plants do not change at all between 2008 and
%2013, and of the plants that do change, the change is very slight relative
%to the 2013 capacity. There are a couple plants that are zero'd out in 2013
%, but these plants are listed in 2030. Given the small changes betweeen
%these years, I don't believe it's necessary to directly account for
%capacity changes in the 5-year average of monthly max energy. 

%Between 2013 and 2030, there are more changes than between 2008 and 2013.
%Many plants experience some decrease in capacity, likely due to retirement
%of generators. There are also some large changes at specific plants that
%can't be ignored.


%% MODIFICATION OF MONTHLY MAXIMUM ENERGY
%Here, I modify the 5-year average monthly max energy calculated above to
%account for the change in capacity from 2013 to 2030 of each plant. I do
%this because I found many plants had significant changes in capacity
%between 2013 and 2030; specifically, many plants have lower capacity in
%2030.

%***Monthly max energy represents the amount of water that flows through
%the dam in a year. If I retire a turbine at a dam, the asme amount of
%water could still flow through the dam; so really, the monthly max energy
%wouldn't change. It just means that the turbines remaining could generate
%at a higher capacity factor, since there's more water available for them.
%The timing of the generation matters here, though. If 2 turbines generate
%at 50% all year, then if 1 retires, the other could generate at 100% and
%result in the same amount of generation. But if both generators generate
%at 0% and then 100% due to water availability, then the retirement of one
%could not be offset by the other. 


%OPTION:
%Monthly max energy will be modified as follows. For plants w/ a
%proportional change in capacity of 0.10 or less, monthly max energy will
%not change. For plants with a proportional change greater than 0.10, I
%scale the monthly max energy by the proportional change in capacity. So if
%2030 capacity is 0.5 of the 2013 capacity, then I multiply the monthly max
%energy value by 0.5. 


%% WRITE CSV
%Write CSV with max monthly energy in MWh
cd 'C:\Users\mtcraig\Desktop\EPP Research\Databases\EIAForm923\2008to2013CompiledFiles\AggregatedData\'
csvwrite(strcat('AverageMISOMonthlyHydroNetElecGen2008to2013',compliancescenario,'.csv'),hydrogenerationformisointerannualaverage);



