module Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Url
import Json.Decode as JD
import Browser.Navigation as Nav
import Url.Parser as UrlParser

type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , route : Route }

type Route
    = Loading
    | NotFound
    | Trip
    | Driver
    | Vehicle
    | Destination

routeParser : UrlParser.Parser (Route -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map Loading UrlParser.top
        , UrlParser.map Trip (UrlParser.s "trip")
        , UrlParser.map Driver (UrlParser.s "driver")
        , UrlParser.map Vehicle (UrlParser.s "vehicle")
        , UrlParser.map Destination (UrlParser.s "destination")
        ]


parseRoute : Url.Url -> Route
parseRoute url =
    UrlParser.parse routeParser url
        |> Maybe.withDefault NotFound

initialModel : Nav.Key -> Url.Url -> Model

initialModel key url =
    { key = key 
    , url = url
    , route = parseRoute url }

type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg)
update msg model =
    case msg of
        LinkClicked _ ->
            ( model, Cmd.none )
        UrlChanged url ->
            ( { model | url = url, route = parseRoute url }, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "Alto"
    , body = [ div []
        [ case model.route of
            Loading ->
                div [][text "Loading..."]
            NotFound ->
                div [][text "404 Not Found"]
            Trip ->
                div [][text "Trip"]
            Driver ->
                div [][text "Driver"]
            Vehicle ->
                div [][text "Vehicle"]
            Destination ->
                div [][text "Destination"]
        ]
    ] }


init : JD.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( initialModel key url, Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none

main : Program JD.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }
