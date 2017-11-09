%Michael Craig
%November 17, 2015
%Function to extract data from a fiscal year generation or reserve file.

function [annualvalue] = GetFiscalYearGeneratorData(fiscalyeardir,plexosid,datatype)

%STEPS
%1) Get CSV name
%2) Get CSV sheet name by truncating CSV name
%3) Load in data

%Need to vary process based on type of data, since CSV names change

if strcmp(datatype,'Gen')
    csvnamebase=strcat('ST Generator(',num2str(plexosid),').Generation');
    csvname=strcat(csvnamebase,'.csv');
    if (length(csvnamebase)>31) csvnamebase=csvnamebase(1:31); end;
    [~,~,annualdata]=xlsread(fullfile(fiscalyeardir,csvname),csvnamebase);
    
elseif strcmp(datatype,'RegUp')
    csvnamebase=strcat('ST Generator(',num2str(plexosid),').Regulation Raise Reserve');
    csvname=strcat(csvnamebase,'.csv');
    if (length(csvnamebase)>31) csvnamebase=csvnamebase(1:31); end;
    [~,~,annualdata]=xlsread(fullfile(fiscalyeardir,csvname),csvnamebase);

elseif strcmp(datatype,'RegDown')
    csvnamebase=strcat('ST Generator(',num2str(plexosid),').Regulation Lower Reserve');
    csvname=strcat(csvnamebase,'.csv');
    if (length(csvnamebase)>31) csvnamebase=csvnamebase(1:31); end;
    [~,~,annualdata]=xlsread(fullfile(fiscalyeardir,csvname),csvnamebase);

elseif strcmp(datatype,'Raise')
    csvnamebase=strcat('ST Generator(',num2str(plexosid),').Raise Reserve');
    csvname=strcat(csvnamebase,'.csv');
    if (length(csvnamebase)>31) csvnamebase=csvnamebase(1:31); end;
    [~,~,annualdata]=xlsread(fullfile(fiscalyeardir,csvname),csvnamebase);

elseif strcmp(datatype,'Replace')
    csvnamebase=strcat('ST Generator(',num2str(plexosid),').Replacement Reserve');
    csvname=strcat(csvnamebase,'.csv');
    if (length(csvnamebase)>31) csvnamebase=csvnamebase(1:31); end;
    [~,~,annualdata]=xlsread(fullfile(fiscalyeardir,csvname),csvnamebase);
end

%Strip out annual value
annualvalue=annualdata{2,4}*1000;
