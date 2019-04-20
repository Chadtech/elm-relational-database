# Elm Relational Database

Some software projects involve the front end handling a large amount of unknown, dynamic and inter-related data, often retrieved from a remote source. Heres what I mean, taking a `User` as an example..

- `Large` meaing, the front end might get a lot of `User`s.
- `Unknown` meaning, it has no idea how many or what `User`s it will get
- `Inter-related` meaning, `User`s might be related to other data, for example your software might let `User` be friends with each other. 
- `Dynamic` meaning, the `User`s and their relationship might change over time. A new `User` might show up, or, two existing `User`s might become friends with each other during or between run times.

Projects like this need a centralized single source of truth for all this data, so so that your data can be represented the same across the entire software. Indeed, thats exactly what a relational database is. 
```elm
import Db exposing (Db)

type alias Model =
    { users : Db User }
```
[If you still are wondering what the deal is, Richard Feldman gave a really good talk on relational database stuff in Elm.](https://www.youtube.com/watch?v=28OdemxhfbU)


## This package has three parts.
- `Db`
- `Id`
- `Remote.Db`

### Db

Short for "Database", `Db item` is basically a glorified `Dict String item`. It takes `Id item`, and it if has an `item` under that `Id item`, it gives it to you.

```elm

users : Db User
users =
    --

maybeBob : (Id User, Maybe User)
maybeBob =
    Db.get users (Id.fromString "bob") 
```

The functions in the `Db` module are much like those of `Dict`, but they are specialized for the use case of a relational database.

### Id

This package exposes a really simple type called `Id`.

```elm
type Id x
    = Id String
```

Its for when your data has an id. Such as..

```elm
import Id exposing (Id)

type alias User =
    { id : Id ()
    , email : String
    }
```

### Why an `Id` and not a `String`?

The Elm compiler is totally okay with the following code snippet..

```elm
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
```

These mistake is really easy to make and they cause real problems, but if you just use an `Id` you can make them impossible.

### Whats the `x` in `Id x` for?

You understand the problem in the previous example right? Here is a very similar problem..

```elm
type Id
    = Id String

updateUsersCatsFavoriteFood : Id -> Id -> Id -> Cmd Msg
updateUsersCatsFavoriteFood userId catId foodId =
    -- ..
```

Theres absolutely nothing stopping a developer from mixing up a `catId` with a `userId` or a `foodId` with a `catId`.

Instead we can do..

```elm
type Id x
    = Id String

updateUsersCatsFavoriteFood : Id User -> Id Cat -> Id Food -> Cmd Msg
updateUsersCatsFavoriteFood userId catId foodId =
    -- ..
```

Now with `Id x`, it is impossible (again) to mix up a `Id User` with a `Id Cat`. They have different types. And the compiler will point out if you try and use a `Id User` where only a `Id Cat` works.

### Okay, there is one trade off

The following code is not possible due to a circular definition of `User`..

```elm
type alias User =
    { id : Id User }
```

Easy work arounds include..

```elm
type UserId 
    = UserId (Id User)

type alias User =
    { id : UserId }
```

and

```elm
type User 
    = User
        { id : Id User }
```

..but I would encourage you to build your architecture such that data _does not_ contain its own `Id x` to begin with. Instead, get used to operating on `(Id User, User)` pairs, and treat the left side as the single source of truth for that identifier.

```elm
    (Id User, User)
```

### Message Board Example

```elm
type alias Thread =
    { title : String
    , posts : List (Id Post)
    }


type alias Post =
    { author : String
    , content : String
    }


threadView : Db Post -> (Id Thread, Thread) -> Html Msg
threadView postsDb (threadId, thread) =
    thread.posts
        |> Db.getMany postsDb
        |> List.map postView
        |> (::) (p [] [ Html.text thread.title ])
        |> div [ css [ threadStyle ] ]


postView : (Id Post, Maybe Post) -> Html Msg
postView post =
    Html.div
        [ Attrs.css [ postStyle ] ]
        (postBody post)


postBody : (Id Post, Maybe Post) -> List (Html Msg)
postBody (id, maybePost) =
    case maybePost of
        Just post ->
            [ Html.p
                []
                [ Html.text post.author ]
            , Html.p
                [ Event.onClick (ReplyToPostClicked id) ]
                [ Html.text post.content ]
            ]

        Nothing ->
            [ Html.p
                []
                [ Html.text "Post not found" ]
            ]
```
