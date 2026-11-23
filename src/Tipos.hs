-- Camada 1: tipos e consultas básicas sobre partidas.
module Tipos
  ( Time
  , Resultado (..)
  , Partida (..)
  , Linha (..)
  , golsDoTime
  , participou
  , resultadoPara
  , resultadoPorGols
  , times
  ) where

import Data.List (nub, sort)

-- | Nome de um time.
type Time = String

-- | Resultado de uma partida do ponto de vista de um time.
data Resultado = Vitoria | Empate | Derrota
  deriving (Show, Eq)

-- | Uma partida jogada. O mandante vem antes do visitante, como na tabela.
data Partida = Partida
  { rodada        :: Int
  , mandante      :: Time
  , golsMandante  :: Int
  , golsVisitante :: Int
  , visitante     :: Time
  } deriving (Show, Eq)

-- | Uma linha da tabela de classificação.
data Linha = Linha
  { time         :: Time
  , jogos        :: Int
  , vitorias     :: Int
  , empates      :: Int
  , derrotas     :: Int
  , golsPro      :: Int
  , golsContra   :: Int
  } deriving (Show, Eq)

-- | Gols marcados e sofridos pelo time na partida; 'Nothing' se ele não jogou.
golsDoTime :: Time -> Partida -> Maybe (Int, Int)
golsDoTime t p
  | t == mandante p  = Just (golsMandante p, golsVisitante p)
  | t == visitante p = Just (golsVisitante p, golsMandante p)
  | otherwise        = Nothing

-- | Verdadeiro se o time jogou a partida (como mandante ou visitante).
participou :: Time -> Partida -> Bool
participou t p = t == mandante p || t == visitante p

-- | Resultado de quem marcou @pro@ gols e sofreu @contra@ gols.
resultadoPorGols :: Int -> Int -> Resultado
resultadoPorGols pro contra = case compare pro contra of
  GT -> Vitoria
  EQ -> Empate
  LT -> Derrota

-- | Resultado da partida do ponto de vista do time; 'Nothing' se ele não jogou.
resultadoPara :: Time -> Partida -> Maybe Resultado
resultadoPara t p = uncurry resultadoPorGols <$> golsDoTime t p

-- | Todos os times do campeonato, sem repetição e em ordem alfabética.
times :: [Partida] -> [Time]
times = nub . sort . concatMap (\p -> [mandante p, visitante p])
