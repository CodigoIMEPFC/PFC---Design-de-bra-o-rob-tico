function h = hipoteses_construcao()
% HIPOTESES_CONSTRUCAO Valores iniciais de estudo, nao projeto de fabricacao.
% Fonte, justificativas e limites em dados/HIPOTESES_CONSTRUCAO.md.
h.material="Aluminio EN AW-6061";
h.densidade_kgm3=2700;
h.secao="Tubo quadrado idealizado, sem raios de canto";
h.lado_externo_m=0.060;
h.espessura_m=0.003;
h.comprimentos_segmento_1_m=0.15:0.05:0.50;
h.comprimentos_segmento_2_m=0.15:0.05:0.50;
% Altura absoluta do eixo do ombro acima do piso; nao somar d1 do UR5.
h.altura_ombro_sobre_piso_m=0.30;
% Afastamentos d4, d5 e d6 preservados da referencia UR5 CB3 nesta etapa.
h.afastamentos_punhos_m=[0.10915 0.09465 0.0823];
% Dominio geometrico hipotetico; nao e limite mecanico de um produto.
h.limites_juntas_graus=repmat([-180 180],4,1);
h.raio_esfera_m=0.10;
h.massa_garra_kg=0.50;
% Distancias medidas em +z local da flange final.
h.distancia_flange_centro_garra_m=0.05;
h.distancia_flange_centro_esfera_m=0.15;
% Cada linha representa as massas nas juntas 1 a 4 em um cenario.
% Nao sao massas de redutores comerciais nem dependem da reducao por lei fisica.
h.massas_redutores_kg=[0.5 0.5 0.5 0.5;1 1 1 1;1.5 1.5 1.5 1.5];
h.indice_cenario_redutores_base=2;
h.massa_suporte_por_junta_kg=0.20;
h.margem_torque_estatico=1.50;
h.natureza="Hipoteses iniciais documentadas, exceto densidade obtida de ficha tecnica";
h.status="Geometria, estatica, busca de coleta e teste dinamico de transporte implementados";
end
