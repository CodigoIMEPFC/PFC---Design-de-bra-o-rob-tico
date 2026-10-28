# Dimensionamento de bracos a partir de atuadores disponiveis

Este projeto inicia o desenvolvimento do metodo discutido no TCC:
**colecao de acionamentos + tarefa de pick and place de 5 kg -> configuracoes de braco possiveis**.

Objetivo inicial acordado: comparar geometrias com base fixa e quatro juntas
inspiradas em J2-J5 do UR5 CB3 pela regiao de coleta em que conseguem sustentar
uma esfera de 5 kg, sem orientacao prescrita. O espaco de trabalho sera uma saida.
O fluxo integrado verifica uma tarefa de transporte e compara PD/MPC nas
geometrias selecionadas; o limite padrao e de tres geometrias.
Por decisao do usuario, esta versao nao verificara colisoes com o proprio braco,
o piso ou o ambiente. A comparacao sera geometrica e por torque; o piso permanece
como referencia para a posicao da esfera na coleta.
O primeiro cenario hipotetico de construcao esta em `dados/HIPOTESES_CONSTRUCAO.md`;
seus valores editaveis estao em `hipoteses_construcao.m` e sao carregados em
`estudo.config.construcao`. A busca amostrada da regiao de coleta ja esta implementada.

## O que ja esta implementado

- Copia integral do programa fornecido, em `referencia/`.
- Cinematica DH padrao e dinamica para um numero variavel de juntas rotativas.
- Carga pontual, gravidade com orientacao configuravel e trajetorias quinticas.
- Cinematica inversa de posicao com preservacao das juntas fixas e verificacao de convergencia.
- Calculo dos torques exigidos, torque RMS, velocidade, potencia e energia.
- Execucao curta da referencia UR5 CB3: ida sem carga e retorno com 5 kg.
- Testes contra funcoes extraidas do original, casos analiticos e Robotics System Toolbox.
- Planilha simplificada com NXM640A e quatro unidades hipoteticas, leitura e validacao no MATLAB.
- Configuracao das tres alternativas completas de reducao e rendimento 0,75.
- Modelo geometrico parametrico 4R com base fixa, ferramenta e esfera.
- Janela 3D com controles de quatro angulos e dois comprimentos: `visualizar_braco`.
- Massas e centros de 19 componentes para sustentacao estatica, sem colisoes.
- Comparacao de uma postura com as tres reducoes e os tres cenarios de massa dos redutores.
- Busca da regiao de coleta no piso para 64 geometrias, com atribuicoes de motores que respeitam estoque.
- Comparacao de duas resolucoes, ranking e posturas salvas para cada ponto aceito.
- Transporte carregado e retorno vazio: tres geometrias, tres massas de redutor,
  tres reducoes e tres tempos, com inercias documentadas e parcela dos rotores.
- Controle PD com compensacao dinamica, torque limitado e integracao do movimento
  realizado; comparacao de massas nominais e construcao 20% mais pesada.

Esta entrega contem a **base numerica, o cadastro, o modelo parametrico e o fluxo
integrado de selecao com verificacao por MPC**.
A busca compara geometrias pela regiao amostrada de sustentacao estatica.
O teste de transporte verifica um ciclo especifico; nao garante conexao entre
todos os pontos do mapa nem aprova acionamentos completos.
A execucao de referencia permanece
com os parametros fisicos incompletos recebidos e identifica essa limitacao nos resultados.

## Como executar

Para executar o fluxo integrado, do cadastro aos candidatos verificados:

```matlab
projeto = projetar_braco;
visualizar_projeto(projeto);
```

Edite a tarefa e os limites de busca em `entrada_projeto.m`; cadastre os motores
na planilha existente. O padrao examina 64 geometrias, tres reducoes e tres tempos,
e simula PD/MPC nas tres geometrias mais bem classificadas na triagem.
Somente candidatos com triagem e MPC concluidos dentro dos criterios entram
em `projeto.qualificados`. Os demais mantem o motivo da falha ou a pendencia.
As saidas ficam em uma subpasta datada de `resultados/projeto_integrado/`.
Consulte `dados/PROJETO_INTEGRADO.md` para entradas, classificacao e limites.

Para comparar MPC linear variante no tempo com PD digital:

```matlab
estudo = simular_mpc;
visualizar_mpc(estudo);
```

O MPC preve aproximadamente 0,3 s, respeita os limites de torque na otimizacao
e atua sobre a planta nao linear. A comparacao usa a mesma taxa de atualizacao
nos dois controladores. Implementacao em MATLAB base; detalhes e limites em
`dados/MPC_TRANSPORTE.md`. Resultados em `resultados/mpc/`.

Para simular o movimento realizado com controle e limites de torque:

```matlab
controle = simular_controle;
visualizar_controle(controle);
```

Esta etapa compara as tres reducoes em um braco de 0,30/0,45 m, com erro
inicial e dois cenarios de massas. Veja `dados/CONTROLE_TRANSPORTE.md` para
hipoteses, tolerancias e diferencas em relacao a dinamica inversa abaixo.

Para comparar os tres bracos no transporte de 5 kg:

```matlab
transporte = simular_transporte;
visualizar_transporte(transporte);
```

O resultado fica em `resultados/transporte/`. Pontos, elevacao, tempos e hipoteses
de inercia estao em `hipoteses_transporte.m`. Metodo, comandos para consultar
resultados salvos e limites estao em `dados/TRANSPORTE_DINAMICO.md`.

Para executar a busca completa e visualizar o resultado:

```matlab
busca = buscar_regiao_coleta;
visualizar_regiao_coleta(busca);
```

Para consultar a busca ja salva sem calcular novamente:

```matlab
load('resultados/busca_coleta/busca_coleta.mat','busca');
visualizar_regiao_coleta(busca);
```

Consulte `dados/BUSCA_REGIAO_COLETA.md` para metodo, resolucao, resultados e limites.

Para calcular os torques e comparar as reducoes na postura inicial:

```matlab
resultado = avaliar_estatica;
visualizar_estatica(resultado);
```

Os resultados ficam em `resultados/estatica/`. O comando avalia segmentos de
0,30 m e 0,30 m; exemplos para mudar comprimentos, angulos e motores estao em
`dados/AVALIACAO_ESTATICA.md`. Esta etapa nao determina o espaco de trabalho.

Para explorar a geometria, abra esta pasta no MATLAB e execute:

```matlab
visualizar_braco
```

Mova os controles para alterar as quatro juntas e os comprimentos. A esfera e a
garra acompanham o punho. Esta janela ainda nao verifica carga nem colisoes.
Detalhes: `dados/MODELO_GEOMETRICO_4R.md`.

Para importar o cadastro, abra esta pasta no MATLAB e execute:

```matlab
estudo = preparar_estudo;
```

Edite `dados/cadastro_motores_simplificado.xlsx`, aba Motores, a partir da linha 6.
As entradas validadas ficam em `estudo.motores`; reducoes e hipoteses em `estudo.config`.
Este comando nao calcula nem aprova um braco. Consulte `dados/LEIA-ME.md`.

Para executar a referencia UR5 CB3:

No MATLAB, abra esta pasta como pasta atual e execute:

```matlab
iniciar
```

O resultado fica na variavel `resultado` e em `resultados/referencia/`:

- `requisitos_referencia.csv`: requisitos nas juntas ativas.
- `referencia.mat`: parametros, historicos e resultados numericos.
- `status.json`: hipoteses e estado da avaliacao.

Para verificar a base:

```matlab
executar_testes
```

Os testes que usam a implementacao independente requerem Robotics System Toolbox.
O nucleo de calculo e a execucao de referencia usam MATLAB base. A verificacao de
integridade da copia do original utiliza .NET no Windows.

## Diferencas deliberadas em relacao ao programa recebido

1. A matematica foi separada da simulacao de controle, das tabelas e das figuras.
2. O numero de juntas deixou de estar fixado em seis no nucleo generico.
3. Um alvo nao atingido pela IK interrompe a execucao de referencia.
4. Os requisitos vem da dinamica inversa na trajetoria desejada, sem cortar o torque
   por um limite provisorio. Torque aplicado e erro de controle serao avaliados em etapa separada.
5. A referencia e chamada UR5 CB3, de acordo com os parametros presentes no arquivo.
6. A IK nesta etapa verifica posicao, nao orientacao da garra nem colisoes.
   Ela usa DLS sem o objetivo secundario do original; a solucao articular pode diferir.
7. A referencia usa 41 amostras por fase de 2 s para verificacao inicial. Os valores
   nao sao uma reproducao da simulacao RK4 de 1 kHz do original. O controle nao foi portado.
8. As metricas de cada fase sao integradas separadamente; a mudanca de massa entre
   as fases nao e interpolada como uma variacao gradual de carga.

## Proximas etapas do desenvolvimento

1. Refinar os limites mecanicos e as hipoteses do modelo geometrico 4R ja implementado.
2. Refinar massas, centros e inercias equivalentes implementadas na dinamica;
   obter dados dos conjuntos de transmissao e da construcao efetiva.
3. Refinar a resolucao e os intervalos de comprimentos da busca implementada.
4. Ampliar a colecao de motores documentados e definir propriedades dos redutores.
   O cadastro simplificado usa torque, massa e inercia do rotor. As reducoes e o
   rendimento estao em `configuracao_estudo.m`.
5. Avaliar sensibilidade a massas, secoes, altura de montagem e garra.
6. Ampliar as tarefas do teste dinamico e otimizar trajetorias e tempos.
   Validar curvas torque-velocidade e propriedades das transmissoes.
   Estrutura e transmissao requerem verificacoes proprias para um projeto fisico.
7. Construir a interface depois da verificacao do avaliador e da busca.

## Rastreabilidade

Consulte `ANALISE_DO_ORIGINAL.md` para os pontos de reaproveitamento e as limitacoes
identificadas no arquivo recebido. A copia em `referencia/` e preservada para comparacao.
As funcoes extraidas para testes nao executam a rotina principal nem o controlador.

Documentacao de apoio para a comparacao independente:

- [Dinamica inversa no MATLAB](https://www.mathworks.com/help/robotics/ref/rigidbodytree.inversedynamics.html)
- [Propriedades de corpos rigidos](https://www.mathworks.com/help/robotics/ref/rigidbody.html)
- [Convencao DH no MATLAB](https://www.mathworks.com/help/robotics/ref/rigidbodyjoint.setfixedtransform.html)
