module Game.View exposing (view)

import Backend.Types exposing (ConnectionStatus(..))
import Board
import Game.Chat
import Game.Footer
import Game.PlayerCard as PlayerCard
import Game.State exposing (findUserPlayer)
import Game.Types exposing (PlayerAction(..), TableInfo, Player, statusToString)
import Html exposing (..)
import Html.Attributes exposing (class, style, type_, disabled)
import Html.Events exposing (onClick)
import Ordinal exposing (ordinal)
import Tables exposing (Table)
import Time exposing (posixToMillis)
import Types exposing (Model, Msg(..))


view : Model -> Html Types.Msg
view model =
    let
        board =
            Board.view model.game.board
                |> Html.map BoardMsg
    in
        div [ class "edMainScreen" ]
            [ div [ class "edGameBoardWrapper" ]
                [ tableInfo model
                , header model
                , board
                , sitInModal model
                , boardFooter model
                ]
            , div [ class "edGame__meta" ]
                [ gameChat model
                , gameLog model
                ]
            , Game.Footer.footer model
            ]


header : Model -> Html.Html Types.Msg
header model =
    div [ class "edGameHeader" ]
        [ playerBar 4 model
        ]


boardFooter : Model -> Html.Html Types.Msg
boardFooter model =
    let
        toolbar =
            if model.screenshot then
                []
            else
                [ div [ class "edGameBoardFooter__content" ]
                    --[ label [ class "edCheckbox" ]
                    --[ input
                    --[ type_ "checkbox" ]
                    --[]
                    --, text "Ready"
                    --]
                    [ seatButton model
                    ]
                ]
    in
        div [ class "edGameBoardFooter" ] <|
            (playerBar 0 model)
                :: toolbar


playerBar : Int -> Model -> Html Msg
playerBar dropCount model =
    div [ class "edPlayerChips" ] <|
        List.indexedMap (PlayerCard.view model) <|
            List.take 4 <|
                List.drop dropCount <|
                    model.game.players


seatButton : Model -> Html.Html Types.Msg
seatButton model =
    let
        canPlay =
            case model.backend.status of
                Online ->
                    True

                _ ->
                    False

        ( label, msg ) =
            case findUserPlayer model.user model.game.players of
                Just player ->
                    if model.game.status == Game.Types.Playing then
                        if player.out then
                            ( "Sit in", onClick <| GameCmd SitIn )
                        else if model.game.hasTurn then
                            ( "End turn", onClick <| GameCmd EndTurn )
                        else
                            ( "Sit out", onClick <| GameCmd SitOut )
                    else
                        ( "Leave", onClick <| GameCmd Leave )

                Nothing ->
                    case model.user of
                        Types.Anonymous ->
                            ( "Join", onClick <| ShowLogin Types.LoginShowJoin )

                        Types.Logged user ->
                            ( "Join", onClick <| GameCmd Join )
    in
        button [ class "edButton edGameHeader__button", msg, disabled <| not canPlay ] [ text label ]


gameLog : Model -> Html.Html Types.Msg
gameLog model =
    Game.Chat.gameBox
        model.game.gameLog
    <|
        "gameLog-"
            ++ (Maybe.withDefault "NOTABLE" model.game.table)


gameChat : Model -> Html.Html Types.Msg
gameChat model =
    div [ class "chatboxContainer" ]
        [ Game.Chat.chatBox
            model.game.chatInput
            (List.map .color model.game.players)
            model.game.chatLog
          <|
            "chatLog-"
                ++ (Maybe.withDefault "NOTABLE" model.game.table)
        ]


userCard : Types.User -> Html.Html Types.Msg
userCard user_ =
    case user_ of
        Types.Logged user ->
            div [ class "edGame__user", Html.Events.onClick <| NavigateTo <| Types.ProfileRoute user.id ] <|
                [ div
                    [ class "edPlayerChip__picture"
                    , style "width" "70px"
                    , style "height" "70px"
                    ]
                    [ div
                        [ class "edPlayerChip__picture__image"
                        , style "background-image" ("url(" ++ user.picture ++ ")")
                        , style "background-size" "cover"
                        ]
                        []
                    ]
                , div [] [ text <| user.name ]
                , div [] [ text <| "✪ " ++ String.fromInt user.points ]
                ]

        Types.Anonymous ->
            text "not logged"


sitInModal : Model -> Html.Html Types.Msg
sitInModal model =
    div
        [ if model.game.isPlayerOut then
            style "" ""
          else
            style "display" "none"
        , class "edGame__SitInModal"
        , Html.Events.onClick <| GameCmd SitIn
        ]
        [ button
            [ onClick <| GameCmd SitIn
            ]
            [ text "Sit in!" ]
        ]


tableInfo : Model -> Html Types.Msg
tableInfo model =
    div [ class "edGameStatus" ] <|
        case model.game.table of
            Just table ->
                [ span [ class "edGameStatus__chip" ]
                    [ text "Table "
                    , span [ class "edGameStatus__chip--strong" ]
                        [ text <| table
                        ]
                    ]
                , span [ class "edGameStatus__chip" ] <|
                    List.append
                        [ text ", "
                        , span [ class "edGameStatus__chip--strong" ]
                            [ text <|
                                if model.game.playerSlots == 0 then
                                    "∅"
                                else
                                    String.fromInt model.game.playerSlots
                            ]
                        , text " player game is "
                        , span [ class "edGameStatus__chip--strong" ]
                            [ text <| statusToString model.game.status ]
                        ]
                        (case model.game.gameStart of
                            Nothing ->
                                [ text <| " round " ++ String.fromInt model.game.roundCount ]

                            Just timestamp ->
                                [ text " starting in "
                                , span [ class "edGameStatus__chip--strong" ]
                                    [ text <| String.fromInt (round <| toFloat timestamp - ((toFloat <| posixToMillis model.time) / 1000)) ++ "s" ]
                                ]
                        )
                ]

            Nothing ->
                []
