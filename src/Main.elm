module Main exposing (..)

import Array exposing (Array)
import Browser
import Dict
import Game exposing (Grid, Row, defaultGame, games, getGame)
import Html exposing (Html, button, div, option, select, table, td, text, tr)
import Html.Attributes exposing (class, value)
import Html.Events exposing (on, onClick, targetValue)
import Time
import Json.Decode exposing (Decoder)


---- MODEL ----


type alias Model =
    { grid : Grid
    , running : Bool
    }


toList : Grid -> List (List Bool)
toList listGrid =
    listGrid
        |> Array.map Array.toList
        |> Array.toList


init : ( Model, Cmd Msg )
init =
    ( { grid = defaultGame
      , running = False
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = Tick Time.Posix
    | StartStop
    | SetGame String


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


iterateCell : Grid -> Int -> ( Int, Bool ) -> Bool
iterateCell grid rowIndex ( columnIndex, alive ) =
    let
        getCellInGrid =
            getCell grid

        livingNeighbours =
            [ getCellInGrid (rowIndex - 1) (columnIndex - 1)
            , getCellInGrid (rowIndex - 1) columnIndex
            , getCellInGrid (rowIndex - 1) (columnIndex + 1)
            , getCellInGrid rowIndex (columnIndex - 1)
            , getCellInGrid rowIndex (columnIndex + 1)
            , getCellInGrid (rowIndex + 1) (columnIndex - 1)
            , getCellInGrid (rowIndex + 1) columnIndex
            , getCellInGrid (rowIndex + 1) (columnIndex + 1)
            ]
                |> List.filter identity

        numberOfLivingNeighbours =
            List.length livingNeighbours
    in
    if alive then
        numberOfLivingNeighbours == 2 || numberOfLivingNeighbours == 3

    else
        numberOfLivingNeighbours == 3


iterateRow : Grid -> ( Int, Row ) -> Row
iterateRow grid ( rowIndex, row ) =
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
            ( { model | grid = iterate model.grid }
            , Cmd.none
            )
        StartStop ->
            ( { model | running = not model.running }
            , Cmd.none)
        SetGame game ->
            ( { grid = getGame game
              , running = model.running
              }
            , Cmd.none
            )


---- VIEW ----


view : Model -> Html Msg
view model =
    let
        listGrid =
            toList model.grid
    in
    div [ class "app" ]
        [ controls model
        , table [] (listGrid |> List.map htmlRow)
        ]


controls : Model -> Html Msg
controls model =
    let
        startStopButtonText =
            if model.running then
                "Stop"
            else
                "Start"
    in
    div []
        [ select [ on "change" (Json.Decode.map SetGame targetValue) ] options
        , button [ onClick StartStop ] [ text startStopButtonText ]
        ]


options : List (Html msg)
options =
    games
        |> Dict.toList
        |> List.map toOption


toOption : (String, Grid) -> Html msg
toOption (gameName, _) =
    option [ value gameName ] [ text gameName ]


htmlRow : List Bool -> Html msg
htmlRow row =
    tr []
        (row |> List.map htmlCell)


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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.running then
        Time.every 200 Tick
    else
        Sub.none


---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }
