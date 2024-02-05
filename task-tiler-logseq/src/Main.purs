module Main where

import Prelude

import Block (loadBlocks)
import Data.Array (any, mapMaybe)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.String (Pattern(..), contains)
import Effect (Effect)
import Effect.AVar (AVar, new, tryPut, tryRead, tryTake) as AV
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (logShow)
import Effect.Console (log)
import Effect.Timer (setInterval)
import Logseq (ready)
import Logseq.Editor (BlockEntity(..), getBlock, getCurrentBlock, registerSlashCommand)
import Simple.JSON (writeJSON)
import Topic (loadTopic)
import Web.Socket.ReadyState (ReadyState(..)) as RS
import Web.Socket.WebSocket (WebSocket, create, readyState, sendString)

findTaskTilerParent :: Maybe BlockEntity -> Aff (Maybe BlockEntity)
findTaskTilerParent Nothing = pure Nothing
findTaskTilerParent (Just (block@(BlockEntity {parent, content}))) = do
  if any (\pat -> contains (Pattern pat) content) ["#plan", "#task-tiler"] then
    pure (Just block) else
    getBlock (Left parent) >>= findTaskTilerParent
  
sendTasks :: AV.AVar WebSocket -> Aff Unit
sendTasks avarWs = do
  block <- getCurrentBlock >>= findTaskTilerParent
  blocks <- loadBlocks $ fromMaybe [] (block >>= (\(BlockEntity { children }) -> children))
  let json = writeJSON $ mapMaybe loadTopic blocks
  logShow $ json
  liftEffect do
    maybeWs <- AV.tryRead avarWs
    case maybeWs of
      Just ws -> sendString ws json
      Nothing -> logShow $ "Failed to send last message, couldn't get websocket connction"

replaceSocket :: AV.AVar WebSocket -> Effect Unit
replaceSocket avarWs = do
  _ <- AV.tryTake avarWs
  newWs <- create "ws://localhost:8080/websocket" []
  done <- AV.tryPut newWs avarWs
  logShow $ "replaced socket: " <> show done

keepWsAlive :: AV.AVar WebSocket -> Effect Unit
keepWsAlive avarWs = do
  mWs <- AV.tryRead avarWs
  rs <- maybe (pure RS.Closed) readyState mWs
  case rs of
    RS.Closed -> replaceSocket avarWs
    _ -> pure unit

actualMain :: Effect Unit
actualMain = do
  websocket <- create "ws://localhost:8080/websocket" []
  avarWs <- AV.new websocket
  _ <- setInterval 5000 $ keepWsAlive avarWs
  registerSlashCommand "tiler" (sendTasks avarWs)

main :: Effect Unit
main = do
  log "🍝"
  ready actualMain
