-- Demonstração das três camadas. Única parte do programa com IO.
module Main (main) where

import System.IO (hSetEncoding, stdout, utf8)

import Dados (dadosCampeonato, dadosComErros)
import Leitura (demonstracao)

main :: IO ()
main = do
  hSetEncoding stdout utf8
  putStr (demonstracao dadosCampeonato dadosComErros)
