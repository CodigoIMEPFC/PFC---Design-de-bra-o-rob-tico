function estudo = preparar_estudo(arquivo)
% PREPARAR_ESTUDO Importa e valida as entradas; ainda nao busca bracos.
% Uso: estudo = preparar_estudo
% Ou: estudo = preparar_estudo("caminho/para/cadastro.xlsx")
raiz=fileparts(mfilename('fullpath'));
if nargin==0
    arquivo=fullfile(raiz,'dados','cadastro_motores_simplificado.xlsx');
end
estudo.motores=braco.ler_motores(string(arquivo));
estudo.config=configuracao_estudo();
estudo.arquivo=string(arquivo);
fprintf('Cadastro validado: %d modelo(s), %g unidade(s) informada(s).\n', ...
    height(estudo.motores),sum(estudo.motores.quantidade));
disp(estudo.motores(:,1:6));
fprintf('Carga util: 5 kg. Rendimento: 0,75. Tres alternativas completas de reducao:\n');
disp(estudo.config.reducoes);
fprintf('Entradas prontas. A busca de geometrias e a avaliacao dos motores ainda nao foram executadas.\n');
end
