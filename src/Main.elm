module Main exposing (main)

import Browser
import Html exposing (Html, div, text, button, img, h1, h2, span, p)
import Html.Attributes exposing (src, class)
import Html.Events exposing (onClick)
import Json.Decode as JD
import Time exposing (Posix, Zone, millisToPosix, utc)
import Http

main : Program JD.Value Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none

type alias Model = 
    { screen : Screen
    , tripData : Maybe TripData  }

initialModel : Model
initialModel =
    { screen = Loading
    , tripData = Nothing }

type Screen
    = Loading
    | ErrorScreen
    | TripScreen
    | DriverScreen
    | VehicleScreen
    | VibeScreen

type alias Trip =
    { arrival : Posix
    , timeZone : Zone
    , fare : Fare
    , passengers : Passengers
    , payment : String
    , dropoff : Location
    , pickup : Location
    , notes : String }

type alias Fare =
    { min : Int
    , max : Int }

type alias Passengers =
    { min : Int 
    , max : Int }

type alias Location =
    { name : Maybe String
    , street1 : String
    , street2 : Maybe String
    , city : String
    , state : String
    , zipcode : String
    , lat : Maybe String
    , long : Maybe String }

type alias Driver =
    { name : String
    , image : String
    , bio : String
    , phone : Maybe String }

type alias Vehicle =
    { license : String
    , make : String
    , color : String
    , image : String }

type alias Vibe =
    { name : String }

type alias TripData =
    { trip : Trip 
    , driver : Driver 
    , vehicle : Vehicle
    , vibe : Vibe }

type Msg
    = GotTripData (Result Http.Error TripData)


update : Msg -> Model -> ( Model, Cmd Msg)
update msg model =
    case msg of
        GotTripData result ->
            case result of
                Err err ->
                    let
                        _ = Debug.log "trip data failed" err
                    in
                    ( { model | tripData = Nothing, screen = ErrorScreen } , Cmd.none)
                Ok tripData ->
                    ( { model | tripData = Just tripData, screen = TripScreen }, Cmd.none )


init : JD.Value -> ( Model, Cmd Msg )
init _ =
    ( 
        initialModel
        , Http.get
            { url = "http://localhost:3000"
            , expect = Http.expectJson GotTripData tripDataDecoder
            }
    )

tripDataDecoder =
    JD.map4 TripData
        (JD.field "trip" tripDecoder)
        (JD.field "driver" driverDecoder)
        (JD.field "vehicle" vehicleDecoder)
        (JD.field "vibe" vibeDecoder)

tripDecoder =
    JD.map8 Trip
        (JD.field "estimated_arrival_posix" JD.int |> JD.andThen posixDecoder )
        (JD.succeed utc)
        fareDecoder
        passsengersDecoder
        (JD.field "payment" JD.string)
        (JD.field "dropoff_location" locationDecoder)
        (JD.field "pickup_location" locationDecoder)
        (JD.field "notes" JD.string)

posixDecoder millis =
    JD.succeed (millisToPosix millis)

fareDecoder =
    JD.map2 Fare
        (JD.field "estimated_fare_min" JD.int)
        (JD.field "estimated_fare_max" JD.int)

passsengersDecoder =
    JD.map2 Passengers
        (JD.field "passengers_min" JD.int)
        (JD.field "passengers_max" JD.int)

locationDecoder =
    JD.map8 Location
        (JD.maybe (JD.field "name" JD.string))
        (JD.field "street_line1" JD.string)
        (JD.maybe (JD.field "street_line2" JD.string))
        (JD.field "city" JD.string)
        (JD.field "state" JD.string)
        (JD.field "zipcode" JD.string)
        (JD.maybe (JD.field "lat" JD.string))
        (JD.maybe (JD.field "long" JD.string))

driverDecoder =
    JD.map4 Driver
        (JD.field "name" JD.string)
        (JD.field "image" JD.string)
        (JD.field "bio" JD.string)
        (JD.maybe (JD.field "phone" JD.string))

vehicleDecoder =
    JD.map4 Vehicle
        (JD.field "license" JD.string)
        (JD.field "make" JD.string)
        (JD.field "color" JD.string)
        (JD.field "image" JD.string)

vibeDecoder =
    JD.map Vibe
        (JD.field "name" JD.string)


view : Model -> Html Msg 
view model =
    case model.screen of
        Loading ->
            div [][text "Loading..."]
        ErrorScreen ->
            div [][
                text "We failed to load your trip data. Please try again in a few seconds."
                , button [][ text "Retry"] 
            ]
        TripScreen ->
            div [][
                div [][ 
                    img [src "images/Alto_logo.png"][]
                    , h1 [class "font-optima text-4xl"][text "Your Trip"]
                    , h2 [class "font-pxgrotesk text-7xl"][
                        text "5:39 "
                        , span [class "text-3xl uppercase"][text "pm"]
                    ]
                    , p [][text "Estimated arrival at DFW Int'l Airport - Terminal E"]
                    , div [class "flex flex-row w-screen gap-8"][
                        div [class "flex flex-col basis-1/3 border-t-2 border-t-solid border-t-alto-line"][
                            p [][text "Estimated Fare:"]
                            , p [][text "$65 - $75", span [][text "icon"]]
                        ]
                        , div [class "flex flex-col basis-1/3 border-t-2 border-t-solid border-t-alto-line"][
                            p [][text "Passengers:"]
                            , p [][text "1 - 5"]
                        ]
                        , div [class "flex flex-col basis-1/3 border-t-2 border-t-solid border-t-alto-line"][
                            p[][text "Payment:"]
                            , p [][text "Amex01"]
                        ]
                    ]
                ]
            ]
        DriverScreen ->
            div [][text "Driver"]
        VehicleScreen ->
            div [][text "Vehicle"]
        VibeScreen ->
            div [][text "Vibe"]
