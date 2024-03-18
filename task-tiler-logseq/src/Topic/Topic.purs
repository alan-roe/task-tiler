module Topic where

import Prelude

import Block as B
import Data.Array (concatMap, cons, mapMaybe)
import Data.Foldable (sum)
import Data.Int (fromString)
import Data.Maybe (Maybe(..), fromMaybe, isJust, maybe)
import Data.String (Pattern(..), split, stripPrefix, take, trim)
import Topic.Checkbox (CheckboxState(..), checkboxState)

type Logbook =
  { start :: String
  , end :: String
  }

type Block =
  { uuid :: String
  , text :: String
  , checkbox :: CheckboxState
  , logbook :: Maybe Logbook
  }

type Info =
  { block :: Block
  , indent :: Int
  }

type TimeAllotment =
  { seconds :: Int
  , block :: Block
  }

type Topic =
  { title :: Block
  , time_allotment :: Maybe TimeAllotment
  , info :: Array Info
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
loadSpent :: B.Block -> Int
loadSpent (B.Block { content, children }) = readLogbook content + (sum $ map loadSpent children)
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

fmtInfo :: Int -> B.Block -> Array Info
fmtInfo n (B.Block { content, uuid, children }) =
  cons
    { block: { uuid: uuid, text: strip content, checkbox: checkboxState content, logbook: Nothing }, indent: n }
    (concatMap (fmtInfo (n + 1)) children)
  where
  strip = removeTodo <<< removeLogbook

removeTodo ∷ String → String
removeTodo s =
  case mapMaybe (\x -> stripPrefix (Pattern (x <> " ")) s) [ "TODO", "LATER", "DOING", "NOW", "DONE" ] of
    [ stripped ] -> stripped
    _ -> s

loadInfo :: Array B.Block -> Array Info
loadInfo blocks = concatMap (fmtInfo 0) blocks

removeLogbook :: String -> String
removeLogbook s =
  case split (Pattern ":LOGBOOK:") s of
    [ logRemoved, _ ] -> trim logRemoved
    _ -> s

loadBlock :: String -> String -> Block
loadBlock text uuid = { uuid: uuid, text: (removeLogbook <<< removeTodo) text, checkbox: None, logbook: Nothing }

loadTopic :: B.Block -> Topic
loadTopic (B.Block { content: title, uuid: title_uuid, children }) =
  case children of
    -- just one direct child, potentially time or info
    [ B.Block { content: childContent, uuid, children: childChildren } ] ->
      { title: loadBlock title title_uuid
      , time_allotment: maybe Nothing (\x -> Just { seconds: x, block: loadBlock childContent uuid }) allot
      , info: if validTime then loadInfo childChildren else loadInfo children
      }
      where
      validTime = isJust $ allot
      allot = loadTime childContent
    _ ->
      { title: loadBlock title title_uuid
      , time_allotment: Nothing
      , info: loadInfo children
      }