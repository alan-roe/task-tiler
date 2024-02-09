module Topic.Checkbox where

import Prelude

import Data.Array (head, take)
import Data.Generic.Rep (class Generic)
import Data.Maybe (maybe)
import Data.Show.Generic (genericShow)
import Data.String (Pattern(..), split)
import Foreign (unsafeToForeign)
import Simple.JSON (class WriteForeign)

data CheckboxState
  = None
  | Todo
  | Doing
  | Done

derive instance genericCheckboxState :: Generic CheckboxState _

instance writeCheckboxStateForeign :: WriteForeign CheckboxState where
  writeImpl = unsafeToForeign <<< show

instance checkboxStateShow :: Show CheckboxState where
  show = genericShow

todoStates :: Array String
todoStates = [ "TODO", "LATER", "DOING", "NOW", "DONE" ]

checkboxState :: String -> CheckboxState
checkboxState s =
  maybe None strToState <<< 
  head <<<
  take 1 <<< 
  split (Pattern " ") 
    $ s
  where
  strToState "TODO" = Todo
  strToState "LATER" = Todo
  strToState "DOING" = Doing
  strToState "NOW" = Doing
  strToState "DONE" = Done
  strToState _ = None