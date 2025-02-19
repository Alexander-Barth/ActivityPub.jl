# ActivityPub


Minimalist and experimental ActivityPub client for [julia](https://julialang.org/).
ActivityPub is the protocol used by [Mastodon](https://docs.joinmastodon.org/).

The client so far only support posting messages (with additional media such as images).
Pull requests are welcome!


### Example

``` julia
username = "name@email-server.com" # this is _not_ your @handle
password = "secret"
baseurl = "https://fosstodon.org"

conn = ActivityPub.Connection(baseurl,username,password)
ActivityPub.verify_credentials(conn)

filename = "cat.png"
mime_type = "image/png"
description = "My cat"

media_id = ActivityPub.post_media(conn,filename,mime_type,
                                  description = description)

status = "My silly cat"
response = ActivityPub.post_status(conn,status, media_ids = [media_id])
```

## Credits

* Thanks to marvin8 for https://codeberg.org/MarvinsMastodonTools/minimal-activitypub (git [commit](https://codeberg.org/marvinsmastodontools/minimal-activitypub/commit/aabbd45e68eb02700fed9be22efd4431cac36a75))
