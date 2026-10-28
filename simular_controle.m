function controle=simular_controle(opcoes)
% SIMULAR_CONTROLE Controle PD com torque calculado e dinamica direta limitada.
if nargin<1, opcoes=struct(); end
raiz=fileparts(mfilename('fullpath')); cfg=configuracao_estudo(); ht=hipoteses_transporte(); h=hipoteses_controle();
if isfield(opcoes,'hipoteses'), h=opcoes.hipoteses; end
out=fullfile(raiz,'resultados','controle');
if isfield(opcoes,'pasta_saida'), out=opcoes.pasta_saida; end
arquivo=fullfile(raiz,'dados','cadastro_motores_simplificado.xlsx');
if isfield(opcoes,'arquivo_motores'), arquivo=opcoes.arquivo_motores; end
motores=braco.ler_motores(string(arquivo));
if isfield(opcoes,'ids_motores')
    [ok,ids]=ismember(string(opcoes.ids_motores(:)),motores.id);
    assert(numel(ids)==4 && all(ok),'braco:DefinirMotores','Informe quatro IDs cadastrados.');
else
    assert(height(motores)==1,'braco:DefinirMotores','Informe opcoes.ids_motores.'); ids=ones(4,1);
end
for i=1:height(motores), assert(sum(ids==i)<=motores.quantidade(i),'braco:EstoqueInsuficiente','Estoque insuficiente.'); end
for field={'frequencia_natural_rad_s','amortecimento'}
    v=h.(field{1}); validateattributes(v,{'numeric'},{'vector','numel',4,'positive','finite'});
    h.(field{1})=v(:);
end
validateattributes(h.erro_inicial_graus,{'numeric'},{'vector','numel',4,'finite','real'});
validateattributes(h.comprimentos_m,{'numeric'},{'vector','numel',2,'positive','finite'});
validateattributes(h.fatores_massas_estimadas,{'numeric'},{'vector','positive','finite'});
validateattributes(h.cenario_massa_redutor,{'numeric'},{'scalar','integer','>=',1,'<=',3});
assert(~cfg.verificar_colisoes,'braco:Escopo','Colisoes nao implementadas.');
if h.motor_dinamica=="toolbox"
    assert(exist('rigidBodyTree','class')==8,'braco:ToolboxAusente', ...
        'Instale Robotics System Toolbox ou use h.motor_dinamica="nucleo".');
end
g=braco.modelo_geometrico_4r(h.comprimentos_m(1),h.comprimentos_m(2),cfg.construcao);
m=motores(ids,:); mr=cfg.construcao.massas_redutores_kg(h.cenario_massa_redutor,:);
cap=cfg.rendimento(:).*cfg.reducoes(end,:).'.*m.torque_continuo_Nm;
tr=braco.escolher_trajetoria_4r(g,ht,m.massa_kg,mr,5,cap);
base=braco.base_dinamica_transporte(g,tr,m.massa_kg,mr,5,ht);
controle=struct('hipoteses',h,'hipoteses_transporte',ht,'config',cfg,'geometria',g, ...
    'trajetoria',tr,'motores_por_junta',m,'casos',{{}},'referencias',{{}});
rows=cell(0,11); k=0;
for a=1:3
    ciclo=braco.avaliar_ciclo_transporte(tr,base,h.tempo_ida_s,cfg.reducoes(a,:), ...
        cfg.rendimento,m.inercia_rotor_kgm2,m.torque_continuo_Nm,ht);
    controle.referencias{a}=ciclo;
    for fator=h.fatores_massas_estimadas(:).'
        k=k+1; fprintf('Controle: reducao %d, fator de massas %.2f\n',a,fator);
        r=braco.integrar_controle(g,ciclo,m.massa_kg,mr,m.inercia_rotor_kgm2, ...
            m.torque_continuo_Nm,ht,h,fator);
        r.alternativa_reducao=a; controle.casos{k}=r;
        rows(k,:)={k,a,fator,r.completo,r.erro_posicao_max_m*1000,r.erro_movimento_max_m*1000, ...
            r.erro_deposito_m*1000,100*r.fracao_tempo_saturado,max(r.rpm_motor_pico), ...
            r.atende_acompanhamento,r.motivo};
    end
end
controle.resumo=cell2table(rows,'VariableNames',{'caso','alternativa_reducao','fator_massas', ...
    'ciclo_completo','erro_total_max_mm','erro_movimento_max_mm','erro_deposito_mm', ...
    'tempo_com_saturacao_pct','rpm_max','atende_acompanhamento','status'});
controle.caso_referencia=k;
controle.refinamento=struct('executado',false);
if h.refinar_passo
    hf=h; hf.passo_integracao_s=h.passo_integracao_s/2;
    fprintf('Conferencia numerica: ultimo caso com metade do passo de integracao\n');
    fina=braco.integrar_controle(g,ciclo,m.massa_kg,mr,m.inercia_rotor_kgm2, ...
        m.torque_continuo_Nm,ht,hf,fator);
    erro=0;
    for f=1:min(numel(fina.fases),numel(r.fases))
        coarse=r.fases{f}; fine=fina.fases{f};
        idx=coarse.t_s<=fine.t_s(end);
        q=interp1(fine.t_s.',fine.Q.',coarse.t_s(idx).','linear').';
        erro=max(erro,max(abs(rad2deg(q-coarse.Q(:,idx))),[],'all'));
    end
    controle.refinamento=struct('executado',true,'caso',k,'passo_fino_s',hf.passo_integracao_s, ...
        'erro_angular_entre_passos_graus',erro,'diferenca_erro_movimento_mm', ...
        abs(fina.erro_movimento_max_m-r.erro_movimento_max_m)*1000, ...
        'mesma_classificacao',fina.atende_acompanhamento==r.atende_acompanhamento);
end
if ~isfolder(out), mkdir(out); end
save(fullfile(out,'controle.mat'),'controle','-v7.3');
writetable(controle.resumo,fullfile(out,'comparacao_controle.csv'));
fig=visualizar_controle(controle,k,'off'); c=onCleanup(@()close(fig));
exportgraphics(fig,fullfile(out,'controle_referencia.png'),'Resolution',160); clear c;
for junta=1:4
    fig=visualizar_estados_controle(controle,junta,k,'off'); c=onCleanup(@()close(fig));
    exportgraphics(fig,fullfile(out,sprintf('estados_junta_%d.png',junta)),'Resolution',150); clear c;
end
historico=table();
for f=r.fases
    seg=f{1}; n=numel(seg.t_s);
    tab=array2table([seg.t_s(:) repmat(seg.carga_kg,n,1) seg.Q_ref.' seg.Q.' ...
        seg.dq_ref.' seg.dq.' seg.ddq_ref.' seg.ddq.' seg.torque_pedido_Nm.' ...
        seg.torque_aplicado_Nm.' seg.rpm_motor.' seg.erro_posicao_m(:)], ...
        'VariableNames',["t_s","carga_kg","q_ref"+(1:4),"q_real"+(1:4), ...
        "dq_ref"+(1:4),"dq_real"+(1:4),"ddq_ref"+(1:4),"ddq_real"+(1:4), ...
        "torque_pedido"+(1:4),"torque_aplicado"+(1:4),"rpm_motor"+(1:4),"erro_posicao_m"]);
    tab.fase=repmat(seg.nome,n,1); historico=[historico;tab]; %#ok<AGROW>
end
writetable(historico,fullfile(out,'historico_controle.csv'));
status=struct('hipoteses',h,'refinamento',controle.refinamento,'escopo',h.escopo, ...
    'criado_em',char(datetime('now')));
fid=fopen(fullfile(out,'status.json'),'w','n','UTF-8'); assert(fid>=0,'braco:FalhaEscrita','Falha ao salvar status.');
c=onCleanup(@()fclose(fid)); fprintf(fid,'%s',jsonencode(status,PrettyPrint=true));
disp(controle.resumo); fprintf('Resultados: %s\n',out);
end
