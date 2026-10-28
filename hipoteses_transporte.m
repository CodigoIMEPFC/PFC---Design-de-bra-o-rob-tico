function h=hipoteses_transporte()
% HIPOTESES_TRANSPORTE Caso comparativo editavel; dimensoes nao catalogadas.
h.geometrias_m=[0.30 0.45;0.25 0.45;0.35 0.45];
h.coleta_m=[-0.40 -0.18 0.10];
h.deposito_m=[-0.20 -0.05 0.10];
h.elevacao_m=0.15;
% Tempo de uma ida carregada, dividida igualmente entre tres movimentos.
% Retorno vazio tem igual duracao; duas pausas de 0.5 s completam o ciclo.
h.tempos_ida_s=[2 4 8];
h.pausa_s=0.5;
h.amostras_por_movimento=201;
h.passo_orientacao_graus=15;
h.raios_equivalentes_m=[0.040 0.045 0.030 0.050]; % motor, redutor, suporte, garra
h.modelo_inercias="Tubos quadrados ocos; demais corpos aproximados por esferas macicas";
h.modelo_rotor="Inercia axial refletida diagonal; acoplamento com rotacao da carcaca desprezado";
h.inercia_interna_redutor="Sem dados: rotacao interna das engrenagens nao modelada";
h.margem_torque=1.5;
end
