function h=hipoteses_mpc()
% HIPOTESES_MPC MPC LTV experimental; nao requer MPC/Optimization Toolbox.
h.controle=hipoteses_controle(); h.controle.motor_dinamica="nucleo";
h.periodo_controle_s=0.020;
h.horizonte_passos=15;
h.passo_planta_s=0.002;
h.peso_estado=[40000*ones(4,1);25*ones(4,1)];
h.peso_torque=0.01; h.peso_variacao_torque=0.05;
h.peso_terminal=2;
h.qp_tolerancia=1e-7; h.qp_max_iteracoes=200;
h.alternativas_reducao=1:3;
h.fatores_massas=[1 1.2];
h.refinar_planta=true;
h.escopo="MPC LTV com limite de torque; planta nao linear e estados medidos ideais";
end
