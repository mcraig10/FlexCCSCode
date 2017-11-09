%Michael Craig
%October 23, 2014

%This script imports CEMS data for July 2014 for MISO and compares it at
%the generator level to emissions rates calculated from the IPM Parsed
%Files. 

%% Import CEMS data
%JULY 2014
cd 'C:\Users\mtcraig\Desktop\EPP Research\Databases\CEMS\CEMS MISO 2014 Sample\EPADownload';
cemsfiletoopen='emission_01-06-2015.xlsx';
[~,~,cemsdata]=xlsread(cemsfiletoopen,'emission_01-06-2015');

%JANUARY & FEBRUARY 2014
% cd 'C:\Users\mcraig10\Desktop\EPP Research\Databases\CEMS\CEMS_MISO_JanAndFeb2014_1Apr2015';
% cemsfiletoopen='emission_04-01-2015.xlsx';
% [~,~,cemsdata]=xlsread(cemsfiletoopen,'emission_04-01-2015');

%Get data columns
facilityidcolcemsdata=find(strcmp(cemsdata(1,:),(' Facility ID (ORISPL)')));
unitidcolcemsdata=find(strcmp(cemsdata(1,:),(' Unit ID')));
so2emscoldemsdata=find(strcmp(cemsdata(1,:),(' SO2 (pounds)')));
noxemscoldemsdata=find(strcmp(cemsdata(1,:),(' NOx (pounds)')));
co2emscoldemsdata=find(strcmp(cemsdata(1,:),(' CO2 (short tons)')));
heatinputcolcemsdata=find(strcmp(cemsdata(1,:),(' Heat Input (MMBtu)')));
grossoutputcolcemsdata=find(strcmp(cemsdata(1,:),(' Gross Load (MW)')));
fueltypecolcemsdata=find(strcmp(cemsdata(1,:),(' Fuel Type (Primary)')));

%Convert facility & some unit IDs to strings
for i=2:size(cemsdata,1)
    cemsdata{i,facilityidcolcemsdata}=num2str(cemsdata{i,facilityidcolcemsdata});
    cemsdata{i,unitidcolcemsdata}=num2str(cemsdata{i,unitidcolcemsdata});
end
%Get unique plant + generator combos
genandunitidcems=strcat(cemsdata(:,facilityidcolcemsdata),cemsdata(:,unitidcolcemsdata));
uniquegenscems=unique(genandunitidcems);

%Calculate emissions rate for unique plants
emissionsratescems={'ORISId','GenID','NOxEmsRate(ton/mwh)','SO2EmsRate(ton/mwh)','CO2EmsRate(ton/mwh)'};
for i=2:size(uniquegenscems,1)
    %Get rows in CEMS
    [rowsofdata,~]=find(strcmp(uniquegenscems(i,1),genandunitidcems(:,1)));
    
    %Get data
    grossgen=cell2mat(cemsdata(rowsofdata,grossoutputcolcemsdata));
    so2emissions=cell2mat(cemsdata(rowsofdata,so2emscoldemsdata));
    noxemissions=cell2mat(cemsdata(rowsofdata,noxemscoldemsdata));
    co2emissions=cell2mat(cemsdata(rowsofdata,co2emscoldemsdata));
    orisid=cemsdata{rowsofdata(1),facilityidcolcemsdata};
    genid=cemsdata{rowsofdata(1),unitidcolcemsdata};
    
    %Get rid of NaNs
    grossgen=grossgen(isnan(grossgen)==0);
    so2emissions=so2emissions(isnan(so2emissions)==0);
    noxemissions=noxemissions(isnan(noxemissions)==0);
    co2emissions=co2emissions(isnan(co2emissions)==0);
    
    %Calculate emissions rates
    so2emsratecems=sum(grossgen)/sum(so2emissions)/2000; %convert to tons/mwh
    noxemsratecems=sum(grossgen)/sum(noxemissions)/2000; %convert to tons/mwh
    co2emsratecems=sum(grossgen)/sum(co2emissions); %already in tons/mwh
    
    %Save data
    rowofdata={orisid,genid,noxemsratecems,so2emsratecems,co2emsratecems};
    emissionsratescems=[emissionsratescems;rowofdata];
end



%% IMPORT PARSED FILE DATA
%Import Base Case (2025)
cd 'C:\Users\mtcraig\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\Parsed Files'
parsedfile='CPP_ParsedFile_BaseCase_2025_ToTinkerWith.xlsx';
[~,~,parseddata]=xlsread(parsedfile,'EPA5-13_Base_Case 2025');

%Get columns
cd 'C:\Users\mtcraig\Desktop\EPP Research\Matlab'
[parseddataorisidcol,parseddataunitidcol,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(parseddata);
noxemsrateparsedcol=find(strcmp(parseddata(1,:),'SO2EmsRate (1000 ton/GWh)'));
so2emsrateparsedcol=find(strcmp(parseddata(1,:),'NOxEmsRate (1000 ton/GWh) '));
co2emsrateparsedcol=find(strcmp(parseddata(1,:),'CO2EmsRate  (1000 ton/GWh)'));

%Isolate MISO plants
parseddatamiso(1,:)=parseddata(1,:);
for i=2:size(parseddata,1)
    if strcmp(parseddata{i,parseddataregioncol}(1:3),'MIS')==1 %if first 3 letters are MIS
        parseddatamiso(end+1,:)=parseddata(i,:);
    end
end

%Convert facility & some unit IDs to strings
for i=2:size(parseddatamiso,1)
    parseddatamiso{i,parseddataorisidcol}=num2str(parseddatamiso{i,parseddataorisidcol});
    parseddatamiso{i,parseddataunitidcol}=num2str(parseddatamiso{i,parseddataunitidcol});
end

%Isolate MISO plants without retrofits
parseddatamisonoretrofits=parseddatamiso;
for i=size(parseddatamisonoretrofits,1):-1:2
    if isempty(parseddatamisonoretrofits{i,parseddataretrofitcol})==0 %if retrofits
        parseddatamisonoretrofits(i,:)=[]; %eliminate row
    end
end

%Match up MISO plants to CEMS plants
cemsandparsedfileemissionsrates=emissionsratescems;
cemsandparsedfileemissionsrates{1,end+1}='ParsedNOxEmsRate';
cemsandparsedfileemissionsrates{1,end+1}='ParsedSO2EmsRate';
cemsandparsedfileemissionsrates{1,end+1}='ParsedCO2EmsRate';
cemsandparsedfileemissionsrates{1,end+1}='CoalIndicator';
cemsandparsedfileemissionsratesnoretrofits=emissionsratescems;
cemsandparsedfileemissionsratesnoretrofits{1,end+1}='ParsedNOxEmsRate';
cemsandparsedfileemissionsratesnoretrofits{1,end+1}='ParsedSO2EmsRate';
cemsandparsedfileemissionsratesnoretrofits{1,end+1}='ParsedCO2EmsRate';
for i=2:size(emissionsratescems,1)
    %Get row of generator in parsed file for current row in CEMS
    plantrow=find(strcmp(emissionsratescems{i,1},parseddatamiso(:,parseddataorisidcol))...
        & strcmp(emissionsratescems{i,2},parseddatamiso(:,parseddataunitidcol)));
    
    %Tack on parsed file emissions rate (don't need to convert units since
    %1000 ton/GWh = ton/MWh).
    cemsandparsedfileemissionsrates{i,6}=parseddatamiso{i,noxemsrateparsedcol};
    cemsandparsedfileemissionsrates{i,7}=parseddatamiso{i,so2emsrateparsedcol};
    cemsandparsedfileemissionsrates{i,8}=parseddatamiso{i,co2emsrateparsedcol};
    fueltypetemp=parseddatamiso{i,parseddatafueltypecol};
    if strcmp(fueltypetemp,'Coal')==1
        cemsandparsedfileemissionsrates{i,9}=1;
    else
        cemsandparsedfileemissionsrates{i,9}=0;
    end
    
    %Repeat above for generators without retrofits
    %Get row of generator in parsed file for current row in CEMS
    plantrow=find(strcmp(emissionsratescems{i,1},parseddatamisonoretrofits(:,parseddataorisidcol))...
        & strcmp(emissionsratescems{i,2},parseddatamisonoretrofits(:,parseddataunitidcol)));
    
    %Tack on parsed file emissions rate (don't need to convert units since
    %1000 ton/GWh = ton/MWh).
    cemsandparsedfileemissionsratesnoretrofits{i,6}=parseddatamisonoretrofits{i,noxemsrateparsedcol};
    cemsandparsedfileemissionsratesnoretrofits{i,7}=parseddatamisonoretrofits{i,so2emsrateparsedcol};
    cemsandparsedfileemissionsratesnoretrofits{i,8}=parseddatamisonoretrofits{i,co2emsrateparsedcol};
end

%Isolate coal plants
cemsandparseddatacoalplants=cell2mat(cemsandparsedfileemissionsrates(2:end,3:9));
cemsandparseddatacoalplants=cemsandparseddatacoalplants(cemsandparseddatacoalplants(:,7)==1,:);

%% PLOT
%ALL PLANTS
%Plot CO2 emissions rates
figure; subplot(2,2,1); scatter(cell2mat(cemsandparsedfileemissionsrates(2:end,5)),cell2mat(cemsandparsedfileemissionsrates(2:end,8)));
refline(1,0); title('CO2 Em Rates, Parsed v CEMS, All Gen');
%Plot so2 emissions rates
subplot(2,2,2); scatter(cell2mat(cemsandparsedfileemissionsrates(2:end,4)),cell2mat(cemsandparsedfileemissionsrates(2:end,7)));
refline(1,0); title('SO2 Em Rates, Parsed v CEMS, All Gen');
%Plot nox emissions rates
subplot(2,2,3); scatter(cell2mat(cemsandparsedfileemissionsrates(2:end,3)),cell2mat(cemsandparsedfileemissionsrates(2:end,6)));
refline(1,0); title('NOx Em Rates, Parsed v CEMS, All Gen');
% %Solo plots
% figure; scatter(cell2mat(cemsandparsedfileemissionsrates(2:end,3)),cell2mat(cemsandparsedfileemissionsrates(2:end,6)));
% refline(1,0); title('NOx Em Rates, Parsed v CEMS, All Gen');

%COAL PLANTS
%Plot CO2 emissions rates
figure; subplot(2,2,1); scatter(cemsandparseddatacoalplants(:,3),cemsandparseddatacoalplants(:,6));
refline(1,0); title('CO2 Em Rates, Parsed v CEMS, Coal Gen');
%Plot so2 emissions rates
subplot(2,2,2); scatter(cemsandparseddatacoalplants(:,2),cemsandparseddatacoalplants(:,5));
refline(1,0); title('SO2 Em Rates, Parsed v CEMS, Coal Gen');
%Plot nox emissions rates
subplot(2,2,3); scatter(cemsandparseddatacoalplants(:,1),cemsandparseddatacoalplants(:,4));
refline(1,0); title('NOx Em Rates, Parsed v CEMS, Coal Gen');

%PLOT RATIO OF PARSED/CEMS EMISSIONS TO TOTAL EMISSIONS
%This will give a sense for how much of the emissions are at plants with
%emissions rates that match well between CEMS & parsed files
%Didn't do this.

%NO RETROFITS
%Plot CO2 emissions rates
figure; subplot(2,2,1); scatter(cell2mat(cemsandparsedfileemissionsratesnoretrofits(2:end,5)),cell2mat(cemsandparsedfileemissionsratesnoretrofits(2:end,8)));
refline(1,0); title('CO2 Em Rates, Parsed v CEMS, No Rets');
%Plot so2 emissions rates
subplot(2,2,2); scatter(cell2mat(cemsandparsedfileemissionsratesnoretrofits(2:end,4)),cell2mat(cemsandparsedfileemissionsratesnoretrofits(2:end,7)));
refline(1,0);title('SO2 Em Rates, Parsed v CEMS, No Rets');
%Plot nox emissions rates
subplot(2,2,3); scatter(cell2mat(cemsandparsedfileemissionsratesnoretrofits(2:end,3)),cell2mat(cemsandparsedfileemissionsratesnoretrofits(2:end,6)));
refline(1,0);title('NOx Em Rates, Parsed v CEMS, No Rets');

%% COMPARE EMISSIONS RATES IN OPTION 1 VERSUS OPTION 2 OF CPP COMPLIANCE
%Compare these because both are examples of implementation, and would
%expect emissions rates to be roughly the same, especially with respect to
%CO2.

%Import Option 1 (State, 2025)
cd 'C:\Users\mtcraig\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\Parsed Files'
parsedfile='CPP_ParsedFile_Option1State_2025.xlsx';
[~,~,parseddataoption1]=xlsread(parsedfile,'Option 1 State 2025');

%Import Option 2 (Regional, 2025)
cd 'C:\Users\mtcraig\Desktop\EPP Research\Databases\EPA IPM Clean Power Plan Files\Parsed Files'
parsedfile='CPP_ParsedFile_Option2Regional_2025.xlsx';
[~,~,parseddataoption2]=xlsread(parsedfile,'Option 2 Regional 2025');

%Get columns (same for both Options)
cd 'C:\Users\mtcraig\Desktop\EPP Research\Matlab'
[parseddataorisidcol,parseddataunitidcol,parseddatafueltypecol,...
    parseddataheatratecol, parseddatacapacitycol,parseddataplanttypecol,...
    parseddataretrofitcol,parseddataregioncol,parseddatastatecol,parseddatafossilunitcol]=...
    GetColumnNumbersFromCPPParsedFile(parseddataoption1);

%Isolate MISO plants
for i=size(parseddataoption1,1):-1:2
    if strcmp(parseddataoption1{i,parseddataregioncol}(1:3),'MIS')==0 
        parseddataoption1(i,:)=[];
    end
end
for i=2:size(parseddataoption2,1)
    if strcmp(parseddataoption2{i,parseddataregioncol}(1:3),'MIS')==0
        parseddataoption2(i,:)=[];
    end
end

%Convert facility & some unit IDs to strings
for i=2:size(parseddataoption1,1)
    parseddataoption1{i,parseddataorisidcol}=num2str(parseddataoption1{i,parseddataorisidcol});
    parseddataoption1{i,parseddataunitidcol}=num2str(parseddataoption1{i,parseddataunitidcol});
end
for i=2:size(parseddataoption2,1)
    parseddataoption2{i,parseddataorisidcol}=num2str(parseddataoption2{i,parseddataorisidcol});
    parseddataoption2{i,parseddataunitidcol}=num2str(parseddataoption2{i,parseddataunitidcol});
end



%Match up MISO plants to CEMS plants
cemsandparsedfileemissionsrates=emissionsratescems;
cemsandparsedfileemissionsrates{1,end+1}='ParsedNOxEmsRate';
cemsandparsedfileemissionsrates{1,end+1}='ParsedSO2EmsRate';
cemsandparsedfileemissionsrates{1,end+1}='ParsedCO2EmsRate';
cemsandparsedfileemissionsrates{1,end+1}='CoalIndicator';
cemsandparsedfileemissionsratesnoretrofits=emissionsratescems;
cemsandparsedfileemissionsratesnoretrofits{1,end+1}='ParsedNOxEmsRate';
cemsandparsedfileemissionsratesnoretrofits{1,end+1}='ParsedSO2EmsRate';
cemsandparsedfileemissionsratesnoretrofits{1,end+1}='ParsedCO2EmsRate';
for i=2:size(emissionsratescems,1)
    %Get row of generator in parsed file for current row in CEMS
    plantrow=find(strcmp(emissionsratescems{i,1},parseddatamiso(:,parseddataorisidcol))...
        & strcmp(emissionsratescems{i,2},parseddatamiso(:,parseddataunitidcol)));
    
    %Tack on parsed file emissions rate (don't need to convert units since
    %1000 ton/GWh = ton/MWh).
    cemsandparsedfileemissionsrates{i,6}=parseddatamiso{i,noxemsrateparsedcol};
    cemsandparsedfileemissionsrates{i,7}=parseddatamiso{i,so2emsrateparsedcol};
    cemsandparsedfileemissionsrates{i,8}=parseddatamiso{i,co2emsrateparsedcol};
    fueltypetemp=parseddatamiso{i,parseddatafueltypecol};
    if strcmp(fueltypetemp,'Coal')==1
        cemsandparsedfileemissionsrates{i,9}=1;
    else
        cemsandparsedfileemissionsrates{i,9}=0;
    end
    
    %Repeat above for generators without retrofits
    %Get row of generator in parsed file for current row in CEMS
    plantrow=find(strcmp(emissionsratescems{i,1},parseddatamisonoretrofits(:,parseddataorisidcol))...
        & strcmp(emissionsratescems{i,2},parseddatamisonoretrofits(:,parseddataunitidcol)));
    
    %Tack on parsed file emissions rate (don't need to convert units since
    %1000 ton/GWh = ton/MWh).
    cemsandparsedfileemissionsratesnoretrofits{i,6}=parseddatamisonoretrofits{i,noxemsrateparsedcol};
    cemsandparsedfileemissionsratesnoretrofits{i,7}=parseddatamisonoretrofits{i,so2emsrateparsedcol};
    cemsandparsedfileemissionsratesnoretrofits{i,8}=parseddatamisonoretrofits{i,co2emsrateparsedcol};
end






