function fig=visualizar_mpc(estudo,visibilidade)
if nargin<2, visibilidade='on'; end
fig=figure('Name','MPC e PD','Visible',visibilidade,'Color','w','Position',[80 60 1180 780]);
tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
tab=estudo.resumo;
for i=1:2
    ax=nexttile; fator=estudo.hipoteses.fatores_massas(min(i,end));
    alts=estudo.hipoteses.alternativas_reducao; vals=NaN(numel(alts),2);
    for a=1:numel(alts)
        for j=1:2
            nomes=["PD" "MPC"]; linha=tab(tab.fator_massas==fator & ...
                tab.alternativa_reducao==alts(a) & tab.metodo==nomes(j),:);
            if ~isempty(linha) && linha.completo, vals(a,j)=linha.erro_movimento_max_mm; end
        end
    end
    bar(ax,alts,vals); grid(ax,'on'); xlabel(ax,'Alternativa de reducao'); ylabel(ax,'Erro maximo no movimento (mm)');
    yline(ax,5,'k--','Tolerancia'); legend(ax,{'PD digital','MPC LTV'},'Location','best');
    title(ax,sprintf('Massas x %.2f | casos interrompidos omitidos',fator));
end
% Ultimo par PD/MPC: mesma reducao, massas e taxa de atualizacao.
ax=nexttile; hold(ax,'on'); grid(ax,'on'); nomes=["PD digital","MPC LTV"]; colors=lines(2);
for j=1:2
    r=estudo.casos{end-2+j}; d=r.historico;
    plot(ax,d(:,1),1000*d(:,44),'Color',colors(j,:),'DisplayName',nomes(j),'LineWidth',1.4);
end
xlabel(ax,'Tempo (s)'); ylabel(ax,'Erro de posicao (mm)'); legend(ax,'Location','best');
title(ax,'Ultimo cenario: erro ao longo do ciclo'); yline(ax,5,'k--','HandleVisibility','off');
ax=nexttile; hold(ax,'on'); grid(ax,'on'); r=estudo.casos{end}; d=r.historico;
plot(ax,d(:,1),d(:,26:29),'LineWidth',1.2); xlabel(ax,'Tempo (s)'); ylabel(ax,'Torque no motor (N.m)');
lim=estudo.motores.torque_continuo_Nm;
if all(abs(lim-lim(1))<eps), yline(ax,lim(1),'k:'); yline(ax,-lim(1),'k:'); end
title(ax,'MPC: torques escolhidos dentro dos limites'); legend(ax,{'J1','J2','J3','J4'},'Location','best');
sgtitle(fig,sprintf('MPC LTV | horizonte %d passos | periodo %.0f ms | planta nao linear', ...
    estudo.hipoteses.horizonte_passos,1000*estudo.hipoteses.periodo_controle_s));
end
