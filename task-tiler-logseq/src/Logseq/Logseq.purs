module Logseq
  ( ready
  , showMsg
  )
  where

import Prelude

import Control.Promise (Promise, toAffE)
import Effect (Effect)
import Effect.Aff (Aff)

-- logseq
foreign import ready :: Effect Unit -> Effect Unit

-- UI

-- Returns ID of message
foreign import showMsgImpl :: String -> Effect (Promise String)

showMsg :: String -> Aff String
showMsg n = toAffE $ showMsgImpl n
