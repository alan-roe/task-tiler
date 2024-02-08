module Topic where

import Prelude

import Block (Block(..))
import Data.Array (mapMaybe)
import Data.Foldable (sum)
import Data.Int (fromString)
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.String (Pattern(..), joinWith, split, stripPrefix, take, trim)

type Topic =
  { title :: String
  , allot :: Int
  , spent :: Int
  , info :: String
  }

loadTime :: String -> Maybe Int
loadTime s =
  case split (Pattern "hr") s of
    -- we have an hour
    [ hour, minStr ] ->
      fromString (trim hour)
        >>= (\x -> Just $ 60 * 60 * x)
        >>= (\x -> Just $ fromMaybe 0 (parseMin minStr) + x)
    -- no hour, check for minutes
    [ minStr ] -> parseMin minStr
    _ -> Nothing
  where
  parseMin :: String -> Maybe Int
  parseMin minStr = case split (Pattern "m") (trim minStr) of
    [ min, _ ] -> fromString (trim min) >>= (\x -> Just $ 60 * x)
    _ -> Nothing

-- NOW Roadmap for completion
-- :LOGBOOK:
-- CLOCK: [2024-02-05 Mon 18:52:11]
-- :END:

-- LATER Roadmap for completion
-- :LOGBOOK:
-- CLOCK: [2024-02-05 Mon 18:52:11]--[2024-02-05 Mon 19:06:29] =>  00:14:18
-- :END:
loadSpent :: Block -> Int
loadSpent (Block { content, children }) = readLogbook content + (sum $ map loadSpent children)
  where
  readLogbook :: String -> Int
  readLogbook s =
    case split (Pattern ":LOGBOOK:") s of
      [ _, log ] ->
        case split (Pattern " =>  ") log of
          [ _, time ] -> parseTime ((split (Pattern ":") <<< take 8) time)
          _ -> 0
      _ -> 0

  parseTime :: Array String -> Int
  parseTime [ hrs, mins, secs ] = (fromMaybe 0 (fromString hrs)) * 60 * 60 + (fromMaybe 0 (fromString mins)) * 60 + (fromMaybe 0 (fromString secs))
  parseTime _ = 0

tabs ∷ Int → String
tabs 0 = ""
tabs n = "  " <> tabs (n - 1)

fmtInfoArr :: Int -> Array Block -> Array String
fmtInfoArr n blocks = map (fmtInfo n) blocks

fmtInfo :: Int -> Block -> String
fmtInfo n (Block { content, children }) = joinWith "\n" $ [ tabs n <> "- " <> removeLogbook content ] <> (fmtInfoArr (n + 1) children)

loadInfo :: Array Block -> String
loadInfo bs = joinWith "\n" $ fmtInfoArr 0 bs

removeLogbook :: String -> String
removeLogbook s =
  case split (Pattern ":LOGBOOK:") s of
    [ logRemoved, _ ] -> trim logRemoved
    _ -> s

loadTitle :: String -> String
loadTitle = removeLogbook <<< removeTodo
  where
  removeTodo s =
    case mapMaybe (\x -> stripPrefix (Pattern (x <> " ")) s) [ "TODO", "LATER", "DOING", "NOW", "DONE" ] of
      [ stripped ] -> stripped
      _ -> s

loadTopic :: Block -> Topic
loadTopic block@(Block { content: title, children }) =
  case children of
    -- just one direct child, potentially time or info
    [ Block { content: childContent, children: childChildren } ] ->
      { title: loadTitle title
      , allot: fromMaybe 0 allot
      , spent: loadSpent block
      , info: if validTime then loadInfo childChildren else loadInfo children
      }
      where
      validTime = isJust $ allot
      allot = loadTime childContent
    _ ->
      { title: loadTitle title
      , allot: 0
      , spent: loadSpent block
      , info: loadInfo children
      }