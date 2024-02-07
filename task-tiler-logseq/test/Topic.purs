module Test.Topic where

import Prelude

import Block (Block(..), fmtBlock, fmtBlockArr)
import Control.Monad.Gen (chooseInt)
import Data.Array (fold, length, replicate)
import Data.List (List(..))
import Effect (Effect)
import Effect.Console (log)
import Test.Block (genBlock)
import Test.QuickCheck (quickCheckGen, (<?>))
import Test.QuickCheck.Gen (Gen, listOf)
import Topic (loadTime)

listToArray :: forall a. List a -> Array a
listToArray (Cons x xs) = [ x ] <> (listToArray xs)
listToArray Nil = []

genTimeStr :: Int -> Int -> Gen String
genTimeStr hours 0 = pure $ show hours <> "hr"
genTimeStr 0 mins = pure $ show mins <> "m"
genTimeStr hours mins = pure $ show hours <> "hr" <> " " <> show mins <> "m"

timeTests :: Effect Unit
timeTests = do
  log "blocks with no children format with content"
  quickCheckGen do
    tabs <- chooseInt 0 10
    block@(Block { content, children }) <- genBlock false
    pure $
      ( if length children == 0 then
          eq (fmtBlock tabs block) (fold (replicate tabs "  ") <> "- " <> content)
        else false
      ) <?> "Test failed for input:\n" <> fmtBlock tabs block

  log "first block of array always formatted with n tabs"
  quickCheckGen do
    tabs <- chooseInt 0 10
    blocks <- listOf 10 $ genBlock false
    let blockArr = listToArray blocks
    pure $
      ( eq
          (fmtBlockArr tabs blockArr)
          (map (\(Block { content }) -> fold (replicate tabs "  ") <> "- " <> content) blockArr)
      )
        <?> "Test failed for input:\n" <> show (fmtBlockArr tabs (blockArr))

  log "load hours"
  quickCheckGen do
    h <- chooseInt 1 8
    time <- genTimeStr h 0
    let loaded = loadTime time
    let correctTime = h * 60 * 60
    pure $
      eq loaded correctTime
        <?> "Test failed for input:\n" <> "time string: " <> time <> "time loaded: " <> show loaded <> "correct time:" <> show correctTime

  log "load mins"
  quickCheckGen do
    m <- chooseInt 1 60
    time <- genTimeStr 0 m
    let loaded = loadTime time
    let correctTime = m * 60
    pure $
      eq loaded correctTime
        <?> "Test failed for input:\n" <> "time string: " <> time <> "time loaded: " <> show loaded <> "correct time:" <> show correctTime

  log "load times"
  quickCheckGen do
    h <- chooseInt 1 8
    m <- chooseInt 1 60
    time <- genTimeStr h m
    let loaded = loadTime time
    let correctTime = (h * 60 * 60 + m * 60)
    pure $
      eq loaded correctTime
        <?> "Test failed for input:\n" <> "time string: " <> time <> "time loaded: " <> show loaded <> "correct time:" <> show correctTime
