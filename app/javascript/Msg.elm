module Msg exposing (Msg(..))

import ActivityCache
import Block
import Mouse
import Navigation exposing (Location)
import Route exposing (Route)


type Msg
    = UpdateActivityCache ActivityCache.Msg
    | OnLocationChange Location
    | NewPage Route
    | BlockEvent (Maybe ( Block.Event, Block.Model ))
    | MouseMsg Mouse.Position
    | ZoomToday
    | NoOp
