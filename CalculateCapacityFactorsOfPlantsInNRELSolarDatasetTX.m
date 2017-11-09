%Michael Craig, 29 May 2015
%This script goes through the NREL Transmission Grid Integration Solar PV
%Generation datasets (at C:\Users\mcraig10\Desktop\EPP
%Research\Databases\NRELSolarPVData) and ranks plants by capacity factor.
%PV Generation datasets are from http://www.nrel.gov/electricity/transmission/solar_integration_dataset.html?disclaimeragreement=This+data+and+software+%28%22Data%22%29+is+provided+by+the+National+Renewable+Energy+Laboratory+%28%22NREL%22%29%2C+which+is+operated+by+the+Alliance+for+Sustainable+Energy%2C+LLC+%28%22ALLIANCE%22%29+for+the+U.S.+Department+Of+Energy+%28%22DOE%22%29.%0D%0A%0D%0AAccess+to+and+use+of+these+Data+shall+impose+the+following+obligations+on+the+user%2C+as+set+forth+in+this+Agreement.++The+user+is+granted+the+right%2C+without+any+fee+or+cost%2C+to+use%2C+copy%2C+modify%2C+alter%2C+enhance+and+distribute+these+Data+for+any+purpose+whatsoever%2C+provided+that+this+entire+notice+appears+in+all+copies+of+the+Data.++Further%2C+the+user+agrees+to+credit+DOE%2FNREL%2FALLIANCE+in+any+publication+that+results+from+the+use+of+these+Data.++The+names+DOE%2FNREL%2FALLIANCE%2C+however%2C+may+not+be+used+in+any+advertising+or+publicity+to+endorse+or+promote+any+products+or+commercial+entities+unless+specific+written+permission+is+obtained+from+DOE%2FNREL%2F+ALLIANCE.++The+user+also+understands+that+DOE%2FNREL%2FAlliance+is+not+obligated+to+provide+the+user+with+any+support%2C+consulting%2C+training+or+assistance+of+any+kind+with+regard+to+the+use+of+these+Data+or+to+provide+the+user+with+any+updates%2C+revisions+or+new+versions+of+these+Data.%0D%0A%0D%0AYOU+AGREE+TO+INDEMNIFY+DOE%2FNREL%2FAlliance%2C+AND+ITS+SUBSIDIARIES%2C+AFFILIATES%2C+OFFICERS%2C+AGENTS%2C+AND+EMPLOYEES+AGAINST+ANY+CLAIM+OR+DEMAND%2C+INCLUDING+REASONABLE+ATTORNEYS%27+FEES%2C+RELATED+TO+YOUR+USE+OF+THESE+DATA.++THESE+DATA+ARE+PROVIDED+BY+DOE%2FNREL%2FAlliance+%22AS+IS%22+AND+ANY+EXPRESS+OR+IMPLIED+WARRANTIES%2C+INCLUDING+BUT+NOT+LIMITED+TO%2C+THE+IMPLIED+WARRANTIES+OF+MERCHANTABILITY+AND+FITNESS+FOR+A+PARTICULAR+PURPOSE+ARE+DISCLAIMED.++IN+NO+EVENT+SHALL+DOE%2FNREL%2FALLIANCE+BE+LIABLE+FOR+ANY+SPECIAL%2C+INDIRECT+OR+CONSEQUENTIAL+DAMAGES+OR+ANY+DAMAGES+WHATSOEVER%2C+INCLUDING+BUT+NOT+LIMITED+TO+CLAIMS+ASSOCIATED+WITH+THE+LOSS+OF+DATA+OR+PROFITS%2C+WHICH+MAY+RESULT+FROM+AN+ACTION+IN+CONTRACT%2C+NEGLIGENCE+OR+OTHER+TORTIOUS+CLAIM+THAT+ARISES+OUT+OF+OR+IN+CONNECTION+WITH+THE+ACCESS%2C+USE+OR+PERFORMANCE+OF+THESE+DATA.%0D%0A%0D%0A&agree=1&submit=Submit

%Process:
%1) Define states for analysis
%2) For each state, open folder
%3) In that folder, find relevant files (want actual generation, not day or
%hour ahead)
%4) From file name, extract plant size
%5) Open file
%6) Calculate hourly capacity factors - need to downscale power generation
%6a) Check that capacity factors <1
%7) Calculate average annual capacity factor - do this by averaging hourly
%CFs, and by dividing total annual generation by total annual possible
%generation. Should be the same.
%8) Save file name & capacity factor in cell array

%% DEFINE WHICH COMPUTER RUNNING ON
pc='work';

%% DEFINE STATES TO EXAMINE
%Generation data is divided by state into separate folders. Here, list the
%states you want to analyze generation data for.
statestoanalyze=['TX'];

%% SET MASTER DIRECTORY
masterdir='C:\Users\mtcraig\Desktop\EPP Research\Databases\NRELSolarPVDataTX';

%% ITERATE OVER STATE FOLDERS
filenamesandcfs={'State','File','CF','PlantSize'};
for statectr=1:size(statestoanalyze,1)
    currstate=statestoanalyze(statectr,:);    
    %Get list of CSV files
    listoffiles=dir(fullfile(masterdir,currstate,'*.csv'));
    %Create cell array to save results just from this state
    filenamesandcfscurrstate={};
    %Go through files, identifying actual generation files
    for filectr=1:size(listoffiles,1)
        currfilename=listoffiles(filectr).name;
        %See if it's an Actual generation file. If not, then don't need
        %file. If so, then will calculate CF.
        if findstr(currfilename,'Actual')
            %Now have an actual generation file. Get plant size from file
            %name. Do this by finding MW, then moving backwards.
            %Get index of 'MW'
            indexofmw=strfind(currfilename,'MW');
            %Largest solar plants are triple digits (not even close to 1
            %GW) - so move backward 3 steps and see if '_' or #; if '_', 
            %use 2 prior digits; if #, use 3 prior digits. Some plants,
            %though, have single digit size, so need to check 3 back too!
            test=currfilename(indexofmw-3);
            test2=currfilename(indexofmw-2);
            if strcmp(test,'_') || strcmp(test,'V') %if '_', or in the case of a single digit size, 'V' (since before _ is UPV)
                if strcmp(test2,'_') 
                    currplantsize=currfilename(indexofmw-1); %1 digit size
                else
                    currplantsize=currfilename((indexofmw-2):(indexofmw-1)); %2 digit size
                end
            else
                currplantsize=currfilename((indexofmw-3):(indexofmw-1)); %3 digit size
            end      
            currplantsize=str2num(currplantsize);
            %Read in file - col 1 = local time, col 2 = generation (MW)
            [~,~,plantdata]=xlsread(fullfile(masterdir,currstate,currfilename));
            %Downscale 5-minute data to hourly data
            plantgen=cell2mat(plantdata(2:end,2));
            hourlyplantgen=zeros(8760,1); hourlyplantgenctr=1;
            for genctr=1:12:size(plantgen,1) %jump forward in icnrements of 12 to get to new hour
                hourlyplantgen(ceil(genctr/12),1)=mean(plantgen(genctr:(genctr+11)));
            end
            %Get hourly CF
            hourlycf=hourlyplantgen/currplantsize;
            %Get mean hourly CF
            meanhourlycf=mean(hourlycf);
            %Also get total annual generation and capacity factor that way
            totalannualgen=sum(hourlyplantgen);
            totalannualcf=totalannualgen/(currplantsize*8760);
            
            %Save file name and capacity factor in cell array with only
            %entires from this state
            filenamesandcfscurrstate=vertcat(filenamesandcfscurrstate,{currstate,currfilename,meanhourlycf,currplantsize});
            %Sort in decreasing capacity factor
            sortedcfs=sortrows(filenamesandcfscurrstate,-3); %NOTE: column # is for mean hourly CF
                        
            %TESTS
            %If CFs not equal, output message
            if round(meanhourlycf*100)~=round(totalannualcf*100)
                'Mean hourly and total annual CF not equal!'
                strcat(currstate,',',currfilename)
            end      
            %Make sure no hourly CFs >1
            if min(hourlycf<=1)==0
                'Hourly CF greater than 1!'
                strcat(currstate,',',currfilename)
            end
        end        
    end
    %Save CFs for this state into 1 giant cell array
    filenamesandcfs=vertcat(filenamesandcfs,sortedcfs);       
end

%Write CSV with info for all states in master director
cell2csv(fullfile(masterdir,'SolarCapacityFactorsNRELSERC.csv'),filenamesandcfs);














