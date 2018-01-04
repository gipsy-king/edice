module Tables exposing (Table(..), decodeTable, encodeTable, tableList)


type Table
    = Melchor
    | Miño
    | Serrano
    | Avocado
    | DeLucía
    | Sabicas


tableList : List Table
tableList =
    [ Melchor, Miño, DeLucía, Serrano, Avocado ]


decodeTable : String -> Maybe Table
decodeTable name =
    case name of
        "Melchor" ->
            Just Melchor

        "Miño" ->
            Just Miño

        "Serrano" ->
            Just Serrano

        "Avocado" ->
            Just Avocado

        "DeLucía" ->
            Just DeLucía

        "Sabicas" ->
            Just Sabicas

        _ ->
            Nothing


encodeTable : Table -> String
encodeTable table =
    case table of
        Melchor ->
            "Melchor"

        Miño ->
            "Miño"

        Serrano ->
            "Serrano"

        Avocado ->
            "Avocado"

        DeLucía ->
            "DeLucía"

        Sabicas ->
            "Sabicas"
