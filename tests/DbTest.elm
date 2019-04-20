module DbTest exposing (suite)

import Db exposing (Db)
import Expect exposing (Expectation)
import Id
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Db"
        [ test "toList and fromList are exactly reversible" <|
            \_ ->
                let
                    list : List (Db.Row Int)
                    list =
                        [ ( Id.fromString "1", 1 )
                        , ( Id.fromString "2", 2 )
                        ]
                in
                list
                    |> Db.fromList
                    |> Db.toList
                    |> Expect.equal list
        , test "inserting an item leads to it being 'get-able'" <|
            \_ ->
                Db.get
                    (Db.insert ( Id.fromString "1", 1 ) Db.empty)
                    (Id.fromString "1")
                    |> Expect.equal (Just 1)
        , test "filtering works" <|
            \_ ->
                [ ( Id.fromString "1", 1 ) ]
                    |> Db.fromList
                    |> Db.filter (always False)
                    |> Expect.equal Db.empty
        , test "filterMissing" <|
            \_ ->
                [ ( Id.fromString "1", Just 1 )
                , ( Id.fromString "2", Nothing )
                ]
                    |> Db.filterMissing
                    |> Expect.equal [ ( Id.fromString "1", 1 ) ]
        , test "allPresent is Ok when all present" <|
            \_ ->
                [ ( Id.fromString "1", Just 1 )
                , ( Id.fromString "2", Just 2 )
                ]
                    |> Db.allPresent
                    |> Expect.equal
                        (Ok [ ( Id.fromString "1", 1 ), ( Id.fromString "2", 2 ) ])
        , test "allPresent is Err when not all present" <|
            \_ ->
                [ ( Id.fromString "1", Just 1 )
                , ( Id.fromString "2", Nothing )
                , ( Id.fromString "3", Just 3 )
                , ( Id.fromString "4", Nothing )
                ]
                    |> Db.allPresent
                    |> Expect.equal
                        (Err [ Id.fromString "2", Id.fromString "4" ])
        , test "mapItem" <|
            \_ ->
                let
                    db : Db Int
                    db =
                        Db.fromList [ ( Id.fromString "1", 1 ) ]
                            |> Db.mapItem
                                (Id.fromString "1")
                                ((+) 1)
                in
                Db.get db (Id.fromString "1")
                    |> Expect.equal (Just 2)
        ]
