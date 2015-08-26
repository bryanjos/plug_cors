## DEPRECATED: Please use [Corsica](https://github.com/whatyouhide/corsica) instead

## PlugCors [![Documentation](https://img.shields.io/badge/docs-hexpm-blue.svg)](http://hexdocs.pm/plug_cors/) [![Downloads](https://img.shields.io/hexpm/dt/plug_cors.svg)](https://hex.pm/packages/plug_cors)

A CORS Middleware for Plug.

## Installation

Add the following to the deps section in your ```mix.exs``` file.

```Elixir
defp deps do
  [...
   {:plug_cors, "~> 0.7.3"}]
end
```

After you are done, run ```mix deps.get``` in your shell to fetch and compile PlugCors.

## Usage

```elixir
    plug PlugCors, origins: ["test.origin.test", "*.domain.com"], methods: ["GET", "POST"], headers: ["Authorization"]
```

If using with Phoenix, make sure to define the plug above your router. This is so the plug correctly responds to the OPTIONS requests the browser makes for CORS and prevents 404 responses to the browser's CORS requests.

```elixir
defmodule App.Endpoint do
  #the rest of the plugs defined in App.Endpoint

  plug PlugCors, origins: ["*"]
  plug :router, App.Router
end
```

You can also define the parameters inside of your elixir config if you wish. Parameters defined directly on the plug take precedence over the ones in config

```elixir
  config :plug_cors,
    origins: ["test.origin.test", "*.domain.com"],
    methods: ["GET", "POST"],
    headers: ["Authorization"]
```

## Parameters

* origins: A list of allowed origins or "\*" for all origins. Default: "\*". Can add use wildcards domains such as "*.domain.com" to match on the domain and all it's sub domains

* methods: A list of allowed HTTP methods. Default: ["GET", "HEAD", "POST", "OPTIONS", "PUT", "PATCH", "DELETE"]

* headers: A list of additional HTTP headers. Default: []
** This is in addition to PlugCors.Preflight.default_accept_headers  :
** [ "accept", "accept-language","content-language", "last-event-id", "content-type" ]

* expose_headers: A list of headers to expose to the browser via the "Access-Control-Expose-Headers" header. Default: [] (Will not output header)

* max_age: The max cache age of the response in seconds "Access-Control-Max-Age" header. Default: 0 (Will not output header)

* supports_credentials: Whether or not to allow cookies with requests "Access-Control-Allow-Credentials" header. Default: false (Will not output header)



