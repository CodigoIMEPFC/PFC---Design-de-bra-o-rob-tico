function transporte=simular_transporte(opcoes)
% SIMULAR_TRANSPORTE Compara tres geometrias na mesma tarefa de pick and place.
% Uso: transporte=simular_transporte; visualizar_transporte(transporte)
if nargin<1, opcoes=struct(); end
raiz=fileparts(mfilename('fullpath')); cfg=configuracao_estudo(); ht=hipoteses_transporte();
if isfield(opcoes,'hipoteses'), ht=opcoes.hipoteses; end
arquivo=fullfile(raiz,'dados','cadastro_motores_simplificado.xlsx');
if isfield(opcoes,'arquivo_motores'), arquivo=opcoes.arquivo_motores; end
out=fullfile(raiz,'resultados','transporte');
if isfield(opcoes,'pasta_saida'), out=opcoes.pasta_saida; end
motores=braco.ler_motores(string(arquivo));
if isfield(opcoes,'ids_motores')
    [ok,ids]=ismember(string(opcoes.ids_motores(:)),motores.id);
    assert(numel(ids)==4 && all(ok),'braco:DefinirMotores','Informe quatro IDs cadastrados.');
else
    assert(height(motores)==1,'braco:DefinirMotores','Informe opcoes.ids_motores para varios modelos.');
    ids=ones(4,1);
end
for i=1:height(motores)
    assert(sum(ids==i)<=motores.quantidade(i),'braco:EstoqueInsuficiente','Estoque insuficiente.');
end
validateattributes(ht.geometrias_m,{'numeric'},{'2d','ncols',2,'positive','finite'});
validateattributes(ht.tempos_ida_s,{'numeric'},{'vector','positive','finite'});
validateattributes(ht.pausa_s,{'numeric'},{'scalar','positive','finite'});
validateattributes(ht.margem_torque,{'numeric'},{'scalar','>=',1,'finite'});
assert(~cfg.verificar_colisoes,'braco:Escopo','Este estudo nao implementa colisoes.');
assert(cfg.carga_util_kg==5,'braco:Escopo','Este ciclo foi definido para esfera de 5 kg.');
m=motores(ids,:); mm=m.massa_kg; red=cfg.construcao.massas_redutores_kg;
central=cfg.construcao.indice_cenario_redutores_base;
capacity=cfg.rendimento(:).*cfg.reducoes(end,:).'.*m.torque_continuo_Nm;
transporte=struct('config',cfg,'hipoteses',ht,'motores_por_junta',m, ...
    'geometrias',{{}},'trajetorias',{{}},'casos',{{}});
rows=cell(0,13); details=cell(0,11); k=0; maxErro=0;
for a=1:size(ht.geometrias_m,1)
    L=ht.geometrias_m(a,:); g=braco.modelo_geometrico_4r(L(1),L(2),cfg.construcao);
    fprintf('Transporte: geometria %.2f / %.2f m\n',L);
    tr=braco.escolher_trajetoria_4r(g,ht,mm,red(central,:),cfg.carga_util_kg,capacity);
    for f=1:3
        for j=1:numel(tr.fases{f}.u)
            fk=braco.cinematica_4r(tr.fases{f}.Q(:,j),g);
            maxErro=max(maxErro,norm(fk.centro_esfera-tr.fases{f}.xyz_m(j,:).'));
        end
    end
    transporte.geometrias{a}=g; transporte.trajetorias{a}=tr;
    for s=1:size(red,1)
        base=braco.base_dinamica_transporte(g,tr,mm,red(s,:),cfg.carga_util_kg,ht);
        for alt=1:size(cfg.reducoes,1)
            for tempo=ht.tempos_ida_s(:).'
                k=k+1;
                r=braco.avaliar_ciclo_transporte(tr,base,tempo,cfg.reducoes(alt,:), ...
                    cfg.rendimento,m.inercia_rotor_kgm2,m.torque_continuo_Nm,ht);
                r.geometria=a; r.cenario_massa=s; r.alternativa_reducao=alt;
                transporte.casos{k}=r;
                rows(k,:)={k,a,L(1),L(2),s,alt,tempo,r.tempo_ciclo_s, ...
                    r.utilizacao_maxima,r.junta_critica,r.atende_torque_amostrado, ...
                    max(r.rpm_motor_pico),r.diferenca_pico_malhas_relativa};
                for j=1:4
                    details(end+1,:)={k,j,m.id(j),r.N(j),r.torque_juntas_pico_Nm(j), ...
                        r.torque_motor_envelope_pico_Nm(j),r.torque_motor_envelope_rms_Nm(j), ...
                        r.rpm_motor_pico(j),r.utilizacao_com_margem(j),m.torque_continuo_Nm(j), ...
                        m.inercia_rotor_kgm2(j)*r.N(j)^2}; %#ok<AGROW>
                end
            end
        end
    end
end
assert(maxErro<1e-8,'braco:ErroTrajetoria','Trajetoria nao confere com cinematica direta.');
transporte.resumo=cell2table(rows,'VariableNames',{'caso','geometria','L1_m','L2_m', ...
    'cenario_massa','alternativa_reducao','tempo_ida_s','tempo_ciclo_s', ...
    'utilizacao_maxima_com_margem','junta_critica','atende_torque_amostrado', ...
    'rpm_maxima_entre_motores','diferenca_pico_malhas_relativa'});
transporte.por_junta=cell2table(details,'VariableNames',{'caso','junta','motor','reducao', ...
    'torque_junta_pico_Nm','envelope_motor_pico_Nm','envelope_motor_rms_Nm', ...
    'rpm_motor_pico','utilizacao_com_margem','torque_continuo_cadastrado_Nm','inercia_rotor_refletida_kgm2'});
transporte.erro_posicao_maximo_m=maxErro;
transporte.escopo="Triagem dinamica amostrada por torque; curva torque-velocidade, termica, estrutura e colisoes nao verificadas";
ref=transporte.resumo;
transporte.caso_referencia=find(ref.geometria==1 & ref.cenario_massa==central & ...
    ref.alternativa_reducao==size(cfg.reducoes,1) & ref.tempo_ida_s==min(ht.tempos_ida_s),1);
if ~isfolder(out), mkdir(out); end
writetable(transporte.resumo,fullfile(out,'comparacao_transporte.csv'));
writetable(transporte.por_junta,fullfile(out,'requisitos_por_junta.csv'));
save(fullfile(out,'transporte.mat'),'transporte','-v7.3');
fig=visualizar_transporte(transporte,'off');
c=onCleanup(@()close(fig)); exportgraphics(fig,fullfile(out,'comparacao_transporte.png'),'Resolution',160); clear c;
fig=visualizar_ciclo_transporte(transporte,transporte.caso_referencia,'off');
c=onCleanup(@()close(fig)); exportgraphics(fig,fullfile(out,'ciclo_referencia.png'),'Resolution',160); clear c;
historico=table();
for f=transporte.casos{transporte.caso_referencia}.fases
    seg=f{1}; n=numel(seg.t_s);
    tab=array2table([seg.t_s(:) repmat(seg.carga_kg,n,1) seg.Q.' seg.dq.' seg.ddq.' ...
        seg.torque_juntas_Nm.' seg.motor.envelope_motor_Nm.' seg.motor.rpm_motor.'], ...
        'VariableNames',["t_s","carga_kg","q"+(1:4)+"_rad","dq"+(1:4)+"_rad_s", ...
        "ddq"+(1:4)+"_rad_s2","tau_junta"+(1:4)+"_Nm", ...
        "envelope_motor"+(1:4)+"_Nm","rpm_motor"+(1:4)]);
    tab.fase=repmat(seg.nome,n,1); historico=[historico;tab]; %#ok<AGROW>
end
writetable(historico,fullfile(out,'historico_caso_referencia.csv'));
status=struct('escopo',transporte.escopo,'hipoteses',ht,'casos',k, ...
    'atendem_torque',sum(transporte.resumo.atende_torque_amostrado), ...
    'erro_cinematica_m',maxErro,'max_diferenca_pico_malhas_relativa', ...
    max(transporte.resumo.diferenca_pico_malhas_relativa),'verificar_colisoes',false, ...
    'criado_em',char(datetime('now')));
fid=fopen(fullfile(out,'status.json'),'w','n','UTF-8');
assert(fid>=0,'braco:FalhaEscrita','Nao foi possivel salvar status.');
c=onCleanup(@()fclose(fid)); fprintf(fid,'%s',jsonencode(status,PrettyPrint=true));
disp(transporte.resumo(transporte.resumo.cenario_massa==central,:));
fprintf('Resultados em %s\n',out);
end
