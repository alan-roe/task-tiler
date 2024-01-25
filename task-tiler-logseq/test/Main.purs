module Test.Main where

import Prelude

import Block (Block(..), fmtBlock)
import Control.Monad.Gen (chooseInt, resize, sized)
import Data.Array (length)
import Data.List.Lazy (fold, replicate)
import Effect (Effect)
import Effect.Class.Console (log)
import Test.QuickCheck (arbitrary, quickCheckGen, (<?>))
import Test.QuickCheck.Gen (Gen, arrayOf)

--- pass false for no children
genBlock :: Boolean -> Gen Block
genBlock c = resize (min 6) $ sized genBlock'
  where
    genBlock' :: Int -> Gen Block
    genBlock' size 
      | size > 1 && c = resize (_ - 1) genChildren
      | otherwise = do 
        content <- arbitrary
        pure $ Block {content: content, children: []}
    genChildren :: Gen Block
    genChildren = do 
      content <- arbitrary
      children <- arrayOf $ genBlock true
      pure $ Block {content: content, children: children}

main :: Effect Unit
main = do
  log "🍝"
  log "blocks with no children format with content"
  quickCheckGen do
    tabs <- chooseInt 0 10
    block@(Block {content, children}) <- genBlock false
    pure $ (if length children == 0 then 
      eq (fmtBlock tabs block) (fold (replicate tabs "  ") <> "- " <> content)
      else false) <?> "Test failed for input:\n" <> fmtBlock tabs block
  