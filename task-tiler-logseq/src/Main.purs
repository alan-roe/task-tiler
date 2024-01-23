module Main where

import Prelude

import Data.Maybe (maybe)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class.Console (logShow)
import Effect.Console (log)
import Logseq (ready, showMsg)
import Logseq.Editor (content, getCurrentBlock, registerSlashCommand)


sendTasks :: Aff Unit
sendTasks = do 
  block <- getCurrentBlock
  logShow block
  _ <- showMsg $ maybe "invalid block" content block
  pure unit

actualMain :: Effect Unit
actualMain = do
  registerSlashCommand "tiler" sendTasks

main :: Effect Unit
main = do
  log "🍝"
  ready actualMain
  