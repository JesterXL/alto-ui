module Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Json.Decode as JD

type alias Model = 
    { screen : Screen }

type Screen
    = Loading
    | Trip
    | Driver
    | Vehicle
    | Vibe


initialModel : Model
initialModel =
    { screen = Loading }

type Msg
    = Noop


update : Msg -> Model -> ( Model, Cmd Msg)
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

view : Model -> Html Msg 
view model =
    case model.screen of
        Loading ->
            div [][text "Loading..."]
        Trip ->
            div [][text "Trip"]
        Driver ->
            div [][text "Driver"]
        Vehicle ->
            div [][text "Vehicle"]
        Vibe ->
            div [][text "Vibe"]


init : JD.Value -> ( Model, Cmd Msg )
init _ =
    ( initialModel, Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none

main : Program JD.Value Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
