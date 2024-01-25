module Test.Main where

import Prelude

import Block (Block(..), fmtBlock, fmtBlockArr)
import Control.Monad.Gen (chooseInt, resize, sized)
import Data.Array (length)
import Data.List (List(..))
import Data.List.Lazy (fold, replicate)
import Effect (Effect)
import Effect.Class.Console (log)
import Topic (loadTime)
import Test.QuickCheck (arbitrary, quickCheckGen, (<?>))
import Test.QuickCheck.Gen (Gen, arrayOf, listOf)

--- pass false for no children
genBlock :: Boolean -> Gen Block
genBlock c = resize (min 6) $ sized genBlock'
  where
  genBlock' :: Int -> Gen Block
  genBlock' size
    | size > 1 && c = resize (_ - 1) genChildren
    | otherwise = do
        content <- arbitrary
        pure $ Block { content: content, children: [] }

  genChildren :: Gen Block
  genChildren = do
    content <- arbitrary
    children <- arrayOf $ genBlock true
    pure $ Block { content: content, children: children }

genTimeStr :: Int -> Int -> Gen String
genTimeStr hours 0 = pure $ show hours <> "hr"
genTimeStr 0 mins = pure $ show mins <> "m"
genTimeStr hours mins = pure $ show hours <> "hr" <> " " <> show mins <> "m"

listToArray :: forall a. List a -> Array a
listToArray (Cons x xs) = [ x ] <> (listToArray xs)
listToArray Nil = []

main :: Effect Unit
main = do
  log "🍝"
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
