function resultados=executar_testes()
%EXECUTAR_TESTES Comparacoes com o original, formulas analiticas e toolbox.
raiz=fileparts(mfilename('fullpath')); addpath(raiz);
saida=fullfile(raiz,'resultados');
if ~exist(saida,'dir'), mkdir(saida); end
resultados=runtests(fullfile(raiz,'testes'));
disp(table(resultados));
resumo=struct('passaram',sum([resultados.Passed]), ...
    'falharam',sum([resultados.Failed]),'incompletos',sum([resultados.Incomplete]), ...
    'matlab',version,'executado_em',char(datetime('now')));
fid=fopen(fullfile(saida,'testes.json'),'w','n','UTF-8');
assert(fid>=0,'braco:FalhaEscrita','Nao foi possivel salvar o resumo dos testes.');
c=onCleanup(@()fclose(fid)); fprintf(fid,'%s',jsonencode(resumo,PrettyPrint=true));
assert(all([resultados.Passed]),'braco:TesteFalhou','Existem testes reprovados ou incompletos.');
end
