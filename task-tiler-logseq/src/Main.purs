module Main where

import Prelude

import Block (Block(..), fmtBlockArr, loadBlocks)
import Data.Array (head)
import Data.Int (fromString)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..), joinWith, split)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (logShow)
import Effect.Console (log)
import Logseq (ready)
import Logseq.Editor (BlockEntity(..), getCurrentBlock, registerSlashCommand)
import Mqtt.Mqtt (connect, publish)
import Simple.JSON (writeJSON)

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

sendTasks :: (String -> Effect Unit) -> Aff Unit
sendTasks mqtt = do 
  block <- getCurrentBlock
  blocks <- loadBlocks $ fromMaybe [] (block >>= (\(BlockEntity {children}) -> children))
  let json = writeJSON $ map loadTopic blocks
  logShow $ json
  liftEffect $ mqtt json

actualMain :: Effect Unit
actualMain = do
  mqtt <- connect "ws://192.168.1.153:8083" {clientId: "task-tiler", username: "task-tiler", password: "task-tiler"} 
  registerSlashCommand "tiler" (sendTasks (\x -> publish mqtt "tasks" x {retain: true}))

main :: Effect Unit
main = do
  log "🍝"
  ready actualMain
