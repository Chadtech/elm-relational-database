module Db exposing
    ( Db, empty, Row
    , fromList, toList
    , insert, insertMany
    , get, getWithId, getMany
    , update
    , map, mapItem
    , remove
    , filter, filterMissing, allPresent
    )

{-| A way of storing your data by `Id`


# Db

@docs Db, empty, Row


# List

@docs fromList, toList


# Insert

@docs insert, insertMany


# Get

@docs get, getWithId, getMany


# Update

@docs update


# Map

@docs map, mapItem


# Remove

@docs remove


# Filter

@docs filter, filterMissing, allPresent

-}

import Dict
import Id exposing (Id)


{-| Short for "Database", it stores data by unique identifiers
-}
type Db item
    = Db (Dict.Dict String item)


{-| A single row in the `Db`; an `item` paired with its `Id`
-}
type alias Row item =
    ( Id item, item )


{-| Insert an item into the `Db` under the given `Id`
-}
insert : Row item -> Db item -> Db item
insert ( thisId, item ) (Db dict) =
    Dict.insert (Id.toString thisId) item dict
        |> Db


{-| Insert many items into the `Db` under their given `Id`s
-}
insertMany : List (Row item) -> Db item -> Db item
insertMany elements db =
    List.foldr insert db elements


{-| Update an item in a `Db`, using an update function. If the item doesnt exist in the `Db`, it comes into the update as `Nothing`. If a `Nothing` comes out of the update function, the value under that id will be removed.
-}
update : Id item -> (Maybe item -> Maybe item) -> Db item -> Db item
update id f (Db dict) =
    Dict.update (Id.toString id) f dict
        |> Db


{-| Remove the item at the given `Id`, if it exists
-}
remove : Id item -> Db item -> Db item
remove thisId (Db dict) =
    Db (Dict.remove (Id.toString thisId) dict)


{-| Get the item under the provided `Id`
-}
get : Db item -> Id item -> Maybe item
get (Db dict) thisId =
    Dict.get (Id.toString thisId) dict


{-| Just like `get`, except it comes with the `Id`, for those cases where you dont want the item separated from its `Id`
-}
getWithId : Db item -> Id item -> ( Id item, Maybe item )
getWithId db thisId =
    ( thisId, get db thisId )


{-| Get many items from a `Db`. The `(id, Nothing)` case represents the item under that `Id` being absent.
-}
getMany : Db item -> List (Id item) -> List ( Id item, Maybe item )
getMany db =
    List.map (getWithId db)


{-| Filter out items from a `Db`
-}
filter : (Row item -> Bool) -> Db item -> Db item
filter rowFilterFunction (Db dict) =
    let
        uncurried : String -> item -> Bool
        uncurried key value =
            rowFilterFunction ( Id.fromString key, value )
    in
    Dict.filter uncurried dict
        |> Db


{-| Take a `List` of items, presumably ones you just retrieved using `getMany`, and filter out
the ones that werent present in the `Db`

    myFriendsList
        |> Db.getMany people
        |> Db.filterMissing
        -->: List (Row Person)

-}
filterMissing : List ( Id item, Maybe item ) -> List (Row item)
filterMissing items =
    let
        onlyPresent : ( Id item, Maybe item ) -> Maybe (Row item)
        onlyPresent ( id, maybeItem ) =
            Maybe.map (Tuple.pair id) maybeItem
    in
    items
        |> List.map onlyPresent
        |> List.filterMap identity


{-| Verify that all the items are present, and if not, fail with a list of the items that are missing

    allPresent [ (id1, Just user1), (id2, Just user2) ]
    --> Ok [ (id1, user1), (id2, user2) ]

    allPresent [ (id1, Nothing), (id2, Just user2), (id3, Nothing) ]
    --> Err [ id1, id3 ]

-}
allPresent : List ( Id item, Maybe item ) -> Result (List (Id item)) (List (Row item))
allPresent items =
    let
        allPresentHelper :
            List ( Id item, Maybe item )
            -> Result (List (Id item)) (List (Row item))
            -> Result (List (Id item)) (List (Row item))
        allPresentHelper remainingItems accumulation =
            case accumulation of
                Ok foundItems ->
                    case remainingItems of
                        ( id, Just item ) :: rest ->
                            allPresentHelper rest (Ok (( id, item ) :: foundItems))

                        ( id, Nothing ) :: rest ->
                            allPresentHelper rest (Err [ id ])

                        [] ->
                            Ok <| List.reverse foundItems

                Err missingIds ->
                    case remainingItems of
                        ( id, Just _ ) :: rest ->
                            allPresentHelper rest (Err missingIds)

                        ( id, Nothing ) :: rest ->
                            allPresentHelper rest (Err (id :: missingIds))

                        [] ->
                            Err <| List.reverse missingIds
    in
    allPresentHelper items (Ok [])


{-| Turn your `Db` into a list
-}
toList : Db item -> List (Row item)
toList (Db dict) =
    Dict.toList dict
        |> List.map
            (Tuple.mapFirst Id.fromString)


{-| Initialize a `Db` from a list of id-value pairs
-}
fromList : List (Row item) -> Db item
fromList items =
    items
        |> List.map
            (Tuple.mapFirst Id.toString)
        |> Dict.fromList
        |> Db


{-| An empty `Db` with no entries
-}
empty : Db item
empty =
    Db Dict.empty


{-| Map a `Db` to a different data type.
-}
map : (a -> b) -> Db a -> Db b
map f (Db dict) =
    Dict.map (always f) dict
        |> Db


{-| Apply a change to just one item in the `Db`, assuming the item is in the `Db` in the first place. This function is just like `update` except deleting the item is not possible.
-}
mapItem : Id item -> (item -> item) -> Db item -> Db item
mapItem id f (Db dict) =
    Dict.update (Id.toString id) (Maybe.map f) dict
        |> Db
