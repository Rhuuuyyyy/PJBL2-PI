# Decisões de modelagem e limitações conhecidas

## 1. Lacunas do enunciado e como foram resolvidas

- **Critérios de ordenação não listados.** O enunciado diz "ordenada pelos
  critérios abaixo", mas não há lista. Adotei os critérios usuais do futebol,
  nesta ordem: mais pontos, mais vitórias, maior saldo de gols, mais gols pró e,
  como último critério, o nome do time. Esse último critério torna a ordem
  total: a tabela não depende da ordem em que as partidas aparecem na entrada.
  Confronto direto e cartões não foram implementados (exigiriam dados que o
  formato de entrada não tem).
- **Referências a seções inexistentes.** A numeração do enunciado vai da seção 7
  para a 9, e há referências a "Seção 4.1", "Seção 5" e "Seção 8". Tratei a tabela
  de armadilhas (seção 4) como a lista de casos de borda e os casos da seção 7
  como o mínimo de testes; os testes vão além disso.

## 2. Camada 1 — tipos

- `Partida` e `Linha` são *records*, não tuplas: os campos têm nome, então não é
  possível trocar sem querer gols do mandante com gols do visitante.
- `Resultado` é um tipo soma (`Vitoria | Empate | Derrota`). Com `-Wall`, o
  compilador avisa quando um caso fica sem tratamento.
- `Partida` tem o construtor exportado, como no exemplo do enunciado
  (`Partida 1 "Coritiba" 2 1 "Athletico"`). A validação acontece na fronteira de
  leitura (`lerPartida`): partidas lidas do texto sempre têm rodada ≥ 1, gols
  entre 0 e 1.000.000, nomes não vazios e times distintos. Quem monta uma
  `Partida` direto no código não passa por essa validação.
- `golsDoTime` (gols pró e contra de um time numa partida, em `Maybe`) é a base de
  `resultadoPara` e de `linhaDoTime`: a lógica "de que lado o time jogou" existe
  em um lugar só.
- `times` usa `nub . sort`. A ordem alfabética é a de `String` em Haskell, por
  ponto de código: maiúsculas antes de minúsculas, e letras acentuadas depois
  das não acentuadas (um time "Átila" ficaria depois de "Zeta").
- **Campeonato de teste** (`src/Dados.hs`): 6 times, 5 rodadas, 15 partidas,
  nenhum time joga duas vezes na mesma rodada; tem um 0 x 0 (rodada 1, Paraná x
  Operário), vitórias por 4 gols (Cianorte 4 x 0 Operário), nomes com acento, e
  empates em pontos na classificação final resolvidos por vitórias (Londrina e
  Operário, 6 pontos) e por saldo de gols (Cianorte, Athletico e Coritiba, 7
  pontos). O campeonato existe como texto e como lista de `Partida`; um teste
  confere que a leitura do texto produz exatamente a lista.

## 3. Camada 2 — classificação

- `linhaDoTime` usa `foldl`; a cada partida, `acumula` ignora quem não jogou
  (`maybe linha ... (golsDoTime t p)`).
- `classificacao` usa um único `sortBy` com
  `comparing (Down . pontosLinha) <> comparing (Down . vitorias) <> ...`. A
  comparação por vários critérios é uma função só: `Ordering` é um `Monoid`, e
  `<>` passa para o próximo critério apenas em caso de empate. `Down` inverte a
  ordem onde "mais é melhor". Encadear vários `sortBy` não serviria: um `sortBy`
  só preserva a ordem anterior se for estável e aplicado do critério menos para o
  mais importante, o que é frágil e mais difícil de ler.
- `aproveitamento` é o percentual (0 a 100) dos pontos disputados que o time
  conquistou: `100 * pontos / (3 * jogos)`, com `fromIntegral` e `/`. Sem jogos,
  devolve 0 em vez de dividir por zero.
- `maiorGoleada` ordena por diferença de gols decrescente e pega o primeiro com
  `listToMaybe`. Não usa `maximumBy` (que quebra em lista vazia). Em caso de empate
  na diferença, vale a primeira partida da lista (o `sortBy` é estável).
- `mediaGols` devolve `Nothing` para lista vazia. Em `maiorGoleada` e em
  `mediaGols` a ausência de resultado é parte do tipo (`Maybe`).
- `ateRodada n` mantém as partidas com `rodada <= n`. `n` zero ou negativo
  resulta em lista vazia; `n` maior que a última rodada devolve tudo.
- Nenhuma função da camada usa recursão explícita nem função parcial
  (`head`, `tail`, `maximum`, `foldr1`, `!!`, `fromJust`).

## 4. Camada 3 — leitura e validação

### Erros

`Erro` tem os cinco construtores exigidos mais dois, e cada um carrega a linha
ou a rodada do problema:

| Construtor | Carrega | Quando |
|---|---|---|
| `CamposInvalidos` | linha, quantidade de campos | linha sem exatamente 5 campos |
| `NumeroInvalido` | linha, campo, texto | rodada ou gols que não são um inteiro aceito |
| `PlacarNegativo` | linha, lado, gols | gols negativos |
| `RodadaInvalida` | linha, rodada | rodada menor que 1 (extra) |
| `TimeVazio` | linha, lado | nome em branco (extra) |
| `MesmoTime` | linha, time | mandante igual ao visitante |
| `TimeRepetidoNaRodada` | rodada, time | time escalado em duas partidas da mesma rodada |

`Lado` (`Mandante | Visitante`) e `Campo` (`CampoRodada | CampoGols Lado`) evitam
descrever o campo com uma `String` livre: uma mensagem como "gols do visitante"
é gerada a partir de valores que o compilador confere. `descreverErro` produz a
mensagem legível em português.

A numeração das linhas começa em 1 e conta comentários e linhas em branco, para
coincidir com o que o editor mostra.

### Ordem de validação dentro de uma linha

`lerPartida` valida, nesta ordem: quantidade de campos, rodada, gols do mandante,
gols do visitante, nome do mandante, nome do visitante e, por fim, mandante ≠
visitante. Como `lerPartida` devolve `Either Erro Partida` (um erro só), reporta o
**primeiro** problema da linha. É escrita com notação `do` na mônada `Either`.

### `lerCampeonato` e `todosOsErros`

- `lerCampeonato` usa `traverse (uncurry lerPartida)` sobre as linhas úteis: para
  no primeiro `Left`. Depois verifica o que depende de mais de uma linha: um time
  jogando duas vezes na mesma rodada (`TimeRepetidoNaRodada`).
- `todosOsErros` devolve o primeiro erro de **cada** linha inválida, em ordem de
  linha, seguido dos erros entre linhas. Esses erros entre linhas são calculados
  só sobre as linhas válidas; um time repetido numa rodada em que uma das linhas
  é inválida por outro motivo não é reportado até que a outra seja corrigida.
  Há um erro por par (rodada, time), mesmo que o time apareça três vezes.
- Consistência: para qualquer texto, `lerCampeonato` devolve `Left e` se e somente
  se `todosOsErros` não é vazio, e nesse caso `e` é o primeiro elemento de
  `todosOsErros`.
- Texto vazio, ou só com comentários e linhas em branco, é um campeonato válido
  sem partidas: `Right []`.

### Rigor da conversão de números (`readMaybe`)

Verifiquei empiricamente o comportamento de `readMaybe` (GHC 9.6.7):

| Texto | `readMaybe :: Maybe Int` | Decisão do programa |
|---|---|---|
| `" 3 "` | `Just 3` | aceito (espaços são removidos antes) |
| `"+3"` | `Nothing` | rejeitado |
| `"-1"` | `Just (-1)` | aceito como número; vira `PlacarNegativo` |
| `"- 1"` | `Just (-1)` | **rejeitado** (`readMaybe` aceita; o programa não) |
| `"0x10"` | `Just 16` | **rejeitado** (hexadecimal) |
| `"0o7"` | `Just 7` | **rejeitado** (octal) |
| `"(3)"` | `Just 3` | **rejeitado** |
| `"1e3"`, `"3.0"`, `""` | `Nothing` | rejeitado |
| `"99999999999999999999"` | `Just 7766279631452241919` | **rejeitado** (em `Int`, estoura em silêncio) |

Por isso `lerInteiro` aceita só texto formado por dígitos ASCII, com um `-`
opcional na frente, converte com `readMaybe` para `Integer` (que não estoura) e
rejeita valores com módulo acima de 1.000.000. Esse limite é uma escolha de
sanidade: garante que as somas de gols da classificação nunca estourem `Int`.
`"dois"` resulta em `NumeroInvalido`; `"-1"` resulta em `PlacarNegativo`. Zeros à
esquerda são aceitos (`"007"` vale 7).

### Espaços, finais de linha e BOM

`aparar` remove espaços (qualquer `isSpace`, o que inclui o `\r` do final de
linha do Windows) e o BOM (U+FEFF) das duas pontas de cada campo. Nomes de time
mantêm os espaços internos. Linhas só com espaços ou só com `\r` contam como em
branco. Finais de linha só com `\r` (Mac antigo) não são reconhecidos como quebra
de linha: o texto inteiro seria lido como uma linha só (com erro de campos).

### Formatação

`tabelaFormatada` mostra posição, time, pontos, jogos, vitórias, empates,
derrotas e saldo, com colunas alinhadas. A largura da coluna do time é calculada
com `foldr` (nunca com `maximum`, que quebra em lista vazia) e vale no mínimo 4,
a largura do cabeçalho. Lista vazia produz só o cabeçalho.

### Separação entre núcleo puro e IO

Toda a lógica, inclusive o texto do relatório (`demonstracao`), é pura e testada.
`main` é a única função do programa com IO: configura a saída e imprime o
relatório. Os dados ficam no código como `String`, como pede o enunciado
(playground sem entrada pelo teclado); não há `getLine`, `getContents` nem
`readFile`.

### Codificação da saída

Forçar UTF-8 (`hSetEncoding stdout utf8`) mostra acentos errados em consoles
Windows com página de código 850 ou 1252, e a codificação padrão do GHC lança
exceção ao imprimir um caractere que o terminal não representa. Por isso `main`
lê a codificação atual de `stdout` e a reaplica com o sufixo `//TRANSLIT`:
os acentos saem certos na codificação do terminal e, no pior caso, um caractere
não representável vira `?`. Conferi os bytes de saída com as páginas 850
(`á` = 0xA0), 1252 (0xE1) e UTF-8 (0xC3 0xA1). O programa de testes usa a mesma
configuração.

## 5. Imports

O enunciado lista `Data.List`, `Data.Char`, `Data.Maybe`, `Data.Either`,
`Data.Ord` e `Text.Read`. Além deles (todos de `base`):

- `Numeric (showFFloat)` em `Leitura.hs`: formata números com duas casas decimais
  sem recorrer a `Text.Printf`.
- `System.IO` em `Main.hs` e `Testes.hs`: `hGetEncoding`, `hSetEncoding` e
  `mkTextEncoding`, pelo motivo descrito em "Codificação da saída".
- `System.Exit (exitFailure)` em `Testes.hs`: o programa de testes termina com
  código diferente de zero se algum teste falhar.

Não há extensões de linguagem nem diretivas `OPTIONS_GHC`.

## 6. Testes

- `testar` é o do enunciado (`IO ()`, mesmas mensagens `OK`/`FALHOU`; na falha, a
  mensagem também mostra o valor esperado). Para contar falhas sem mudar a
  assinatura, cada teste é um par `(passou, testar ...)`, criado por `caso`.
- Cobertura: casos obrigatórios da seção 7 do enunciado; um teste por construtor
  de `Erro` (com mais de uma variante quando há); estritez de `readMaybe`
  (tabela da seção 4); CRLF, espaços sobrando, BOM; texto vazio e só com
  comentários; desempate por cada critério (pontos, vitórias, saldo, gols pró,
  nome); `ateRodada` em 0, negativo, 3, 5 e além do fim; `maiorGoleada` e
  `mediaGols` em lista vazia e com empate; tabela formatada com nome longo, curto
  e lista vazia; acentos.
- Os valores esperados das tabelas não foram copiados da saída do programa:
  vieram de um cálculo independente em outra linguagem (Python), feito a partir
  dos placares, e conferidos com a leitura manual das partidas.
- Verificações adicionais feitas fora do repositório: comparação da classificação
  com esse cálculo independente em 3.000 campeonatos aleatórios; 20.000 textos
  adversariais (lixo, caracteres de controle, números enormes, `\r`, BOM) sem
  nenhuma exceção; e teste de mutação (alterar de propósito critérios de
  desempate, `ateRodada`, validações, etc.) em que cada alteração relevante faz
  pelo menos um teste falhar.

## 7. Armadilhas do enunciado e como foram evitadas

| Armadilha | Como foi evitada |
|---|---|
| Partida como tupla | `Partida` e `Linha` são *records* |
| Resultado como `String`/`Int` | tipo soma `Resultado` |
| `head`/`maximum`/`foldr1` em lista vazia | `listToMaybe` após `sortBy`; guarda `null`; `foldr` com valor inicial |
| `div` no aproveitamento | `fromIntegral` e `/` |
| Ordenar só por pontos ou encadear `sortBy` | um `sortBy` com `comparing ... <> ...` e `Down` |
| Recursão explícita | `map`, `filter`, `foldl`, `foldr`, `sortBy`, `unfoldr` |
| `read` | `readMaybe` (e rigor adicional, seção 4) |
| `case` aninhados sobre `Either` | notação `do` e `traverse` |
| `getLine` no `main` | dados em `String`; núcleo puro separado do `main` |

## 8. Limitações conhecidas

- Nomes de time diferem por maiúsculas/minúsculas e acentos: "Parana" e "Paraná"
  são times distintos. Erros de digitação em nomes não são detectados.
- A ordem alfabética é por ponto de código (seção 2), não por regras de
  intercalação do português.
- Sem confronto direto, cartões ou outros critérios que dependam de dados que o
  formato não tem.
- Uma linha com vários problemas reporta apenas o primeiro (limitação do tipo
  `Either Erro Partida`). Erros entre linhas só são detectados sobre linhas
  válidas.
- Números acima de 1.000.000 em rodada e gols são rejeitados.
- Percentuais e médias usam ponto decimal (`3.07`), não vírgula.
- Finais de linha só com `\r` não são suportados (seção 4).
- `nub` é quadrático; para os tamanhos de um campeonato isso é irrelevante.
- `Partida` pode ser construída sem validação por quem usa o construtor
  diretamente (seção 2).
- Testado apenas com GHC 9.6.7 e 9.14.1, no Windows 11.
