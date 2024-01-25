module Logseq.Editor
  ( BlockEntity(..)
  , BlockUUID
  , EntityID
  , getBlock
  , getCurrentBlock
  , registerSlashCommand
  ) where

import Prelude

import Control.Promise (Promise, fromAff, toAffE)
import Data.Either (Either(..))
import Data.Function.Uncurried (Fn2, runFn2)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)

foreign import registerSlashCommandImpl :: Fn2 String (Effect (Promise Unit)) (Effect Unit)

registerSlashCommand :: String -> Aff Unit -> Effect Unit
registerSlashCommand name f = runFn2 registerSlashCommandImpl name (fromAff f)

type BlockUUID = String
type EntityID = Int

newtype BlockEntity = BlockEntity
  { parent :: EntityID
  , children :: Maybe (Array (Either BlockEntity BlockUUID))
  , content :: String
  }

foreign import getCurrentBlockImpl :: forall a x y. (a -> Maybe a) -> Maybe a -> (x -> Either x y) -> (y -> Either x y) -> Effect (Promise (Maybe BlockEntity))

getCurrentBlock :: Aff (Maybe BlockEntity)
getCurrentBlock = toAffE $ getCurrentBlockImpl Just Nothing Left Right

foreign import getBlockNImpl :: forall a x y. (a -> Maybe a) -> Maybe a -> (x -> Either x y) -> (y -> Either x y) -> EntityID -> Effect (Promise (Maybe BlockEntity))
foreign import getBlockUImpl :: forall a x y. (a -> Maybe a) -> Maybe a -> (x -> Either x y) -> (y -> Either x y) -> BlockUUID -> Effect (Promise (Maybe BlockEntity))

getBlock :: Either EntityID BlockUUID -> Aff (Maybe BlockEntity)
getBlock e = toAffE
  case e of
    Left n -> getBlockNImpl Just Nothing Left Right n
    Right u -> getBlockUImpl Just Nothing Left Right u
