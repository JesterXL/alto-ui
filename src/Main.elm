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
                    ( { model | tripData = Just tripData, screen = DriverScreen }, Cmd.none )


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
    div [][
        div [class "h-screen"][
            div [class "flex flex-col p-4"][ -- TODO/FIXME: This padding causes side-scrolling
                div [class "flex flex-col bg-[#D9E0E6]"][
                    div [class "m-auto pt-4 pb-4"][img [src "images/Alto_logo.png", class "w-[50px] h-[14px]"][]]
                ]
                , case model.screen of
                    Loading ->
                        div [][text "Loading..."]
                    ErrorScreen ->
                        div [][
                            text "We failed to load your trip data. Please try again in a few seconds."
                            , button [][ text "Retry"] 
                        ]
                    TripScreen ->
                        div [class "flex grow flex-col"][
                            h1 [class "font-optima text-4xl pt-10 pb-10"][text "Your Trip"]
                            , h2 [class "font-pxgrotesk text-7xl"][
                                text "5:39 "
                                , span [class "text-3xl uppercase"][text "pm"]
                            ]
                            , p [class "pb-8 text-alto-base text-alto-primary"][text "Estimated arrival at DFW Int'l Airport - Terminal E"]
                            , div [class "flex flex-row w-screen gap-8 pb-12"][
                                div [class "flex flex-col basis-1/3 border-t-2 border-t-solid border-t-alto-line"][
                                    p [class "text-alto-title text-alto-primary opacity-75"][text "Estimated Fare:"]
                                    , p [class "flex flex-row items-center gap-1 text-alto-base font-bold opacity-60"][text "$65 - $75", span [][img [src "images/Info_icon.png", class "w-[13px] h-[13px]"][]]]
                                ]
                                , div [class "flex flex-col basis-1/3 border-t-2 border-t-solid border-t-alto-line"][
                                    p [class "text-alto-title text-alto-primary opacity-75"][text "Passengers:"]
                                    , p [class "text-alto-base font-bold opacity-60"][text "1 - 5"]
                                ]
                                , div [class "flex flex-col basis-1/3 border-t-2 border-t-solid border-t-alto-line"][
                                    p[class "text-alto-title text-alto-primary opacity-75"][text "Payment:"]
                                    , p [class "text-alto-base font-bold opacity-60"][text "Amex01"]
                                ]
                            ]
                            , div [class "pb-2 text-alto-base text-alto-primary opacity-75"][
                                    p [][text "449 Flora St."]
                                    , p [][text "Dallas, Texas 75201"]
                                ]
                            , div [class "pt-2 pb-2 border-t-2 border-t-solid border-t-alto-line"][]
                            , div [class "pb-4 text-alto-base text-alto-primary font-bold opacity-75"][
                                p[][text "DFW International Airport"]
                                , p[][text "American Airlines Terminal E"]
                                , p[][text "Irving, Texas 75261"]
                            ]
                            , div [class "flex flex-row gap-4 items-center text-alto-base text-alto-primary opacity-75"][
                                p[][text "Can you drop me off at AA International Bag Drop please?"]
                                , img [src "images/Edit_icon.png", class "w-[10px] h-[10px]"][]
                            ]
                            , div [class "grow"][]
                            , button [ class "p-4 border-2 border-solid border-alto-line w-screen"][
                                span [class "uppercase text-alto-base font-semibold text-alto-primary opacity-20"][text "Cancel Trip"]
                            ]
                        
                        ]
                    DriverScreen ->
                        div [class "flex grow flex-col"][
                            img [class "object-none object-[50%_44%]", src "images/Driver_photo.png"][]
                            , h1 [class "font-pxgrotesk text-alto-title tracking-widest uppercase text-alto-dark pt-8 pb-8"][text "Your Driver"]
                            , h2 [class "font-pxgrotesklight text-7xl"][text "Steph"]
                        
                        ]
                    VehicleScreen ->
                        div [][text "Vehicle"]
                    VibeScreen ->
                        div [][text "Vibe"]
                , div [ class "mt-6 pt-2 flex flex-row w-screen border-t-2 border-t-solid border-t-alto-line"][
                    div [class "m-auto w-[24px] h-[24px]"][img [src "images/Profile_icon.png"][]]
                    , div [class "flex grow w-screen justify-center"][ 
                        div [class "text-alto-base text-alto-primary opacity-70"][
                            p [class "font-semibold"][text "DFW Int'l Airport"]
                            , p [class "uppercase text-alto-title"][text "ETA: 5:39 PM"]
                        ]
                    ]
                    , div [class "m-auto w-[24px] h-[24px]"][img [src "images/Vibes_icon.png"][]]
                ]
            ]
        ]
    ]

getBGColor : Screen -> String
getBGColor screen =
    case screen of
        DriverScreen -> "bg-[#D9E0E6]"
        _ -> "bg-alto-page-background"