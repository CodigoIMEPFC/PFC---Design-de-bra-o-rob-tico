function resultado=avaliar_estatica(comprimentos,qGraus,idsMotores,arquivo)
% AVALIAR_ESTATICA Compara a postura com tres reducoes e cenarios de massa.
% Uso: resultado=avaliar_estatica
% Ou: resultado=avaliar_estatica([0.30 0.40],[-60 45 -45 30])
% Se houver varios modelos no cadastro, informar quatro IDs na ordem das juntas.
raiz=fileparts(mfilename('fullpath'));
config=configuracao_estudo();
if nargin<1 || isempty(comprimentos), comprimentos=[0.30 0.30]; end
validateattributes(comprimentos,{'numeric'},{'vector','numel',2,'real','finite','positive'});
g=braco.modelo_geometrico_4r(comprimentos(1),comprimentos(2),config.construcao);
if nargin<2 || isempty(qGraus), qGraus=rad2deg(g.q_inicial); end
if nargin<4 || isempty(arquivo), arquivo=fullfile(raiz,'dados','cadastro_motores_simplificado.xlsx'); end
motores=braco.ler_motores(string(arquivo));
if nargin<3 || isempty(idsMotores)
    assert(height(motores)==1,'braco:DefinirMotores', ...
        'Ha varios modelos: informe os quatro IDs na ordem das juntas no terceiro argumento.');
    indices=ones(4,1);
else
    idsMotores=string(idsMotores(:));
    assert(numel(idsMotores)==4,'braco:DefinirMotores','Informe quatro IDs, um por junta.');
    [encontrados,indices]=ismember(idsMotores,motores.id);
    assert(all(encontrados),'braco:MotorNaoEncontrado','Um ou mais IDs nao existem no cadastro.');
end
resultado=braco.comparar_estatica_4r(g,deg2rad(qGraus),motores,indices,config);
saida=fullfile(raiz,'resultados','estatica');
if ~isfolder(saida), mkdir(saida); end
writetable(resultado.resumo,fullfile(saida,'comparacao_estatica.csv'));
writetable(resultado.detalhes,fullfile(saida,'torques_por_junta.csv'));
for s=1:numel(resultado.estatica)
    writetable(resultado.estatica{s}.componentes,fullfile(saida,sprintf('componentes_cenario_%d.csv',s)));
end
save(fullfile(saida,'resultado_estatica.mat'),'resultado');
fig=visualizar_estatica(resultado,config.construcao.indice_cenario_redutores_base,'off');
limparFigura=onCleanup(@()close(fig));
exportgraphics(fig,fullfile(saida,'comparacao_torques.png'),'Resolution',150);
clear limparFigura;
status=struct('etapa','postura_estatica','escopo',resultado.escopo, ...
    'comprimentos_m',g.comprimentos_m,'angulos_graus',qGraus(:).', ...
    'ids_motores',{cellstr(resultado.motores_por_junta.id)}, ...
    'carga_kg',config.carga_util_kg,'margem',g.hipoteses.margem_torque_estatico, ...
    'verificar_colisoes',false,'reducao',config.reducoes,'rendimento',config.rendimento, ...
    'massas_redutores_kg',g.hipoteses.massas_redutores_kg, ...
    'hipotese_transmissao','Capacidade estatica aproximada por eta*N*torque continuo do motor', ...
    'criado_em',char(datetime('now')));
fid=fopen(fullfile(saida,'status.json'),'w','n','UTF-8');
assert(fid>=0,'braco:FalhaEscrita','Nao foi possivel salvar status.json.');
limpar=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',jsonencode(status,PrettyPrint=true));
fprintf('\nPOSTURA ESTATICA - esfera de %.1f kg, margem %.2f, sem colisoes\n', ...
    config.carga_util_kg,g.hipoteses.margem_torque_estatico);
fprintf('Juntas 1 a 4 usam: %s\n',strjoin(resultado.motores_por_junta.id,', '));
disp(resultado.resumo);
fprintf('Utilizacao <= 1 atende ao torque com a margem adotada.\n');
fprintf('Esta comparacao vale somente para a postura informada.\nResultados: %s\n',saida);
end
