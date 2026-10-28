function h=hipoteses_controle()
% HIPOTESES_CONTROLE Primeiro ensaio de acompanhamento, nao controle de hardware.
h.comprimentos_m=[0.30 0.45]; h.tempo_ida_s=2;
h.cenario_massa_redutor=2;
h.frequencia_natural_rad_s=12*ones(4,1); h.amortecimento=ones(4,1);
h.erro_inicial_graus=[1;-1;0.5;-0.5];
h.passo_integracao_s=0.002;
h.fatores_massas_estimadas=[1 1.2];
h.tolerancia_posicao_m=0.005; h.tolerancia_junta_graus=1;
h.refinar_passo=true;
h.motor_dinamica="toolbox"; % "nucleo" permite o calculo por Jacobianas em MATLAB base.
h.limite_torque="Torque continuo cadastrado, sem multiplicar/dividir por margem";
h.transmissao="Ganho constante eta*N em ambos os sentidos; nao e modelo energetico regenerativo";
h.escopo="Controle ideal de torque; sem malha eletrica, sensores, atrasos, atrito detalhado ou colisoes";
end
