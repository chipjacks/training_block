module Duration.View exposing (input)

import Html exposing (Html, text)
import Html.Attributes exposing (style)
import UI.Input
import UI.Label
import UI.Layout exposing (column, compactColumn, row)


input : (( String, String, String ) -> msg) -> ( String, String, String ) -> Html msg
input msg ( hrs, mins, secs ) =
    row []
        [ compactColumn [ style "width" "3rem" ]
            [ UI.Label.input "HOURS" |> UI.Label.view
            , UI.Input.number (\h -> msg ( h, mins, secs )) 9
                |> UI.Input.withAttributes
                    [ style "border-top-right-radius" "0"
                    , style "border-bottom-right-radius" "0"
                    ]
                |> UI.Input.view hrs
            ]
        , compactColumn [ style "width" "3.5rem" ]
            [ UI.Label.input "MINS" |> UI.Label.view
            , UI.Input.number (\m -> msg ( hrs, m, secs )) 60
                |> UI.Input.withAttributes
                    [ style "border-top-left-radius" "0"
                    , style "border-bottom-left-radius" "0"
                    , style "border-top-right-radius" "0"
                    , style "border-bottom-right-radius" "0"
                    ]
                |> UI.Input.view mins
            ]
        , compactColumn [ style "width" "3.5rem" ]
            [ UI.Label.input "SECS" |> UI.Label.view
            , UI.Input.number (\s -> msg ( hrs, mins, s )) 60
                |> UI.Input.withAttributes
                    [ style "border-top-left-radius" "0"
                    , style "border-bottom-left-radius" "0"
                    ]
                |> UI.Input.view secs
            ]
        ]
