module Test.Main where

import Prelude

import Effect (Effect)
import Effect.Class.Console (log)
import Test.Topic (loadTopicTests, timeTests)

main :: Effect Unit
main = do
  log "🍝"
  _ <- timeTests
  loadTopicTests