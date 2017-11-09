%Michael Craig
%November 4, 2015
%Function opens a fiscal year regional data file, and extracts the data.

function [data] = ExtractDataPLEXOSAnnual(fiscalyeardir,filename)

%Get sheet name in that file
if (size(filename,2)>31) sheetname=filename(1:31); else sheetname=filename; end

%Define .csv file
filecsv=strcat(filename,'.csv');

%Open file
[~,~,data]=xlsread(fullfile(fiscalyeardir,filecsv),sheetname);