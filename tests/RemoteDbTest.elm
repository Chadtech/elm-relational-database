module DbTest exposing (tests)

import Expect exposing (Expectation)
import Remote.Db as Db exposing (Db)
import Remote.Id
import Test exposing (Test, describe, test)


tests : Test
tests =
    describe "Db"
        []
