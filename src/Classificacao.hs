-- Camada 2: classificação e estatísticas com funções de ordem superior.
module Classificacao
  ( pontos
  , linhaDoTime
  , pontosLinha
  , saldo
  , aproveitamento
  , classificacao
  , ateRodada
  , maiorGoleada
  , mediaGols
  ) where

import Data.List (sortBy)
import Data.Maybe (listToMaybe)
import Data.Ord (Down (..), comparing)

import Tipos

-- | Pontos de um resultado: 3 pela vitória, 1 pelo empate, 0 pela derrota.
pontos :: Resultado -> Int
pontos Vitoria = 3
pontos Empate  = 1
pontos Derrota = 0

-- | Linha da tabela de um time, acumulada com 'foldl' sobre as partidas.
linhaDoTime :: [Partida] -> Time -> Linha
linhaDoTime ps t = foldl (acumula t) (Linha t 0 0 0 0 0 0) ps

-- | Soma à linha a partida do time (partidas em que ele não jogou não alteram nada).
acumula :: Time -> Linha -> Partida -> Linha
acumula t linha p = maybe linha (registra linha) (golsDoTime t p)

-- | Registra uma partida em que o time marcou e sofreu os gols informados.
registra :: Linha -> (Int, Int) -> Linha
registra linha (pro, contra) =
  (contabiliza (resultadoPorGols pro contra) linha)
    { jogos      = jogos linha + 1
    , golsPro    = golsPro linha + pro
    , golsContra = golsContra linha + contra
    }

-- | Incrementa o contador (vitórias, empates ou derrotas) do resultado.
contabiliza :: Resultado -> Linha -> Linha
contabiliza Vitoria linha = linha { vitorias = vitorias linha + 1 }
contabiliza Empate  linha = linha { empates  = empates linha + 1 }
contabiliza Derrota linha = linha { derrotas = derrotas linha + 1 }

-- | Pontos ganhos pelo time, a partir dos seus resultados.
pontosLinha :: Linha -> Int
pontosLinha linha =
  vitorias linha * pontos Vitoria
    + empates linha * pontos Empate
    + derrotas linha * pontos Derrota

-- | Saldo de gols: gols pró menos gols contra.
saldo :: Linha -> Int
saldo linha = golsPro linha - golsContra linha

-- | Percentual (0 a 100) dos pontos disputados que o time conquistou;
-- 0 se o time ainda não jogou.
aproveitamento :: Linha -> Double
aproveitamento linha
  | jogos linha == 0 = 0
  | otherwise        = 100 * fromIntegral (pontosLinha linha) / fromIntegral disputados
  where
    disputados = jogos linha * pontos Vitoria

-- | Tabela completa. Critérios, nesta ordem: mais pontos, mais vitórias,
-- maior saldo de gols, mais gols pró e, por fim, nome do time (ordem alfabética).
classificacao :: [Partida] -> [Linha]
classificacao ps = sortBy criterios (map (linhaDoTime ps) (times ps))
  where
    criterios =
      comparing (Down . pontosLinha)
        <> comparing (Down . vitorias)
        <> comparing (Down . saldo)
        <> comparing (Down . golsPro)
        <> comparing time

-- | Apenas as partidas disputadas até a rodada informada (inclusive).
ateRodada :: Int -> [Partida] -> [Partida]
ateRodada n = filter ((<= n) . rodada)

-- | Partida com a maior diferença de gols (a primeira, em caso de empate
-- nesse critério); 'Nothing' para lista vazia.
maiorGoleada :: [Partida] -> Maybe Partida
maiorGoleada = listToMaybe . sortBy (comparing (Down . diferenca))
  where
    diferenca p = abs (golsMandante p - golsVisitante p)

-- | Média de gols por partida; 'Nothing' para lista vazia.
mediaGols :: [Partida] -> Maybe Double
mediaGols ps
  | null ps   = Nothing
  | otherwise = Just (fromIntegral totalDeGols / fromIntegral (length ps))
  where
    totalDeGols = foldr ((+) . golsNaPartida) 0 ps
    golsNaPartida p = golsMandante p + golsVisitante p
