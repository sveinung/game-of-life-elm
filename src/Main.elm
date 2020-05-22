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


---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }



---- UPDATE ----


type Msg
    = Tick Time.Posix
    | StartStop
    | SetGame String
    | ToggleCell (Int, Int, Bool)


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
        ToggleCell (rowIndex, columnIndex, alive) ->
            ( { model | grid = updateCell model.grid rowIndex columnIndex alive }
            , Cmd.none
            )


updateCell : Grid -> Int -> Int -> Bool -> Grid
updateCell grid rowIndex columnIndex alive =
    let
        row = Array.get rowIndex grid
        newColumn =
            case row of
                Nothing -> Array.empty
                Just r -> Array.set columnIndex alive r
    in
    Array.set rowIndex newColumn grid


iterate : Grid -> Grid
iterate grid =
    grid
        |> Array.toIndexedList
        |> List.map (iterateRow grid)
        |> Array.fromList


iterateRow : Grid -> ( Int, Row ) -> Row
iterateRow grid ( rowIndex, row ) =
    row
        |> Array.toIndexedList
        |> List.map (iterateCell grid rowIndex)
        |> Array.fromList


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



---- MODEL ----


type alias Model =
    { grid : Grid
    , running : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { grid = defaultGame
      , running = False
      }
    , Cmd.none
    )



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ controls model
        , htmlGrid model.grid
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


htmlGrid : Grid -> Html Msg
htmlGrid grid =
    let
        rows =
            grid
                |> Array.toIndexedList
                |> List.map htmlRow
    in
    table [] rows


htmlRow : (Int, Row) -> Html Msg
htmlRow (rowIndex, row) =
    let
        cells =
            row
                |> Array.toIndexedList
                |> List.map (htmlCell rowIndex)
    in
    tr [] cells


htmlCell : Int -> (Int, Bool) -> Html Msg
htmlCell rowIndex (columnIndex, alive) =
    td
        [ class
            (if alive then
                "alive cell"

             else
                "cell"
            )
        , onClick (ToggleCell (rowIndex, columnIndex, not alive))
        ]
        []



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.running then
        Time.every 200 Tick
    else
        Sub.none

