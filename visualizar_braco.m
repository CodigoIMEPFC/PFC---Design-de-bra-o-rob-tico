function fig=visualizar_braco(L1,L2,visivel)
% VISUALIZAR_BRACO Janela interativa com quatro juntas e dois comprimentos.
% Uso: visualizar_braco ou visualizar_braco(0.30,0.40).
% Para exportacao automatica sem janela: visualizar_braco(0.30,0.30,'off').
if nargin<1, L1=0.30; end
if nargin<2, L2=0.30; end
if nargin<3, visivel='on'; end
h=hipoteses_construcao();
g=braco.modelo_geometrico_4r(L1,L2,h);
limL=[min(h.comprimentos_segmento_1_m) max(h.comprimentos_segmento_1_m); ...
    min(h.comprimentos_segmento_2_m) max(h.comprimentos_segmento_2_m)];
assert(L1>=limL(1,1) && L1<=limL(1,2) && L2>=limL(2,1) && L2<=limL(2,2), ...
    'braco:ComprimentoForaDaFaixa','Na janela, use comprimentos entre 0,15 e 0,50 m.');
fig=figure('Name','Braco 4R - geometria parametrica','NumberTitle','off', ...
    'Color','white','Position',[100 80 1250 790],'Visible',visivel);
ax=axes('Parent',fig,'Position',[0.06 0.27 0.67 0.66]);
view(ax,38,24);
uicontrol(fig,'Style','text','Units','normalized','Position',[0.76 0.65 0.22 0.28], ...
    'String',{'MODELO GEOMETRICO';'Base fixa; quatro juntas';'Referencia: UR5 J2-J5';''; ...
    'Azul/verde: segmentos';'Laranja: juntas e esfera';'Roxo: ferramenta simplificada';''; ...
    'Esfera de 5 kg; raio de 10 cm';'Carga e colisoes ainda nao avaliadas'}, ...
    'BackgroundColor','white','HorizontalAlignment','left','FontSize',11);
info=uicontrol(fig,'Style','text','Units','normalized','Position',[0.76 0.23 0.22 0.35], ...
    'BackgroundColor','white','HorizontalAlignment','left','FontSize',11);
sliders=gobjects(6,1); etiquetas=gobjects(6,1);
valores=[rad2deg(g.q_inicial);L1;L2]; limites=[h.limites_juntas_graus;limL];
for i=1:6
    coluna=mod(i-1,3); linha=floor((i-1)/3);
    x=0.06+coluna*0.31; y=0.17-linha*0.085;
    etiquetas(i)=uicontrol(fig,'Style','text','Units','normalized', ...
        'Position',[x y+0.026 0.27 0.032],'BackgroundColor','white','HorizontalAlignment','left','FontSize',10);
    sliders(i)=uicontrol(fig,'Style','slider','Units','normalized','Position',[x y 0.27 0.025], ...
        'Min',limites(i,1),'Max',limites(i,2),'Value',valores(i), ...
        'Tag',sprintf('parametro_%d',i),'Callback',@atualizar);
end
atualizar();

    function atualizar(~,~)
        v=arrayfun(@(s)s.Value,sliders);
        gAtual=braco.modelo_geometrico_4r(v(5),v(6),h);
        q=deg2rad(v(1:4));
        r=braco.desenhar_geometria(ax,gAtual,q);
        for j=1:4, etiquetas(j).String=sprintf('J%d: %.1f graus',j,v(j)); end
        for j=5:6, etiquetas(j).String=sprintf('Segmento %d: %.3f m',j-4,v(j)); end
        info.String={sprintf('Centro da esfera (m):\nx = %.3f\ny = %.3f\nz = %.3f',r.centro_esfera); ...
            ''; 'Piso: z = 0';'Para coleta no piso, centro da';'esfera deve estar em z = 0,10 m.'; ...
            ''; 'Controles geometricos: posturas';'podem atravessar o piso ou o braco.'};
        fig.UserData=struct('modelo',gAtual,'cinematica',r,'q',q,'eixos',ax);
        drawnow;
    end
end
