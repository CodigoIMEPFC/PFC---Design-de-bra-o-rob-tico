function fig=visualizar_ciclo_transporte(transporte,caso,visibilidade)
% VISUALIZAR_CICLO_TRANSPORTE Historicos de um caso, sem interpolar troca de carga.
if nargin<2, caso=transporte.caso_referencia; end
if nargin<3, visibilidade='on'; end
r=transporte.casos{caso}; ht=transporte.hipoteses;
fig=figure('Name','Historicos do transporte','Visible',visibilidade, ...
    'Color','w','Position',[60 60 1280 820]);
tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
ax=gobjects(1,4);
for a=1:4, ax(a)=nexttile; hold(ax(a),'on'); grid(ax(a),'on'); xlabel(ax(a),'Tempo do ciclo (s)'); end
colors=lines(4);
for fase=1:numel(r.fases)
    f=r.fases{fase};
    for j=1:4
        for a=1:3
            if a==1
                y=ht.margem_torque*f.motor.envelope_motor_Nm(j,:)/transporte.motores_por_junta.torque_continuo_Nm(j)*100;
            elseif a==2, y=f.motor.rpm_motor(j,:);
            else, y=rad2deg(f.Q(j,:));
            end
            line=plot(ax(a),f.t_s,y,'Color',colors(j,:),'LineWidth',1.5,'DisplayName',sprintf('Junta %d',j));
            if fase>1, line.HandleVisibility='off'; end
        end
    end
    nomes={'x','y','z'};
    for j=1:3
        line=plot(ax(4),f.t_s,f.xyz_m(:,j),'Color',colors(j,:),'LineWidth',1.5,'DisplayName',nomes{j});
        if fase>1, line.HandleVisibility='off'; end
    end
end
yline(ax(1),100,'k--','Limite com margem','LabelHorizontalAlignment','left','HandleVisibility','off');
title(ax(1),'Torque: criterio aplicado ao envelope'); ylabel(ax(1),'Utilizacao com margem (%)');
title(ax(2),'Rotacao exigida: limite de velocidade nao verificado'); ylabel(ax(2),'Motor (rpm)');
title(ax(3),'Movimento das quatro juntas'); ylabel(ax(3),'Angulo (graus)');
title(ax(4),'Centro do objeto na ida; ponto virtual da ferramenta no retorno'); ylabel(ax(4),'Posicao (m)');
for a=1:4
    xlim(ax(a),[0 r.tempo_ciclo_s]); legend(ax(a),'Location','best');
    xline(ax(a),ht.pausa_s+r.tempo_ida_s,':','Liberar 5 kg','HandleVisibility','off');
end
L=ht.geometrias_m(r.geometria,:);
sgtitle(fig,sprintf('Caso %d | L1/L2 = %.2f/%.2f m | N=%s | ida %.1f s, ciclo %.1f s', ...
    caso,L(1),L(2),mat2str(r.N),r.tempo_ida_s,r.tempo_ciclo_s));
end
