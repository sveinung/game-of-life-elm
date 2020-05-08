module Main exposing (..)

import Array exposing (Array)
import Browser
import Html exposing (Html, button, div, table, td, text, tr)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Time


---- MODEL ----


x =
    True


o =
    False


type alias Row =
    Array Bool


type alias Grid =
    Array Row


type alias Model =
    { grid : Grid
    , running : Bool
    }


toArray : List (List Bool) -> Grid
toArray listGrid =
    listGrid
        |> List.map Array.fromList
        |> Array.fromList


toList : Grid -> List (List Bool)
toList listGrid =
    listGrid
        |> Array.map Array.toList
        |> Array.toList


blinker : Grid
blinker =
    toArray [ [ o, o, o, o, o ]
    , [ o, o, o, o, o ]
    , [ o, x, x, x, o ]
    , [ o, o, o, o, o ]
    , [ o, o, o, o, o ]
    ]


init : ( Model, Cmd Msg )
init =
    ( { grid = blinker
      , running = False
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = Tick Time.Posix


getRow : Grid -> Int -> Row
getRow grid rowIndex =
    let
        cellRow =
            grid
                |> Array.get rowIndex
    in
    case cellRow of
        Nothing ->
            Array.empty

        Just value ->
            value


getCell : Grid -> Int -> Int -> Bool
getCell grid rowIndex columnIndex =
    let
        cell =
            getRow grid rowIndex
                |> Array.get columnIndex
    in
    case cell of
        Nothing ->
            False

        Just value ->
            value


iterateCell : Grid -> Int -> (Int, Bool) -> Bool
iterateCell grid rowIndex (columnIndex, alive) =
    let
        getCellInGrid = getCell grid
        livingNeighbours =
            [ getCellInGrid (rowIndex - 1) (columnIndex - 1)
            , getCellInGrid (rowIndex - 1) (columnIndex)
            , getCellInGrid (rowIndex - 1) (columnIndex + 1)
            , getCellInGrid (rowIndex) (columnIndex - 1)
            , getCellInGrid (rowIndex) (columnIndex + 1)
            , getCellInGrid (rowIndex + 1) (columnIndex - 1)
            , getCellInGrid (rowIndex + 1) (columnIndex)
            , getCellInGrid (rowIndex + 1) (columnIndex + 1)
            ]
            |> List.filter identity
        numberOfLivingNeighbours = List.length livingNeighbours
    in
    if alive then
        numberOfLivingNeighbours == 2 || numberOfLivingNeighbours == 3
    else
        numberOfLivingNeighbours == 3


iterateRow : Grid -> (Int, Row) -> Row
iterateRow grid (rowIndex, row) =
    row
        |> Array.toIndexedList
        |> List.map (iterateCell grid rowIndex)
        |> Array.fromList


iterate : Grid -> Grid
iterate grid =
    grid
        |> Array.toIndexedList
        |> List.map (iterateRow grid)
        |> Array.fromList


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick _ ->
            ( { grid = iterate model.grid
            , running = True
            }
            , Cmd.none )



---- VIEW ----


htmlCell : Bool -> Html msg
htmlCell alive =
    td
        [ class
            (if alive then
                "alive cell"

             else
                "cell"
            )
        ]
        []


htmlRow : List Bool -> Html msg
htmlRow row =
    tr []
        (row |> List.map htmlCell)


view : Model -> Html Msg
view model =
    let
        listGrid = toList model.grid
    in
    div [ class "app" ]
        [ table [] (listGrid |> List.map htmlRow)
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every 1000 Tick



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }
