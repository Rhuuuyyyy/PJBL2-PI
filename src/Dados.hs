-- Dados do campeonato de teste: 6 times, 5 rodadas, 15 partidas.
module Dados
  ( dadosCampeonato
  , campeonatoTeste
  , dadosComErros
  ) where

import Tipos

-- | Campeonato de teste em formato de texto (como chegaria à Camada 3).
-- Contém um 0 x 0 (rodada 1), goleadas de 4 x 0 (rodada 2) e empates em
-- pontos na classificação final.
dadosCampeonato :: String
dadosCampeonato = unlines
  [ "# rodada;mandante;gols mandante;gols visitante;visitante"
  , "1;Coritiba;1;0;Athletico"
  , "1;Paraná;0;0;Operário"
  , "1;Londrina;4;3;Cianorte"
  , "2;Paraná;4;2;Coritiba"
  , "2;Athletico;2;0;Londrina"
  , "2;Cianorte;4;0;Operário"
  , "3;Coritiba;1;1;Operário"
  , "3;Athletico;1;3;Cianorte"
  , "3;Paraná;4;2;Londrina"
  , "4;Londrina;2;1;Coritiba"
  , "4;Athletico;1;1;Operário"
  , "4;Paraná;1;1;Cianorte"
  , "5;Coritiba;1;0;Cianorte"
  , "5;Paraná;1;3;Athletico"
  , "5;Londrina;0;2;Operário"
  ]

-- | O mesmo campeonato, escrito diretamente com o construtor 'Partida'.
-- Serve de conferência cruzada para a leitura do texto.
campeonatoTeste :: [Partida]
campeonatoTeste =
  [ Partida 1 "Coritiba" 1 0 "Athletico"
  , Partida 1 "Paraná" 0 0 "Operário"
  , Partida 1 "Londrina" 4 3 "Cianorte"
  , Partida 2 "Paraná" 4 2 "Coritiba"
  , Partida 2 "Athletico" 2 0 "Londrina"
  , Partida 2 "Cianorte" 4 0 "Operário"
  , Partida 3 "Coritiba" 1 1 "Operário"
  , Partida 3 "Athletico" 1 3 "Cianorte"
  , Partida 3 "Paraná" 4 2 "Londrina"
  , Partida 4 "Londrina" 2 1 "Coritiba"
  , Partida 4 "Athletico" 1 1 "Operário"
  , Partida 4 "Paraná" 1 1 "Cianorte"
  , Partida 5 "Coritiba" 1 0 "Cianorte"
  , Partida 5 "Paraná" 1 3 "Athletico"
  , Partida 5 "Londrina" 0 2 "Operário"
  ]

-- | Texto com erros de digitação para a demonstração do tratamento de erros:
-- placar não numérico (linha 3), time contra si mesmo (linha 4), campos a
-- menos (linha 5), placar negativo (linha 6) e time repetido na rodada 2
-- (linhas 7 e 8).
dadosComErros :: String
dadosComErros = unlines
  [ "# rodada;mandante;gols mandante;gols visitante;visitante"
  , "1;Coritiba;1;0;Athletico"
  , "1;Paraná;dois;0;Operário"
  , "1;Londrina;2;2;Londrina"
  , "2;Cianorte;1;0"
  , "2;Athletico;-1;0;Coritiba"
  , "2;Paraná;1;1;Operário"
  , "2;Coritiba;0;0;Paraná"
  ]
