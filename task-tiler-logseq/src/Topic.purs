module Topic where

import Prelude

import Block (Block(..), fmtBlockArr)
import Data.Foldable (sum)
import Data.Int (fromString)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..), joinWith, split, take, trim)

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

loadInfo :: Array Block -> String
loadInfo bs = joinWith "\n" $ fmtBlockArr 0 bs

loadTopic :: Block -> Topic
loadTopic -- a topic with just one child, potentially time or info
  block@
    ( Block
        { content
        , children: infoBlock@[ Block { content: timeText, children } ]
        }
    ) =
  case loadTime timeText of
    Just allot ->
      { title: content
      , allot
      , spent: loadSpent block
      , info: loadInfo children
      }
    Nothing ->
      { title: content
      , allot: 0
      , spent: loadSpent block
      , info: loadInfo infoBlock
      }
loadTopic -- just a topic, no time allotted or info given
  block@(Block { content, children: [] }) =
  { title: content
  , allot: 0
  , spent: loadSpent block
  , info: ""
  }
loadTopic -- a topic with only info, no time allotted
  block@(Block { content, children }) =
  { title: content
  , allot: 0
  , spent: loadSpent block
  , info: loadInfo children
  }
