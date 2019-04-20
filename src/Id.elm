module Id exposing (Id, fromString, toString, encode, decoder, generator)

{-| This package exposes a really simple type called `Id`.

    type Id x
        = Id String

Its for when your data has an id. Such as..

    import Id exposing (Id)

    type alias User =
        { id : Id ()
        , email : String
        }


### Why an `Id` and not a `String`?

The Elm compiler is totally okay with the following code snippet..

    viewUser : String -> String -> Html Msg
    viewUser email id =
        -- first parameter is email
        -- second parameter is id


    view : Model -> Html Msg
    view model =
        div
            []
            [ viewUser
                -- woops! The parameters are mixed up
                model.user.id
                model.user.email
            ]

These mistake is really easy to make and they cause real problems, but if you just use an `Id` you can make them impossible.


### Whats the `x` in `Id x` for?

You understand the problem in the previous example right? Here is a very similar problem..

    type Id
        = Id String

    updateUsersCatsFavoriteFood : Id -> Id -> Id -> Cmd Msg
    updateUsersCatsFavoriteFood userId catId foodId =
        -- ..

Theres absolutely nothing stopping a developer from mixing up a `catId` with a `userId` or a `foodId` with a `catId`.

Instead we can do..

    type Id x
        = Id String

    updateUsersCatsFavoriteFood : Id User -> Id Cat -> Id Food -> Cmd Msg
    updateUsersCatsFavoriteFood userId catId foodId =
        -- ..

Now with `Id x`, it is impossible (again) to mix up a `Id User` with a `Id Cat`. They have different types. And the compiler will point out if you try and use a `Id User` where only a `Id Cat` works.


### Okay, there is one trade off

The following code is not possible due to a circular definition of `User`..

    type alias User =
        { id : Id User }

Easy work arounds include..

    type UserId
        = UserId (Id User)

    type alias User =
        { id : UserId }

and

    type User
        = User { id : Id User }

..but I would encourage you to build your architecture such that data _does not_ contain its own `Id x` to begin with. Instead, get used to operating on `(Id User, User)` pairs, and treat the left side as the single source of truth for that identifier.

        ( Id User, User )


# Id

@docs Id, fromString, toString, encode, decoder, generator

-}

import Char
import Dict
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Random exposing (Generator)


{-| -}
type Id x
    = Id String


{-| Make an id from a string

    Id.fromString "vq93rUv0A4"

-}
fromString : String -> Id x
fromString =
    Id


{-| Extract the string from an id.
-}
toString : Id x -> String
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
encode : Id x -> Value
encode (Id str) =
    Encode.string str


{-| Decode an `Id`

    Decode.decodeString (Decode.field "id" Id.decoder) "{\"id\":\"19\"}"
    -- Ok (Id "19") : Result String Id

-}
decoder : Decoder (Id x)
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
generator : Generator (Id x)
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
