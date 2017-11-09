%Michael Craig
%January 26, 2015
%Create table that is used to convert dates in the NREL wind generation files from
%UTC to CST

function [mapofutctocstwindtime]=CreateTableForConvertingUTCtoCST(winddatadir)

%Load arbitrary NREL wind generation file
winddatafile=strcat(winddatadir,'\','SITE_00001.csv');
winddata=csvread(winddatafile,3); %start at row 3 - skip over headers
%Data: DATE TIME(UTC) SPEED80M(M/S) NETPOWER(MW). DATE is in YEARMONTHDAY.

%First split up year month day
for i=1:size(winddata,1)
    datestr=num2str(winddata(i,1));
    winddata(i,5)=str2num(datestr(1:4)); %yr
    winddata(i,6)=str2num(datestr(5:6)); %mo
    winddata(i,7)=str2num(datestr(7:8)); %day
end

%**2004 is a leap year so Feb has 29 days then, 28 days in other years.
%Eliminate leap year data
winddata(winddata(:,6)==2 & winddata(:,7)==29,:)=[];

%Get # days in each month - loop over months & get max associated
maxdayinmonth=zeros(12,2);
for i=1:12
    maxdayinmonth(i,1)=i;
    maxdayinmonth(i,2)=max(winddata(winddata(:,6)==i,7));
end

%Now create table that converts from YEARMONTHDAY HOUR to CST info
%UTC is 6 hours behind CST. Note that PLEXOS takes in datetime as 0:00 to
%23:00; so hour 1 is 0:00-1:00, and hour 24 is 23:00-0:00. 
%Create new table with year, month, day, hour
winddata(:,end+1)=ceil(winddata(:,2)/100); 
%Round up 0's for hour to 24, because final hour in day given is 0, but
%really belongs to hour 24 in prior day. Also need to make that row's day
%month & year the same as prior rows (because 0s belong to past day)
rowswithzerohours=winddata(:,8)==0;
rowswithzerohoursshifted=rowswithzerohours;
rowswithzerohoursshifted(1,:)=[];
winddata(rowswithzerohours,end)=24; %hour
winddata(rowswithzerohours,end-1)=winddata(rowswithzerohoursshifted,end-1); %day
winddata(rowswithzerohours,end-2)=winddata(rowswithzerohoursshifted,end-2); %month
winddata(rowswithzerohours,end-3)=winddata(rowswithzerohoursshifted,end-3); %year
%Unique month-day-hour
winddatetimedata=winddata(:,5:8);
winddatetimedata=unique(winddatetimedata,'rows');
%Now convert to UTC
convertedwinddatetimedata=zeros(size(winddatetimedata,1),size(winddatetimedata,2));
daycol=3; monthcol=2; yearcol=1; hourcol=4; %cols for converted & original array
for i=1:size(winddatetimedata,1)
    %Subtract 6 from hour; hour is in final column of winddatetimedata
    %If hour is 6 or less, need to change day and/or month
    if winddatetimedata(i,end)<6
        %Start by subtracting hour
        convertedwinddatetimedata(i,hourcol)=winddatetimedata(i,hourcol)+24-6;
        %Handle month & day & year
        if winddatetimedata(i,monthcol)==1 && winddatetimedata(i,daycol)==1 %if on Jan 1st when change time
            convertedwinddatetimedata(i,monthcol)=12; %Dec
            convertedwinddatetimedata(i,daycol)=31; %last day in Dec
            convertedwinddatetimedata(i,yearcol)=winddatetimedata(i,yearcol)-1;
        elseif winddatetimedata(i,daycol)==1 %if month changes when turn back time
            %Turn month back by 1
            convertedwinddatetimedata(i,monthcol)=winddatetimedata(i,monthcol)-1;
            %Get day from maxdayinmonth table
            convertedwinddatetimedata(i,daycol)=maxdayinmonth(maxdayinmonth(:,1)==convertedwinddatetimedata(i,monthcol),2);
            convertedwinddatetimedata(i,yearcol)=winddatetimedata(i,yearcol);
        else %if month doesn't change when rewind time
            convertedwinddatetimedata(i,monthcol)=winddatetimedata(i,monthcol);
            convertedwinddatetimedata(i,daycol)=winddatetimedata(i,daycol)-1;
            convertedwinddatetimedata(i,yearcol)=winddatetimedata(i,yearcol);
        end
    %If day doesn't change when change time.
    %PLEXOS takes in time as 0:00-23:00 - so if in hour 6, then will be
    %midnight of prior day, which is really 0:00 of current day, so just
    %set hour column to zero.
    else 
        convertedwinddatetimedata(i,hourcol)=winddatetimedata(i,hourcol)-6;
        convertedwinddatetimedata(i,monthcol)=winddatetimedata(i,monthcol);
        convertedwinddatetimedata(i,daycol)=winddatetimedata(i,daycol);
        convertedwinddatetimedata(i,yearcol)=winddatetimedata(i,yearcol);
    end
end

%Stick arrays together
mapofutctocstwindtime=[winddatetimedata,convertedwinddatetimedata];







