module Land exposing (..)

import Maybe exposing (..)
import List exposing (..)
import Random
import Hexagons.Hex as HH exposing (Hex, Direction, (===))
import Hexagons.Layout as HL exposing (offsetToHex, orientationLayoutPointy, Layout)
import Hex exposing (Point, borderLeftCorner, center, cellCubicCoords)


type alias Cells =
    List Hex


type alias Point =
    Hex.Point


type alias Land =
    { hexagons : Cells
    , color : Color
    , selected : Bool
    }


type alias Layout =
    { size : ( Float, Float )
    , padding : Float
    }


type alias Map =
    { lands : List Land
    , width : Int
    , height : Int
    }


type alias Border =
    ( Hex, Direction )


type Color
    = Neutral
    | Red
    | Green
    | Blue
    | Yellow
    | Magenta
    | Cyan
    | Black
    | Editor
    | EditorSelected


landPath : Layout -> Cells -> List Point
landPath layout cells =
    landBorders cells |> List.map (uncurry <| borderLeftCorner <| myLayout layout)


myLayout : Layout -> HL.Layout
myLayout { size, padding } =
    { orientation = orientationLayoutPointy
    , size = size
    , origin = ( padding / 2, -(snd size) / 2 + padding / 2 )
    }


center : HL.Layout -> Cells -> Point
center layout cells =
    case cells of
        [] ->
            ( -1, -1 )

        hd :: _ ->
            Hex.center layout hd


cellCenter : HL.Layout -> Hex -> Point
cellCenter layout hex =
    Hex.center layout hex


cellCubicCoords : Hex -> ( Int, Int, Int )
cellCubicCoords hex =
    Hex.cellCubicCoords hex


errorLand : Land
errorLand =
    Land [ offsetToHex ( 0, 0 ) ] Editor False


fullCellMap : Int -> Int -> Color -> Map
fullCellMap w h color =
    Map
        (List.map
            (\r ->
                List.map
                    (\c ->
                        { hexagons = [ offsetToHex ( c, r ) ]
                        , color = color
                        , selected = False
                        }
                    )
                    [1..w]
            )
            [1..h]
            |> List.concat
        )
        w
        h


offsetToHex : ( Int, Int ) -> Hex
offsetToHex ( col, row ) =
    let
        x =
            col - (round ((toFloat (row + ((abs row) % 2))) / 2))
    in
        HH.intFactory ( x, row )


landColor : Map -> Land -> Color -> Map
landColor map land color =
    { map
        | lands =
            List.map
                (\l ->
                    { l
                        | color =
                            if land == l then
                                color
                            else
                                l.color
                    }
                )
                map.lands
    }


highlight : Bool -> Map -> Land -> Map
highlight highlight map land =
    map



-- { map
--     | lands =
--         List.map
--             (\l ->
--                 if l == land then
--                     { l | selected = highlight }
--                 else
--                     { l | selected = False }
--             )
--             map.lands
-- }


append : Map -> Land -> Map
append map land =
    { map | lands = List.append [ land ] map.lands }


{-| indexOf helper
-}
indexOf : List a -> (a -> Bool) -> Int
indexOf lst f =
    let
        helper : List a -> (a -> Bool) -> Int -> Int
        helper lst f offset =
            case lst of
                [] ->
                    -1

                x :: xs ->
                    if f x then
                        offset
                    else
                        helper xs f (offset + 1)
    in
        helper lst f 0


{-| return index of coord in map
-}
at : List Land -> ( Int, Int ) -> Int
at lands coord =
    let
        hex =
            offsetToHex coord

        cb : Hex -> Land -> Bool
        cb hex land =
            any (\h -> h === hex) land.hexagons

        index =
            indexOf lands (cb hex)
    in
        index


{-| concat all cells in map to a single neutral land
-}
concat : Map -> Land
concat map =
    let
        hexes : Cells
        hexes =
            List.map (\l -> l.hexagons) map.lands |> List.concat
    in
        case head hexes of
            Nothing ->
                Land [] Neutral False

            Just hd ->
                Land hexes Neutral False


{-| set one color to neutral
-}
setNeutral : Map -> Color -> Map
setNeutral map color =
    { map
        | lands =
            List.map
                (\l ->
                    { l
                        | color =
                            (if l.color == color then
                                Neutral
                             else
                                l.color
                            )
                    }
                )
                map.lands
    }


playerColor : Int -> Color
playerColor i =
    case i of
        1 ->
            Red

        2 ->
            Green

        3 ->
            Blue

        4 ->
            Yellow

        5 ->
            Magenta

        6 ->
            Cyan

        7 ->
            Black

        0 ->
            Editor

        _ ->
            Neutral


randomPlayerColor : (Color -> a) -> Cmd a
randomPlayerColor v =
    Random.int 1 7 |> Random.map playerColor |> Random.generate v


setColor : Map -> Land -> Color -> Map
setColor map land color =
    { map
        | lands =
            List.map
                (\l ->
                    if l == land then
                        { land | color = color }
                    else
                        l
                )
                map.lands
    }


allSides : List Direction
allSides =
    [ HH.NW, HH.NE, HH.E, HH.SE, HH.SW, HH.W ]


cellBorder : Hex -> Direction -> ( Hex, Direction )
cellBorder hex border =
    ( hex, border )


defaultSide : Direction
defaultSide =
    HH.NW


landBorders : Cells -> List Border
landBorders cells =
    case cells of
        [ one ] ->
            List.map (cellBorder one) (List.reverse allSides)

        _ ->
            case firstFreeBorder cells of
                Nothing ->
                    Debug.crash "Set of cells must have some outer borders"

                Just ( coord, side ) ->
                    nextBorders cells coord ( coord, side ) side [ ( coord, side ) ]


nextBorders : Cells -> Hex -> Border -> Direction -> List Border -> List Border
nextBorders cells coord origin side accum =
    nextBorders_ cells coord (Debug.log "origin" origin) side [] 100000



-- |> List.reverse


nextBorders_ : Cells -> Hex -> Border -> Direction -> List Border -> Int -> List Border
nextBorders_ cells coord origin side accum fuse =
    let
        current =
            ( coord, side )
    in
        if (fst origin === coord) && snd origin == side && List.length accum > 1 then
            (current :: accum)
        else if fuse == 0 then
            let
                _ =
                    Debug.log "Recursion exhausted"
                        ( coord, side, origin, accum |> List.take 32, cells )
            in
                Debug.crash "Recursion exhausted"
        else
            case cellOnBorder coord side cells of
                Just c ->
                    nextBorders_ cells c origin (rightSide (oppositeSide side)) (accum) (fuse - 1)

                Nothing ->
                    nextBorders_ cells coord origin (rightSide side) (current :: accum) (fuse - 1)


rightSide : Direction -> Direction
rightSide side =
    case side of
        HH.NW ->
            HH.NE

        HH.NE ->
            HH.E

        HH.E ->
            HH.SE

        HH.SE ->
            HH.SW

        HH.SW ->
            HH.W

        HH.W ->
            HH.NW


leftSide : Direction -> Direction
leftSide side =
    case side of
        HH.NW ->
            HH.W

        HH.NE ->
            HH.NW

        HH.E ->
            HH.NE

        HH.SE ->
            HH.E

        HH.SW ->
            HH.SE

        HH.W ->
            HH.SW


oppositeSide : Direction -> Direction
oppositeSide =
    rightSide >> rightSide >> rightSide


hasCell : Cells -> Hex -> Bool
hasCell cells coord =
    any (\c -> c === coord) cells


firstFreeBorder : Cells -> Maybe Border
firstFreeBorder cells =
    firstFreeBorder_ cells cells


firstFreeBorder_ : Cells -> Cells -> Maybe Border
firstFreeBorder_ accum cells =
    case accum of
        [] ->
            Nothing

        hd :: tail ->
            case hasFreeBorder cells hd allSides of
                Just a ->
                    Just ( hd, a )

                Nothing ->
                    firstFreeBorder_ tail cells


hasFreeBorder : Cells -> Hex -> List Direction -> Maybe Direction
hasFreeBorder cells coord sides =
    case sides of
        [] ->
            Nothing

        hd :: tl ->
            if cellOnBorder coord hd cells |> isNothing then
                Just hd
            else
                hasFreeBorder cells coord tl


isNothing : Maybe a -> Bool
isNothing a =
    case a of
        Nothing ->
            True

        Just a ->
            False


cellOnBorder : Hex -> Direction -> Cells -> Maybe Hex
cellOnBorder coord side cells =
    case head cells of
        Nothing ->
            Nothing

        Just hd ->
            case tail cells of
                Nothing ->
                    Nothing

                Just tl ->
                    if isBorderOnSide coord side hd then
                        Just (hd)
                    else if length cells == 1 then
                        Nothing
                    else
                        cellOnBorder coord side tl


isBorderOnSide : Hex -> Direction -> Hex -> Bool
isBorderOnSide coord side other =
    if coord === other then
        False
    else
        isBorderOnSideCube coord side other


{-| offset implementation - too messy but probably faster
-}
isBorderOnSideCube : Hex -> Direction -> Hex -> Bool
isBorderOnSideCube coord side other =
    let
        ( x, y ) =
            HL.hexToOffset coord

        ( x', y' ) =
            HL.hexToOffset other

        even =
            y % 2 == 0
    in
        case side of
            HH.W ->
                y' == y && x' == x - 1

            HH.E ->
                y' == y && x' == x + 1

            HH.NW ->
                if even then
                    x' == x - 1 && y' == y - 1
                else
                    x' == x && y' == y - 1

            HH.NE ->
                if even then
                    x' == x && y' == y - 1
                else
                    x' == x + 1 && y' == y - 1

            HH.SW ->
                if even then
                    x' == x - 1 && y' == y + 1
                else
                    x' == x && y' == y + 1

            HH.SE ->
                if even then
                    x' == x && y' == y + 1
                else
                    x' == x + 1 && y' == y + 1
