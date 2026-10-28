function resultado = executar_referencia(alvo,pastaSaida)
%EXECUTAR_REFERENCIA Verifica a base extraida: ida sem carga e volta com 5 kg.
% Nao e a busca de novos bracos. Nao seleciona atuadores comerciais.
% Uso: resultado = executar_referencia;
raiz=fileparts(mfilename('fullpath')); addpath(raiz);
if nargin<1, alvo=[0.2;-0.1;0.30]; end
if nargin<2, pastaSaida=fullfile(raiz,'resultados','referencia'); end
p=braco.modelo_ur5_cb3();
ik=braco.resolver_posicao(p,alvo,p.q0,p.free_idx);
if ~ik.atingido
    error('braco:AlvoInalcancavel', ...
        'A IK nao atingiu o alvo (erro %.6f m). Nenhuma trajetoria foi avaliada.',ik.erro_m);
end
% Amostragem de verificacao; nao substitui convergencia para um projeto final.
T=2; t=linspace(0,T,41);
[Q1,dQ1,ddQ1]=braco.quintica(p.q0,ik.q,t,T);
[Q2,dQ2,ddQ2]=braco.quintica(ik.q,p.q0,t,T);
Qs={Q1,Q2}; dQs={dQ1,dQ2}; ddQs={ddQ1,ddQ2};
fases=cell(1,2); metricas=cell(1,2);
for f=1:2
    carga=braco.carga_pontual(5*(f==2));
    tau=zeros(p.n,numel(t));
    for k=1:numel(t)
        tau(:,k)=braco.dinamica(Qs{f}(:,k),dQs{f}(:,k),ddQs{f}(:,k),p,carga);
    end
    fases{f}=struct('t',t+(f-1)*T,'q',Qs{f},'dq',dQs{f}, ...
        'ddq',ddQs{f},'tau_exigido_Nm',tau,'carga_kg',carga.mass);
    metricas{f}=braco.metricas(t,dQs{f}(p.free_idx,:),tau(p.free_idx,:));
end
a=metricas{1}; b=metricas{2};
Junta=p.free_idx(:);
TorquePico_Nm=max(a.torque_pico_Nm,b.torque_pico_Nm);
TorqueRMS_Nm=sqrt((a.torque_rms_Nm.^2+b.torque_rms_Nm.^2)/2);
VelocidadePico_rad_s=max(a.velocidade_pico_rad_s,b.velocidade_pico_rad_s);
PotenciaPico_W=max(a.potencia_pico_W,b.potencia_pico_W);
EnergiaMotora_J=a.energia_motora_J+b.energia_motora_J;
EnergiaRegenerativaMecanica_J=a.energia_regenerativa_mecanica_J+b.energia_regenerativa_mecanica_J;
tabela=table(Junta,TorquePico_Nm,TorqueRMS_Nm,VelocidadePico_rad_s, ...
    PotenciaPico_W,EnergiaMotora_J,EnergiaRegenerativaMecanica_J);
resultado=struct('status','REFERENCIA_NUMERICA_COM_INERCIAS_INCOMPLETAS', ...
    'aprovacao_comercial',false,'modelo',p,'ik',ik,'fases',{fases}, ...
    'metricas_por_fase',{metricas},'tabela',tabela);
resultado.observacoes={ ...
    'Modelo recebido: inercias rotacionais incompletas.', ...
    'Dinamica inversa da referencia, sem controle e sem saturacao.', ...
    'Duas fases herdadas; ainda nao e o ciclo completo com pega, deposito e pausas.', ...
    'Apenas posicao do TCP verificada; orientacao e colisoes nao verificadas.', ...
    'Sem avaliacao de motores, redutores, estrutura ou termica.', ...
    'Grandezas nas juntas, nao no eixo do motor.', ...
    'Integracao das metricas separada por fase para preservar a troca de carga.'};
if ~exist(pastaSaida,'dir'), mkdir(pastaSaida); end
writetable(tabela,fullfile(pastaSaida,'requisitos_referencia.csv'));
save(fullfile(pastaSaida,'referencia.mat'),'resultado');
resumo=struct('status',resultado.status,'aprovacao_comercial',false, ...
    'erro_posicao_m',ik.erro_m,'juntas_ativas',p.free_idx, ...
    'duracao_ciclo_s',2*T,'carga_retorno_kg',5, ...
    'observacoes',{resultado.observacoes});
fid=fopen(fullfile(pastaSaida,'status.json'),'w','n','UTF-8');
assert(fid>=0,'braco:FalhaEscrita','Nao foi possivel salvar o resumo.');
limpeza=onCleanup(@()fclose(fid));
fprintf(fid,'%s',jsonencode(resumo,PrettyPrint=true));
fprintf('\n%s\nErro da IK: %.3g m\n',resultado.status,ik.erro_m);
disp(tabela);
fprintf('Saida: %s\n',pastaSaida);
end
