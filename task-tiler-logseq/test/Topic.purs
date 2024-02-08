module Test.Topic where

import Prelude

import Block (Block(..))
import Control.Monad.Gen (chooseInt)
import Data.List (List(..))
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Console (log)
import Test.Block (genBlock)
import Test.QuickCheck (arbitrary, quickCheckGen, (<?>))
import Test.QuickCheck.Gen (Gen, arrayOf)
import Topic (loadTime, loadTopic, fmtInfo)

type TimeStr = String

insertTimeBlock :: TimeStr -> Block -> Block
insertTimeBlock timeStr (Block { content, children }) = do
  Block { content, children: [ Block { content: timeStr, children } ] }

-- generates topic block with time
genTopicBlock :: Gen Block
genTopicBlock = do
  content <- arbitrary
  timeStr <- genTimeStr
  infoBlocks <- arrayOf (genBlock true)
  pure $ Block { content, children: [ Block { content: timeStr, children: infoBlocks } ] }

listToArray :: forall a. List a -> Array a
listToArray (Cons x xs) = [ x ] <> (listToArray xs)
listToArray Nil = []

mkHrStr :: Int -> TimeStr
mkHrStr h = show h <> "hr"

mkMinStr :: Int -> TimeStr
mkMinStr m = show m <> "m"

mkTimeStr :: Int -> Int -> TimeStr
mkTimeStr hours mins =
  mkHrStr hours <> " " <> mkMinStr mins

genTimeStr :: Gen TimeStr
genTimeStr = do
  hours <- chooseInt 1 8
  mins <- chooseInt 1 60
  pure $ mkHrStr hours <> " " <> mkMinStr mins

timeTests :: Effect Unit
timeTests = do
  log "load hours"
  quickCheckGen do
    h <- chooseInt 1 8
    let time = mkHrStr h
    let loaded = loadTime time
    let correctTime = h * 60 * 60
    pure $
      case loaded of
        Just allot -> eq allot correctTime
        Nothing -> false
        <?> "Test failed for input:\n" <> "time string: " <> time <> "\ntime loaded: " <> show loaded <> "\ncorrect time:" <> show correctTime

  log "load mins"
  quickCheckGen do
    m <- chooseInt 1 60
    let time = mkMinStr m
    let loaded = loadTime time
    let correctTime = m * 60
    pure $
      case loaded of
        Just allot -> eq allot correctTime
        Nothing -> false
        <?> "Test failed for input:\n" <> "time string: " <> time <> "time loaded: " <> show loaded <> "correct time:" <> show correctTime

  log "load times"
  quickCheckGen do
    h <- chooseInt 1 8
    m <- chooseInt 1 60
    let time = mkTimeStr h m
    let loaded = loadTime time
    let correctTime = (h * 60 * 60 + m * 60)
    pure $
      case loaded of
        Just allot -> eq allot correctTime
        Nothing -> false
        <?> "Test failed for input:\n" <> "time string: " <> time <> "time loaded: " <> show loaded <> "correct time:" <> show correctTime

loadTopicTests :: Effect Unit
loadTopicTests = do
  log "load topic with 0 allot if no time exists"
  quickCheckGen do
    noTimeTopicBlock <- genBlock true
    pure $
      eq (loadTopic noTimeTopicBlock).allot 0 <?> "Test failed for input:\n" <> (show $ fmtInfo 0 noTimeTopicBlock)

  log "load correct time allotted"
  quickCheckGen do
    noTimeTopicBlock <- genBlock true
    h <- chooseInt 1 8
    m <- chooseInt 1 60
    let timeTopicBlock = insertTimeBlock (mkTimeStr h m) noTimeTopicBlock
    pure $
      eq (loadTopic timeTopicBlock).allot (h * 60 * 60 + m * 60) <?> "Test failed for input:\n" <> (show $ fmtInfo 0 timeTopicBlock)
