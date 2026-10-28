function fig=visualizar_projeto(p,visivel)
% VISUALIZAR_PROJETO Resultado integrado; distingue triagem e qualificacao.
if nargin<2, visivel='on'; end
t=p.candidatos; pre=t.atende_area & t.trajetoria_encontrada & t.atende_estatica & t.atende_dinamica;
fig=figure('Name','Projeto de braco a partir de motores','Color','w','Visible',visivel,'Position',[60 60 1250 820]);
tl=tiledlayout(fig,2,2,'Padding','compact','TileSpacing','compact');
ax=nexttile(tl); counts=[sum(~pre) sum(pre & ~t.mpc_executado) sum(pre & t.mpc_executado & ~t.qualificado) sum(t.qualificado)];
barh(ax,counts,'FaceColor',[.20 .45 .60]);
yticks(ax,1:4); yticklabels(ax,{'Falha na triagem','Controle pendente','Controle sem qualificacao','Qualificado na simulacao'});
xlabel(ax,'Numero de variantes'); title(ax,sprintf('%d variantes / %d geometrias',height(t),numel(p.busca.mapas)));
grid(ax,'on'); xlim(ax,[0 max(1,max(counts)*1.18)]);
for j=1:4, text(ax,counts(j)+max(1,max(counts)*.02),j,string(counts(j))); end
ax=nexttile(tl);
sel=t(t.selecionado_controle,:);
if ~isempty(sel)
    bar(ax,[sel.erro_pd_pior_mm sel.erro_mpc_pior_mm]);
    xticks(ax,1:height(sel)); xticklabels(ax,compose('ID %d',sel.id_candidato));
    yline(ax,p.entrada.tolerancia_posicao_mm,'--','Tolerancia','LabelHorizontalAlignment','left');
    legend(ax,{'PD','MPC'},'Location','best'); ylabel(ax,'Maior erro cartesiano (mm)');
    title(ax,'Pior cenario de massas por candidato'); grid(ax,'on');
else
    axis(ax,'off'); text(ax,.05,.5,'Nenhum controle executado.','Units','normalized');
end
ax=nexttile(tl); hold(ax,'on');
if ~isempty(p.controles)
    c=p.controles{1}; g=c.hipoteses.geometria;
    cin=braco.cinematica_4r(c.ciclo.fases{1}.Q(:,1),g);
    xyz=[cin.origens cin.flange cin.centro_esfera];
    plot3(ax,xyz(1,:),xyz(2,:),xyz(3,:),'-o','LineWidth',3,'Color',[.2 .45 .6],'DisplayName','Braco na coleta');
    for j=2:4
        f=c.ciclo.fases{j}; plot3(ax,f.xyz_m(:,1),f.xyz_m(:,2),f.xyz_m(:,3),'--','LineWidth',2,'Color',[.9 .4 .1],'HandleVisibility','off');
    end
    scatter3(ax,c.ciclo.fases{1}.xyz_m(1,1),c.ciclo.fases{1}.xyz_m(1,2),c.ciclo.fases{1}.xyz_m(1,3),70,'filled','DisplayName','Centro da esfera');
    xlabel(ax,'x (m)'); ylabel(ax,'y (m)'); zlabel(ax,'z (m)'); axis(ax,'equal'); grid(ax,'on'); view(ax,35,25);
    title(ax,sprintf('Candidato %d: postura inicial e caminho desejado',c.id_candidato)); legend(ax,'Location','best');
else
    axis(ax,'off'); text(ax,.05,.5,'Sem candidato selecionado para o ciclo.','Units','normalized');
end
ax=nexttile(tl); axis(ax,'off');
linhas=["ESFERA DE 5 kg | BASE FIXA | 4 JUNTAS"; ...
    "Rendimento 0,75 e tres alternativas completas de reducao"; ...
    "Qualificacao: triagem e acompanhamento MPC"; ...
    "Area de coleta: sustentacao estatica amostrada"; ...
    "Transporte: somente o ciclo especificado"; ...
    "Sem colisoes e sem curva torque-velocidade"; ...
    "Resultados validos sob as hipoteses documentadas"];
text(ax,0,.96,strjoin(linhas,[newline newline]),'Units','normalized','VerticalAlignment','top','FontSize',11,'Interpreter','none');
title(tl,'Motores disponiveis → geometrias candidatas → tarefa simulada','FontSize',17);
end
