module Main exposing (..)

import Browser
import Html exposing (Html, button, div, table, td, tr, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)

import Array


---- MODEL ----


x = True
o = False

type alias Row = List Bool
type alias Grid = List Row

blinker : Grid
blinker = [
    [o, o, o, o, o],
    [o, o, o, o, o],
    [o, x, x, x, o],
    [o, o, o, o, o],
    [o, o, o, o, o]
    ]

init : ( Grid, Cmd Msg )
init =
    ( blinker, Cmd.none )


---- UPDATE ----


type Msg = Increment | Decrement

getRow : Grid -> Int -> Row
getRow grid rowIndex =
    let
        cellRow = Array.fromList grid
            |> Array.get rowIndex
    in
        case cellRow of
            Nothing -> []
            Just value -> value

getCell : Grid ->  Int -> Int -> Bool
getCell grid rowIndex columnIndex =
    let
        cell = getRow grid rowIndex
            |> Array.fromList
            |> Array.get columnIndex
    in
        case cell of
            Nothing -> False
            Just value -> value

iterate : Grid -> Grid
iterate grid =
    grid

update : Msg -> Grid -> ( Grid, Cmd Msg )
update msg model =
    ( blinker, Cmd.none )


---- VIEW ----


htmlCell : Bool -> Html msg
htmlCell alive =
    td [ class (if alive then "alive cell" else "cell")] []

htmlRow : Row -> Html msg
htmlRow row =
    tr []
        (row |> List.map htmlCell)

view : Grid -> Html Msg
view grid =
  div []
    [ button [ onClick Decrement ] [ text "-" ]
    , table [] (grid |> List.map htmlRow)
    , button [ onClick Increment ] [ text "+" ]
    ]


---- PROGRAM ----


main : Program () Grid Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
