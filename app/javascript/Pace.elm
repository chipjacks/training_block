module Pace exposing (TrainingPace(..), TrainingPaceList, calculate, paceFromString, paceToString, secondsToTrainingPace, trainingPace, trainingPaceToSeconds, trainingPaces)

import Activity.Types exposing (ActivityData, DistanceUnits(..))
import Array exposing (Array)
import Distance
import Duration
import Enum exposing (Enum)
import Json.Decode as Decode
import MPRData
import MPRLevel exposing (RunnerType(..))
import Parser


calculate : Int -> Float -> Int
calculate duration distance =
    toFloat duration
        / Distance.fromMeters Miles distance
        |> round


paceToString : Int -> String
paceToString seconds =
    Duration.toString seconds


paceFromString : String -> Maybe Int
paceFromString str =
    case Parser.run Duration.parser str of
        Ok [ 0, mins, secs ] ->
            Just (mins * 60 + secs)

        Ok [ mins, secs ] ->
            Just (mins * 60 + secs)

        Ok [ mins ] ->
            Just (mins * 60)

        _ ->
            Nothing



-- TRAINING PACES


type alias TrainingPaceList =
    List ( TrainingPace, ( String, String ) )


trainingPacesTable : RunnerType -> Array (Array ( String, String ))
trainingPacesTable runnerType =
    let
        json =
            case runnerType of
                MPRLevel.Neutral ->
                    MPRData.neutralTraining

                MPRLevel.Aerobic ->
                    MPRData.aerobicTraining

                MPRLevel.Speed ->
                    MPRData.speedTraining
    in
    Decode.decodeString (Decode.array (Decode.array (Decode.list Decode.string))) json
        |> Result.withDefault Array.empty
        |> Array.map (\a -> Array.map (\t -> toTuple t |> Maybe.withDefault ( "", "" )) a)


trainingPaces : ( RunnerType, Int ) -> Maybe TrainingPaceList
trainingPaces ( runnerType, level ) =
    Array.get (level - 1) (trainingPacesTable runnerType)
        |> Maybe.map
            (\arr ->
                Array.toList arr
                    |> List.map2 (\x y -> Tuple.pair x y) (List.map Tuple.second (List.drop 1 trainingPace.list))
            )


trainingPaceToSeconds : TrainingPaceList -> TrainingPace -> Int
trainingPaceToSeconds paces tp =
    if tp == VeryEasy then
        List.head paces
            |> Maybe.map (\( _, ( minPace, maxPace ) ) -> (paceFromString maxPace |> Maybe.withDefault 0) + 1)
            |> Maybe.withDefault 0

    else
        List.filter (\( name, _ ) -> name == tp) paces
            |> List.head
            |> Maybe.map
                (\( _, ( minPace, maxPace ) ) -> paceFromString maxPace |> Maybe.withDefault 0)
            |> Maybe.withDefault 0


secondsToTrainingPace : TrainingPaceList -> Int -> TrainingPace
secondsToTrainingPace paces seconds =
    List.map (\( name, ( minPace, maxPace ) ) -> ( name, Duration.timeStrToSeconds maxPace |> Result.withDefault 0 )) paces
        |> List.filter (\( name, maxPaceSeconds ) -> seconds <= maxPaceSeconds)
        |> List.reverse
        |> List.head
        |> Maybe.map Tuple.first
        |> Maybe.withDefault VeryEasy


type TrainingPace
    = VeryEasy
    | Easy
    | Moderate
    | Steady
    | Brisk
    | Aerobic
    | Lactate
    | Groove
    | VO2
    | Fast


trainingPace : Enum TrainingPace
trainingPace =
    Enum.create
        [ ( "Very Easy", VeryEasy )
        , ( "Easy", Easy )
        , ( "Moderate", Moderate )
        , ( "Steady", Steady )
        , ( "Brisk", Brisk )
        , ( "Aerobic", Aerobic )
        , ( "Lactate", Lactate )
        , ( "Groove", Groove )
        , ( "VO2", VO2 )
        , ( "Fast", Fast )
        ]


toTuple : List a -> Maybe ( a, a )
toTuple l =
    case l of
        [ a, b ] ->
            Just ( a, b )

        _ ->
            Nothing
