module Main where

import Prelude

import Control.Promise (fromAff)
import Effect (Effect)
import Effect.Console (log)
import Logseq (getCurrentBlock, ready, registerSlashCommand, showMsg)

sendTasks :: Effect Unit
sendTasks = do 
  _ <- fromAff $ showMsg "block.content"
  _ <- fromAff $ getCurrentBlock
  pure unit

actualMain :: Effect Unit
actualMain = do
  registerSlashCommand "tiler" sendTasks

main :: Effect Unit
main = do
  log "🍝"
  ready actualMain
  