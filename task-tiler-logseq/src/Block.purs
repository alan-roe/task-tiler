module Block where

import Prelude

import Data.Array (catMaybes)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Traversable (sequence)
import Effect.Aff (Aff)
import Logseq.Editor (BlockEntity(..), BlockUUID, getBlock)

newtype Block = Block
  { content :: String
  , uuid :: String
  , children :: Array Block
  }

loadBlocks :: Array (Either BlockEntity BlockUUID) -> Aff (Maybe (Array Block))
loadBlocks [] = pure $ Nothing
loadBlocks xs = do
  blocks <- sequence $ map loadBlock xs
  pure $ sequence blocks
  where
  loadBlock :: Either BlockEntity BlockUUID -> Aff (Maybe Block)
  loadBlock (Left (BlockEntity { content, uuid, children: Nothing })) = pure $ Just $ Block { content: content, uuid: uuid, children: [] }
  loadBlock (Left (BlockEntity { content, uuid, children: Just blocks })) = do
    childs <- sequence $ map loadBlock blocks
    pure $ Just $ Block { content: content, uuid, children: catMaybes childs }
  loadBlock (Right ruuid) = do
    blockE <- getBlock (Right ruuid)
    case blockE of
      Just (BlockEntity { children, uuid, content }) -> do
        childs <- sequence $ map loadBlock ((catMaybes <<< sequence) children)
        pure $ Just $ Block { content: content, uuid: uuid, children: catMaybes childs }
      Nothing -> pure $ Nothing
