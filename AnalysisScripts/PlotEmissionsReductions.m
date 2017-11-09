
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
figure; bar(co2cppemissionspercentofmasslimittoplot); colormap gray;
ax=gca; set(ax, 'XTickLabel',cell(10,1));
set(gca,'fontsize',16,'fontweight','bold')
ylabel('Percent Difference of CO_{2} Emissions from CPP Mass Limit','fontsize',16,'fontweight','bold')
for i=1:size(verticalxlabels,1)
    text(i,-2.4,verticalxlabels(i,:),'Fontsize',16,'fontweight','bold','horizontalalignment','center');
end
xlabel('Scenario','fontsize',16,'fontweight','bold');
for i=1:size(verticalxlabels,1)
    text(i,-14,verticalxlabels(i,:),'Fontsize',16,'fontweight','bold','horizontalalignment','center');
end
xlabh=get(gca,'XLabel');
set(xlabh,'Position',get(xlabh,'Position')-[0 0.6 0]);