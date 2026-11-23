-- Testes com resultado esperado. Os valores esperados das tabelas foram
-- conferidos à mão e por um cálculo independente (fora do Haskell).
module Main (main) where

import Data.List (isInfixOf, nub)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stdout, utf8)

import Classificacao
import Dados
import Leitura
import Tipos

-- | Compara o obtido com o esperado e imprime o resultado.
testar :: (Eq a, Show a) => String -> a -> a -> IO ()
testar nome obtido esperado
  | obtido == esperado = putStrLn ("OK      " ++ nome)
  | otherwise          = putStrLn ("FALHOU  " ++ nome ++ ": " ++ show obtido ++ " (esperado: " ++ show esperado ++ ")")

-- | Um teste: se passou e a ação que o imprime (via 'testar').
type Teste = (Bool, IO ())

caso :: (Eq a, Show a) => String -> a -> a -> Teste
caso nome obtido esperado = (obtido == esperado, testar nome obtido esperado)

-- | Igualdade de 'Double' com tolerância.
quase :: Double -> Double -> Bool
quase a b = abs (a - b) < 1e-9

casoQuase :: String -> Maybe Double -> Maybe Double -> Teste
casoQuase nome obtido esperado = caso nome (fmap arredonda obtido) (fmap arredonda esperado)
  where
    arredonda x = fromIntegral (round (x * 1e6) :: Integer) / 1e6 :: Double

-- ---------------------------------------------------------------------
-- Dados auxiliares

exemplo :: Partida
exemplo = Partida 1 "Coritiba" 2 1 "Athletico"

linhaVazia :: Time -> Linha
linhaVazia t = Linha t 0 0 0 0 0 0

-- | Campeonato mínimo para os critérios de desempate: dois times por critério.
-- X e Y empatam em pontos, vitórias e saldo (decide golsPro); Z e W idem.
campeonatoGolsPro :: [Partida]
campeonatoGolsPro = [Partida 1 "X" 3 2 "Z", Partida 1 "Y" 1 0 "W"]

-- | Dois times com campanhas idênticas: só o nome desempata.
campeonatoSoNome :: [Partida]
campeonatoSoNome = [Partida 1 "Beta" 1 1 "Alfa"]

-- | Mesmo campeonato com finais de linha do Windows.
comCRLF :: String -> String
comCRLF = concatMap (\c -> if c == '\n' then "\r\n" else [c])

-- | Texto com 4 linhas inválidas de tipos diferentes e uma repetição na rodada.
textoVariosErros :: String
textoVariosErros = unlines
  [ "1;A;1;0;B"
  , "1;C;dois;0;D"
  , ""
  , "# comentário"
  , "2;E;1;1;E"
  , "2;F;1;0"
  , "3;G;-2;0;H"
  , "4;I;1;0;J"
  , "4;K;0;0;I"
  ]

-- ---------------------------------------------------------------------
-- Camada 1

testesCamada1 :: [Teste]
testesCamada1 =
  [ caso "resultadoPara mandante vencedor" (resultadoPara "Coritiba" exemplo) (Just Vitoria)
  , caso "resultadoPara visitante perdedor" (resultadoPara "Athletico" exemplo) (Just Derrota)
  , caso "resultadoPara time que não jogou" (resultadoPara "Paraná" exemplo) Nothing
  , caso "resultadoPara empate (mandante)" (resultadoPara "A" (Partida 1 "A" 0 0 "B")) (Just Empate)
  , caso "resultadoPara empate (visitante)" (resultadoPara "B" (Partida 1 "A" 0 0 "B")) (Just Empate)
  , caso "resultadoPara derrota do mandante" (resultadoPara "A" (Partida 1 "A" 0 3 "B")) (Just Derrota)
  , caso "resultadoPara vitória do visitante" (resultadoPara "B" (Partida 1 "A" 0 3 "B")) (Just Vitoria)
  , caso "participou mandante" (participou "Coritiba" exemplo) True
  , caso "participou visitante" (participou "Athletico" exemplo) True
  , caso "participou time ausente" (participou "Paraná" exemplo) False
  , caso "times do campeonato de teste, sem repetição e em ordem alfabética"
      (times campeonatoTeste) ["Athletico", "Cianorte", "Coritiba", "Londrina", "Operário", "Paraná"]
  , caso "times de lista vazia" (times []) []
  , caso "times com a mesma partida repetida" (times [exemplo, exemplo]) ["Athletico", "Coritiba"]
  , caso "campeonato de teste tem 15 partidas" (length campeonatoTeste) 15
  , caso "campeonato de teste tem 6 times" (length (times campeonatoTeste)) 6
  , caso "campeonato de teste tem 5 rodadas" (nub (map rodada campeonatoTeste)) [1, 2, 3, 4, 5]
  , caso "ninguém joga duas vezes na mesma rodada"
      (all semRepeticao [1 .. 5]) True
  , caso "existe um 0 x 0" (any (\p -> golsMandante p == 0 && golsVisitante p == 0) campeonatoTeste) True
  , caso "existe vitória por 3 ou mais gols"
      (any (\p -> abs (golsMandante p - golsVisitante p) >= 3) campeonatoTeste) True
  , caso "texto de dados e lista de partidas coincidem" (lerCampeonato dadosCampeonato) (Right campeonatoTeste)
  ]
  where
    semRepeticao r =
      let escalados = concatMap (\p -> [mandante p, visitante p]) (filter ((== r) . rodada) campeonatoTeste)
       in length escalados == length (nub escalados)

-- ---------------------------------------------------------------------
-- Camada 2

tabelaFinal :: [Linha]
tabelaFinal =
  [ Linha "Paraná" 5 2 2 1 10 8
  , Linha "Cianorte" 5 2 1 2 11 7
  , Linha "Athletico" 5 2 1 2 7 6
  , Linha "Coritiba" 5 2 1 2 6 7
  , Linha "Londrina" 5 2 0 3 8 12
  , Linha "Operário" 5 1 3 1 4 6
  ]

tabelaRodada3 :: [Linha]
tabelaRodada3 =
  [ Linha "Paraná" 3 2 1 0 8 4
  , Linha "Cianorte" 3 2 0 1 10 5
  , Linha "Coritiba" 3 1 1 1 4 5
  , Linha "Athletico" 3 1 0 2 3 4
  , Linha "Londrina" 3 1 0 2 6 9
  , Linha "Operário" 3 0 2 1 1 5
  ]

tabelaRodada1 :: [Linha]
tabelaRodada1 =
  [ Linha "Londrina" 1 1 0 0 4 3
  , Linha "Coritiba" 1 1 0 0 1 0
  , Linha "Operário" 1 0 1 0 0 0
  , Linha "Paraná" 1 0 1 0 0 0
  , Linha "Cianorte" 1 0 0 1 3 4
  , Linha "Athletico" 1 0 0 1 0 1
  ]

testesCamada2 :: [Teste]
testesCamada2 =
  [ caso "pontos: vitória" (pontos Vitoria) 3
  , caso "pontos: empate" (pontos Empate) 1
  , caso "pontos: derrota" (pontos Derrota) 0
  , caso "linhaDoTime de Paraná" (linhaDoTime campeonatoTeste "Paraná") (Linha "Paraná" 5 2 2 1 10 8)
  , caso "linhaDoTime de time que não jogou" (linhaDoTime campeonatoTeste "Fantasma") (linhaVazia "Fantasma")
  , caso "linhaDoTime sem partidas" (linhaDoTime [] "Coritiba") (linhaVazia "Coritiba")
  , caso "pontosLinha de Paraná (2 V, 2 E)" (pontosLinha (Linha "Paraná" 5 2 2 1 10 8)) 8
  , caso "pontosLinha de linha vazia" (pontosLinha (linhaVazia "X")) 0
  , caso "saldo positivo" (saldo (Linha "Paraná" 5 2 2 1 10 8)) 2
  , caso "saldo negativo" (saldo (Linha "Londrina" 5 2 0 3 8 12)) (-4)
  , caso "saldo zerado" (saldo (linhaVazia "X")) 0
  , caso "aproveitamento de time sem jogos" (aproveitamento (linhaVazia "X")) 0
  , caso "aproveitamento 100% (só vitórias)" (aproveitamento (Linha "X" 2 2 0 0 4 0)) 100
  , caso "aproveitamento 0% (só derrotas)" (aproveitamento (Linha "X" 2 0 0 2 0 4)) 0
  , caso "aproveitamento de Paraná (8 de 15 pontos)"
      (quase (aproveitamento (Linha "Paraná" 5 2 2 1 10 8)) (100 * 8 / 15)) True
  , caso "aproveitamento de Londrina (6 de 15 pontos)"
      (quase (aproveitamento (Linha "Londrina" 5 2 0 3 8 12)) 40) True
  , caso "classificacao completa do campeonato de teste" (classificacao campeonatoTeste) tabelaFinal
  , caso "classificacao de lista vazia" (classificacao []) []
  , caso "classificacao não depende da ordem das partidas" (classificacao (reverse campeonatoTeste)) tabelaFinal
  , caso "desempate por saldo: Cianorte, Athletico e Coritiba (7 pontos, 2 vitórias)"
      (map time (take 3 (drop 1 (classificacao campeonatoTeste)))) ["Cianorte", "Athletico", "Coritiba"]
  , caso "desempate por vitórias: Londrina (2 V) à frente de Operário (1 V), ambos com 6 pontos"
      (map (\l -> (time l, pontosLinha l, vitorias l)) (drop 4 (classificacao campeonatoTeste)))
      [("Londrina", 6, 2), ("Operário", 6, 1)]
  , caso "desempate por gols pró (pontos, vitórias e saldo iguais)"
      (map time (classificacao campeonatoGolsPro)) ["X", "Y", "Z", "W"]
  , caso "desempate pelo nome (campanhas idênticas)" (map time (classificacao campeonatoSoNome)) ["Alfa", "Beta"]
  , caso "desempate pelo nome na rodada 1 do campeonato de teste (Operário antes de Paraná)"
      (map time (drop 2 (take 4 (classificacao (ateRodada 1 campeonatoTeste))))) ["Operário", "Paraná"]
  , caso "ateRodada 0 não tem partidas" (ateRodada 0 campeonatoTeste) []
  , caso "ateRodada negativa não tem partidas" (ateRodada (-3) campeonatoTeste) []
  , caso "ateRodada 3 tem 9 partidas" (length (ateRodada 3 campeonatoTeste)) 9
  , caso "ateRodada 5 é o campeonato todo" (ateRodada 5 campeonatoTeste) campeonatoTeste
  , caso "ateRodada além da última é o campeonato todo" (ateRodada 99 campeonatoTeste) campeonatoTeste
  , caso "ateRodada de lista vazia" (ateRodada 3 []) []
  , caso "classificacao após a rodada 3" (classificacao (ateRodada 3 campeonatoTeste)) tabelaRodada3
  , caso "classificacao após a rodada 1" (classificacao (ateRodada 1 campeonatoTeste)) tabelaRodada1
  , caso "classificacao na rodada 3 difere da final"
      (classificacao (ateRodada 3 campeonatoTeste) /= classificacao campeonatoTeste) True
  , caso "3º colocado muda entre a rodada 3 (Coritiba) e o final (Athletico)"
      (map (\ps -> map time (take 1 (drop 2 (classificacao ps)))) [ateRodada 3 campeonatoTeste, campeonatoTeste])
      [["Coritiba"], ["Athletico"]]
  , caso "maiorGoleada []" (maiorGoleada []) Nothing
  , caso "maiorGoleada do campeonato de teste" (maiorGoleada campeonatoTeste) (Just (Partida 2 "Cianorte" 4 0 "Operário"))
  , caso "maiorGoleada com vitória do visitante" (maiorGoleada [Partida 1 "A" 1 0 "B", Partida 2 "C" 0 5 "D"])
      (Just (Partida 2 "C" 0 5 "D"))
  , caso "maiorGoleada empatada: fica a primeira"
      (maiorGoleada [Partida 1 "A" 2 0 "B", Partida 2 "C" 0 2 "D"]) (Just (Partida 1 "A" 2 0 "B"))
  , caso "maiorGoleada de uma só partida 0 x 0" (maiorGoleada [Partida 1 "A" 0 0 "B"]) (Just (Partida 1 "A" 0 0 "B"))
  , casoQuase "mediaGols []" (mediaGols []) Nothing
  , casoQuase "mediaGols do campeonato de teste (46 gols em 15 partidas)" (mediaGols campeonatoTeste) (Just (46 / 15))
  , casoQuase "mediaGols de uma partida 2 x 1" (mediaGols [exemplo]) (Just 3)
  , casoQuase "mediaGols de 0 x 0" (mediaGols [Partida 1 "A" 0 0 "B"]) (Just 0)
  ]

-- ---------------------------------------------------------------------
-- Camada 3

-- | Tabela final formatada, conferida contra o cálculo independente.
textoTabelaFinal :: String
textoTabelaFinal = unlines
  [ "Pos Time      Pts   J   V   E   D  SG"
  , "  1 Paraná      8   5   2   2   1   2"
  , "  2 Cianorte    7   5   2   1   2   4"
  , "  3 Athletico   7   5   2   1   2   1"
  , "  4 Coritiba    7   5   2   1   2  -1"
  , "  5 Londrina    6   5   2   0   3  -4"
  , "  6 Operário    6   5   1   3   1  -2"
  ]

testesCamada3 :: [Teste]
testesCamada3 =
  [ caso "separar divide nos separadores" (separar ';' "a;b;c") ["a", "b", "c"]
  , caso "separar preserva campos vazios" (separar ';' "a;;b;") ["a", "", "b", ""]
  , caso "separar de texto vazio" (separar ';' "") [""]
  , caso "separar só o separador" (separar ';' ";") ["", ""]
  , caso "separar sem separador" (separar ';' "abc") ["abc"]
  , caso "lerPartida do exemplo do PDF" (lerPartida 1 "1;Coritiba;2;2;Athletico") (Right (Partida 1 "Coritiba" 2 2 "Athletico"))
  , caso "lerPartida com acentos" (lerPartida 3 "1;Paraná;0;0;Operário") (Right (Partida 1 "Paraná" 0 0 "Operário"))
  , caso "lerPartida com espaços sobrando" (lerPartida 1 "  1 ; Coritiba ;2 ; 1;  Athletico  ")
      (Right (Partida 1 "Coritiba" 2 1 "Athletico"))
  , caso "lerPartida com '\\r' final (Windows)" (lerPartida 1 "1;Coritiba;2;1;Athletico\r")
      (Right (Partida 1 "Coritiba" 2 1 "Athletico"))
  , caso "lerPartida preserva espaços internos do nome" (lerPartida 1 "1;Atlético  Mineiro;1;0;B")
      (Right (Partida 1 "Atlético  Mineiro" 1 0 "B"))
  , caso "lerCampeonato do campeonato de teste" (lerCampeonato dadosCampeonato) (Right campeonatoTeste)
  , caso "lerCampeonato com finais de linha do Windows" (lerCampeonato (comCRLF dadosCampeonato)) (Right campeonatoTeste)
  , caso "lerCampeonato de texto vazio" (lerCampeonato "") (Right [])
  , caso "lerCampeonato só com comentários e linhas em branco" (lerCampeonato "# nada\n\n   \n  # aqui também\n") (Right [])
  , caso "lerCampeonato sem '\\n' no fim" (lerCampeonato "1;A;1;0;B") (Right [Partida 1 "A" 1 0 "B"])
  , caso "tabela do campeonato lido é a esperada" (fmap classificacao (lerCampeonato dadosCampeonato)) (Right tabelaFinal)
  -- Um teste para cada construtor de Erro
  , caso "Erro CamposInvalidos (campos a menos)" (lerPartida 7 "1;A;2") (Left (CamposInvalidos 7 3))
  , caso "Erro CamposInvalidos (campos a mais)" (lerPartida 2 "1;A;1;0;B;extra") (Left (CamposInvalidos 2 6))
  , caso "Erro CamposInvalidos (linha sem separador)" (lerPartida 4 "lixo") (Left (CamposInvalidos 4 1))
  , caso "Erro NumeroInvalido (placar \"dois\")" (lerPartida 5 "1;A;dois;0;B") (Left (NumeroInvalido 5 (CampoGols Mandante) "dois"))
  , caso "Erro NumeroInvalido (gols do visitante)" (lerPartida 5 "1;A;1;2a;B") (Left (NumeroInvalido 5 (CampoGols Visitante) "2a"))
  , caso "Erro NumeroInvalido (rodada)" (lerPartida 5 "x;A;1;0;B") (Left (NumeroInvalido 5 CampoRodada "x"))
  , caso "Erro PlacarNegativo (mandante)" (lerPartida 6 "1;A;-1;0;B") (Left (PlacarNegativo 6 Mandante (-1)))
  , caso "Erro PlacarNegativo (visitante)" (lerPartida 6 "1;A;1;-4;B") (Left (PlacarNegativo 6 Visitante (-4)))
  , caso "Erro RodadaInvalida (zero)" (lerPartida 8 "0;A;1;0;B") (Left (RodadaInvalida 8 0))
  , caso "Erro RodadaInvalida (negativa)" (lerPartida 8 "-2;A;1;0;B") (Left (RodadaInvalida 8 (-2)))
  , caso "Erro TimeVazio (mandante)" (lerPartida 9 "1; ;1;0;B") (Left (TimeVazio 9 Mandante))
  , caso "Erro TimeVazio (visitante)" (lerPartida 9 "1;A;1;0;") (Left (TimeVazio 9 Visitante))
  , caso "Erro MesmoTime" (lerPartida 3 "1;Coritiba;1;0;Coritiba") (Left (MesmoTime 3 "Coritiba"))
  , caso "Erro MesmoTime ignora espaços sobrando" (lerPartida 3 "1;Coritiba;1;0; Coritiba ") (Left (MesmoTime 3 "Coritiba"))
  , caso "Erro TimeRepetidoNaRodada (como mandante e visitante)"
      (lerCampeonato "1;A;1;0;B\n1;C;0;0;A") (Left (TimeRepetidoNaRodada 1 "A"))
  , caso "Erro TimeRepetidoNaRodada (duas vezes como mandante)"
      (lerCampeonato "1;A;1;0;B\n1;A;0;0;C") (Left (TimeRepetidoNaRodada 1 "A"))
  , caso "mesmo time em rodadas diferentes é válido"
      (lerCampeonato "1;A;1;0;B\n2;A;0;0;C") (Right [Partida 1 "A" 1 0 "B", Partida 2 "A" 0 0 "C"])
  -- Rigor da conversão de números
  , caso "número: '+3' é rejeitado" (lerPartida 1 "1;A;+3;0;B") (Left (NumeroInvalido 1 (CampoGols Mandante) "+3"))
  , caso "número: '0x10' é rejeitado" (lerPartida 1 "1;A;0x10;0;B") (Left (NumeroInvalido 1 (CampoGols Mandante) "0x10"))
  , caso "número: '1e3' é rejeitado" (lerPartida 1 "1;A;1e3;0;B") (Left (NumeroInvalido 1 (CampoGols Mandante) "1e3"))
  , caso "número: '3.0' é rejeitado" (lerPartida 1 "1;A;3.0;0;B") (Left (NumeroInvalido 1 (CampoGols Mandante) "3.0"))
  , caso "número: '0o7' é rejeitado" (lerPartida 1 "1;A;0o7;0;B") (Left (NumeroInvalido 1 (CampoGols Mandante) "0o7"))
  , caso "número: '(3)' é rejeitado" (lerPartida 1 "1;A;(3);0;B") (Left (NumeroInvalido 1 (CampoGols Mandante) "(3)"))
  , caso "número: '- 1' é rejeitado" (lerPartida 1 "1;A;- 1;0;B") (Left (NumeroInvalido 1 (CampoGols Mandante) "- 1"))
  , caso "número: campo vazio é rejeitado" (lerPartida 1 "1;A;;0;B") (Left (NumeroInvalido 1 (CampoGols Mandante) ""))
  , caso "número: '-' sozinho é rejeitado" (lerPartida 1 "1;A;-;0;B") (Left (NumeroInvalido 1 (CampoGols Mandante) "-"))
  , caso "número: '--1' é rejeitado" (lerPartida 1 "1;A;--1;0;B") (Left (NumeroInvalido 1 (CampoGols Mandante) "--1"))
  , caso "número: dígitos de outro alfabeto são rejeitados" (lerPartida 1 "1;A;\1635;0;B")
      (Left (NumeroInvalido 1 (CampoGols Mandante) "\1635"))
  , caso "número: '007' vale 7" (lerPartida 1 "1;A;007;0;B") (Right (Partida 1 "A" 7 0 "B"))
  , caso "número: '-0' vale 0" (lerPartida 1 "1;A;-0;0;B") (Right (Partida 1 "A" 0 0 "B"))
  , caso "número: 1000000 (limite) é aceito" (lerPartida 1 "1;A;1000000;0;B") (Right (Partida 1 "A" 1000000 0 "B"))
  , caso "número: 1000001 é rejeitado" (lerPartida 1 "1;A;1000001;0;B")
      (Left (NumeroInvalido 1 (CampoGols Mandante) "1000001"))
  , caso "número: valor enorme é rejeitado, sem estourar Int"
      (lerPartida 1 "1;A;99999999999999999999;0;B")
      (Left (NumeroInvalido 1 (CampoGols Mandante) "99999999999999999999"))
  , caso "número: negativo enorme é rejeitado (não vira PlacarNegativo)"
      (lerPartida 1 "1;A;-99999999999999999999;0;B")
      (Left (NumeroInvalido 1 (CampoGols Mandante) "-99999999999999999999"))
  -- Parada no primeiro erro e numeração das linhas
  , caso "lerCampeonato para no primeiro erro" (lerCampeonato textoVariosErros) (Left (NumeroInvalido 2 (CampoGols Mandante) "dois"))
  , caso "número da linha conta comentários e linhas em branco"
      (lerCampeonato "# c\n\n1;A;1;0;B\n1;C;x;0;D") (Left (NumeroInvalido 4 (CampoGols Mandante) "x"))
  , caso "lerCampeonato aceita linha em branco com '\\r'" (lerCampeonato "\r\n1;A;1;0;B\r\n\r\n") (Right [Partida 1 "A" 1 0 "B"])
  -- todosOsErros
  , caso "todosOsErros de texto válido" (todosOsErros dadosCampeonato) []
  , caso "todosOsErros de texto vazio" (todosOsErros "") []
  , caso "todosOsErros lista todos os erros, inclusive entre linhas"
      (todosOsErros textoVariosErros)
      [ NumeroInvalido 2 (CampoGols Mandante) "dois"
      , MesmoTime 5 "E"
      , CamposInvalidos 6 4
      , PlacarNegativo 7 Mandante (-2)
      , TimeRepetidoNaRodada 4 "I"
      ]
  , caso "todosOsErros dos dados de demonstração"
      (todosOsErros dadosComErros)
      [ NumeroInvalido 3 (CampoGols Mandante) "dois"
      , MesmoTime 4 "Londrina"
      , CamposInvalidos 5 4
      , PlacarNegativo 6 Mandante (-1)
      , TimeRepetidoNaRodada 2 "Paraná"
      ]
  , caso "todosOsErros com três linhas inválidas"
      (todosOsErros "a;b\n1;A;x;0;B\n1;C;1;0;C")
      [CamposInvalidos 1 2, NumeroInvalido 2 (CampoGols Mandante) "x", MesmoTime 3 "C"]
  , caso "lerCampeonato inválido: primeiro erro é o primeiro de todosOsErros"
      (either Just (const Nothing) (lerCampeonato textoVariosErros), take 1 (todosOsErros textoVariosErros))
      (Just (NumeroInvalido 2 (CampoGols Mandante) "dois"), [NumeroInvalido 2 (CampoGols Mandante) "dois"])
  -- Saída
  , caso "tabelaFormatada da classificação final" (tabelaFormatada (classificacao campeonatoTeste)) textoTabelaFinal
  , caso "tabelaFormatada de lista vazia (só cabeçalho)" (tabelaFormatada []) "Pos Time Pts   J   V   E   D  SG\n"
  , caso "tabelaFormatada com nome longo alinha as colunas"
      (tabelaFormatada [Linha "Sociedade Esportiva" 1 1 0 0 2 0])
      (unlines ["Pos Time                Pts   J   V   E   D  SG", "  1 Sociedade Esportiva   3   1   1   0   0   2"])
  , caso "demonstração mostra nomes com acento" (all (`isInfixOf` demonstracao dadosCampeonato dadosComErros) ["Paraná", "Operário"]) True
  , caso "demonstração mostra a tabela final" (textoTabelaFinal `isInfixOf` demonstracao dadosCampeonato dadosComErros) True
  , caso "demonstração mostra a mensagem de erro com a linha"
      ("linha 3: gols do mandante \"dois\"" `isInfixOf` demonstracao dadosCampeonato dadosComErros) True
  , caso "demonstração com dados inválidos não quebra" (null (demonstracao dadosComErros dadosComErros)) False
  , caso "descreverErro de MesmoTime" (descreverErro (MesmoTime 4 "Londrina")) "linha 4: Londrina não pode jogar contra si mesmo"
  , caso "descreverErro de TimeRepetidoNaRodada"
      (descreverErro (TimeRepetidoNaRodada 2 "Paraná")) "rodada 2: Paraná aparece em mais de uma partida"
  , caso "todo erro tem descrição não vazia"
      (all (not . null . descreverErro)
        [ CamposInvalidos 1 2, NumeroInvalido 1 CampoRodada "x", PlacarNegativo 1 Visitante (-1)
        , RodadaInvalida 1 0, TimeVazio 1 Mandante, MesmoTime 1 "A", TimeRepetidoNaRodada 1 "A" ])
      True
  , caso "BOM no início da linha é ignorado" (lerPartida 1 ("\65279" ++ "1;A;1;0;B")) (Right (Partida 1 "A" 1 0 "B"))
  , caso "linha só com BOM conta como um campo vazio" (lerPartida 1 "\65279") (Left (CamposInvalidos 1 1))
  , caso "lerCampeonato trata linha só com BOM como linha em branco" (lerCampeonato "\65279\n1;A;1;0;B") (Right [Partida 1 "A" 1 0 "B"])
  ]

-- ---------------------------------------------------------------------

main :: IO ()
main = do
  hSetEncoding stdout utf8
  let secoes =
        [ ("Camada 1", testesCamada1)
        , ("Camada 2", testesCamada2)
        , ("Camada 3", testesCamada3)
        ]
  mapM_ (\(titulo, testes) -> putStrLn ("\n== " ++ titulo ++ " ==") >> mapM_ snd testes) secoes
  let todos = concatMap snd secoes
      falhas = length (filter (not . fst) todos)
  putStrLn ("\nTotal: " ++ show (length todos) ++ " testes, " ++ show (length todos - falhas) ++ " passaram, " ++ show falhas ++ " falharam.")
  if falhas == 0 then putStrLn "TODOS OS TESTES PASSARAM" else exitFailure
