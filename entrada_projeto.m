function e=entrada_projeto()
% ENTRADA_PROJETO Entradas do fluxo integrado; unidades SI salvo nomes em mm/graus.
raiz=fileparts(mfilename('fullpath')); cfg=configuracao_estudo(); ht=hipoteses_transporte();
e.arquivo_motores=fullfile(raiz,'dados','cadastro_motores_simplificado.xlsx');
e.comprimentos_1_m=cfg.construcao.comprimentos_segmento_1_m;
e.comprimentos_2_m=cfg.construcao.comprimentos_segmento_2_m;
e.tarefa=struct('carga_kg',5,'coleta_m',ht.coleta_m,'deposito_m',ht.deposito_m, ...
    'elevacao_m',ht.elevacao_m,'tempos_ida_s',ht.tempos_ida_s);
e.area_minima_coleta_m2=0;
e.cenario_massa_redutores=cfg.construcao.indice_cenario_redutores_base;
e.passo_coleta_m=.02; e.passo_orientacao_graus=15;
e.comparar_resolucao_coleta=true;
e.limite_atribuicoes_motores=1000;
% Controle e a etapa mais demorada. Os demais candidatos NAO sao aprovados.
e.max_geometrias_controle=3;
e.fatores_massas_controle=[1 1.2];
e.tolerancia_posicao_mm=5; e.tolerancia_junta_graus=1;
e.pasta_resultados=fullfile(raiz,'resultados','projeto_integrado');
end
