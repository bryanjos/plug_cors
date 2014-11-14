defmodule PlugCors do
  @moduledoc """
    A CORS Plug

    Usage:

    ```
        plug PlugCors, origins: ["test.origin.test"], methods: ["GET", "POST"], headers: ["Authorization"]
    ```

    Parameters:

    * origins: A list of allowed origins or "\*" for all origins. Default: "\*"

    * methods: A list of allowed HTTP methods. Default: ["GET", "HEAD", "POST", "OPTIONS", "PUT", "PATCH", "DELETE"]

    * headers: A list of allowed HTTP headers. Default: []

    * expose_headers: A list of headers to expose to the browser via the "Access-Control-Expose-Headers" header. Default: [] (Will not output header)

    * max_age: The max cache age of the response in seconds "Access-Control-Max-Age" header. Default: 0 (Will not output header)

    * supports_credentials: Whether or not to allow cookies with requests "Access-Control-Allow-Credentials" header. Default: false (Will not output header)

  """

  import Plug.Conn
  
  def init(opts) do 
    [
      origins: Keyword.get(opts, :origins, "*"),
      methods: Keyword.get(opts, :methods, ["GET", "HEAD", "POST", "OPTIONS", "PUT", "PATCH", "DELETE"]),
      headers: Keyword.get(opts, :headers, []),
      expose_headers: Keyword.get(opts, :expose_headers, []),
      max_age: Keyword.get(opts, :max_age, 0),
      supports_credentials: Keyword.get(opts, :supports_credentials, false)
    ]
  end

  def call(conn, config) do
    case get_req_header(conn, "origin") do
      [] ->
        conn
      [""] ->
        conn
      _ ->
        origin = hd(get_req_header(conn, "origin"))
        cond do
          is_invalid_origin?(origin, config[:origins]) ->
            conn
            |> resp(403, "")
            |> halt 
          is_preflight_request?(conn) ->
            PlugCors.Preflight.handlePreflight(conn, config)
          true ->
            PlugCors.Actual.handleRequest(conn, config) 
        end
    end
  end

  defp is_invalid_origin?(origin, origins) do
    case origins do
      "*" ->
        false
      _ ->
        Enum.find(origins, fn(x) -> String.contains?(origin, x) end) == nil
    end
  end

  defp is_preflight_request?(conn) do
    get_req_header(conn, "access-control-request-method") != [] and conn.method == "OPTIONS"
  end
end
