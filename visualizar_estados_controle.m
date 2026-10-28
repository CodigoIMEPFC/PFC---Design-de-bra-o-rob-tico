function fig=visualizar_estados_controle(controle,junta,caso,visibilidade)
% VISUALIZAR_ESTADOS_CONTROLE Angulo, velocidade e aceleracao: referencia x real.
if nargin<2, junta=1; end
if nargin<3, caso=controle.caso_referencia; end
if nargin<4, visibilidade='on'; end
validateattributes(junta,{'numeric'},{'scalar','integer','>=',1,'<=',4});
r=controle.casos{caso};
fig=figure('Name','Estados da junta','Visible',visibilidade,'Color','w','Position',[70 70 1050 900]);
tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
refCampos={'Q_ref','dq_ref','ddq_ref'}; realCampos={'Q','dq','ddq'};
titulos={'Angulo','Velocidade angular','Aceleracao angular'};
unidades={'graus','graus/s','graus/s^2'};
for a=1:3
    ax=nexttile; hold(ax,'on'); grid(ax,'on');
    for k=1:numel(r.fases)
        f=r.fases{k}; vis='off'; if k==1, vis='on'; end
        ref=f.(refCampos{a}); atual=f.(realCampos{a});
        plot(ax,f.t_s,rad2deg(ref(junta,:)),'k--','LineWidth',1.8,'DisplayName','Desejado','HandleVisibility',vis);
        plot(ax,f.t_s,rad2deg(atual(junta,:)),'b','LineWidth',1.2,'DisplayName','Realizado na simulacao','HandleVisibility',vis);
    end
    title(ax,titulos{a}); xlabel(ax,'Tempo (s)'); ylabel(ax,unidades{a}); legend(ax,'Location','best');
end
sgtitle(fig,sprintf('Junta %d | Caso %d | N=%s | fator de massas %.2f',junta,caso,mat2str(r.N),r.fator_massas));
end
