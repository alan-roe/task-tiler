module Main where

import Prelude

import Block (loadBlocks)
import Data.Array (any)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.String (Pattern(..), contains)
import Data.Traversable (sequence)
import Effect (Effect)
import Effect.AVar (AVar, new, tryPut, tryRead, tryTake) as AV
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (logShow)
import Effect.Console (log)
import Effect.Timer (setInterval)
import Logseq (ready, showMsg)
import Logseq.Editor (BlockEntity(..), getBlock, getCurrentBlock, registerSlashCommand, settings, useSettingsSchema)
import Simple.JSON (writeJSON)
import Supabase (FunctionResponse, createClient, rpc, signInWithPassword)
import Topic (loadTopic)
import Web.Socket.ReadyState (ReadyState(..)) as RS
import Web.Socket.WebSocket (WebSocket, create, readyState, sendString)

findTaskTilerParent :: Maybe BlockEntity -> Aff (Maybe BlockEntity)
findTaskTilerParent Nothing = pure Nothing
findTaskTilerParent (Just (block@(BlockEntity { parent, content }))) = do
  if any (\pat -> contains (Pattern pat) content) [ "#plan", "#task-tiler" ] then
    pure (Just block)
  else
    getBlock (Left parent) >>= findTaskTilerParent

sendTasks :: AV.AVar WebSocket -> Aff Unit
sendTasks avarWs = do
  mBlock <- getCurrentBlock >>= findTaskTilerParent
  case mBlock of
    Nothing -> do
      _ <- showMsg "Task Tiler: Couldn't find parent with #plan or #task-tiler tag"
      pure unit
    Just block -> do
      case block of
        BlockEntity { children: Nothing } -> do
          _ <- showMsg "Task Tiler: Invalid task tiler block, no children"
          pure unit
        BlockEntity { children: (Just childs) } -> do
          json <- writeJSON <<< map loadTopic <<< fromMaybe [] <$> (loadBlocks childs)
          logShow $ json
          liftEffect do
            maybeWs <- AV.tryRead avarWs
            case maybeWs of
              Just ws -> sendString ws json
              Nothing -> logShow "Failed to send last message, couldn't get websocket connction"

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

testBase ∷ Aff Unit
testBase = do
  client <- liftEffect $ createClient "https://yoknygfcsvbbnkjfeyib.supabase.co" "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlva255Z2Zjc3ZiYm5ramZleWliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg5NjI3NTMsImV4cCI6MjAyNDUzODc1M30.ymA3I_ouyrf8bDS_C2gIHjzxDw3Fvcm52DZ7WagkOU0"
  -- TODO handle auth failure
  email <- liftEffect $ settings "supabaseEmail"
  password <- liftEffect $ settings "supabasePassword"
  _ <- signInWithPassword client { email, password }
  mBlock <- getCurrentBlock >>= findTaskTilerParent
  case mBlock of
    Nothing -> do
      _ <- showMsg "Task Tiler: Couldn't find parent with #plan or #task-tiler tag"
      pure unit
    Just block -> do
      case block of
        BlockEntity { children: Nothing } -> do
          _ <- showMsg "Task Tiler: Invalid task tiler block, no children"
          pure unit
        BlockEntity { children: (Just childs) } -> do
          json <- map (writeJSON <<< (\x -> { task_json: x })) <<< map loadTopic <<< fromMaybe [] <$> (loadBlocks childs)
          logShow $ json
          _ :: Array (FunctionResponse {}) <- sequence $ map (rpc client "add_task") json
          pure unit

actualMain :: Effect Unit
actualMain = do
  websocket <- create "ws://localhost:8080/websocket" []
  avarWs <- AV.new websocket
  _ <- setInterval 5000 $ keepWsAlive avarWs
  useSettingsSchema
    [ { key: "supabaseEmail"
      , type: "string"
      , title: "Task-Tiler Email"
      , description: ""
      , default: ""
      }
    , { key: "supabasePassword"
      , type: "string"
      , title: "Task-Tiler Password"
      , description: ""
      , default: ""
      }
    ]
  registerSlashCommand "tiler" (sendTasks avarWs)

main :: Effect Unit
main = do
  log "🍝"
  ready actualMain
