module Activity exposing (Activity, ActivityData(..), Distance(..), Id, Seconds, activityTypeToString, decoder, distance, encoder, mprLevel, newId)

import Date exposing (Date)
import Emoji
import Enum exposing (Enum)
import Json.Decode as Decode
import Json.Encode as Encode
import MPRLevel
import Pace exposing (Pace)
import Random
import Task exposing (Task)


type alias Activity =
    { id : Id
    , date : Date
    , description : String
    , data : ActivityData
    }


type ActivityData
    = Run Seconds (Maybe Pace) Bool
    | Interval Seconds (Maybe Pace) Bool
    | Race Seconds Distance Bool
    | Other Seconds Bool
    | Note String
    | Session (List Activity)


activityTypeToString : ActivityData -> String
activityTypeToString aType =
    case aType of
        Run _ _ _ ->
            "Run"

        Interval _ _ _ ->
            "Interval"

        Race _ _ _ ->
            "Race"

        Other _ _ ->
            "Other"

        Note _ ->
            "Note"

        Session _ ->
            "Session"


newId : Random.Generator String
newId =
    let
        digitsToString digits =
            List.map String.fromInt digits
                |> String.join ""
    in
    Random.list 10 (Random.int 0 9)
        |> Random.map digitsToString


mprLevel : Activity -> Maybe Int
mprLevel activity =
    case activity.data of
        Race seconds distance_ _ ->
            MPRLevel.lookup MPRLevel.Neutral
                (distance.toString distance_)
                seconds
                |> Result.map (\( rt, level ) -> level)
                |> Result.toMaybe

        _ ->
            Nothing


type alias Id =
    String


type alias Seconds =
    Int


type Distance
    = FiveK
    | EightK
    | FiveMile
    | TenK
    | FifteenK
    | TenMile
    | TwentyK
    | HalfMarathon
    | TwentyFiveK
    | ThirtyK
    | Marathon


distance : Enum Distance
distance =
    Enum.create
        [ FiveK
        , EightK
        , FiveMile
        , TenK
        , FifteenK
        , TenMile
        , TwentyK
        , HalfMarathon
        , TwentyFiveK
        , ThirtyK
        , Marathon
        ]
        (\a ->
            case a of
                FiveK ->
                    "5k"

                EightK ->
                    "8k"

                FiveMile ->
                    "5 mile"

                TenK ->
                    "10k"

                FifteenK ->
                    "15k"

                TenMile ->
                    "10 mile"

                TwentyK ->
                    "20k"

                HalfMarathon ->
                    "Half Marathon"

                TwentyFiveK ->
                    "25k"

                ThirtyK ->
                    "30k"

                Marathon ->
                    "Marathon"
        )



-- SERIALIZATION


decoder : Decode.Decoder Activity
decoder =
    Decode.map4 Activity
        (Decode.field "id" Decode.string)
        (Decode.field "date" dateDecoder)
        (Decode.field "description" Decode.string)
        (Decode.field "data" activityDataDecoder)


activityDataDecoder : Decode.Decoder ActivityData
activityDataDecoder =
    let
        runDecoder =
            Decode.map3 Run
                (Decode.field "duration" Decode.int)
                (Decode.maybe (Decode.field "pace" Decode.int))
                (Decode.field "completed" Decode.bool)

        intervalDecoder =
            Decode.map3 Interval
                (Decode.field "duration" Decode.int)
                (Decode.maybe (Decode.field "pace" Decode.int))
                (Decode.field "completed" Decode.bool)

        raceDecoder =
            Decode.map3 Race
                (Decode.field "duration" Decode.int)
                (Decode.field "distance" distance.decoder)
                (Decode.field "completed" Decode.bool)

        otherDecoder =
            Decode.map2 Other
                (Decode.field "duration" Decode.int)
                (Decode.field "completed" Decode.bool)

        noteDecoder =
            Decode.map Note
                (Decode.field "emoji" Decode.string)

        sessionDecoder =
            Decode.map Session
                (Decode.field "activities" (Decode.list (Decode.lazy (\a -> decoder))))
    in
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\dataType ->
                case dataType of
                    "run" ->
                        runDecoder

                    "interval" ->
                        intervalDecoder

                    "race" ->
                        raceDecoder

                    "other" ->
                        otherDecoder

                    "note" ->
                        noteDecoder

                    "session" ->
                        sessionDecoder

                    _ ->
                        Decode.fail ("Invalid type: " ++ dataType)
            )


encoder : Activity -> Encode.Value
encoder activity =
    let
        dataEncoder data =
            case data of
                Run minutes paceM completed ->
                    Encode.object <|
                        [ ( "type", Encode.string "run" )
                        , ( "duration", Encode.int minutes )
                        , ( "completed", Encode.bool completed )
                        ]
                            ++ (Maybe.map (\p -> [ ( "pace", Encode.int p ) ]) paceM
                                    |> Maybe.withDefault []
                               )

                Interval seconds paceM completed ->
                    Encode.object <|
                        [ ( "type", Encode.string "interval" )
                        , ( "duration", Encode.int seconds )
                        , ( "completed", Encode.bool completed )
                        ]
                            ++ (Maybe.map (\p -> [ ( "pace", Encode.int p ) ]) paceM
                                    |> Maybe.withDefault []
                               )

                Race minutes distance_ completed ->
                    Encode.object
                        [ ( "type", Encode.string "race" )
                        , ( "duration", Encode.int minutes )
                        , ( "distance", distance.encode distance_ )
                        , ( "completed", Encode.bool completed )
                        ]

                Other minutes completed ->
                    Encode.object
                        [ ( "type", Encode.string "other" )
                        , ( "duration", Encode.int minutes )
                        , ( "completed", Encode.bool completed )
                        ]

                Note emoji ->
                    Encode.object
                        [ ( "type", Encode.string "note" )
                        , ( "emoji", Encode.string emoji )
                        ]

                Session activities ->
                    Encode.object
                        [ ( "type", Encode.string "session" )
                        , ( "activities", Encode.list encoder activities )
                        ]
    in
    Encode.object
        [ ( "id", Encode.string activity.id )
        , ( "date", Encode.string (Date.toIsoString activity.date) )
        , ( "description", Encode.string activity.description )
        , ( "data", dataEncoder activity.data )
        ]


dateDecoder : Decode.Decoder Date
dateDecoder =
    let
        isoStringDecoder str =
            case Date.fromIsoString str of
                Ok date ->
                    Decode.succeed date

                Err _ ->
                    Decode.fail "Invalid date string"
    in
    Decode.string
        |> Decode.andThen isoStringDecoder
