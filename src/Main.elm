module Main exposing (main)

import Browser
import Html exposing (Html, a, button, div, h1, h2, img, li, p, span, text, ul)
import Html.Attributes exposing (attribute, class, disabled, href, src)
import Html.Events exposing (onClick)
import Http
import Json.Decode as JD
import Swiper
import Time exposing (Posix, Zone, millisToPosix, toHour, toMinute, toSecond, utc)


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



---- MODEL ----


type alias Model =
    { screen : Screen
    , tripData : Maybe TripData
    , swipingState : Swiper.SwipingState
    , userSwipedLeft : Bool
    , userSwipedRight : Bool
    }


{-| We default to showing a loading screen since
when you startup, she'll attempt to load the data
from the server.
-}
initialModel : Model
initialModel =
    { screen = Loading
    , tripData = Nothing
    , swipingState = Swiper.initialSwipingState
    , userSwipedLeft = False
    , userSwipedRight = False
    }


{-| While this shows all the screens, we _do_ have an error screen
in case the server fails for whatever reason. We could re-use for
additional functionality that fails; for now it's just hardcoded.
-}
type Screen
    = Loading
    | ErrorScreen
    | TripScreen
    | DriverScreen
    | VehicleScreen
    | VibeScreen


{-| TripData represents the JSON given in the original assets folder
with our POSIX addition and money fixes. Some of the JSON had more than
8 properties which forces us to use a lower quality JSON parser. It would
work, but the error messages aren't as good, so I combined some types
together into a single type like Fare & Passengers vs. the flat
structure the JSON has.
-}
type alias TripData =
    { trip : Trip
    , driver : Driver
    , vehicle : Vehicle
    , vibe : Vibe
    }


{-| Note for now we've hardcoded the Zone in UTC, but could grab the user's
timezone from the browser.
-}
type alias Trip =
    { arrival : Posix
    , timeZone : Zone
    , fare : Fare
    , passengers : Passengers
    , payment : String
    , dropoff : Location
    , pickup : Location
    , notes : String
    }


{-| Note our money here is pre-formatted strings from the server; we do NOT futz
around with this stuff, and "just obey the almighty server" here. No worries if the
number is too big for JSON, or if we formatted it wrong; let the server handle it.
-}
type alias Fare =
    { min : String
    , max : String
    }


type alias Passengers =
    { min : Int
    , max : Int
    }


{-| These Maybe's are obnoxious; I only handle "name" for now.
-}
type alias Location =
    { name : Maybe String
    , street1 : String
    , street2 : Maybe String
    , city : String
    , state : String
    , zipcode : String
    , lat : Maybe String
    , long : Maybe String
    }


type alias Driver =
    { name : String
    , image : String
    , bio : String
    , phone : Maybe String
    }


type alias Vehicle =
    { license : String
    , make : String
    , color : String
    , image : String
    }


type alias Vibe =
    { name : String }



---- UPDATE ----


{-| This application can only do 3 things: Load some data from the server
and show a particular screen by clicking navigation dots & tabs,
or swipping left and right to navigate screens.
-}
type Msg
    = GotTripData (Result Http.Error TripData)
    | ShowScreen Screen
    | Swiped Swiper.SwipeEvent


{-| Handle when the user does something or we make an HTTP call.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTripData result ->
            case result of
                Err err ->
                    -- TODO: add better error showcasing in the error screen
                    let
                        _ =
                            Debug.log "trip data failed" err
                    in
                    ( { model | tripData = Nothing, screen = ErrorScreen }, Cmd.none )

                Ok tripData ->
                    ( { model | tripData = Just tripData, screen = TripScreen }, Cmd.none ) -- default landing screen

        ShowScreen screen ->
            ( { model | screen = screen }, Cmd.none )

        Swiped evt ->
            let
                ( newState, swipedLeft ) =
                    Swiper.hasSwipedLeft evt model.swipingState

                ( _, swipedRight ) =
                    Swiper.hasSwipedRight evt model.swipingState

                updatedModel =
                    { model | swipingState = newState, userSwipedLeft = swipedLeft, userSwipedRight = swipedRight }
            in
            if swipedLeft == True then
                goToPreviousScreen updatedModel

            else if swipedRight == True then
                goToNextScreen updatedModel

            else
                ( updatedModel, Cmd.none )


goToPreviousScreen : Model -> ( Model, Cmd Msg )
goToPreviousScreen model =
    case model.screen of
        TripScreen ->
            ( { model | screen = TripScreen }, Cmd.none )

        DriverScreen ->
            ( { model | screen = TripScreen }, Cmd.none )

        VehicleScreen ->
            ( { model | screen = DriverScreen }, Cmd.none )

        VibeScreen ->
            ( { model | screen = VehicleScreen }, Cmd.none )

        _ ->
            ( model, Cmd.none )


goToNextScreen : Model -> ( Model, Cmd Msg )
goToNextScreen model =
    case model.screen of
        TripScreen ->
            ( { model | screen = DriverScreen }, Cmd.none )

        DriverScreen ->
            ( { model | screen = VehicleScreen }, Cmd.none )

        VehicleScreen ->
            ( { model | screen = VibeScreen }, Cmd.none )

        VibeScreen ->
            ( { model | screen = VibeScreen }, Cmd.none )

        _ ->
            ( model, Cmd.none )



---- INIT ----


{-| This function runs when our application starts. We setup the default model
which is to "show the Loading screen" and "we don't have any trip data".
-}
init : JD.Value -> ( Model, Cmd Msg )
init _ =
    ( initialModel
    , Http.get
        { url = "http://localhost:3000"
        , expect = Http.expectJson GotTripData tripDataDecoder
        }
    )


{-| All these decoder functions attempt to parse our JSON. If even 1 thing is off,
it'll fail the parsing and explain exactly which node, and what's wrong with it.
-}
tripDataDecoder : JD.Decoder TripData
tripDataDecoder =
    JD.map4 TripData
        (JD.field "trip" tripDecoder)
        (JD.field "driver" driverDecoder)
        (JD.field "vehicle" vehicleDecoder)
        (JD.field "vibe" vibeDecoder)


tripDecoder : JD.Decoder Trip
tripDecoder =
    JD.map8 Trip
        -- The server gives us milliseconds since EPOC, but we need it as an actual Elm Time Posix type so convert it
        -- We should do additional validation on it, like ensure it's not 0, or negative.
        (JD.field "estimated_arrival_posix" JD.int |> JD.andThen posixDecoder)
        (JD.succeed utc)
        fareDecoder
        passsengersDecoder
        (JD.field "payment" JD.string)
        (JD.field "dropoff_location" locationDecoder)
        (JD.field "pickup_location" locationDecoder)
        (JD.field "notes" JD.string)



-- TODO: more validation on time


posixDecoder : Int -> JD.Decoder Posix
posixDecoder millis =
    JD.succeed (millisToPosix millis)


fareDecoder : JD.Decoder Fare
fareDecoder =
    JD.map2 Fare
        (JD.field "estimated_fare_min" JD.string)
        (JD.field "estimated_fare_max" JD.string)


passsengersDecoder : JD.Decoder Passengers
passsengersDecoder =
    JD.map2 Passengers
        (JD.field "passengers_min" JD.int)
        (JD.field "passengers_max" JD.int)


locationDecoder : JD.Decoder Location
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


driverDecoder : JD.Decoder Driver
driverDecoder =
    JD.map4 Driver
        (JD.field "name" JD.string)
        (JD.field "image" JD.string)
        (JD.field "bio" JD.string)
        -- For the Driver screen, you can contact them. However, if the phone
        -- number is an empty string "" in the JSON, that's pointless. So
        -- we ensure it's an _actual_ full string. We can do more validation,
        -- sure, but this is better than nothing.
        (JD.maybe (JD.field "phone" JD.string) |> JD.andThen validatePhone)



-- TODO: more thorough phone validation


validatePhone : Maybe String -> JD.Decoder (Maybe String)
validatePhone phoneMaybe =
    case phoneMaybe of
        Nothing ->
            JD.succeed Nothing

        Just phone ->
            case phone of
                "" ->
                    JD.succeed Nothing

                _ ->
                    JD.succeed (Just phone)


vehicleDecoder : JD.Decoder Vehicle
vehicleDecoder =
    JD.map4 Vehicle
        (JD.field "license" JD.string)
        (JD.field "make" JD.string)
        (JD.field "color" JD.string)
        (JD.field "image" JD.string)


vibeDecoder : JD.Decoder Vibe
vibeDecoder =
    JD.map Vibe
        (JD.field "name" JD.string)



---- VIEW ----


view : Model -> Html Msg
view model =
    div ([ class "w-screen flex flex-col pl-4 pr-4 justify-between" ] ++ Swiper.onSwipeEvents Swiped)
        -- swipe navigation is on the entire page
        [ -- TODO/FIXME: This padding causes side-scrolling
          div [ class ("flex flex-col " ++ getBGColor model.screen) ]
            [ div [ class "m-auto pt-4 pb-4" ] [ img [ src "images/Alto_logo.png", class "w-[50px] h-[14px]", attribute "data-logo" "Alto" ] [] ]
            , dots model.screen -- only shown in small and medium breakpoints
            , tabs model.screen -- only shown in large breakpoint
            ]
        , case model.tripData of
            Nothing ->
                case model.screen of
                    Loading ->
                        div [] [ text "Loading..." ]

                    ErrorScreen ->
                        div []
                            [ text "We failed to load your trip data. Please try again in a few seconds."
                            , button [] [ text "Retry" ]
                            ]

                    -- If we have no trip data, and you somehow navigate to this screen, we'll just
                    -- assume that you attempted to load data, it failed, but you went away from the
                    -- error screen and should reload the page.
                    _ ->
                        div [] [ text "Reload." ]

            Just tripData ->
                case model.screen of
                    Loading ->
                        div [] [ text "Loading..." ]

                    ErrorScreen ->
                        div []
                            [ text "We failed to load your trip data. Please try again in a few seconds."
                            , button [] [ text "Retry" ]
                            ]

                    TripScreen ->
                        div [ class "flex grow flex-col" ]
                            [ h1 [ class "font-optima text-4xl pt-10 pb-10", attribute "data-title" "Your Trip" ] [ text "Your Trip" ]
                            , h2 [ class "font-pxgrotesk text-7xl" ]
                                [ text (utcTimeToHoursMinutes tripData.trip.arrival)
                                , span [ class "text-3xl uppercase" ] [ text (getAMorPM (toHour utc tripData.trip.arrival)) ]
                                ]
                            , p [ class "pb-8 text-alto-base text-alto-primary" ] [ text ("Estimated arrival at " ++ (tripData.trip.dropoff.name |> Maybe.withDefault "???")) ]
                            , div [ class "flex small:flex-col medium:flex-row small:gap-2 medium:gap-4 pb-12" ]
                                [ div [ class "flex flex-col basis-1/3 border-t-2 border-t-solid border-t-alto-line" ]
                                    [ p [ class "text-alto-title text-alto-primary opacity-75" ] [ text "Estimated Fare:" ]
                                    , p [ class "flex flex-row items-center gap-1 text-alto-base font-bold opacity-60" ] [ text (fareToString tripData.trip.fare), span [] [ img [ src "images/Info_icon.png", class "w-[13px] h-[13px]" ] [] ] ]
                                    ]
                                , div [ class "flex flex-col basis-1/3 border-t-2 border-t-solid border-t-alto-line" ]
                                    [ p [ class "text-alto-title text-alto-primary opacity-75" ] [ text "Passengers:" ]
                                    , p [ class "text-alto-base font-bold opacity-60" ] [ text (passengersToString tripData.trip.passengers) ]
                                    ]
                                , div [ class "flex flex-col basis-1/3 border-t-2 border-t-solid border-t-alto-line" ]
                                    [ p [ class "text-alto-title text-alto-primary opacity-75" ] [ text "Payment:" ]
                                    , p [ class "text-alto-base font-bold opacity-60" ] [ text tripData.trip.payment ]
                                    ]
                                ]
                            , div [ class "flex small:flex-col large:flex-row small:gap-2 medium:gap-4" ]
                                [ div [ class "large:grow basis-1/3" ]
                                    [ p [ class "small:hidden large:block text-alto-title text-alto-primary opacity-75" ] [ text "Pickup Location:" ]
                                    , viewPickupLocation tripData.trip.pickup
                                    ]
                                , div [ class "large:hidden small:pt-2 small:pb-2 medium:pt-0 medium:pb-0 border-t-2 border-t-solid border-t-alto-line" ] []
                                , div [ class "large:grow basis-1/3" ]
                                    [ p [ class "small:hidden large:block text-alto-title text-alto-primary opacity-75" ] [ text "Dropoff Location:" ]
                                    , viewDropoffLocation tripData.trip.dropoff
                                    ]
                                , div [ class "flex flex-row gap-4 items-center large:items-start text-alto-base text-alto-primary opacity-75 basis-1/3" ]
                                    [ p [] [ text tripData.trip.notes ]
                                    , img [ src "images/Edit_icon.png", class "w-[10px] h-[10px]" ] []
                                    ]
                                ]
                            , div [ class "grow small:pt-2" ] []
                            , viewButton "Cancel Trip" False []
                            ]

                    DriverScreen ->
                        div [ class "flex grow flex-col" ]
                            [ 
                            div [class "flex small:flex-col large:flex-row large:gap-8"][
                                img [ class "small:object-none small:object-[50%_39%] medium:object-center large:object-none large:object-[50%_39%] large:w-40 large:basis-1/2", src tripData.driver.image ] []
                                , div [ class "flex flex-col large:basis-1/2"][
                                    h1 [ class "font-pxgrotesk text-alto-title tracking-widest uppercase text-alto-dark pt-8 pb-8", attribute "data-title" "Your Driver" ] [ text "Your Driver" ]
                                    , h2 [ class "font-pxgrotesklight text-7xl tracking-tighter" ] [ text tripData.driver.name ]
                                    , div []
                                        [ div [ class "pt-2 pb-2 border-t-2 border-t-solid border-t-alto-line" ] []
                                        , p [ class "text-alto-title large:text-alto-base tracking-tight text-alto-primary opacity-75" ] [ text tripData.driver.bio ]
                                        ]
                                ]
                            ]
                            , div [ class "grow" ] []

                            -- only enable the contact driver button if they actually have a phone number
                            , case tripData.driver.phone of
                                Nothing ->
                                    viewButton "Contact Driver" False []

                                Just _ ->
                                    viewButton "Contact Driver" True []
                            ]

                    VehicleScreen ->
                        div [ class "flex grow flex-col" ]
                            [ img [ class "small:object-none small:object-[50%_39%] medium:object-contain", src tripData.vehicle.image ] []
                            , h1 [ class "font-pxgrotesk text-alto-title tracking-widest uppercase text-alto-dark pt-8 pb-8", attribute "data-title" "Your Vehicle" ] [ text "Your Vehicle" ]
                            , h2 [ class "font-pxgrotesklight text-7xl tracking-tighter" ] [ text tripData.vehicle.license ]
                            , div [ class "flex small:flex-col medium:flex-row w-screen gap-8 pb-12 pt-8" ]
                                [ div [ class "flex flex-col basis-1/2 border-t-2 border-t-solid border-t-alto-line" ]
                                    [ p [ class "text-alto-title text-alto-primary opacity-75" ] [ text "Make / Model" ]
                                    , p [ class "flex flex-row items-center gap-1 text-alto-base font-bold opacity-60" ] [ text tripData.vehicle.make ]
                                    ]
                                , div [ class "flex flex-col basis-1/2 border-t-2 border-t-solid border-t-alto-line" ]
                                    [ p [ class "text-alto-title text-alto-primary opacity-75" ] [ text "Color" ]
                                    , p [ class "text-alto-base font-bold opacity-60" ] [ text tripData.vehicle.color ]
                                    ]
                                ]
                            , div [ class "grow" ] []
                            , viewButton "Identify Vehicle" False []
                            ]

                    VibeScreen ->
                        div [ class "flex grow flex-col" ]
                            [ img [ class "vibeMask top-4 medium:top-[99px] absolute medium:flex", src "images/Map_overview.png" ] [] -- <-- this guy is so hard...
                            , img [ class "top-60 right-4 absolute", src "images/Map_icon.png" ] []
                            , h1 [ class "pt-[250px] font-pxgrotesk text-alto-title tracking-widest uppercase text-alto-dark pt-8 pb-8", attribute "data-title" "Vibe" ] [ text "Your Trip" ]
                            , h2 [ class "font-pxgrotesklight text-7xl" ]
                                [ text (utcTimeToHoursMinutes tripData.trip.arrival)
                                , span [ class "text-3xl uppercase" ] [ text (getAMorPM (toHour utc tripData.trip.arrival)) ]
                                ]
                            , div [ class "flex small:flex-col medium:flex-row medium:gap-8" ]
                                [ p [ class "pb-8 text-alto-base text-alto-primary" ] [ text ("Estimated arrival at " ++ (tripData.trip.dropoff.name |> Maybe.withDefault "???")) ] -- <-- why would drop off location be blank?
                                , div [ class "flex flex-col pb-12 pt-8 border-t-2 border-t-solid border-t-alto-line medium:pt-0 medium:pb-0 medium:border-t-0" ]
                                    [ p [ class "text-alto-title text-alto-primary opacity-75" ] [ text "Current Vibe" ]
                                    , p [ class "flex flex-row items-center gap-1 text-alto-base font-bold opacity-60" ] [ text tripData.vibe.name ]
                                    ]
                                ]
                            , div [ class "grow" ] []
                            , viewButton "Change Vehicle Vibe" True []
                            ]
        , div [ class "mt-6 pt-2 flex flex-row border-t-2 border-t-solid border-t-alto-line" ]
            [ div [ class "m-auto w-[24px] h-[24px]" ] [ img [ src "images/Profile_icon.png" ] [] ]
            , div [ class "flex grow justify-center" ]
                [ div [ class "text-alto-base text-alto-primary opacity-70" ]
                    [ p [ class "font-semibold" ] [ text (getDestinationName model.tripData) ]
                    , p [ class "uppercase text-alto-title" ] [ text (getETA model.tripData) ]
                    ]
                ]
            , div [ class "m-auto w-[24px] h-[24px]" ] [ img [ src "images/Vibes_icon.png" ] [] ]
            ]
        ]


getBGColor : Screen -> String
getBGColor screen =
    if screen == DriverScreen then
        "small:bg-[#D9E0E6] large:bg-alto-page-background"

    else
        " "


{-| The 6 black & gray dots you see to denoate which screen you're on; I made them interactive
-}
dots : Screen -> Html Msg
dots screen =
    div [ class "absolute small:top-12 small:right-8 flex small:flex-col medium:flex-row large:hidden gap-1" ]
        [ div [ class (getDotClass screen TripScreen), onClick (ShowScreen TripScreen), attribute "data-dot" "My Trip" ] []
        , div [ class (getDotClass screen DriverScreen), onClick (ShowScreen DriverScreen), attribute "data-dot" "My Driver" ] []
        , div [ class (getDotClass screen VehicleScreen), onClick (ShowScreen VehicleScreen), attribute "data-dot" "Vehicle" ] []
        , div [ class (getDotClass screen VibeScreen), onClick (ShowScreen VibeScreen), attribute "data-dot" "Dat Vibe Tho" ] []
        , div [ class (getDotClass screen ErrorScreen), onClick (ShowScreen ErrorScreen), attribute "data-dot" "Error" ] []
        ]


{-| Tabs Component
at a large breakpoint, you can click on tabs to navigate vs. swiping
-}
tabs : Screen -> Html Msg
tabs screen =
    ul [ class "small:hidden large:flex flex flex-wrap text-sm font-medium text-center text-alto-secondary border-b border-alto-line" ]
        [ tab "My Trip" (screenIsActive TripScreen screen) (ShowScreen TripScreen)
        , tab "My Driver" (screenIsActive DriverScreen screen) (ShowScreen DriverScreen)
        , tab "Vehicle" (screenIsActive VehicleScreen screen) (ShowScreen VehicleScreen)
        , tab "Dat Vibe Tho" (screenIsActive VibeScreen screen) (ShowScreen VibeScreen)
        ]


{-| Tab Component
-}
tab : String -> Bool -> Msg -> Html Msg
tab label active onClickMsg =
    if active == True then
        li [ class "mr-2" ] [ a [ href "#", class "inline-block p-4 text-white bg-alto-dark rounded-t-lg active", onClick onClickMsg, attribute "data-tab" label ] [ text label ] ]

    else
        li [ class "mr-2" ] [ a [ href "#", class "inline-block p-4 rounded-t-lg hover:text-alto-primary-gray hover:bg-alto-gray", onClick onClickMsg, attribute "data-tab" label ] [ text label ] ]


screenIsActive : Screen -> Screen -> Bool
screenIsActive screenA screenB =
    screenA == screenB


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
    String.fromInt passengers.min ++ " - " ++ String.fromInt passengers.max



-- TODO: handle street2


viewPickupLocation : Location -> Html Msg
viewPickupLocation location =
    div
        [ class "pb-2 text-alto-base text-alto-primary opacity-75" ]
        (case location.name of
            Nothing ->
                [ p [] [ text location.street1 ]
                , p [] [ text (locationToCityStateZip location) ]
                ]

            Just locationName ->
                [ p [] [ text locationName ]
                , p [] [ text location.street1 ]
                , p [] [ text (locationToCityStateZip location) ]
                ]
        )


locationToCityStateZip : Location -> String
locationToCityStateZip location =
    location.city ++ ", " ++ location.state ++ " " ++ location.zipcode



-- TODO: handle street2


viewDropoffLocation : Location -> Html Msg
viewDropoffLocation location =
    div [ class "pb-4 text-alto-base text-alto-primary font-bold opacity-75" ]
        (case location.name of
            Nothing ->
                [ p [] [ text location.street1 ]
                , p [] [ text (locationToCityStateZip location) ]
                ]

            Just locationName ->
                [ p [] [ text locationName ]
                , p [] [ text location.street1 ]
                , p [] [ text (locationToCityStateZip location) ]
                ]
        )


getDestinationName : Maybe TripData -> String
getDestinationName tripDataMaybe =
    case tripDataMaybe of
        Nothing ->
            "Cannot determine destination at this time."

        Just tripData ->
            case tripData.trip.dropoff.name of
                Nothing ->
                    tripData.trip.dropoff.street1

                Just droppoffName ->
                    droppoffName


toUtcString : Posix -> String
toUtcString time =
    String.fromInt (toHour utc time)
        ++ ":"
        ++ String.fromInt (toMinute utc time)
        ++ ":"
        ++ String.fromInt (toSecond utc time)
        ++ " (UTC)"


getETA : Maybe TripData -> String
getETA tripDataMaybe =
    case tripDataMaybe of
        Nothing ->
            "Caculating ETA..."

        Just tripData ->
            "ETA: " ++ utcTimeToHoursMinutes tripData.trip.arrival ++ " " ++ getAMorPM (toHour utc tripData.trip.arrival)


getAMorPM : Int -> String
getAMorPM hour =
    if hour == 12 then
        "pm"

    else if hour == 24 then
        "am"

    else if hour >= 1 && hour <= 11 then
        "am"

    else if hour >= 12 && hour < 24 then
        "pm"

    else
        "??"


utcTimeToHoursMinutes : Posix -> String
utcTimeToHoursMinutes time =
    String.fromInt (toHour utc time |> militaryHourToRegularHour)
        ++ ":"
        ++ String.fromInt (toMinute utc time)


militaryHourToRegularHour : Int -> Int
militaryHourToRegularHour time =
    if time < 13 then
        time

    else
        time - 12


{-| Button Component
-}
viewButton : String -> Bool -> List (Html.Attribute Msg) -> Html Msg
viewButton label enabled attributes =
    if enabled == True then
        button
            (class enabledButtonStyles :: attributes)
            [ span
                [ class enabledButtonTextStyles ]
                [ text label ]
            ]

    else
        button
            (class disabledButtonStyles :: disabled False :: attributes)
            [ span
                [ class disabledButtonTextStyles ]
                [ text label ]
            ]


disabledButtonStyles : String
disabledButtonStyles =
    "mt-4 p-4 border-2 border-solid border-alto-line"


disabledButtonTextStyles : String
disabledButtonTextStyles =
    "uppercase text-alto-base font-semibold text-alto-primary opacity-20"


enabledButtonStyles : String
enabledButtonStyles =
    "mt-4 p-4 border-2 border-solid border-alto-line bg-alto-dark"


enabledButtonTextStyles : String
enabledButtonTextStyles =
    "uppercase text-alto-base font-semibold text-white"
