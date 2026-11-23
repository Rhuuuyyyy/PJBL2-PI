# PjBL2 — Tabela de Classificação de Campeonato (Haskell)

Programa em Haskell que calcula a tabela de classificação de um campeonato de
futebol a partir dos resultados das partidas, em três camadas:

1. **Tipos e dados** — o domínio (`Partida`, `Linha`, `Resultado`) e consultas básicas.
2. **Classificação** — tabela e estatísticas usando só funções de ordem superior
   (`map`, `filter`, `foldl`, `sortBy`, composição), sem recursão explícita e sem funções parciais.
3. **Leitura, validação e saída** — leitura de texto com `readMaybe`, validação com
   `Either`/`Maybe`, relatório de erros e tabela formatada.

Usa apenas a biblioteca padrão (`base`). Os dados do campeonato estão no próprio
código, como `String` (`src/Dados.hs`); o programa não lê entrada do teclado.

## Ambiente

- GHC instalado localmente via GHCup. Versões testadas: **9.6.7** e **9.14.1**
  (compilação sem nenhum aviso com `-Wall -Wcompat -Wincomplete-patterns -Wincomplete-uni-patterns`
  nas duas; testes passando nas duas).
- Sistema usado nos testes: Windows 11.
- Não são necessários `cabal`, `stack` nem pacotes além do `base`.

## Como compilar e executar

Todos os comandos são executados na raiz do repositório.

Crie a pasta de saída uma vez (`mkdir build`; se ela já existir, ignore o aviso).

**Programa (demonstração das três camadas):**

```
ghc -Wall -isrc -outputdir build/obj-main -o build/campeonato src/Main.hs
./build/campeonato
```

**Testes:**

```
ghc -Wall -isrc -outputdir build/obj-testes -o build/testes tests/Testes.hs
./build/testes
```

No Windows (PowerShell ou Prompt de Comando) os executáveis ganham `.exe`:
`.\build\campeonato.exe` e `.\build\testes.exe`.

O programa de testes imprime `OK`/`FALHOU` para cada caso, um resumo no final e
termina com código de saída diferente de zero se algum teste falhar.

**Sem compilar** (mais lento, mas direto):

```
runghc -isrc src/Main.hs
runghc -isrc tests/Testes.hs
```

## Estrutura

```
src/
  Tipos.hs          Camada 1: tipos e consultas básicas
  Classificacao.hs  Camada 2: ordem superior
  Leitura.hs        Camada 3: Maybe, Either e formatação
  Dados.hs          campeonato de teste, como String
  Main.hs           demonstração das três camadas (única função com IO)
tests/
  Testes.hs         testes com resultado esperado
docs/
  decisoes.md       decisões de modelagem e limitações conhecidas
```

## Formato da entrada

Uma partida por linha, campos separados por `;`:

```
# rodada;mandante;gols mandante;gols visitante;visitante
1;Coritiba;2;2;Athletico
1;Paraná;0;0;Operário
```

Linhas em branco e linhas que começam com `#` são ignoradas. Espaços ao redor
dos campos e finais de linha do Windows (`\r\n`) são tolerados. Entrada inválida
nunca derruba o programa: resulta em `Left Erro`, com a linha ou a rodada do
problema (veja `docs/decisoes.md`).

## Critérios de classificação

Pontos (3/1/0), depois vitórias, saldo de gols, gols pró e, por fim, o nome do
time em ordem alfabética (ordem total e determinística).
