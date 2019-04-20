module Remote.Db exposing
    ( Db, empty, Row
    , succeed, succeedMany, loading, loadingMany, fail, failMany, insert
    , get, getWithId, getMany
    , update
    , map, mapError, mapItem
    , remove
    )

{-| This module combines (Kris Jenkin's RemoteData package)[<https://package.elm-lang.org/packages/krisajenkins/remotedata/latest/>][https://package.elm-lang.org/packages/krisajenkins/remotedata/latest/] with the `Db` type in this package. The kinds of things you store in a relational database are usually fetched from a remote source, and the `RemoteData` type represents whether your data is loading, loaded, or failed to load. By storing data as `RemoteData`, this module can make the assumption that `Id` that are missing from the `Db`are `RemoteData.NotAsked`. This assumption permits our `get` function to return a `RemoteData error item` instead of a `Maybe item` or even a `Maybe (RemoteData error item)`.


# Db

@docs Db, empty, Row


# Insert

@docs succeed, succeedMany, loading, loadingMany, fail, failMany, insert


# Get

@docs get, getWithId, getMany


# Update

@docs update


# Map

@docs map, mapError, mapItem


# Remove

@docs remove

-}

import Db
import Dict
import Remote.Id as Id exposing (Id)
import RemoteData exposing (RemoteData(..))


{-| Short for "Database", it stores data by unique identifiers. The `error` is for loading errors, such as if an http request fails.
-}
type Db error item
    = Db (Dict.Dict String (RemoteData__Internal error item))


{-| A single row in the `Db`; an `Id`, corresponding to either an `item` or the `error` that happend when attempting to load it.
-}
type alias Row error item =
    ( Id error item, RemoteData error item )


type RemoteData__Internal error item
    = Internal__Loading
    | Internal__Loaded item
    | Internal__Failed error


internalRemoteDataToRemoteData : RemoteData__Internal error item -> RemoteData error item
internalRemoteDataToRemoteData remoteDataInternal =
    case remoteDataInternal of
        Internal__Loading ->
            Loading

        Internal__Loaded item ->
            Success item

        Internal__Failed error ->
            Failure error


remoteDataToInternalRemoteData : RemoteData error item -> Maybe (RemoteData__Internal error item)
remoteDataToInternalRemoteData remoteData =
    case remoteData of
        NotAsked ->
            Nothing

        Loading ->
            Just Internal__Loading

        Success item ->
            Just <| Internal__Loaded item

        Failure error ->
            Just <| Internal__Failed error


mapInternalRemoteData : (a -> b) -> RemoteData__Internal error a -> RemoteData__Internal error b
mapInternalRemoteData f remoteData =
    case remoteData of
        Internal__Loading ->
            Internal__Loading

        Internal__Loaded item ->
            Internal__Loaded (f item)

        Internal__Failed error ->
            Internal__Failed error


mapInternalRemoteDataError : (a -> b) -> RemoteData__Internal a item -> RemoteData__Internal b item
mapInternalRemoteDataError f remoteData =
    case remoteData of
        Internal__Loading ->
            Internal__Loading

        Internal__Loaded item ->
            Internal__Loaded item

        Internal__Failed error ->
            Internal__Failed <| f error


{-| An empty `Db` with no entries
-}
empty : Db error item
empty =
    Db Dict.empty


{-| Insert an `item` into a `Db`, when it has been successfully loaded
-}
succeed : ( Id error item, item ) -> Db error item -> Db error item
succeed ( id, item ) =
    insert ( id, Success item )


{-| Insert many `item`s into a `Db`, such as when you loaded many items successfully.
-}
succeedMany : List ( Id error item, item ) -> Db error item -> Db error item
succeedMany rows db =
    List.foldr succeed db rows


{-| Mark the `Id` as `Loading`. After this function is used on a `Db`, it will return `Loading` for that `Id`

    -- if the id is not in the `Db`
    Remote.Db.get db id
    --> RemoteData.NotAsked

    -- but if it is..
    Remote.Db.get (Remote.Db.loading id db) id
    --> RemoteData.Loading

-}
loading : Id error item -> Db error item -> Db error item
loading id =
    insert ( id, Loading )


{-| Mark a `List` of `Id` as `Loading` in a `Db`
-}
loadingMany : List (Id error item) -> Db error item -> Db error item
loadingMany ids db =
    List.foldr loading db ids


{-| When data fails to load, set it as `Failure` in the `Db`
-}
fail : ( Id error item, error ) -> Db error item -> Db error item
fail ( id, error ) =
    insert ( id, Failure error )


{-| Fail many `Id`, representing them as failing to load in the `Db`
-}
failMany : List ( Id error item, error ) -> Db error item -> Db error item
failMany ids db =
    List.foldr fail db ids


{-| A general insert function into `Db`. You can insert a `RemoteData error item` into a `Db`

    -- if the id is not in the `Db`
    Remote.Db.get db id
    --> RemoteData.NotAsked

    -- but if it is..
    Remote.Db.get
        (Remote.Db.insert (id, RemoteData.Failure "Could not load") db)
        id
    --> RemoteData.Failure "Could not load"

-}
insert : Row error item -> Db error item -> Db error item
insert ( id, remoteData ) (Db db) =
    case remoteData of
        NotAsked ->
            Dict.remove (Id.toString id) db
                |> Db

        Loading ->
            Dict.insert (Id.toString id) Internal__Loading db
                |> Db

        Success item ->
            Dict.insert (Id.toString id) (Internal__Loaded item) db
                |> Db

        Failure error ->
            Dict.insert (Id.toString id) (Internal__Failed error) db
                |> Db


{-| Simply remove an `Id` from a `Db`, resetting that item to `RemoteData.NotAsked`

    Remote.Db.get (Remote.Db.remove id db) id
    --> RemoteData.NotAsked

-}
remove : Id error item -> Db error item -> Db error item
remove id (Db db) =
    Dict.remove (Id.toString id) db
        |> Db


{-| Get an item out of a `Db`. Notice how it does not return a `Maybe` like `Dict` do. An `Id` that is not present in the `Db` is returned as `RemoteData.NotAsked`.
-}
get : Db error item -> Id error item -> RemoteData error item
get (Db db) id =
    Dict.get (Id.toString id) db
        |> Maybe.map internalRemoteDataToRemoteData
        |> Maybe.withDefault NotAsked


{-| Just like `get`, except it comes with the `Id`, for those cases where you dont want the item separated from its `Id`
-}
getWithId : Db error item -> Id error item -> Row error item
getWithId db id =
    get db id
        |> Tuple.pair id


{-| Get many items from a `Db`. The `(id, RemoteData.NotAsked)` case represents the item under that `Id` being absent.
-}
getMany : Db error item -> List (Id error item) -> List (Row error item)
getMany db =
    List.map (getWithId db)


{-| Update an item in a `Db`, using an update function. If the item doesnt exist in the `Db`, it comes into the update as `RemoteData.NotAsked`. If a `RemoteData.NotAsked` comes out of the update function, the value under that id will be removed.
-}
update : Id error item -> (RemoteData error item -> RemoteData error item) -> Db error item -> Db error item
update id mapFunction (Db dict) =
    let
        updateFunction :
            Maybe (RemoteData__Internal error item)
            -> Maybe (RemoteData__Internal error item)
        updateFunction maybeRemoteData =
            case maybeRemoteData of
                Nothing ->
                    mapFunction NotAsked
                        |> remoteDataToInternalRemoteData

                Just remoteData ->
                    remoteData
                        |> internalRemoteDataToRemoteData
                        |> mapFunction
                        |> remoteDataToInternalRemoteData
    in
    Dict.update (Id.toString id) updateFunction dict
        |> Db


{-| Map a `Db` to a different data type.
-}
map : (a -> b) -> Db error a -> Db error b
map f (Db dict) =
    Dict.map (always (mapInternalRemoteData f)) dict
        |> Db


{-| Map the error type of a `Db` to something else.
-}
mapError : (a -> b) -> Db a item -> Db b item
mapError f (Db dict) =
    Dict.map (always (mapInternalRemoteDataError f)) dict
        |> Db


{-| Apply a change to just one item in the `Db`, assuming the item is in the `Db` in the first place. This function is just like `update` except deleting the item is not possible.
-}
mapItem : Id error item -> (item -> item) -> Db error item -> Db error item
mapItem id f (Db dict) =
    Dict.update
        (Id.toString id)
        (Maybe.map (mapInternalRemoteData f))
        dict
        |> Db
