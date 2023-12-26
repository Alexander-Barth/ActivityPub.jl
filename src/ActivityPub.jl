module ActivityPub


using HTTP
using JSON3
using UUIDs


mutable struct Connection
    baseurl::String
    access_token:: String
end

const REDIRECT_URI = "urn:ietf:wg:oauth:2.0:oob"

"""
    conn = ActivityPub.Connection(baseurl,username,password)

Connect to activity pub server at `baseurl` using the provided credentials.
Note: for Mastodon username is your email (not your handle).
The API call succeeds even if you credentials are wrong. Use
`verify_credentials` to check the username and password.

When the server is overloaded it may fail with an `EOFError` or with the error
message:

```The provided authorization grant is invalid, expired,
revoked, does not match the redirection URI used in the
authorization request, or was issued to another client`.
```
"""
function Connection(
    baseurl::AbstractString,
    username::AbstractString,
    password::AbstractString;
    user_agent = "ActivityPub.jl",
    client_website = "https://example.com",
    scopes = ["read","write"],
    )

    url = baseurl * "/api/v1/apps"

    # get_auth_token
    params = Dict(
        "client_name" => user_agent,
        "client_website" =>  client_website,
        "scopes" =>  join(scopes,' '),
        "redirect_uris" => REDIRECT_URI,
    )

    @debug "apps" params
    r = HTTP.post(url,
                  ["Content-Type" => "application/json"],
                  JSON3.write(params))

    body =  String(r.body)
    @debug "response api/v1/apps" r.status body

    data = JSON3.read(body)

    params2 = Dict(
        "client_id" => data.client_id,
        "client_secret" => data.client_secret,
        "scope" =>  join(scopes,' '),
        "redirect_uri" => REDIRECT_URI,
        "grant_type" => "password",
        "username" => username,
        "password" => password,
    )

    @debug "form data oauth/token" params2

    r = HTTP.post(baseurl * "/oauth/token",
                  [],
                  HTTP.Form(params2))

    body =  String(r.body)
    data = JSON3.read(body)
    access_token = data.access_token

    @debug "response oauth/token" r.status body

    @debug "access_token" access_token
    return Connection(baseurl,access_token)
end


function verify_credentials(conn::Connection)
    headers = Dict(
        "Authorization" => "Bearer $(conn.access_token)",
    )

    url = conn.baseurl * "/api/v1/accounts/verify_credentials"
    r = HTTP.get(url, headers, status_exception = false)

    body = String(r.body)
    @debug "response accounts/verify_credentials" r.status body
    return JSON3.read(body)
end

function post_media(
    conn::Connection,
    filename::AbstractString,
    mime_type::AbstractString; description = nothing)

    headers = Dict(
        "Authorization" => "Bearer $(conn.access_token)",
    )

    url = conn.baseurl * "/api/v1/media"

    fileext = splitext(basename(filename))[end]
    param = Dict{String,Any}(
        "file" => HTTP.Multipart(string(uuid4()) * fileext , open(filename), mime_type),
    )

    if !isnothing(description)
        param["description"] = description
    end

    r = HTTP.post(url,headers,HTTP.Form(param))

    body =  String(r.body)
    response = JSON3.read(body)

    return response.id
end

function post_status(
    conn,status; media_ids = [], visibility = "public",
    sensitive = false,
    spoiler_text = nothing,
    )

    headers = Dict(
        "Authorization" => "Bearer $(conn.access_token)",
        "Idempotency-Key" => string(uuid4()),
    )

    url = conn.baseurl * "/api/v1/statuses/"

    params = Dict(
        "status" => status,
        "visibility" => visibility,
        "sensitive" => sensitive,
    )

    if !isempty(media_ids)
        params["media_ids"] = media_ids
    end

    if spoiler_text != nothing
        params["spoiler_text"] = spoiler_text
    end

    headers["Content-Type"] = "application/json"

    r = HTTP.post(url,headers,JSON3.write(params))

    body =  String(r.body)
    response = JSON3.read(body)

    return response
end

"""
    id = ActivityPub.account_id(conn,username::AbstractString)

Get the `id` from a user name (e.g. `@FooBar`) for the connect `conn` .
"""
function account_id(conn,username::AbstractString)
    headers = Dict(
        "Authorization" => "Bearer $(conn.access_token)",
    )

    url = conn.baseurl * "/api/v1/accounts/lookup?acct=$username"
    r = HTTP.get(url,headers)
    body =  String(r.body)
    response = JSON3.read(body)

    return response.id
end

"""
    statuses = ActivityPub.statuses(conn,account_id)

Get a list of all statuses of the accound with the `id` of the connect `conn`.
Note the `account_id` is different from the username and can be obtained via
`ActivityPub.account_id`.

"""
function statuses(conn,account_id)
    headers = Dict(
        "Authorization" => "Bearer $(conn.access_token)",
    )

    url = conn.baseurl * "/api/v1/accounts/$account_id/statuses/"
    r = HTTP.get(url,headers)
    body =  String(r.body)
    response = JSON3.read(body)
    return response
end


end # module ActivityPub
