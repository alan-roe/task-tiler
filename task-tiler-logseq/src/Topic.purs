module Topic where

import Prelude

import Block (Block(..), fmtBlockArr)
import Data.Int (fromString)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..), joinWith, split, trim)

type Topic =
  { title :: String
  , allot :: Int
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

loadInfo :: Array Block -> String
loadInfo bs = joinWith "\n" $ fmtBlockArr 0 bs

loadTopic :: Block -> Maybe Topic
loadTopic (Block { content, children: [ Block { content: timeText, children } ] }) = Just { title: content, allot: loadTime timeText, info: loadInfo children }
loadTopic _ = Nothing
