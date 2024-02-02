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
import Simple.JSON (writeJSON)
import Topic (loadTopic)
import Web.Socket.WebSocket (create, sendString)

sendTasks :: (String -> Effect Unit) -> Aff Unit
sendTasks mqtt = do
  block <- getCurrentBlock
  blocks <- loadBlocks $ fromMaybe [] (block >>= (\(BlockEntity { children }) -> children))
  let json = writeJSON $ mapMaybe loadTopic blocks
  logShow $ json
  liftEffect $ mqtt json

actualMain :: Effect Unit
actualMain = do
  websocket <- create "ws://localhost:8080/websocket" []
  registerSlashCommand "tiler" (sendTasks $ sendString websocket)

main :: Effect Unit
main = do
  log "🍝"
  ready actualMain
