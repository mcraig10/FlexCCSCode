sizeFont= 14
verticalxlabels={};
for i=1:size(graphlabels,1)
    currlabel=graphlabels{i};
    if strfind(currlabel,'Base')
        newlabel={'Base','',''};
    elseif strfind(currlabel,'Rdsptch')
        newlabel={'Re-dispatch','',''};
    else
        if strfind(currlabel,'Wnd')
            newlabel={'Wind'};
            capac=currlabel(4:end);
            if strcmp(capac,'6.5')
                gwlabel='GW';
            else
                gwlabel='GW*';
            end
            capacfull=strcat(capac,gwlabel);
            newlabel=horzcat(newlabel,capacfull,{''});
        elseif strfind(currlabel,'CCS')
            if strfind(currlabel,'NCCS')
                newlabel={'Normal','CCS'};
            elseif strfind(currlabel,'FCCS')
                newlabel={'Flexible','CCS'};
            end
            capac=currlabel(5:end);
            if strcmp(capac,'6.2') && testlowerlimit==0
                gwlabel='GW';
            else
                gwlabel='GW*';
            end
            capacfull=strcat(capac,gwlabel);
            newlabel=horzcat(newlabel,capacfull);
        end
    end
    verticalxlabels=vertcat(verticalxlabels,newlabel);
end
co2cppemissionspercentofmasslimit=(co2cppemissions-co2cppmasslimit)./co2cppmasslimit*100;
%Move base to first row
co2cppemissionspercentofmasslimittoplot=co2cppemissionspercentofmasslimit;
baserow=find(strcmp(verticalxlabels(:,1),'Base'));
savedval=co2cppemissionspercentofmasslimittoplot(baserow);
co2cppemissionspercentofmasslimittoplot(baserow)=[];
co2cppemissionspercentofmasslimittoplot=vertcat(savedval,co2cppemissionspercentofmasslimittoplot); clear savedval;
savedlabel=verticalxlabels(baserow,:);
verticalxlabels(baserow,:)=[];
verticalxlabels=vertcat(savedlabel,verticalxlabels); clear savedlabel;
%Make plot
figure; bar(co2cppemissionspercentofmasslimittoplot,'FaceColor',[.8 .8 .8]); colormap gray;
ax=gca; set(ax, 'XTickLabel',cell(10,1));
set(gca,'fontsize',sizeFont,'fontweight','bold')
if testlowerlimit==0
    ylabel('Percent Difference of CO_{2} Emissions from CPP Mass Limit','fontsize',sizeFont,'fontweight','bold')
else
    ylabel('Percent Difference of CO_{2} Emissions from Stronger CPP Mass Limit','fontsize',sizeFont,'fontweight','bold')
end
% %Add vertical lines b/wn data sets
% ylimsplot=get(gca,'YLim');
% xpointsforlines=[1.5;2.5;5.5;8.5];
% for i=1:size(xpointsforlines,1)
%     currxval=xpointsforlines(i);
%     line([currxval currxval],ylimsplot,'Color','k','LineStyle','--');
% end
%Add labels
if testlowerlimit==1
    offset=-13;
else
    offset=-2.4;
end
for i=1:size(verticalxlabels,1)
    text(i,offset,verticalxlabels(i,:),'Fontsize',sizeFont,'fontweight','bold','horizontalalignment','center');
end
if testlowerlimit==1
    labeloffset=[0 4.7 0];
else
    labeloffset=[0 .6 0];
end
xlabel('Scenario','fontsize',sizeFont,'fontweight','bold');
xlabh=get(gca,'XLabel');
set(xlabh,'Position',get(xlabh,'Position')-labeloffset);






verticalxlabels={};
for i=1:size(graphlabels,1)
    currlabel=graphlabels{i};
    if strfind(currlabel,'Base')
        newlabel={'Base','',''};
    elseif strfind(currlabel,'Rdsptch')
        newlabel={'Re-dispatch','',''};
    else
        if strfind(currlabel,'Wnd')
            newlabel={'Wind'};
            capac=currlabel(4:end);
            capacfull=strcat(capac,'GW');
            newlabel=horzcat(newlabel,capacfull,{''});
        elseif strfind(currlabel,'CCS')
            if strfind(currlabel,'NCCS')
                newlabel={'Normal','CCS'};
            elseif strfind(currlabel,'FCCS')
                newlabel={'Flexible','CCS'};
            end
            capac=currlabel(5:end);
            capacfull=strcat(capac,'GW');
            newlabel=horzcat(newlabel,capacfull);
        end
    end
    verticalxlabels=vertcat(verticalxlabels,newlabel);
end
%Move base to front
opandcapcostsmidscaledtoplot=opandcapcostsmidscaled;
baserow=find(strcmp(verticalxlabels(:,1),'Base'));
savedval=opandcapcostsmidscaledtoplot(baserow,:);
opandcapcostsmidscaledtoplot(baserow,:)=[];
opandcapcostsmidscaledtoplot=vertcat(savedval,opandcapcostsmidscaledtoplot); clear savedval;
savedlabel=verticalxlabels(baserow,:);
verticalxlabels(baserow,:)=[];
verticalxlabels=vertcat(savedlabel,verticalxlabels); clear savedlabel;

%Bar graph of total op + cap costs as difference from baseline for mid
totalopandcapcostsdiffscaled=totalopandcapcostsdiffmid/scalecosts;




%PLOT TOTAL COSTS AS DIFFERENCE FROM BASELINE, MID CAP COST
totalopandcapcostsdiffmidnobase=totalopandcapcostsdiffmid;
totalopandcapcostsdiffmidnobase(basecaserow-1,:)=[];
totalopandcapcostsdiffmidnobasescaled=totalopandcapcostsdiffmidnobase/scalecosts;
barwidthtoplot=.75;
%ALL GRAY BARS
figure; bar(totalopandcapcostsdiffmidnobasescaled,barwidthtoplot,'FaceColor',[.8 .8 .8]); 
colormap gray; hold on
%DIFFERENT COLORED BARS
% figure; legendarray=[];
% for i=1:size(totalopandcapcostsdiffmidnobasescaled,1)
%     h = bar(i, totalopandcapcostsdiffmidnobasescaled(i));
%     if i==1
%         hold on
%     end
%     if i==1
%         col = [0 0 0];
%     elseif mod(i,3)==2
%         col = [.3 .3 .3];
%     elseif mod(i,3)==0
%         col = [.6 .6 .6];
%     elseif mod(i,3)==1
%         col = [.9 .9 .9];
%     end
%     set(h,'FaceColor',col)
%     
%     %Form legend array
%     if i<=4
%         legendarray=[legendarray h];
%     end
% end
% if testlowerlimit==1
%     legend(legendarray, '$39/ton','$36/ton','$31/ton','$27/ton');
% else
%     legend(legendarray, '$9/ton','$7/ton','$3/ton','$0/ton');
% end
%AXIS LABELS
xlabel('Scenario','fontsize',sizeFont,'fontweight','bold'); ax=gca; set(ax, 'XTickLabel',cell(size(graphlabelsnobasecase,1),1));
ylabel(['Difference in Total Cost from Base Scenario ($',scalecostsstr,')'],'fontsize',sizeFont,'fontweight','bold'); 
xlimtoplot=[1-barwidthtoplot+barwidthtoplot/size(opandcapcostsmidwithtotaldiffnobasescaled,1),...
    size(opandcapcostsmidwithtotaldiffnobasescaled,1)+barwidthtoplot+barwidthtoplot/size(opandcapcostsmidwithtotaldiffnobasescaled,1)];
set(gca,'XLim',xlimtoplot);
%Add vertical lines b/wn data sets
% ylimsplot=get(gca,'YLim');
% xpointsforlines=[1.5;4.5;7.5];
% for i=1:size(xpointsforlines,1)
%     currxval=xpointsforlines(i);
%     line([currxval currxval],ylimsplot,'Color','k','LineStyle','--');
% end
%Add labels
if testlowerlimit==0
    offset=-.07;
else
    offset=-.15;
end
for i=1:size(verticalxlabels,1)
    text(i,offset,verticalxlabels(i,:),'Fontsize',sizeFont,'fontweight','bold','horizontalalignment','center');
end
xlabel('Compliance Scenario','fontsize',sizeFont,'fontweight','bold');
xlabh=get(gca,'XLabel');
if testlowerlimit==0
    offset=[0 .1 0];
else
    offset=[0 .22 0];
end
set(xlabh,'Position',get(xlabh,'Position')-offset);






verticalxlabels={};
for i=1:size(graphlabelsnobasecase,1)
    currlabel=graphlabelsnobasecase{i};
    if strfind(currlabel,'Rdsptch')
        newlabel={'Re-dispatch','',''};
    else
        if strfind(currlabel,'Wnd')
            newlabel={'Wind'};
            capac=currlabel(4:end);
            if strcmp(capac,'6.5')
                gwlabel='GW';
            else
                gwlabel='GW*';
            end
            capacfull=strcat(capac,gwlabel);
            newlabel=horzcat(newlabel,capacfull,{''});
        elseif strfind(currlabel,'CCS')
            if strfind(currlabel,'NCCS')
                newlabel={'Normal','CCS'};
            elseif strfind(currlabel,'FCCS')
                newlabel={'Flexible','CCS'};
            end
            capac=currlabel(5:end);
            if strcmp(capac,'6.2') && testlowerlimit==0
                gwlabel='GW';
            else
                gwlabel='GW*';
            end
            capacfull=strcat(capac,gwlabel);
            newlabel=horzcat(newlabel,capacfull);
        end
    end
    verticalxlabels=vertcat(verticalxlabels,newlabel);
end
%Error bars for graphs
errorbarlow=opandcapcostperco2emsreduxscaledmid-opandcapcostperco2emsreduxscaledlow;
errorbarhigh=opandcapcostperco2emsreduxscaledhigh-opandcapcostperco2emsreduxscaledmid;

%SCATTER PLOT OF COST-EFF VS. EMISSIONS. 
%Each point is @ best guess value for cost-effectiveness, and has error
%bars for high/low at each point.
%Get emissions reduction
basecaseemissions=co2cppemissionsscaled(basecaserow-1);
co2cppemissionsreduction=abs(co2cppemissionsscaled-basecaseemissions);
co2cppemissionsreductionnobase=co2cppemissionsreduction;
co2cppemissionsreductionnobase(basecaserow-1)=[];
figure; hold on; scatter(co2cppemissionsreductionnobase,opandcapcostperco2emsreduxscaledmid,10,'filled','k')
errorbar(co2cppemissionsreductionnobase,opandcapcostperco2emsreduxscaledmid,errorbarlow,errorbarhigh,'k.','LineWidth',1)
xlabel('CO_{2} Emissions Reductions (million tons)','fontsize',sizeFont,'fontweight','bold')
ylabel(['Cost per Ton of CO_{2} Emissions Reductions ($/ton)'],'fontsize',sizeFont,'fontweight','bold')
set(gca,'fontsize',sizeFont,'fontweight','bold'); 
if testlowerlimit==1
    set(gca,'YLim',[0 25])
end
%Now add text labels
xbuffer=.2;
for i=1:size(co2cppemissionsreductionnobase,1)
    xtemp=co2cppemissionsreductionnobase(i);
    ytemp=opandcapcostperco2emsreduxscaledmid(i);
    labeltemp='';
    for j=1:size(verticalxlabels,2)
        labeltemp=strcat(labeltemp,verticalxlabels(i,j),{' '});
    end
    text(xtemp+xbuffer,ytemp,labeltemp,'fontsize',sizeFont,'fontweight','bold');
end


