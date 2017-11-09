
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
barwidthforplot=0.7;
figure; barcosts=bar(opandcapcostperco2emsreduxscaledmid,barwidthforplot,'FaceColor',[.7 .7 .7]); hold on;
ax=gca; set(ax, 'XTickLabel',cell(10,1));
ylabel(['Cost per Ton of CO_{2} Emissions Reductions ($/ton)'],'fontsize',16,'fontweight','bold')
set(gca,'fontsize',16,'fontweight','bold')
%Add errorbars - need to get lower and upper bounds of error bars
%Lower bound on error bar: mid-low. Upper bound: high-mid.
errorbarlow=opandcapcostperco2emsreduxscaledmid-opandcapcostperco2emsreduxscaledlow;
errorbarhigh=opandcapcostperco2emsreduxscaledhigh-opandcapcostperco2emsreduxscaledmid;
%Add error bars: X, Y, L, U
errorbar(xvalsforscatter,opandcapcostperco2emsreduxscaledmid,errorbarlow,errorbarhigh,'k.','LineWidth',1)
xlimsplot=[1-barwidthforplot+barwidthforplot/10,...
    (size(opandcapcostperco2emsreduxscaledmid,1)+barwidthforplot+barwidthforplot/10)];
set(gca,'XLim',xlimsplot)
for i=1:size(verticalxlabels,1)
    text(i,-16,verticalxlabels(i,:),'Fontsize',16,'fontweight','bold','horizontalalignment','center');
end
xlabel('Compliance Scenario','fontsize',16,'fontweight','bold');
xlabh=get(gca,'XLabel');
set(xlabh,'Position',get(xlabh,'Position')-[0 6 0]);

%Add horizontal line for SCC
hold on;
line(xlimsplot,[50 50], 'color','k','linestyle','--')
