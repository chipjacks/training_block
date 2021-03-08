module ActivityForm.Selection exposing (add, copy, delete, get, init, select, selectedIndex, set, shift, toList, updateAll)

import Activity
import Activity.Types exposing (Activity, ActivityData)
import ActivityForm.Types exposing (Selection)
import Array


init : List a -> Selection a
init list =
    ( 0, list )


toList : Selection a -> List a
toList ( _, list ) =
    list


selectedIndex : Selection a -> Int
selectedIndex ( index, _ ) =
    index


select : Int -> Selection a -> Selection a
select newIndex ( index, list ) =
    ( newIndex, list )


get : Selection a -> Maybe a
get ( index, list ) =
    Array.fromList list
        |> Array.get index


set : a -> Selection a -> Selection a
set item ( index, list ) =
    ( index
    , Array.fromList list
        |> Array.set index item
        |> Array.toList
    )


updateAll : (a -> a) -> Selection a -> Selection a
updateAll transform ( index, list ) =
    ( index
    , List.map transform list
    )


add : a -> Selection a -> Selection a
add item ( index, list ) =
    ( List.length list, list ++ [ item ] )


copy : Selection a -> Selection a
copy ( index, list ) =
    let
        tail =
            List.drop index list

        copied =
            case List.head tail of
                Just lap ->
                    [ lap ]

                _ ->
                    []
    in
    ( index + 1
    , List.take index list ++ copied ++ tail
    )


shift : Bool -> Selection a -> Selection a
shift up ( index, list ) =
    let
        ( indexA, indexB ) =
            if up then
                ( index - 1, index )

            else
                ( index, index + 1 )

        array =
            Array.fromList list

        shiftedList =
            [ Array.slice 0 indexA array
            , Array.slice indexB (indexB + 1) array
            , Array.slice indexA (indexA + 1) array
            , Array.slice (indexB + 1) (Array.length array) array
            ]
                |> List.map Array.toList
                |> List.concat
    in
    if indexA < 0 || indexB >= List.length list then
        ( index
        , list
        )

    else
        ( if up then
            index - 1

          else
            index + 1
        , shiftedList
        )


delete : Selection a -> Selection a
delete ( index, laps ) =
    ( if index < (List.length laps - 1) then
        index

      else
        index - 1
    , List.take index laps ++ List.drop (index + 1) laps
    )
