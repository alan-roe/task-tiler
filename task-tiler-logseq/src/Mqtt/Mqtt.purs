module Mqtt.Mqtt where

import Prelude

import Data.Function.Uncurried (Fn2, Fn4, runFn2, runFn4)
import Effect (Effect)

type IClientPublishOptions =
  { retain :: Boolean
  }

foreign import data MqttClient :: Type

type IClientOptions =
  { clientId :: String
  , username :: String
  , password :: String
  }

foreign import connectImpl :: Fn2 String IClientOptions (Effect MqttClient)

connect :: String -> IClientOptions -> Effect MqttClient
connect addr opts = runFn2 connectImpl addr opts

foreign import publishImpl :: Fn4 MqttClient String String IClientPublishOptions (Effect Unit)

publish :: MqttClient -> String -> String -> IClientPublishOptions -> Effect Unit
publish client topic msg opts = runFn4 publishImpl client topic msg opts
