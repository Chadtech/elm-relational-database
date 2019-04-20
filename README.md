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



## Message Board Example

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
