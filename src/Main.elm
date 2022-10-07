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
    { min : String
    , max : String }

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
    | ShowScreen Screen


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
        ShowScreen screen ->
            ( { model | screen = screen }, Cmd.none )

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
        (JD.field "estimated_fare_min" JD.string)
        (JD.field "estimated_fare_max" JD.string)

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
    div [class "w-screen flex flex-col pl-4 pr-4 justify-between"][ -- TODO/FIXME: This padding causes side-scrolling
        div [class ("flex flex-col " ++ (getBGColor model.screen))][
            div [class "m-auto pt-4 pb-4 z-10"][img [src "images/Alto_logo.png", class "w-[50px] h-[14px]"][]]
            , dots model.screen
        ]
        , case model.tripData of
            Nothing ->
                case model.screen of
                    Loading ->
                        div [][text "Loading..."]
                    ErrorScreen ->
                        div [][
                            text "We failed to load your trip data. Please try again in a few seconds."
                            , button [][ text "Retry"] 
                        ]
                    _ ->
                        div [][text "Reload."]
            Just tripData ->
                case model.screen of
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
                            , p [class "pb-8 text-alto-base text-alto-primary"][text ("Estimated arrival at " ++ (tripData.trip.dropoff.name |> Maybe.withDefault "???"))]
                            , div [class "flex flex-row gap-8 pb-12"][
                                div [class "flex flex-col basis-1/3 border-t-2 border-t-solid border-t-alto-line"][
                                    p [class "text-alto-title text-alto-primary opacity-75"][text "Estimated Fare:"]
                                    , p [class "flex flex-row items-center gap-1 text-alto-base font-bold opacity-60"][text (fareToString tripData.trip.fare), span [][img [src "images/Info_icon.png", class "w-[13px] h-[13px]"][]]]
                                ]
                                , div [class "flex flex-col basis-1/3 border-t-2 border-t-solid border-t-alto-line"][
                                    p [class "text-alto-title text-alto-primary opacity-75"][text "Passengers:"]
                                    , p [class "text-alto-base font-bold opacity-60"][text (passengersToString tripData.trip.passengers)]
                                ]
                                , div [class "flex flex-col basis-1/3 border-t-2 border-t-solid border-t-alto-line"][
                                    p[class "text-alto-title text-alto-primary opacity-75"][text "Payment:"]
                                    , p [class "text-alto-base font-bold opacity-60"][text tripData.trip.payment]
                                ]
                            ]
                            , viewPickupLocation tripData.trip.pickup
                            , div [class "pt-2 pb-2 border-t-2 border-t-solid border-t-alto-line"][]
                            , viewDropoffLocation tripData.trip.dropoff
                            , div [class "flex flex-row gap-4 items-center text-alto-base text-alto-primary opacity-75"][
                                p[][text tripData.trip.notes]
                                , img [src "images/Edit_icon.png", class "w-[10px] h-[10px]"][]
                            ]
                            , div [class "grow"][]
                            , button [ class "p-4 border-2 border-solid border-alto-line"][
                                span [class "uppercase text-alto-base font-semibold text-alto-primary opacity-20"][text "Cancel Trip"]
                            ]
                        
                        ]
                    DriverScreen ->
                        div [class "flex grow flex-col"][
                            img [class "object-none object-[50%_39%]", src "images/Driver_photo.png"][]
                            , h1 [class "font-pxgrotesk text-alto-title tracking-widest uppercase text-alto-dark pt-8 pb-8"][text "Your Driver"]
                            , h2 [class "font-pxgrotesklight text-7xl tracking-tighter"][text "Steph"]
                            , div [][
                                div [class "pt-2 pb-2 border-t-2 border-t-solid border-t-alto-line"][]
                                , p [class "text-alto-title tracking-tight text-alto-primary opacity-75"][text "Steph Festiculma is a graduate of Parsons New School in New York and fluent in Portugeuse, Spanish and English. Steph has been driving with Alto since 2018."]
                            ]
                            , div [class "grow"][]
                            , button [ class "mt-4 p-4 border-2 border-solid border-alto-line w-screen"][
                                span [class "uppercase text-alto-base font-semibold text-alto-primary opacity-20"][text "Contact Driver"]
                            ]
                        
                        ]
                    VehicleScreen ->
                        div [class "flex grow flex-col"][
                            img [class "object-none object-[50%_39%]", src "images/Vehicle_photo.png"][]
                            , h1 [class "font-pxgrotesk text-alto-title tracking-widest uppercase text-alto-dark pt-8 pb-8"][text "Your Vehicle"]
                            , h2 [class "font-pxgrotesklight text-7xl tracking-tighter"][text "Alto 09"]
                            , div [class "flex flex-row w-screen gap-8 pb-12 pt-8"][
                                div [class "flex flex-col basis-1/2 border-t-2 border-t-solid border-t-alto-line"][
                                    p [class "text-alto-title text-alto-primary opacity-75"][text "Make / Model"]
                                    , p [class "flex flex-row items-center gap-1 text-alto-base font-bold opacity-60"][text "2019 Volkswagen Atlas"]
                                ]
                                , div [class "flex flex-col basis-1/2 border-t-2 border-t-solid border-t-alto-line"][
                                    p [class "text-alto-title text-alto-primary opacity-75"][text "Color"]
                                    , p [class "text-alto-base font-bold opacity-60"][text "Pure White"]
                                ]
                            ]
                            , div [class "grow"][]
                            , button [ class "mt-4 p-4 border-2 border-solid border-alto-line w-screen"][
                                span [class "uppercase text-alto-base font-semibold text-alto-primary opacity-20"][text "Identify Vehicle"]
                            ]
                        
                        ]
                    VibeScreen ->
                        div [class "flex grow flex-col"][
                            -- TODO/FIXME: this works with the whole absolute + top-4 thing,
                            -- but the rest of the flex content gets confused
                            img [class "vibeMask top-4 absolute", src "images/Map_overview.png"][]
                            , img [class "top-60 right-4 absolute", src "images/Map_icon.png"][]
                            , h1 [class "pt-[250px] font-pxgrotesk text-alto-title tracking-widest uppercase text-alto-dark pt-8 pb-8"][text "Your Trip"]
                            , h2 [class "font-pxgrotesklight text-7xl"][
                                text "5:39 "
                                , span [class "text-3xl uppercase"][text "pm"]
                            ]
                            , p [class "pb-8 text-alto-base text-alto-primary"][text "Estimated arrival at DFW Int'l Airport - Terminal E"]
                            , div [class "flex flex-col w-screen pb-12 pt-8 border-t-2 border-t-solid border-t-alto-line"][
                                p [class "text-alto-title text-alto-primary opacity-75"][text "Current Vibe"]
                                , p [class "flex flex-row items-center gap-1 text-alto-base font-bold opacity-60"][text "Vaporwave Beats"]
                            ]
                            , div [class "grow"][]
                            , button [ class "mt-4 p-4 border-2 border-solid border-alto-line w-screen bg-alto-dark" ][
                                span [class "uppercase text-alto-base font-semibold text-white"][text "Change Vehicle Vibe"]
                            ]
                        
                        ]

        , div [ class "mt-6 pt-2 flex flex-row border-t-2 border-t-solid border-t-alto-line"][
            div [class "m-auto w-[24px] h-[24px]"][img [src "images/Profile_icon.png"][]]
            , div [class "flex grow justify-center"][ 
                div [class "text-alto-base text-alto-primary opacity-70"][
                    p [class "font-semibold"][text "DFW Int'l Airport"]
                    , p [class "uppercase text-alto-title"][text "ETA: 5:39 PM"]
                ]
            ]
            , div [class "m-auto w-[24px] h-[24px]"][img [src "images/Vibes_icon.png"][]]
        ]
    ]

getBGColor : Screen -> String
getBGColor screen =
    if screen == DriverScreen then
        "bg-[#D9E0E6]"
    else
        " "

dots : Screen -> Html Msg
dots screen =
    div [class "absolute top-12 right-4 flex flex-col gap-1"][
        div [class (getDotClass screen TripScreen), onClick (ShowScreen TripScreen)][]
        , div [class (getDotClass screen DriverScreen), onClick (ShowScreen DriverScreen)][]
        , div [class (getDotClass screen VehicleScreen), onClick (ShowScreen VehicleScreen)][]
        , div [class (getDotClass screen VibeScreen), onClick (ShowScreen VibeScreen)][]
        , div [class (getDotClass screen ErrorScreen), onClick (ShowScreen ErrorScreen)][]
    ]

getDotClass : Screen -> Screen -> String
getDotClass screenA screenB =
    if screenA == screenB then
        "dot"
    else
        "dotFade"

fareToString : Fare -> String
fareToString fare =
    fare.min ++ " - " ++ fare.max

passengersToString : Passengers -> String
passengersToString passengers =
    (String.fromInt passengers.min) ++ " - " ++ (String.fromInt passengers.max)

-- TODO: handle street2
viewPickupLocation : Location -> Html Msg
viewPickupLocation location =
    div
        [class "pb-2 text-alto-base text-alto-primary opacity-75"]
        (
            case location.name of
                Nothing ->
                    [
                        p [][text location.street1]
                        , p [][text (locationToCityStateZip location)]
                    ]
                Just locationName ->
                    [
                        p [][text locationName]
                        , p [][text location.street1]
                        , p [][text (locationToCityStateZip location)]
                    ]
        )


locationToCityStateZip : Location -> String
locationToCityStateZip location =
    location.city ++ ", " ++ location.state ++ " " ++ location.zipcode

-- TODO: handle street2
viewDropoffLocation : Location -> Html Msg
viewDropoffLocation location =
    div [class "pb-4 text-alto-base text-alto-primary font-bold opacity-75"]
    (
        case location.name of
            Nothing ->
                [
                    p[][text location.street1]
                    , p[][text (locationToCityStateZip location)]
                ]
            Just locationName ->
                [
                    p[][text locationName]
                    , p[][text location.street1]
                    , p[][text (locationToCityStateZip location)]
                ]
    )
    
    