function fig=visualizar_estatica(resultado,cenario,visivel)
% VISUALIZAR_ESTATICA Esforco com margem e capacidade das tres reducoes.
if nargin<2, cenario=resultado.geometria.hipoteses.indice_cenario_redutores_base; end
if nargin<3, visivel='on'; end
validateattributes(cenario,{'numeric'},{'scalar','integer','positive','<=',numel(resultado.estatica)});
nr=size(resultado.config.reducoes,1);
dados=zeros(4,nr+1);
dados(:,1)=resultado.geometria.hipoteses.margem_torque_estatico*abs(resultado.estatica{cenario}.torque_juntas_Nm);
for a=1:nr
    d=resultado.detalhes(resultado.detalhes.cenario_massa==cenario & resultado.detalhes.alternativa_reducao==a,:);
    dados(:,a+1)=d.capacidade_junta_Nm;
end
fig=figure('Name','Torques estaticos - postura avaliada','NumberTitle','off', ...
    'Color','white','Visible',visivel,'Position',[100 100 1000 570]);
ax=axes(fig); barras=bar(ax,1:4,dados,'grouped');
barras(1).FaceColor=[0.78 0.28 0.20];
cores=[0.20 0.45 0.62;0.18 0.63 0.56;0.47 0.38 0.68];
for a=1:nr, barras(a+1).FaceColor=cores(mod(a-1,3)+1,:); end
xticks(ax,1:4); xticklabels(ax,{'J1 (UR5 J2)','J2 (UR5 J3)','J3 (UR5 J4)','J4 (UR5 J5)'});
ylabel(ax,'Torque na junta (N.m)'); grid(ax,'on'); ax.FontSize=11;
legendas=["Exigido com margem";"Capacidade - alternativa "+string((1:nr).')];
legend(ax,legendas,'Location','northoutside','NumColumns',2);
title(ax,{sprintf('Sustentacao estatica de %.1f kg | cenario de massa %d',resultado.config.carga_util_kg,cenario); ...
    sprintf('Uma postura | margem %.2f | colisoes desconsideradas',resultado.geometria.hipoteses.margem_torque_estatico)});
end
