function estudo=simular_mpc(opcoes)
% SIMULAR_MPC MPC LTV com QP e comparacao PD sob mesma taxa de amostragem.
if nargin<1, opcoes=struct(); end
raiz=fileparts(mfilename('fullpath')); h=hipoteses_mpc();
if isfield(opcoes,'hipoteses'), h=opcoes.hipoteses; end
out=fullfile(raiz,'resultados','mpc');
if isfield(opcoes,'pasta_saida'), out=opcoes.pasta_saida; end
cfg=configuracao_estudo(); ht=hipoteses_transporte(); hc=h.controle;
assert(~cfg.verificar_colisoes,'braco:Escopo','Este ensaio nao implementa colisoes.');
validateattributes(h.horizonte_passos,{'numeric'},{'scalar','integer','>=',2});
validateattributes(h.periodo_controle_s,{'numeric'},{'scalar','positive','finite'});
validateattributes(h.passo_planta_s,{'numeric'},{'scalar','positive','finite','<=',h.periodo_controle_s});
validateattributes(h.peso_estado,{'numeric'},{'vector','numel',8,'positive','finite'});
validateattributes(h.peso_torque,{'numeric'},{'scalar','positive','finite'});
validateattributes(h.peso_variacao_torque,{'numeric'},{'scalar','nonnegative','finite'});
validateattributes(h.peso_terminal,{'numeric'},{'scalar','positive','finite'});
validateattributes(h.qp_tolerancia,{'numeric'},{'scalar','positive','finite'});
validateattributes(h.qp_max_iteracoes,{'numeric'},{'scalar','integer','positive'});
validateattributes(h.alternativas_reducao,{'numeric'},{'vector','integer','>=',1,'<=',3});
validateattributes(h.fatores_massas,{'numeric'},{'vector','positive','finite'});
arquivo=fullfile(raiz,'dados','cadastro_motores_simplificado.xlsx');
if isfield(opcoes,'arquivo_motores'), arquivo=opcoes.arquivo_motores; end
motores=braco.ler_motores(string(arquivo));
if isfield(opcoes,'ids_motores')
    [ok,ids]=ismember(string(opcoes.ids_motores(:)),motores.id);
    assert(numel(ids)==4 && all(ok),'braco:DefinirMotores','Informe quatro IDs validos.');
else
    assert(height(motores)==1,'braco:DefinirMotores','Informe quatro IDs em opcoes.ids_motores.'); ids=ones(4,1);
end
for i=1:height(motores), assert(sum(ids==i)<=motores.quantidade(i),'braco:EstoqueInsuficiente','Estoque insuficiente.'); end
m=motores(ids,:); mr=cfg.construcao.massas_redutores_kg(hc.cenario_massa_redutor,:);
g=braco.modelo_geometrico_4r(hc.comprimentos_m(1),hc.comprimentos_m(2),cfg.construcao); h.geometria=g;
cap=cfg.rendimento(:).*cfg.reducoes(end,:).'.*m.torque_continuo_Nm;
tr=braco.escolher_trajetoria_4r(g,ht,m.massa_kg,mr,5,cap);
base=braco.base_dinamica_transporte(g,tr,m.massa_kg,mr,5,ht);
pNom=cell(1,2);
for modo=1:2, pNom{modo}=braco.modelo_dinamico_4r(g,m.massa_kg,mr,5*(modo==1),ht); end
estudo=struct('hipoteses',h,'config',cfg,'motores',m,'casos',{{}},'previsores',{{}});
rows={}; k=0;
for alt=h.alternativas_reducao(:).'
    fprintf('MPC: preparando modelos de previsao, reducao %d\n',alt);
    ciclo=braco.avaliar_ciclo_transporte(tr,base,hc.tempo_ida_s,cfg.reducoes(alt,:),cfg.rendimento, ...
        m.inercia_rotor_kgm2,m.torque_continuo_Nm,ht);
    pr=braco.preparar_mpc(ciclo,pNom,m.inercia_rotor_kgm2,m.torque_continuo_Nm,h);
    estudo.previsores{alt}=pr;
    for fator=h.fatores_massas(:).'
        pReal=pNom;
        if fator~=1
            gr=g; gr.hipoteses.densidade_kgm3=g.hipoteses.densidade_kgm3*fator;
            gr.hipoteses.massa_garra_kg=g.hipoteses.massa_garra_kg*fator;
            gr.hipoteses.massa_suporte_por_junta_kg=g.hipoteses.massa_suporte_por_junta_kg*fator;
            for modo=1:2, pReal{modo}=braco.modelo_dinamico_4r(gr,m.massa_kg,mr*fator,5*(modo==1),ht); end
        end
        for metodo=["PD","MPC"]
            k=k+1; fprintf('  %s, massas x %.2f\n',metodo,fator);
            r=braco.ensaio_mpc(pr,pNom,pReal,m.inercia_rotor_kgm2,h,metodo);
            r.alternativa=alt; r.fator_massas=fator; estudo.casos{k}=r;
            rows(k,:)={k,metodo,alt,fator,r.completo,r.erro_movimento_max_mm,r.atende,r.motivo};
            fprintf('  erro maximo no movimento %.4f mm; %s\n',r.erro_movimento_max_mm,r.motivo);
        end
    end
end
estudo.resumo=cell2table(rows,'VariableNames',{'caso','metodo','alternativa_reducao', ...
    'fator_massas','completo','erro_movimento_max_mm','atende_acompanhamento','status'});
estudo.refinamento=struct('executado',false);
if h.refinar_planta && r.completo
    fprintf('MPC: conferencia da planta com passo pela metade\n');
    hf=h; hf.passo_planta_s=h.passo_planta_s/2;
    rf=braco.ensaio_mpc(pr,pNom,pReal,m.inercia_rotor_kgm2,hf,"MPC");
    estudo.refinamento=struct('executado',true,'caso',k,'passo_fino_s',hf.passo_planta_s, ...
        'diferenca_pico_erro_mm',abs(rf.erro_movimento_max_mm-r.erro_movimento_max_mm), ...
        'mesma_classificacao',rf.atende==r.atende,'fino_completo',rf.completo);
end
if ~isfolder(out), mkdir(out); end
save(fullfile(out,'mpc.mat'),'estudo','-v7.3');
writetable(estudo.resumo,fullfile(out,'comparacao_mpc_pd.csv'));
for id=1:numel(estudo.casos)
    c=estudo.casos{id};
    tab=array2table(c.log_otimizacao,'VariableNames',{'tempo_s','calculo_comando_s','iteracoes', ...
        'residuo_projetado','violacao_limites','convergiu'});
    writetable(tab,fullfile(out,sprintf('solver_caso_%02d.csv',id)));
end
writematrix(estudo.casos{end}.historico,fullfile(out,'historico_mpc_referencia.csv'));
fig=visualizar_mpc(estudo,'off'); c=onCleanup(@()close(fig));
exportgraphics(fig,fullfile(out,'comparacao_mpc_pd.png'),'Resolution',150); clear c;
status=struct('escopo',h.escopo,'refinamento',estudo.refinamento, ...
    'casos',height(estudo.resumo),'criado_em',char(datetime('now')));
fid=fopen(fullfile(out,'status.json'),'w','n','UTF-8'); assert(fid>=0,'braco:FalhaEscrita','Falha ao salvar status.');
c=onCleanup(@()fclose(fid)); fprintf(fid,'%s',jsonencode(status,PrettyPrint=true));
disp(estudo.resumo);
end
