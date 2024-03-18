module Test.Block where

import Prelude

import Block (Block(..))
import Control.Monad.Gen (resize, sized)
import Test.QuickCheck (arbitrary)
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
        uuid <- resize (const 36) arbitrary
        pure $ Block { content: content, uuid: uuid, children: [] }

  genChildren :: Gen Block
  genChildren = do
    content <- arbitrary
    children <- arrayOf $ genBlock true
    uuid <- resize (const 36) arbitrary
    pure $ Block { content: content, uuid: uuid, children: children }
