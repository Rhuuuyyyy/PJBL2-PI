-- Camada 3: leitura, validação e formatação da saída.
module Leitura
  ( Lado (..)
  , Campo (..)
  , Erro (..)
  , descreverErro
  , separar
  , lerPartida
  , lerCampeonato
  , todosOsErros
  , tabelaFormatada
  ) where

import Data.Char (isDigit, isSpace)
import Data.Either (partitionEithers)
import Data.List (dropWhileEnd, group, intercalate, isPrefixOf, sort, unfoldr)
import Data.Maybe (listToMaybe)
import Text.Read (readMaybe)

import Classificacao
import Tipos

-- | Lado da partida a que um campo se refere.
data Lado = Mandante | Visitante
  deriving (Show, Eq)

-- | Campo numérico de uma linha da entrada.
data Campo = CampoRodada | CampoGols Lado
  deriving (Show, Eq)

-- | Erros de leitura e validação. Cada um carrega a linha (contada a partir
-- de 1, incluindo comentários e linhas em branco) ou a rodada do problema.
data Erro
  = CamposInvalidos Int Int          -- ^ linha, quantidade de campos encontrada
  | NumeroInvalido Int Campo String  -- ^ linha, campo, texto que não é número
  | PlacarNegativo Int Lado Int      -- ^ linha, lado, gols negativos informados
  | RodadaInvalida Int Int           -- ^ linha, rodada (precisa ser maior que 0)
  | TimeVazio Int Lado               -- ^ linha, lado com nome em branco
  | MesmoTime Int Time               -- ^ linha, time contra si mesmo
  | TimeRepetidoNaRodada Int Time    -- ^ rodada, time escalado mais de uma vez
  deriving (Show, Eq)

-- | Quantidade de campos de uma linha: rodada, mandante, gols (2) e visitante.
camposPorLinha :: Int
camposPorLinha = 5

-- | Maior valor aceito para rodada e gols (limite de sanidade que também
-- impede estouro de 'Int' nas somas da classificação).
limiteNumerico :: Integer
limiteNumerico = 1000000

nomeDoLado :: Lado -> String
nomeDoLado Mandante = "mandante"
nomeDoLado Visitante = "visitante"

nomeDoCampo :: Campo -> String
nomeDoCampo CampoRodada = "rodada"
nomeDoCampo (CampoGols lado) = "gols do " ++ nomeDoLado lado

-- | Mensagem legível, em português, para um erro.
descreverErro :: Erro -> String
descreverErro (CamposInvalidos n qtd) =
  "linha " ++ show n ++ ": esperados " ++ show camposPorLinha
    ++ " campos separados por ';', encontrados " ++ show qtd
descreverErro (NumeroInvalido n campo texto) =
  "linha " ++ show n ++ ": " ++ nomeDoCampo campo ++ " \"" ++ texto
    ++ "\" não é um número inteiro válido (até " ++ show limiteNumerico ++ ")"
descreverErro (PlacarNegativo n lado gols) =
  "linha " ++ show n ++ ": " ++ nomeDoCampo (CampoGols lado)
    ++ " negativo (" ++ show gols ++ ")"
descreverErro (RodadaInvalida n r) =
  "linha " ++ show n ++ ": rodada " ++ show r ++ " inválida (deve ser maior que 0)"
descreverErro (TimeVazio n lado) =
  "linha " ++ show n ++ ": nome do " ++ nomeDoLado lado ++ " está em branco"
descreverErro (MesmoTime n t) =
  "linha " ++ show n ++ ": " ++ t ++ " não pode jogar contra si mesmo"
descreverErro (TimeRepetidoNaRodada r t) =
  "rodada " ++ show r ++ ": " ++ t ++ " aparece em mais de uma partida"

-- | Quebra um texto nos separadores, preservando campos vazios.
separar :: Char -> String -> [String]
separar sep = unfoldr passo . Just
  where
    passo Nothing = Nothing
    passo (Just texto) = Just $ case break (== sep) texto of
      (campo, [])        -> (campo, Nothing)
      (campo, _ : resto) -> (campo, Just resto)

-- | Remove espaços (inclusive '\r' de finais de linha do Windows), BOM
-- (U+FEFF) e espaço de largura zero (U+200B) das duas pontas.
aparar :: String -> String
aparar = dropWhileEnd ehEspaco . dropWhile ehEspaco
  where
    ehEspaco c = isSpace c || c == '\65279' || c == '\8203'

-- | Aceita somente inteiros decimais simples (dígitos, com '-' opcional),
-- dentro de 'limiteNumerico'. Rejeita '+3', '0x10', '1e3', '3.0' e vazio.
lerInteiro :: String -> Maybe Int
lerInteiro texto
  | decimalSimples texto = readMaybe texto >>= dentroDoLimite
  | otherwise            = Nothing
  where
    decimalSimples ('-' : digitos) = soDigitos digitos
    decimalSimples digitos         = soDigitos digitos
    soDigitos digitos = not (null digitos) && all isDigit digitos
    dentroDoLimite :: Integer -> Maybe Int
    dentroDoLimite n
      | abs n <= limiteNumerico = Just (fromInteger n)
      | otherwise               = Nothing

lerNumero :: Int -> Campo -> String -> Either Erro Int
lerNumero n campo texto = maybe (Left (NumeroInvalido n campo texto)) Right (lerInteiro texto)

lerRodada :: Int -> String -> Either Erro Int
lerRodada n texto = do
  r <- lerNumero n CampoRodada texto
  if r < 1 then Left (RodadaInvalida n r) else Right r

lerGols :: Int -> Lado -> String -> Either Erro Int
lerGols n lado texto = do
  gols <- lerNumero n (CampoGols lado) texto
  if gols < 0 then Left (PlacarNegativo n lado gols) else Right gols

lerTime :: Int -> Lado -> String -> Either Erro Time
lerTime n lado nome
  | null nome = Left (TimeVazio n lado)
  | otherwise = Right nome

-- | Converte uma linha (com o seu número) em partida, validando cada campo.
-- Formato: @rodada;mandante;gols mandante;gols visitante;visitante@.
lerPartida :: Int -> String -> Either Erro Partida
lerPartida n linha = case map aparar (separar ';' linha) of
  [r, m, gm, gv, v] -> do
    rod <- lerRodada n r
    golsM <- lerGols n Mandante gm
    golsV <- lerGols n Visitante gv
    mand <- lerTime n Mandante m
    visi <- lerTime n Visitante v
    if mand == visi
      then Left (MesmoTime n mand)
      else Right (Partida rod mand golsM golsV visi)
  campos -> Left (CamposInvalidos n (length campos))

-- | Linhas úteis do texto, com o número original; ignora linhas em branco
-- e comentários (que começam com '#').
linhasUteis :: String -> [(Int, String)]
linhasUteis = filter (not . ignorada . snd) . zip [1 ..] . lines
  where
    ignorada linha = null (aparar linha) || "#" `isPrefixOf` aparar linha

-- | Erros entre linhas: um time escalado mais de uma vez na mesma rodada
-- (um erro por par rodada/time, em ordem de rodada e de nome).
repeticoesNaRodada :: [Partida] -> [Erro]
repeticoesNaRodada ps =
  [ TimeRepetidoNaRodada r t
  | ((r, t) : _ : _) <- group (sort (concatMap escalados ps))
  ]
  where
    escalados p = [(rodada p, mandante p), (rodada p, visitante p)]

-- | Lê o campeonato inteiro, parando no primeiro erro de linha (via
-- 'traverse'); depois confere que nenhum time joga duas vezes na mesma rodada.
-- Texto vazio, ou só com comentários, é um campeonato sem partidas.
lerCampeonato :: String -> Either Erro [Partida]
lerCampeonato texto = do
  partidas <- traverse (uncurry lerPartida) (linhasUteis texto)
  maybe (Right partidas) Left (listToMaybe (repeticoesNaRodada partidas))

-- | Todos os erros do texto: o primeiro erro de cada linha inválida, em
-- ordem de linha, seguido dos erros entre linhas (calculados sobre as
-- linhas válidas).
todosOsErros :: String -> [Erro]
todosOsErros texto = errosDeLinha ++ repeticoesNaRodada partidas
  where
    (errosDeLinha, partidas) = partitionEithers (map (uncurry lerPartida) (linhasUteis texto))

-- | Tabela pronta para impressão: posição, time, pontos, jogos, vitórias,
-- empates, derrotas e saldo de gols.
tabelaFormatada :: [Linha] -> String
tabelaFormatada linhas = unlines (cabecalho : zipWith formatar [1 :: Int ..] linhas)
  where
    larguraTime = foldr (max . length . time) (length "Time") linhas
    colunas posicao nome numeros =
      intercalate " " (preencheEsq 3 posicao : preencheDir larguraTime nome : map (preencheEsq 3) numeros)
    cabecalho = colunas "Pos" "Time" ["Pts", "J", "V", "E", "D", "SG"]
    formatar posicao linha =
      colunas (show posicao) (time linha)
        (map show [pontosLinha linha, jogos linha, vitorias linha, empates linha, derrotas linha, saldo linha])

preencheDir :: Int -> String -> String
preencheDir largura texto = texto ++ replicate (largura - length texto) ' '

preencheEsq :: Int -> String -> String
preencheEsq largura texto = replicate (largura - length texto) ' ' ++ texto
