-- Demonstração das três camadas. Única parte do programa com IO.
module Main (main) where

import System.IO (hGetEncoding, hSetEncoding, mkTextEncoding, stdout)

import Dados (dadosCampeonato, dadosComErros)
import Leitura (demonstracao)

-- | Mantém a codificação do terminal (para os acentos aparecerem certos),
-- mas com transliteração: um caractere que ela não representa vira '?'
-- em vez de lançar exceção.
main :: IO ()
main = do
  atual <- hGetEncoding stdout
  mapM_ (\e -> mkTextEncoding (show e ++ "//TRANSLIT") >>= hSetEncoding stdout) atual
  putStr (demonstracao dadosCampeonato dadosComErros)
