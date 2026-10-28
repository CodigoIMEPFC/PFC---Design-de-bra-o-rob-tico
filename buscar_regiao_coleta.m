function busca=buscar_regiao_coleta(opcoes)
% BUSCAR_REGIAO_COLETA Compara geometrias pela coleta estatica no piso.
% Uso: busca=buscar_regiao_coleta;
% Opcoes: passo_m, passo_angular_graus, comprimentos_1_m, comprimentos_2_m,
% verificar_resolucao, arquivo_motores, limite_atribuicoes, pasta_saida.
if nargin<1, opcoes=struct(); end
raiz=fileparts(mfilename('fullpath')); cfg=configuracao_estudo(); h=cfg.construcao;
padrao=struct('passo_m',0.02,'passo_angular_graus',15, ...
    'comprimentos_1_m',h.comprimentos_segmento_1_m,'comprimentos_2_m',h.comprimentos_segmento_2_m, ...
    'verificar_resolucao',true,'arquivo_motores',fullfile(raiz,'dados','cadastro_motores_simplificado.xlsx'), ...
    'limite_atribuicoes',1000,'pasta_saida',fullfile(raiz,'resultados','busca_coleta'));
assert(isstruct(opcoes) && isscalar(opcoes),'braco:OpcoesInvalidas','Informe uma estrutura de opcoes.');
for f=string(fieldnames(opcoes)).'
    assert(isfield(padrao,f),'braco:OpcaoDesconhecida','Opcao desconhecida: %s',f);
    padrao.(f)=opcoes.(f);
end
op=padrao;
validateattributes(op.passo_m,{'numeric'},{'scalar','finite','positive'});
validateattributes(op.passo_angular_graus,{'numeric'},{'scalar','finite','positive','<=',90});
validateattributes(op.comprimentos_1_m,{'numeric'},{'vector','nonempty','finite','positive'});
validateattributes(op.comprimentos_2_m,{'numeric'},{'vector','nonempty','finite','positive'});
assert(islogical(op.verificar_resolucao) && isscalar(op.verificar_resolucao),'braco:OpcoesInvalidas','verificar_resolucao deve ser true ou false.');
motores=braco.ler_motores(string(op.arquivo_motores));
atr=braco.atribuicoes_motores(motores,op.limite_atribuicoes);
[a,b]=ndgrid(unique(op.comprimentos_1_m),unique(op.comprimentos_2_m)); L=[a(:) b(:)];
fprintf('Busca: %d geometrias, %d atribuicao(oes), sem colisoes.\n',size(L,1),size(atr,1));
busca=executar_grade(L,op.passo_m,op.passo_angular_graus,motores,atr,cfg);
busca.opcoes=op; busca.motores=motores; busca.atribuicoes=atr; busca.config=cfg;
fina=sortrows(busca.ranking,'id_comparacao');
busca.comparacao_resolucao=fina(:,{'id_comparacao','geometria','L1_m','L2_m','atribuicao','cenario_massa','alternativa_reducao'});
busca.comparacao_resolucao.area_malha_principal_m2=fina.area_estimada_m2;
busca.comparacao_resolucao.area_malha_grossa_m2=nan(height(fina),1);
busca.comparacao_resolucao.diferenca_m2=nan(height(fina),1);
if op.verificar_resolucao
    fprintf('Comparacao com malha mais grossa: %.3f m / %.1f graus.\n',2*op.passo_m,2*op.passo_angular_graus);
    grossa=executar_grade(L,2*op.passo_m,2*op.passo_angular_graus,motores,atr,cfg);
    fina=sortrows(busca.ranking,'id_comparacao'); grossaTabela=sortrows(grossa.ranking,'id_comparacao');
    busca.comparacao_resolucao=fina(:,{'id_comparacao','geometria','L1_m','L2_m','atribuicao','cenario_massa','alternativa_reducao'});
    busca.comparacao_resolucao.area_malha_principal_m2=fina.area_estimada_m2;
    busca.comparacao_resolucao.area_malha_grossa_m2=grossaTabela.area_estimada_m2;
    busca.comparacao_resolucao.diferenca_m2=fina.area_estimada_m2-grossaTabela.area_estimada_m2;
    busca.ranking_malha_grossa=grossa.ranking;
end
saida=op.pasta_saida; if ~isfolder(saida), mkdir(saida); end
writetable(busca.ranking,fullfile(saida,'ranking_geometrias.csv'));
if ~isempty(busca.comparacao_resolucao)
    writetable(busca.comparacao_resolucao,fullfile(saida,'comparacao_resolucoes.csv'));
end
% Exporta todas as posturas que testemunham a viabilidade dos pontos vencedores
% no cenario central (uma geometria, atribuicao e reducao especificas).
sCentral=h.indice_cenario_redutores_base;
linhas=busca.ranking(busca.ranking.cenario_massa==sCentral,:);
melhor=linhas(1,:); busca.melhor_cenario_central=melhor;
caso=busca.mapas{melhor.geometria}.casos{melhor.caso};
busca.conferencia_melhor=braco.conferir_mapa_coleta(busca.mapas{melhor.geometria}.geometria,caso,busca.xy,motores,cfg);
xy=busca.xy(caso.celulas_aceitas,:);
t=array2table([xy repmat(h.raio_esfera_m,size(xy,1),1) rad2deg(caso.posturas_rad) caso.utilizacao_com_margem], ...
    'VariableNames',{'x_m','y_m','z_centro_esfera_m','q1_graus','q2_graus','q3_graus','q4_graus','utilizacao_com_margem'});
writetable(t,fullfile(saida,'posturas_melhor_cenario_central.csv'));
busca.status="Estimativa por centros de celulas e orientacoes amostradas; nao e otimo global nem garantia de transporte";
save(fullfile(saida,'busca_coleta.mat'),'busca','-v7.3');
status=struct('escopo',busca.status,'colisoes',false,'passo_m',op.passo_m, ...
    'carga_kg',cfg.carga_util_kg,'margem_torque',h.margem_torque_estatico, ...
    'rendimento',cfg.rendimento,'reducoes',cfg.reducoes,'massas_redutores_kg',h.massas_redutores_kg, ...
    'passo_angular_graus',op.passo_angular_graus,'n_geometrias',size(L,1), ...
    'n_atribuicoes',size(atr,1),'pontos_aceitos_cenario_central',height(t), ...
    'melhor_cenario_central',table2struct(melhor),'conferencia',busca.conferencia_melhor, ...
    'verificar_resolucao',op.verificar_resolucao,'executado_em',char(datetime('now')));
fid=fopen(fullfile(saida,'status.json'),'w','n','UTF-8');
assert(fid>=0,'braco:FalhaEscrita','Falha ao gravar status da busca.');
fechar=onCleanup(@()fclose(fid)); fprintf(fid,'%s',jsonencode(status,PrettyPrint=true)); %#ok<NASGU>
f=visualizar_regiao_coleta(busca,'off'); limpar=onCleanup(@()close(f)); %#ok<NASGU>
exportgraphics(f,fullfile(saida,'regiao_coleta.png'),'Resolution',140);
disp(linhas(1:min(5,height(linhas)),:));
fprintf('Areas estimadas por malha; celulas sem solucao nao comprovam impossibilidade.\nResultados: %s\n',saida);
end

function r=executar_grade(L,passo,angular,motores,atr,cfg)
h=cfg.construcao; d=h.afastamentos_punhos_m;
limX=max(L(:,1))+max(L(:,2))+d(2)+d(3)+h.distancia_flange_centro_esfera_m;
D=d(3)+h.distancia_flange_centro_esfera_m;
x=(ceil(-limX/passo):floor(limX/passo))*passo;
y=(ceil((-d(1)-D)/passo):floor((-d(1)+D)/passo))*passo;
assert(~isempty(x) && ~isempty(y),'braco:MalhaVazia','O passo espacial nao produz pontos no dominio.');
[X,Y]=ndgrid(x,y); r.xy=[X(:) Y(:)]; r.x=x; r.y=y; r.passo_m=passo;
r.passo_angular_graus=angular; r.mapas=cell(size(L,1),1);
nc=size(atr,1)*size(h.massas_redutores_kg,1)*size(cfg.reducoes,1);
linhas=zeros(size(L,1)*nc,11); k=0;
for i=1:size(L,1)
    g=braco.modelo_geometrico_4r(L(i,1),L(i,2),h);
    mapa=braco.mapear_coleta_4r(g,r.xy,angular,motores,atr,cfg); r.mapas{i}=mapa;
    for j=1:numel(mapa.casos)
        c=mapa.casos{j}; k=k+1;
        linhas(k,:)=[k i L(i,:) c.atribuicao c.cenario_massa c.alternativa_reducao j ...
            numel(c.celulas_aceitas) numel(c.celulas_aceitas)*passo^2 sum(mapa.geometrico)*passo^2];
    end
    if mod(i,8)==0 || i==size(L,1)
        fprintf('Malha %.3f m: geometria %d/%d; %d posturas candidatas.\n',passo,i,size(L,1),mapa.n_posturas);
    end
end
r.ranking=array2table(linhas,'VariableNames',{'id_comparacao','geometria','L1_m','L2_m','atribuicao', ...
    'cenario_massa','alternativa_reducao','caso','n_celulas_aceitas','area_estimada_m2','area_geometrica_amostrada_m2'});
r.ranking=sortrows(r.ranking,{'cenario_massa','area_estimada_m2','id_comparacao'},{'ascend','descend','ascend'});
for j=1:4
    r.ranking.("motor_J"+j)=motores.id(atr(r.ranking.atribuicao,j));
end
end
