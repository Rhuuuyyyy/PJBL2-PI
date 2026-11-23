-- Demonstração das três camadas. Única parte do programa com IO.
module Main (main) where

import Numeric (showFFloat)
import System.IO (hGetEncoding, hSetEncoding, mkTextEncoding, stdout)

import Classificacao
import Dados (dadosCampeonato, dadosComErros)
import Leitura
import Tipos

-- | Relatório completo (puro): as três camadas sobre o campeonato válido,
-- mais o tratamento do texto com erros.
demonstracao :: String -> String -> String
demonstracao dadosValidos dadosInvalidos =
  unlines (either secaoErro secaoCampeonato (lerCampeonato dadosValidos) ++ secaoErros dadosInvalidos)

secaoErro :: Erro -> [String]
secaoErro erro = ["Erro ao ler o campeonato: " ++ descreverErro erro]

secaoCampeonato :: [Partida] -> [String]
secaoCampeonato partidas =
  [ "== Classificação final =="
  , tabelaFormatada (classificacao partidas)
  , "== Classificação após a rodada " ++ show rodadaIntermediaria ++ " =="
  , tabelaFormatada (classificacao (ateRodada rodadaIntermediaria partidas))
  , "== Estatísticas =="
  , "Maior goleada: " ++ maybe "nenhuma partida" descreverPartida (maiorGoleada partidas)
  , "Média de gols por partida: " ++ maybe "sem partidas" duasCasas (mediaGols partidas)
  , "Aproveitamento:"
  ]
    ++ map linhaDeAproveitamento (classificacao partidas)
    ++ [""]
  where
    rodadaIntermediaria = 3

descreverPartida :: Partida -> String
descreverPartida p =
  "rodada " ++ show (rodada p) ++ ", " ++ mandante p ++ " " ++ show (golsMandante p)
    ++ " x " ++ show (golsVisitante p) ++ " " ++ visitante p

-- | Número com duas casas decimais.
duasCasas :: Double -> String
duasCasas numero = showFFloat (Just 2) numero ""

linhaDeAproveitamento :: Linha -> String
linhaDeAproveitamento linha = "  " ++ time linha ++ ": " ++ duasCasas (aproveitamento linha) ++ "%"

secaoErros :: String -> [String]
secaoErros dados =
  [ "== Entrada com erros =="
  , "Primeiro erro (lerCampeonato): " ++ either descreverErro (const "nenhum") (lerCampeonato dados)
  , "Todos os erros (todosOsErros):"
  ]
    ++ map (("  - " ++) . descreverErro) (todosOsErros dados)

-- | Mantém a codificação do terminal (para os acentos aparecerem certos),
-- mas com transliteração: um caractere que ela não representa vira '?'
-- em vez de lançar exceção.
main :: IO ()
main = do
  atual <- hGetEncoding stdout
  mapM_ (\e -> mkTextEncoding (show e ++ "//TRANSLIT") >>= hSetEncoding stdout) atual
  putStr (demonstracao dadosCampeonato dadosComErros)
