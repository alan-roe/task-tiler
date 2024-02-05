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

loadTime :: String -> Int
loadTime s =
  case split (Pattern "hr") s of
    -- we have an hour
    [ hour, minStr ] -> (fromMaybe 0 $ fromString hour >>= (\x -> Just $ 60 * 60 * x)) + parseMin minStr
    -- no hour, check for minutes
    [ minStr ] -> parseMin minStr
    _ -> 0
  where
  parseMin minStr = case split (Pattern "m") (trim minStr) of
    [ min, _ ] -> fromMaybe 0 $ fromString min >>= (\x -> Just $ 60 * x)
    _ -> 0

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
        [_, log] -> 
          case split (Pattern " =>  ") log of
            [_, time] -> parseTime ((split (Pattern ":") <<< take 8) time)
            _ -> 0
        _ -> 0
    parseTime :: Array String -> Int
    parseTime [hrs, mins, secs] = (fromMaybe 0 (fromString hrs)) * 60 * 60 + (fromMaybe 0 (fromString mins)) * 60 + (fromMaybe 0 (fromString secs))
    parseTime _ = 0

loadInfo :: Array Block -> String
loadInfo bs = joinWith "\n" $ fmtBlockArr 0 bs

loadTopic :: Block -> Maybe Topic
loadTopic block@(Block { content, children: [ Block { content: timeText, children } ] }) = Just { title: content, allot: loadTime timeText, spent: loadSpent block, info: loadInfo children }
loadTopic _ = Nothing
