# Elm Relational Database

Some software projects involve the front end handling a large amount of unknown, dynamic and inter-related data, often retrieved from a remote source. Heres what I mean, taking a `User` as an example..

- `Large` meaning, the front end might get a lot of `User`s.
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



## Message Board Example

```elm
import Db exposing (Db)
import Id exposing (Id)

type alias Model =
    { threads : Db Thread
    , posts : Db Post
    }


type alias Thread =
    { title : String
    , posts : List (Id Post)
    }


type alias Post =
    { author : String
    , content : String
    }


-- ..

threadView : Db Post -> (Id Thread, Thread) -> Html Msg
threadView postsDb (threadId, thread) =
    let
        posts : List (Html Msg)
        posts =
            thread.posts
                |> Db.getMany postsDb
                |> Db.filterMissing 
                |> List.map postView
    in
    Html.div [ css [ threadStyle ] ]
        (Html.p [] [ Html.text thread.title ] :: posts)


postView : (Id Post, Post) -> Html Msg
postView (id, post) =
    Html.div
        [ Attrs.css [ postStyle ] ]
        [ Html.p
            []
            [ Html.text post.author ]
        , Html.p
            [ Event.onClick (ReplyToPostClicked id) ]
            [ Html.text post.content ]
        ]
```
