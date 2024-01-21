module Logseq where

import Prelude

import Control.Promise (Promise, toAffE)
import Data.Either (Either(..))
import Data.Function.Uncurried (Fn2, runFn2)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)

-- logseq
foreign import ready :: Effect Unit -> Effect Unit

-- UI

-- Returns ID of message
foreign import showMsgImpl :: String -> Effect (Promise String)

showMsg :: String -> Aff String
showMsg n = toAffE $ showMsgImpl n

-- Editor
foreign import registerSlashCommandImpl :: Fn2 String (Effect Unit) (Effect Unit)

registerSlashCommand ::String -> Effect Unit -> Effect Unit
registerSlashCommand name f = runFn2 registerSlashCommandImpl name f

type BlockUUID = String

type BlockUUIDTuple = {
  uuid :: BlockUUID
}

newtype BlockEntity = BlockEntity {
  children :: Maybe (Either BlockEntity BlockUUIDTuple),
  content :: String
}

foreign import getCurrentBlockImpl :: (forall x. x -> Maybe x) -> (forall x. Maybe x) -> (forall x y. x -> Either x y) -> (forall x y. y -> Either x y) -> Effect (Promise BlockEntity)

getCurrentBlock :: Aff BlockEntity
getCurrentBlock = toAffE $ getCurrentBlockImpl Just Nothing Left Right