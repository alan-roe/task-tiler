module Logseq.Editor
  ( BlockEntity(..)
  , BlockUUID
  , EntityID
  , children
  , content
  , getBlock
  , getCurrentBlock
  , registerSlashCommand
  )
  where

import Prelude

import Control.Promise (Promise, fromAff, toAffE)
import Data.Either (Either(..))
import Data.Function.Uncurried (Fn2, runFn2)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Data.Show.Generic (genericShow)
import Effect (Effect)
import Effect.Aff (Aff)

foreign import registerSlashCommandImpl :: Fn2 String (Effect (Promise Unit)) (Effect Unit)

registerSlashCommand ::String -> Aff Unit -> Effect Unit
registerSlashCommand name f = runFn2 registerSlashCommandImpl name (fromAff f)

type BlockUUID = String
type EntityID = Int

newtype BlockEntity = BlockEntity {
  parent :: EntityID,
  children :: Maybe (Array (Either BlockEntity BlockUUID)),
  content :: String
}

derive instance genericBlockEntity :: Generic BlockEntity _

instance showBlockEntity :: Show BlockEntity where
  show x = genericShow x

content :: BlockEntity -> String
content (BlockEntity a) = a.content

children :: BlockEntity -> Maybe (Array (Either BlockEntity BlockUUID))
children (BlockEntity a) = a.children

foreign import getCurrentBlockImpl :: (forall x. x -> Maybe x) -> (forall x. Maybe x) -> (forall x y. x -> Either x y) -> (forall x y. y -> Either x y) -> Effect (Promise (Maybe BlockEntity))

getCurrentBlock :: Aff (Maybe BlockEntity)
getCurrentBlock = toAffE $ getCurrentBlockImpl Just Nothing Left Right

foreign import getBlockNImpl :: (forall x. x -> Maybe x) -> (forall x. Maybe x) -> (forall x y. x -> Either x y) -> (forall x y. y -> Either x y) -> EntityID -> Effect (Promise (Maybe BlockEntity))
foreign import getBlockUImpl :: (forall x. x -> Maybe x) -> (forall x. Maybe x) -> (forall x y. x -> Either x y) -> (forall x y. y -> Either x y) -> BlockUUID -> Effect (Promise (Maybe BlockEntity))

getBlock :: Either EntityID BlockUUID -> Aff (Maybe BlockEntity)
getBlock e = toAffE
  case e of
    Left n -> getBlockNImpl Just Nothing Left Right n
    Right u -> getBlockUImpl Just Nothing Left Right u
