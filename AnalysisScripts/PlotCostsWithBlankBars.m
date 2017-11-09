opandcapcostsmidwithtotaldiffnobasescaledcol0=opandcapcostsmidwithtotaldiffnobasescaled;
opandcapcostsmidwithtotaldiffnobasescaledcol0(:,1:end)=0;
opandcapcostsmidwithtotaldiffnobasescaledcol1=opandcapcostsmidwithtotaldiffnobasescaled;
opandcapcostsmidwithtotaldiffnobasescaledcol1(:,2:end)=0;
opandcapcostsmidwithtotaldiffnobasescaledcol12=opandcapcostsmidwithtotaldiffnobasescaled;
opandcapcostsmidwithtotaldiffnobasescaledcol12(:,3:end)=0;
opandcapcostsmidwithtotaldiffnobasescaledcol123=opandcapcostsmidwithtotaldiffnobasescaled;
opandcapcostsmidwithtotaldiffnobasescaledcol123(:,4:end)=0;
opandcapcostsmidwithtotaldiffnobasescaledcol1234=opandcapcostsmidwithtotaldiffnobasescaled;
opandcapcostsmidwithtotaldiffnobasescaledcol1234(:,5)=0;

%Plot original order, dashed separating lines, vertical labels
currfontsize=16;
barwidthtoplot=1;
figure; bar(opandcapcostsmidwithtotaldiffnobasescaledcol0,barwidthtoplot); colormap gray; hold on
ylim([-1 1.5])
xlabel('Scenario','fontsize',currfontsize,'fontweight','bold'); ax=gca; set(ax, 'XTickLabel',cell(size(graphlabelsnobasecase,1),1));
ylabel(['Difference in Cost from Base Scenario ($',scalecostsstr,')'],'fontsize',currfontsize,'fontweight','bold'); 
legend(opandcapcostslegend,'fontsize',currfontsize); set(gca,'fontsize',currfontsize,'fontweight','bold')
xlimtoplot=[1-barwidthtoplot+barwidthtoplot/size(opandcapcostsmidwithtotaldiffnobasescaled,1),...
    size(opandcapcostsmidwithtotaldiffnobasescaled,1)+barwidthtoplot+barwidthtoplot/size(opandcapcostsmidwithtotaldiffnobasescaled,1)];
set(gca,'XLim',xlimtoplot);
%Add vertical lines b/wn data sets
ylimsplot=get(gca,'YLim');
xpointsforlines=[1.5;4.5;7.5];
for i=1:size(xpointsforlines,1)
    currxval=xpointsforlines(i);
    line([currxval currxval],ylimsplot,'Color','k','LineStyle','--');
end
%Add vertical labels
verticalxlabels={};
for i=1:size(graphlabelsnobasecase,1)
    currlabel=graphlabelsnobasecase{i};
    if strfind(currlabel,'Rdsptch')
        newlabel={'Re-dispatch','',''};
    else
        if strfind(currlabel,'Wnd')
            newlabel={'Wind'};
            capac=currlabel(4:end);
            capacfull=strcat(capac,'GW');
            if strcmp(capac,'6.5')==0
                capacfull=strcat(capacfull,'*');
            end
            newlabel=horzcat(newlabel,capacfull,{''});
        elseif strfind(currlabel,'CCS')
            if strfind(currlabel,'NCCS')
                newlabel={'Normal','CCS'};
            elseif strfind(currlabel,'FCCS')
                newlabel={'Flexible','CCS'};
            end
            capac=currlabel(5:end);            
            capacfull=strcat(capac,'GW');
            if strcmp(capac,'5.8')==0
                capacfull=strcat(capacfull,'*');
            end
            newlabel=horzcat(newlabel,capacfull);
        end
    end
    verticalxlabels=vertcat(verticalxlabels,newlabel);
end
for i=1:size(verticalxlabels,1)
    text(i,-1.12,verticalxlabels(i,:),'Fontsize',currfontsize,'fontweight','bold','horizontalalignment','center');
end
xlabel('Compliance Scenario','fontsize',currfontsize,'fontweight','bold');
xlabh=get(gca,'XLabel');
set(xlabh,'Position',get(xlabh,'Position')-[0 .18 0]);



hold on
bar(opandcapcostsmidwithtotaldiffnobasescaledcol1,barwidthtoplot)
bar(opandcapcostsmidwithtotaldiffnobasescaledcol12,barwidthtoplot)
bar(opandcapcostsmidwithtotaldiffnobasescaledcol123,barwidthtoplot)
bar(opandcapcostsmidwithtotaldiffnobasescaledcol1234,barwidthtoplot)
bar(opandcapcostsmidwithtotaldiffnobasescaled,barwidthtoplot)
