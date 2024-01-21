module Main where

import Prelude

import Control.Promise (fromAff)
import Effect (Effect)
import Effect.Console (log)
import Logseq (readyUp, registerSlashCommand, showMsg)

sendTasks :: Effect Unit
sendTasks = do 
  _ <- fromAff $ showMsg "hi from purescript"
  pure unit

actualMain :: Effect Unit
actualMain = do
  registerSlashCommand "tiler" sendTasks

main :: Effect Unit
main = do
  log "🍝"
  readyUp actualMain
  