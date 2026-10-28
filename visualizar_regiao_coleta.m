function fig=visualizar_regiao_coleta(busca,visivel)
% VISUALIZAR_REGIAO_COLETA Melhor candidato do cenario central na malha.
if nargin<2, visivel='on'; end
t=busca.melhor_cenario_central; mapa=busca.mapas{t.geometria}; caso=mapa.casos{t.caso};
fig=figure('Color','white','Visible',visivel,'Position',[100 100 1120 850], ...
    'Name','Regiao de coleta estimada','NumberTitle','off');
layout=tiledlayout(fig,3,2,'Padding','loose','TileSpacing','loose');
ax=nexttile(layout,1,[1 2]); imagem=double(reshape(mapa.geometrico,numel(busca.x),numel(busca.y))).';
aceitas=false(size(mapa.geometrico)); aceitas(caso.celulas_aceitas)=true;
imagem(reshape(aceitas,numel(busca.x),numel(busca.y)).')=2;
imagesc(ax,busca.x,busca.y,imagem); axis(ax,'xy'); axis(ax,'equal'); axis(ax,'tight');
colormap(ax,[1 1 1;0.82 0.84 0.87;0.08 0.56 0.51]); clim(ax,[0 2]);
cb=colorbar(ax); cb.Ticks=[0 1 2]; cb.TickLabels={'Sem solucao encontrada','Alcance geometrico','Atende torque'};
xlabel(ax,'x do centro da esfera (m)'); ylabel(ax,'y do centro da esfera (m)');
title(ax,{sprintf('Regiao de coleta estimada: %.4f m2',t.area_estimada_m2); ...
    sprintf('L1 = %.2f m | L2 = %.2f m | alternativa %d',t.L1_m,t.L2_m,t.alternativa_reducao)});
ax2=nexttile(layout,3,[2 1]); s=busca.config.construcao.indice_cenario_redutores_base;
linhas=busca.ranking(busca.ranking.cenario_massa==s,:);
ng=numel(busca.mapas); areas=zeros(ng,1); l=zeros(ng,2);
for i=1:ng
    selecao=linhas(linhas.geometria==i,:); areas(i)=max(selecao.area_estimada_m2); l(i,:)=selecao{1,{'L1_m','L2_m'}};
end
scatter(ax2,l(:,1),l(:,2),130,areas,'filled','MarkerEdgeColor',[0.3 0.3 0.3]);
colormap(ax2,parula); colorbar(ax2); xlabel(ax2,'L1 (m)'); ylabel(ax2,'L2 (m)');
title(ax2,{'Maior area por geometria (m2)';'Melhor atribuicao e reducao no cenario central'}); grid(ax2,'on');
xlim(ax2,[min(l(:,1))-0.025 max(l(:,1))+0.025]);
ylim(ax2,[min(l(:,2))-0.025 max(l(:,2))+0.025]);
ax3=nexttile(layout,4,[2 1]); top=linhas(1:min(5,height(linhas)),:);
b=barh(ax3,top.area_estimada_m2); b.FaceColor=[0.08 0.56 0.51];
set(ax3,'YDir','reverse'); yticks(ax3,1:height(top));
rotulos=compose('%.0f / %.0f cm | R%d',100*top.L1_m,100*top.L2_m,top.alternativa_reducao);
yticklabels(ax3,rotulos); xlabel(ax3,'Area estimada (m2)'); grid(ax3,'on');
xlim(ax3,[0 1.12*max(top.area_estimada_m2)]);
title(ax3,{'Cinco maiores areas admissiveis';'L1 / L2 | alternativa de reducao'});
drawnow;
end
