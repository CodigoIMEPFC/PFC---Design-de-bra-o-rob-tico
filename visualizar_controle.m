function fig=visualizar_controle(controle,caso,visibilidade)
% VISUALIZAR_CONTROLE Compara referencia e resposta integrada do braco.
if nargin<2, caso=controle.caso_referencia; end
if nargin<3, visibilidade='on'; end
r=controle.casos{caso};
fig=figure('Name','Controle do transporte','Visible',visibilidade,'Color','w','Position',[50 50 1250 800]);
tiledlayout(fig,2,2,'Padding','compact','TileSpacing','compact');
ax=gobjects(4,1); for i=1:4, ax(i)=nexttile; hold(ax(i),'on'); grid(ax(i),'on'); end
colors=lines(4);
for k=1:numel(r.fases)
    f=r.fases{k}; vis='off'; if k==1, vis='on'; end
    plot(ax(1),f.t_s,1000*f.erro_posicao_m,'b','LineWidth',1.5);
    for j=1:4
        plot(ax(2),f.t_s,rad2deg(f.Q(j,:)-f.Q_ref(j,:)),'Color',colors(j,:), ...
            'LineWidth',1.4,'DisplayName',sprintf('Junta %d',j),'HandleVisibility',vis);
    end
    plot(ax(3),f.t_s,f.torque_pedido_Nm(1,:),'r--','LineWidth',1.4,'DisplayName','Pedido','HandleVisibility',vis);
    plot(ax(3),f.t_s,f.torque_aplicado_Nm(1,:),'b','LineWidth',1.4,'DisplayName','Aplicado','HandleVisibility',vis);
    plot3(ax(4),f.xyz_ref_m(1,:),f.xyz_ref_m(2,:),f.xyz_ref_m(3,:),'k--', ...
        'LineWidth',2,'DisplayName','Planejado','HandleVisibility',vis);
    plot3(ax(4),f.xyz_m(1,:),f.xyz_m(2,:),f.xyz_m(3,:),'b','LineWidth',1.2, ...
        'DisplayName','Realizado na simulacao','HandleVisibility',vis);
end
title(ax(1),'Distancia entre posicao desejada e realizada'); ylabel(ax(1),'Erro (mm)');
yline(ax(1),controle.hipoteses.tolerancia_posicao_m*1000,'k--','Tolerancia apos pausa inicial');
xline(ax(1),controle.hipoteses_transporte.pausa_s,':','Fim da acomodacao');
title(ax(2),'Diferencas nos angulos das quatro juntas'); ylabel(ax(2),'Realizado - desejado (graus)'); legend(ax(2),'Location','best');
title(ax(3),'Motor da junta 1: comando e saturacao'); ylabel(ax(3),'Torque no motor (N.m)');
lim=controle.motores_por_junta.torque_continuo_Nm(1); yline(ax(3),lim,'k:','HandleVisibility','off');
yline(ax(3),-lim,'k:','HandleVisibility','off'); legend(ax(3),'Location','best');
title(ax(4),'Trajetoria do ponto da ferramenta'); xlabel(ax(4),'x (m)'); ylabel(ax(4),'y (m)'); zlabel(ax(4),'z (m)');
view(ax(4),35,25); axis(ax(4),'equal'); legend(ax(4),'Location','best');
for i=1:3, xlabel(ax(i),'Tempo (s)'); end
sgtitle(fig,sprintf('Controle PD com compensacao dinamica | N=%s | fator de massas %.2f',mat2str(r.N),r.fator_massas));
end
