%Michael Craig
%Get total generation by generator

%% KEY PARAMETERS
%FOLDER W/ OUTPUT FILES
%CPP, 4 GW flex CCS
% basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\CCSPaper\CPP\CPPEEPt5FlxCCS1MW4000WndMW0Rmp1MSL1Vnt0NRELRes24LA';
%CPP, 4 GW inflex CCS
% basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\CCSPaper\CPP\CPPEEPt5FlxCCS0MW4000WndMW0Rmp1MSL1Vnt0NRELRes24LA';
%Lower limit, 4 GW flex CCS
% basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\CCSPaper\LwrLm\CPPEEPt5FlxCCS1MW4000WndMW0Rmp1MSL1Vnt0LwrLmtNRELRes24LA';
%Lower limit, 4 GW inflex CCS
% basedirforflatfiles='C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\CCSPaper\LwrLm\CPPEEPt5FlxCCS0MW4000WndMW0Rmp1MSL1Vnt0LwrLmtNRELRes24LA';
basedirforflatfiles = 'C:\Users\mtcraig\Desktop\EPP Research\PLEXOS Data Files\Clean Power Plan Analysis\ResultsNRELRes\CPPLimit\CPPEEPt5FlxCCS0MW0WndMW0Rmp1MSL1Vnt0CO2P0NRELRes';
%SET FOLDER NAME FOR ANNUAL GENERATION DATA
annualdir = fullfile(basedirforflatfiles,'fiscal year');

%% GET ID FILE
[~,~,ids]=xlsread(fullfile(basedirforflatfiles,'id2name.csv'),'id2name');
idsidcol=find(strcmp(ids(1,:),'id'));
idsnamecol=find(strcmp(ids(1,:),'name'));
idclasscol=find(strcmp(ids(1,:),'class'));
%Isolate generator IDs and convert PLEXOS IDs to strings
generatorids=ids(1,:);
for i=2:size(ids,1)
    if strcmp(ids{i,idclasscol},'Generator')
        newrow=size(generatorids,1)+1;
        generatorids(newrow,:)=ids(i,:);
        generatorids{newrow,2}=num2str(generatorids{newrow,2});
    end
end

%% GET ANNUAL GENERATION
generationdata={'PLEXOSID','ORIS-GenID','AnnualGenMWh'};
plexosidcol=1; orisgenidcol=2; annualgencol=3;

%Get list of files in annual directory
filesandfolders=dir(annualdir);
filesandfolders(1:2,:)=[]; %remove . and ..

%For each folder, check if generation file, and if so, add data to
%generationdata
for filectr=1:size(filesandfolders,1)
    filename=filesandfolders(filectr).name;
    if strfind(filename,'ST Generator')
        if strfind(filename,'Generation')
            newrow=size(generationdata,1)+1;
            %Get PLEXOS ID
            idindexstart = length('ST Generator(')+1;
            idindexend = findstr(filename,').Generation')-1;
            plexosid = filename(idindexstart:idindexend);
            generationdata{newrow,plexosidcol}=plexosid;

            %Get ORIS & Gen ID from id2name file
            %First, find row in ids
            idsrow = find(strcmp(generatorids(:,idsidcol),plexosid));
            unitid = generatorids{idsrow,idsnamecol};
            hasbackslash=findstr(unitid,'/');
            if isempty(hasbackslash)==0 %if not empty, has a backslash so need to change around
                %Last 4 digits go first, then first digit, then first digit, then
                %middle digit
                slashpositions=findstr(unitid,'/');
                newcurrunitid=unitid(slashpositions(2)+1:end);
                newcurrunitid=strcat(newcurrunitid,'-',unitid(1:slashpositions(1)-1));
                newcurrunitid=strcat(newcurrunitid,'-',unitid(slashpositions(1)+1:slashpositions(2)-1));
                unitid=newcurrunitid;
            end
            generationdata{newrow,orisgenidcol}=unitid;

            %Get total generation data
            parttoremove=length('.csv'); filelength=length(filename);
            sheetname=filename(1:filelength-parttoremove);
            if (size(sheetname,2)>31) sheetname=sheetname(1:31); end
            [~,~,gendata]=xlsread(fullfile(annualdir,filename),sheetname);
            annualgen = gendata{2,4}*1000; clear gendata
            generationdata{newrow,annualgencol}=annualgen;
        end
    end
end










