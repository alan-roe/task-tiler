module Logseq where

import Prelude

import Control.Promise (Promise, toAffE)
import Data.Function.Uncurried (Fn2, runFn2)
import Effect (Effect)
import Effect.Aff (Aff)

-- Returns ID of message
foreign import showMsgImpl :: String -> Effect (Promise String)

showMsg :: String -> Aff String
showMsg n = toAffE $ showMsgImpl n

foreign import registerSlashCommandImpl :: Fn2 String (Effect Unit) (Effect Unit)

registerSlashCommand ::String -> Effect Unit -> Effect Unit
registerSlashCommand name f = runFn2 registerSlashCommandImpl name f

foreign import ready :: Effect Unit -> Effect Unit
