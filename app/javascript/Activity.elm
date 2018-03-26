module Activity exposing (Activity, list, decoder, ActivityType(..), groupByType)

import Http exposing (..)
import Json.Decode as JD exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional, custom)
import Date exposing (Date)


type alias Activity =
    { id : String
    , name : String
    , distance : Float
    , movingTime : Int
    , elapsedTime : Int
    , totalElevationGain : Float
    , type_ : ActivityType
    , startDate : Date
    , startDateLocal : Date
    , averageSpeed : Float
    , maxSpeed : Float
    }


type ActivityType
    = Run
    | Ride
    | Weights
    | Swim
    | Other


list : Date -> Date -> Request (List Activity)
list startDate endDate =
    let
        request_url =
            url "/activities"
                [ ( "before", ((Date.toTime endDate / 1000) |> toString) ) ]
    in
        Http.get request_url (JD.list decoder)


decoder : Decoder Activity
decoder =
    decode Activity
        |> required "id" (JD.int |> JD.andThen (JD.succeed << toString))
        |> required "name" JD.string
        |> required "distance" JD.float
        |> required "moving_time" JD.int
        |> required "elapsed_time" JD.int
        |> required "total_elevation_gain" JD.float
        |> custom (JD.field "type" JD.string |> JD.andThen (JD.succeed << typeFromString))
        |> custom (JD.field "start_date" JD.string |> JD.andThen (fromResult << Date.fromString))
        |> custom (JD.field "start_date_local" JD.string |> JD.andThen (fromResult << Date.fromString))
        |> custom (JD.field "average_speed" JD.float)
        |> custom (JD.field "max_speed" JD.float)


groupByType : List Activity -> List (List Activity)
groupByType activities =
    activityTypes
        |> List.map (\t -> List.filter (\a -> a.type_ == t) activities)
        |> List.filter (\l -> List.length l > 0)


activityTypes : List ActivityType
activityTypes =
    [ Run, Ride, Weights, Swim, Other ]


-- INTERNAL 

url : String -> List ( String, String ) -> String
url baseUrl args =
    case args of
        [] ->
            baseUrl

        _ ->
            baseUrl ++ "?" ++ String.join "&" (List.map queryPair args)


queryPair : ( String, String ) -> String
queryPair ( key, value ) =
    Http.encodeUri key ++ "=" ++ Http.encodeUri value


typeFromString : String -> ActivityType
typeFromString str =
    case str of
        "Run" ->
            Run

        "Ride" ->
            Ride

        "WeightTraining" ->
            Weights

        "Swim" ->
            Swim

        _ ->
            Other


fromResult : Result String a -> Decoder a
fromResult result =
  case result of
    Ok a -> JD.succeed a
    Err errorMessage -> JD.fail errorMessage