module Main where

import Prelude

import Block (loadBlocks)
import Data.Array (mapMaybe)
import Data.Maybe (fromMaybe)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (logShow)
import Effect.Console (log)
import Logseq (ready)
import Logseq.Editor (BlockEntity(..), getCurrentBlock, registerSlashCommand)
import Mqtt.Mqtt (connect, publish)
import Simple.JSON (writeJSON)
import Topic (loadTopic)

sendTasks :: (String -> Effect Unit) -> Aff Unit
sendTasks mqtt = do 
  block <- getCurrentBlock
  blocks <- loadBlocks $ fromMaybe [] (block >>= (\(BlockEntity {children}) -> children))
  let json = writeJSON $ mapMaybe loadTopic blocks
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
