module Main where

import Prelude

import Block (Block(..), fmtBlockArr, loadBlocks)
import Data.Array (head)
import Data.Int (fromString)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..), joinWith, split)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class.Console (logShow)
import Effect.Console (log)
import Logseq (ready)
import Logseq.Editor (BlockEntity(..), getCurrentBlock, registerSlashCommand)

type Topic = {
  title :: String,
  allot :: Int,
  info :: String
}

loadTime :: String -> Int
loadTime s = fromMaybe 0 (head (split (Pattern "h") s) >>= fromString >>= (\x -> Just $ 60 * 60 * x))

loadInfo :: Array Block -> String
loadInfo bs = joinWith "\n" $ fmtBlockArr 0 bs

loadTopic :: Block -> Maybe Topic
loadTopic (Block {content, children: [Block {content: timeText, children}]}) = Just {title: content, allot: loadTime timeText, info: loadInfo children}
loadTopic _ = Nothing

sendTasks :: Aff Unit
sendTasks = do 
  block <- getCurrentBlock
  blocks <- loadBlocks $ fromMaybe [] (block >>= (\(BlockEntity {children}) -> children))
  logShow $ map loadTopic blocks
  pure unit

actualMain :: Effect Unit
actualMain = do
  registerSlashCommand "tiler" sendTasks

main :: Effect Unit
main = do
  log "🍝"
  ready actualMain
