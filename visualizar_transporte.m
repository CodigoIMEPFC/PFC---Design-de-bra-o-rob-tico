function fig=visualizar_transporte(transporte,visibilidade)
% VISUALIZAR_TRANSPORTE Tarefa comum e envelope de torque por tempo/reducao.
if nargin<2, visibilidade='on'; end
ht=transporte.hipoteses; central=transporte.config.construcao.indice_cenario_redutores_base;
fig=figure('Name','Transporte de esfera de 5 kg','Color','w', ...
    'Visible',visibilidade,'Position',[60 60 1280 820]);
tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
ax=nexttile; hold(ax,'on'); colors=lines(size(ht.geometrias_m,1));
for i=1:numel(transporte.trajetorias)
    tr=transporte.trajetorias{i}; xyz=vertcat(tr.fases{1}.xyz_m,tr.fases{2}.xyz_m,tr.fases{3}.xyz_m);
    plot3(ax,xyz(:,1),xyz(:,2),xyz(:,3),'-','Color',colors(i,:),'LineWidth',2);
end
pts=transporte.trajetorias{1}.pontos_m;
scatter3(ax,pts(:,1),pts(:,2),pts(:,3),65,'k','filled');
text(ax,pts(:,1),pts(:,2),pts(:,3)+.018,{'Coleta','Elevado','Sobre deposito','Deposito'});
grid(ax,'on'); axis(ax,'equal'); view(ax,35,25);
xlabel(ax,'x (m)'); ylabel(ax,'y (m)'); zlabel(ax,'Centro da esfera: z (m)');
title(ax,{'Mesma rota cartesiana para os tres bracos','Ida com 5 kg; retorno vazio'});
tab=transporte.resumo;
for alt=1:3
    ax=nexttile; hold(ax,'on');
    for a=1:numel(transporte.trajetorias)
        t=tab(tab.geometria==a & tab.cenario_massa==central & tab.alternativa_reducao==alt,:);
        plot(ax,t.tempo_ida_s,100*t.utilizacao_maxima_com_margem,'-o','LineWidth',1.8, ...
            'Color',colors(a,:),'DisplayName',sprintf('L1=%.2f; L2=%.2f m',ht.geometrias_m(a,:)));
    end
    yline(ax,100,'k--','Limite com margem','LabelHorizontalAlignment','left','HandleVisibility','off');
    vals=100*tab.utilizacao_maxima_com_margem(tab.cenario_massa==central & tab.alternativa_reducao==alt);
    ylim(ax,[min(95,5*floor(min(vals)/5)-5) max(110,5*ceil(max(vals)/5)+5)]);
    xlabel(ax,'Tempo da ida carregada (s)'); ylabel(ax,'Maior utilizacao com margem (%)');
    title(ax,sprintf('Reducao %s',mat2str(transporte.config.reducoes(alt,:))));
    grid(ax,'on'); xticks(ax,ht.tempos_ida_s); legend(ax,'Location','best');
end
sgtitle(fig,sprintf('Teste de transporte | redutor %.1f kg/junta | rendimento 0,75 | margem %.1f', ...
    transporte.config.construcao.massas_redutores_kg(central,1),ht.margem_torque));
end
