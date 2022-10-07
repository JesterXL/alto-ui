module Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Json.Decode as JD
import Time exposing (Posix, Zone)

type alias Model = 
    { screen : Screen }

initialModel : Model
initialModel =
    { screen = Loading }

type Screen
    = Loading
    | MyTrip
    | Driver
    | Vehicle
    | Vibe

type alias Trip =
    { arrival : Posix
    , timeZone : Zone
    , fareMin : Int
    , fareMax : Int
    , passengersMin : Int
    , passengersMax : Int
    , payment : String
    , dropoff : Location
    , pickup : Location
    , notes : String }

type alias Location =
    { name : Maybe String
    , street1 : String
    , street2 : String
    , city : String
    , state : String
    , zipcode : String
    , lat : Maybe String
    , long : Maybe String }



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
        MyTrip ->
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
