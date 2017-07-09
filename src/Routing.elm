module Routing exposing (..)

import Navigation exposing (Location)
import UrlParser exposing (..)
import Types exposing (..)
import Tables exposing (Table(..), decodeTable)


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map (GameRoute Melchor) top
        , tableMatcher
        , map StaticPageRoute (s "static" </> staticPageMatcher)
        , map EditorRoute (s "editor")
        ]


staticPageMatcher : Parser (StaticPage -> a) a
staticPageMatcher =
    UrlParser.custom "STATIC_PAGE" <|
        \segment ->
            case segment of
                "help" ->
                    Ok Help

                _ ->
                    Err segment


tableMatcher : Parser (Route -> a) a
tableMatcher =
    UrlParser.custom "GAME" <|
        \segment ->
            case decodeTable segment of
                Just table ->
                    Ok (GameRoute table)

                Nothing ->
                    Err <| "No such table: " ++ segment


parseLocation : Location -> Route
parseLocation location =
    let
        route =
            case (parseHash matchers location) of
                Just route ->
                    route

                Nothing ->
                    NotFoundRoute

        _ =
            Debug.log "parseLocation" ( location, route )
    in
        route


navigateTo : Route -> Cmd Msg
navigateTo route =
    Navigation.newUrl <|
        case route of
            GameRoute table ->
                "/#" ++ (toString table)

            StaticPageRoute page ->
                case page of
                    Help ->
                        "#/static/help"

            EditorRoute ->
                "/#editor"

            NotFoundRoute ->
                "/#404"