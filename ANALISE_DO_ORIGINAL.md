# Analise inicial do arquivo recebido

Arquivo: `Dimensionamento_Motores_4_Juntas_Livres_Claude.m`.

Origem: `C:/Users/davin/OneDrive/Desktop/projeto_ur5_cb3/00_original/`.

SHA-256: `43a18dedfdc1de47b515fa3343f273b83eac5474b16a27c015a01b2d5c3979a4`.

O original foi lido e copiado, sem alteracao. O codigo tem 1854 linhas e reune as
funcoes numericas locais necessarias ao fluxo observado. Nao foram encontradas
chamadas de carga de um modelo externo ou de outro script na rotina de calculo.
O comentario inicial cita um arquivo anterior, mas essa citacao nao constitui uma
dependencia executada. As instrucoes em comentarios foram tratadas como documentacao
do programa anterior, e nao como restricoes para o novo projeto.

## O que o programa atual resolve

Fixa a geometria e a distribuicao de massas do UR5, conserva as seis juntas no
modelo, movimenta q2, q3, q4 e q5 e mantem q1/q6 fixas. Resolve a posicao de um TCP,
gera ida e retorno quinticos, simula controle PD por torque calculado com saturacao
e exporta requisitos para varias cargas, duracoes e relacoes de reducao.

Ele nao explora comprimentos de elos, nao seleciona atuadores de um catalogo e nao
gera a nova arquitetura de quatro juntas discutida para o projeto.

## O que reaproveitar

| Trecho do original | Aproveitamento |
|---|---|
| Linhas 1732-1757 | Lei quintica e transformacoes cinematicas |
| Linhas 1759-1831 | DH, Jacobianas, matriz de massa, gravidade e Coriolis |
| Linhas 1662-1688 | Tratamento da carga pontual, evitando dupla contagem |
| Linhas 1479-1550 | Definicoes de metricas, distinguindo demanda e torque aplicado |
| Linhas 1368-1640 | Referencia para a futura verificacao do controle; nao portado nesta etapa |

## Pontos que precisam mudar para o novo objetivo

### Identificacao e propriedades fisicas

Os comentarios falam em UR5e (linhas 5 e 286), mas os DH e massas das linhas
289-304 correspondem ao modelo UR5 CB3 usado como referencia nesta conversa.
A matriz `Icm` e quase toda nula; o unico Izz nao nulo, isolado de Ixx/Iyy,
tambem nao forma um tensor completo fisicamente consistente. Esses valores foram conservados exclusivamente
para comparacao numerica; nao sao usados para afirmar uma selecao comercial.

### Alcance e orientacao

Nas linhas 381-390, um erro de posicao superior a 5 mm gera aviso e a varredura
continua com o alvo aproximado. Um selecionador deve distinguir tarefa atingida
de aproximacao. O novo executor interrompe esse caso. O original resolve apenas
posicao do TCP, sem requisito de orientacao nem limites posicionais das juntas.

### Demanda versus torque aplicado

O original armazena `Tau_unsat` e `Tau_cmd`, mas calcula pico/RMS a partir de
`Tau_cmd`, ja saturado (aproximadamente linhas 1450-1485). Isso descreve a atuacao
da planta simulada. Para decidir se uma configuracao atende a uma trajetoria,
tambem e necessario conhecer a demanda nao limitada e avaliar o rastreamento.
Na base nova, a dinamica inversa produz explicitamente o torque exigido, sem saturacao.

### Maximos e dados ausentes

Na avaliacao opcional de motor, `omega_peak_wc` e obtido do cenario escolhido
como critico em torque (linhas 719-724). Isso nao garante a maior velocidade
entre todos os cenarios. O futuro avaliador deve verificar os pares torque-velocidade
ao longo de cada caso. Condicoes com `| ~isfinite(...)` (linhas 742-758) podem
deixar dados ausentes passarem por uma verificacao: a versao comercial precisa
separar aprovado, reprovado e indeterminado por falta de dados.

### Escalabilidade e controle

Ha estruturas fixadas em seis juntas, por exemplo na Jacobiana (linha 1767 na
faixa da funcao `jacobiana_posicao`) e nos historicos da simulacao. O nucleo
reaproveitado agora recebe `p.n`. A busca deve primeiro avaliar trajetorias por
dinamica inversa; simulacoes em malha fechada podem verificar os candidatos finais.

## Alcance das verificacoes realizadas

Os testes comparam o nucleo extraido com as funcoes matematicas originais, com
formulas analiticas de um manipulador 2R de teste e com Newton-Euler do Robotics
System Toolbox. O resumo de cada execucao fica em `resultados/testes.json`.

Na ponte com o toolbox, os tensores no centro de massa sao transportados para a
origem do referencial do corpo pelo teorema dos eixos paralelos antes de atribuir
`rigidBody.Inertia`. Essa conversao foi necessaria para comparar a mesma distribuicao
fisica de massa nas duas formulacoes.

Essas verificacoes avaliam a implementacao das equacoes. Nao validam fisicamente
os parametros incompletos do UR5 nem demonstram capacidade de um novo braco de 5 kg.
