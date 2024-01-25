module Block where

import Prelude

import Data.Array (catMaybes)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.String (joinWith)
import Data.Traversable (sequence)
import Effect.Aff (Aff)
import Logseq.Editor (BlockEntity(..), BlockUUID, getBlock)

newtype Block = Block
  { content :: String
  , children :: Array Block
  }

tabs ∷ Int → String
tabs 0 = ""
tabs n = "  " <> tabs (n - 1)

fmtBlockArr :: Int -> Array Block -> Array String
fmtBlockArr n blocks = map (fmtBlock n) blocks

fmtBlock :: Int -> Block -> String
fmtBlock n (Block { content, children }) = joinWith "\n" $ [ tabs n <> "- " <> content ] <> (fmtBlockArr (n + 1) children)

loadBlocks :: Array (Either BlockEntity BlockUUID) -> Aff (Array Block)
loadBlocks [] = pure $ [ Block { content: "", children: [] } ]
loadBlocks xs = do
  blocks <- sequence $ map loadBlock xs
  pure $ catMaybes blocks
  where
  loadBlock :: Either BlockEntity BlockUUID -> Aff (Maybe Block)
  loadBlock (Left (BlockEntity { content, children: Nothing })) = pure $ Just $ Block { content: content, children: [] }
  loadBlock (Left (BlockEntity { content, children: Just blocks })) = do
    childs <- sequence $ map loadBlock blocks
    pure $ Just $ Block { content: content, children: catMaybes childs }
  loadBlock (Right uuid) = do
    blockE <- getBlock (Right uuid)
    case blockE of
      Just (BlockEntity { children, content }) -> do
        childs <- sequence $ map loadBlock ((catMaybes <<< sequence) children)
        pure $ Just $ Block { content: content, children: catMaybes childs }
      Nothing -> pure $ Just $ Block { content: "", children: [] }
