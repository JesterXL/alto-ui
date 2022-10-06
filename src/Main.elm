module Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Url
import Json.Decode as JD
import Browser.Navigation as Nav

type alias Model =
    { key : Nav.Key
    , url : Url.Url }

initialModel : Nav.Key -> Url.Url -> Model

initialModel key url =
    { key = key 
    , url = url }

type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg)
update msg model =
    case msg of
        LinkClicked _ ->
            ( model, Cmd.none )
        UrlChanged _ ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view _ =
    { title = "Sup"
    , body = [ div []
        [ div [][text "Hey"]
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
