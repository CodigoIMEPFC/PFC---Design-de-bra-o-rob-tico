function config = configuracao_estudo()
% CONFIGURACAO_ESTUDO Hipoteses acordadas para o futuro estudo inverso.
config.carga_util_kg=5;
config.rendimento=0.75*ones(1,4);
% Cada linha e uma alternativa COMPLETA, sem combinacao entre linhas.
config.reducoes=[50 50 50 50; 80 80 60 60; 100 100 80 80];
config.ordem_colunas_original=[2 3 4 5];
config.ordem_juntas_novo_braco="Juntas 1 a 4 inspiradas em J2, J3, J4 e J5 do UR5 CB3; base fixa";
config.objeto="Esfera de 5 kg; raio hipotetico de 0,10 m";
config.construcao=hipoteses_construcao();
config.orientacao_tarefa="Livre, com hipotese de preensao estavel pela garra";
config.verificar_colisoes=false;
config.hipotese_colisoes="Interferencias com piso, base, elos, garra, esfera e ambiente desconsideradas";
config.objetivo_busca="Comparar geometrias pela regiao de coleta com sustentacao estatica de 5 kg";
config.etapa_seguinte="Refinar tarefa, hipoteses fisicas e limites torque-velocidade apos o teste de transporte";
config.escopo="Avaliacao preliminar por torque; velocidade e termica nao validadas";
config.hipotese_torque="Torque cadastrado considerado disponivel nas velocidades do teste";
config.pendencias=["Refinamento das hipoteses geometricas e dos limites articulares"; ...
    "Refinamento das hipoteses de instalacao e centros de massa dos componentes"; ...
    "Refinamento da resolucao da busca e verificacao das hipoteses de construcao"; ...
    "Ampliar tarefas e otimizar os tempos e trajetorias de transporte"; ...
    "Refinar inercias equivalentes, rotacao interna dos redutores e perdas de transmissao"];
end
