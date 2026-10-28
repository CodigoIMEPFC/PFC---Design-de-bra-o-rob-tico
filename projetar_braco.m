function projeto=projetar_braco(e)
% PROJETAR_BRACO Motores + tarefa -> candidatos verificados no escopo simulado.
% Uso: projeto=projetar_braco; ou e=entrada_projeto; projeto=projetar_braco(e);
if nargin<1, e=entrada_projeto(); end
cfg=configuracao_estudo(); braco.validar_entrada_projeto(e,cfg);
motores=braco.ler_motores(string(e.arquivo_motores));
braco.atribuicoes_motores(motores,e.limite_atribuicoes_motores); % valida estoque antes de escrever
ht=hipoteses_transporte(); ht.coleta_m=e.tarefa.coleta_m; ht.deposito_m=e.tarefa.deposito_m;
ht.elevacao_m=e.tarefa.elevacao_m; ht.tempos_ida_s=e.tarefa.tempos_ida_s;
ht.passo_orientacao_graus=e.passo_orientacao_graus;
ht.margem_torque=cfg.construcao.margem_torque_estatico;
out=fullfile(e.pasta_resultados,char(datetime('now','Format','yyyyMMdd_HHmmss_SSS')));
assert(~isfolder(out),'braco:SaidaExistente','Pasta de execucao ja existe. Execute novamente.');
mkdir(out);
copyfile(e.arquivo_motores,fullfile(out,'cadastro_utilizado.xlsx'));
save(fullfile(out,'entradas.mat'),'e','cfg','ht','motores');
writetable(motores,fullfile(out,'motores_utilizados.csv'));
op=struct('passo_m',e.passo_coleta_m,'passo_angular_graus',e.passo_orientacao_graus, ...
    'comprimentos_1_m',e.comprimentos_1_m,'comprimentos_2_m',e.comprimentos_2_m, ...
    'verificar_resolucao',e.comparar_resolucao_coleta,'arquivo_motores',fullfile(out,'cadastro_utilizado.xlsx'), ...
    'limite_atribuicoes',e.limite_atribuicoes_motores,'pasta_saida',fullfile(out,'busca_coleta'));
busca=buscar_regiao_coleta(op);
t=braco.triar_projeto(busca,e,ht);
for j=1:4, t.("reducao_J"+j)=cfg.reducoes(t.alternativa_reducao,j); end
[ids,~]=braco.selecionar_candidatos_projeto(t,e.max_geometrias_controle);
t.selecionado_controle=ismember(t.id_candidato,ids);
writetable(t,fullfile(out,'candidatos.csv'));
controles=cell(numel(ids),1);
fprintf('Triagem concluida: %d variantes; %d geometrias selecionadas para controle.\n',height(t),numel(ids));
for k=1:numel(ids)
    i=find(t.id_candidato==ids(k)); c=braco.verificar_candidato_projeto(t(i,:),busca,e,ht,k==1);
    controles{k}=c; dest=fullfile(out,'controles',sprintf('candidato_%03d',ids(k))); mkdir(dest);
    save(fullfile(dest,'controle.mat'),'c','-v7.3');
    writetable(c.resumo,fullfile(dest,'comparacao_pd_mpc.csv'));
    for j=1:numel(c.casos)
        writematrix(c.casos{j}.historico,fullfile(dest,sprintf('historico_caso_%02d.csv',j)));
        solver=array2table(c.casos{j}.log_otimizacao,'VariableNames', ...
            {'tempo_s','calculo_comando_s','iteracoes','residuo_projetado','violacao_limites','convergiu'});
        writetable(solver,fullfile(dest,sprintf('solver_caso_%02d.csv',j)));
    end
    mpc=c.resumo(c.resumo.metodo=="MPC",:); pd=c.resumo(c.resumo.metodo=="PD",:);
    t.mpc_executado(i)=true; t.mpc_concluido(i)=all(mpc.completo); t.atende_mpc(i)=all(mpc.atende_acompanhamento);
    if c.refinamento.executado && ~(c.refinamento.fino_completo && c.refinamento.mesma_classificacao)
        t.mpc_concluido(i)=false; % divergencia numerica impede qualificacao
    end
    t.pd_executado(i)=true; t.atende_pd(i)=all(pd.atende_acompanhamento);
    t.erro_mpc_pior_mm(i)=max(mpc.erro_movimento_max_mm,[],'includemissing');
    t.erro_pd_pior_mm(i)=max(pd.erro_movimento_max_mm,[],'includemissing');
    t=braco.qualificar_projeto(t);
    writetable(t,fullfile(out,'candidatos.csv')); % checkpoint apos cada candidato
end
t=braco.qualificar_projeto(t); [~,ranking]=braco.selecionar_candidatos_projeto(t,0);
projeto=struct('entrada',e,'config',cfg,'hipoteses_transporte',ht,'busca',busca, ...
    'candidatos',t,'ranking_preliminar',ranking,'qualificados',ranking(ranking.qualificado,:), ...
    'controles',{controles},'pasta_saida',out,'concluido',true);
save(fullfile(out,'projeto.mat'),'projeto','-v7.3');
braco.exportar_projeto(projeto);
fprintf('\nProjeto concluido: %d variantes qualificadas, %d pendentes de controle.\n', ...
    height(projeto.qualificados),sum(t.resultado=="Pendente de controle"));
disp(projeto.qualificados(:,{'id_candidato','L1_m','L2_m','alternativa_reducao','tempo_ida_s','area_coleta_m2','erro_mpc_pior_mm'}));
fprintf('Resultados: %s\n',out);
end

