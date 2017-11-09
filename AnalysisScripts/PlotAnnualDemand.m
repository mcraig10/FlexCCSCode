[~,~,demanddata]=xlsread('C:\Users\mtcraig\Desktop\EPP Research\CPPPLEXOSDemand1EEScalarPt5NLDC0.csv','CPPPLEXOSDemand1EEScalarPt5NLDC');

demand=[];
for i=2:size(demanddata,1)
    tempdemand=cell2mat(demanddata(i,4:end));
    demand=[demand;tempdemand'];
end
clear tempdemand

figure; hold on
gap=25;
ctr=0;
for i=1:gap:326
    ctr=ctr+1;
    firsthour=(i-1)*24+1;
    lasthour=(i+gap)*24;
    tempdemand=demand(firsthour:lasthour);    
    
    subplot(5,3,ctr);
    plot(tempdemand)
end

diffindemand=demand;
for i=2:size(demand,1)
    diffindemand(i)=demand(i)-demand(i-1);
end