module Remote.Id exposing (Id, fromString, toString, encode, decoder, generator)

{-| Much like the `Id` type in the non-remote version of this module, except now the `Id` might also point to the `error` that occured when trying to load the `item`.


# Id

@docs Id, fromString, toString, encode, decoder, generator

-}

import Char
import Dict
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Random exposing (Generator)


{-| -}
type Id error x
    = Id String


{-| Make an id from a string

    Id.fromString "vq93rUv0A4"

-}
fromString : String -> Id error x
fromString =
    Id


{-| Extract the string from an id.
-}
toString : Id error x -> String
toString (Id str) =
    str


{-| Encode an `Id`

    Encode.encode 0 (Id.encode id)
    -- ""hDFL0Cs2EqWJ4jc3kMtOrKdEUTWh"" : String

    [ ("id", Id.encode id) ]
        |> Encode.object
        |> Encode.encode 0

    -- {\"id\":\"hDFL0Cs2EqWJ4jc3kMtOrKdEUTWh\"} : String

-}
encode : Id error x -> Value
encode (Id str) =
    Encode.string str


{-| Decode an `Id`

    Decode.decodeString (Decode.field "id" Id.decoder) "{\"id\":\"19\"}"
    -- Ok (Id "19") : Result String Id

-}
decoder : Decoder (Id error x)
decoder =
    Decode.map Id Decode.string


{-| A way to generate random `Id`s

    import Id exposing (Id)
    import Random exposing (Seed)

    user : Seed -> ( User, Seed )
    user seed =
        let
            ( id, nextSeed ) =
                Random.step Id.generator seed
        in
        ( { id = id, email = "Bob@sci.org" }
        , nextSeed
        )

-}
generator : Generator (Id error x)
generator =
    Random.int 0 61
        |> Random.list 64
        |> Random.map (intsToString >> Id)


intsToString : List Int -> String
intsToString =
    List.map toChar >> String.fromList


toChar : Int -> Char
toChar int =
    let
        code : Int
        code =
            if int < 10 then
                int + 48

            else if int < 36 then
                int + 55

            else
                int + 61
    in
    Char.fromCode code
