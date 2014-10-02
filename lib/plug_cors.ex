defmodule PlugCors do
  import Plug.Conn
  
  def init(opts) do
    auto_allowed_headers = ["Accept", "Accept-Language", "Content-Language", "Last-Event-ID", "Content-Type"] 
    [
      allowed_origins: Keyword.fetch!(opts, :allowed_origins),
      allowed_methods: Keyword.fetch!(opts, :allowed_methods),
      allowed_headers: auto_allowed_headers ++ Keyword.fetch!(opts, :allowed_headers) 
    ]
  end

  def call(%Plug.Conn{method: "OPTIONS"} = conn, config) do
    conn
    |> get_origin
    |> check_origin(config)
  end

  defp get_origin(conn) do
    origin = get_req_header(conn, "origin")
    {conn, origin}
  end

  defp check_origin({conn, []}, _config) do
    conn
  end

  defp check_origin({conn, origin}, config) do
    origin = hd(origin)

    cond do
      origin == "*" or is_origin_allowed?(origin, config) ->
        conn 
        |> put_resp_header("Access-Control-Allow-Origin", origin) 
        |> check_request_method(config)
      true ->
        conn
        |> put_status(403)
        |> send_resp
        |> halt        
    end
  end

  defp is_origin_allowed?(origin, config) do
    Enum.find(config[:allowed_origins], fn(x) -> x == origin end) != nil 
  end

  defp check_request_method(conn, config) do
    request_method = get_req_header(conn, "Access-Control-Request-Method") |> hd
    case is_method_allowed?(request_method, config) do
      nil -> 
        conn
        |> put_status(403)
        |> send_resp
        |> halt  
      _ ->
        conn 
        |> put_resp_header("Access-Control-Allow-Methods", Enum.join(config[:allowed_methods], ","))       
        |> check_access_control_headers(config)
    end 
  end

  defp is_method_allowed?(request_method, config) do
    Enum.find(config[:allowed_methods], fn(x) -> x == request_method end) != nil 
  end

  defp check_access_control_headers(conn, config) do
    headers = get_req_header(conn, "Access-Control-Request-Headers")
    case Enum.empty? do
      true ->
        conn 
        |> put_resp_header("Access-Control-Allow-Headers", Enum.join(config[:allowed_headers], ","))       
        |> put_status(200)
        |> send_resp
        |> halt
      false ->

        headers = hd(headers) |> Split.split(",")
        responses = Enum.each(headers, fn(x) ->
          Enum.find(config[:allowed_headers], fn(y) -> String.downcase(y) == String.downcase(x) end)
        end)

        case Enum.find(responses, fn(x) -> x == nil end) do
          nil -> 
            conn 
            |> put_resp_header("Access-Control-Allow-Headers", Enum.join(config[:allowed_headers], ","))       
            |> put_status(200)
            |> send_resp
            |> halt
          _ ->
            conn 
            |> put_resp_header("Access-Control-Allow-Headers", Enum.join(config[:allowed_headers], ","))       
            |> put_status(403)
            |> send_resp
            |> halt
        end

    end
  end


  def call(conn, config) do
    origin = get_req_header(conn, "origin")
    case origin do
      [] ->
        conn
      _ ->
        case Enum.find(config[:allowed_methods], fn(x) -> x == conn.method end) do
          nil ->
            conn
            |> put_status(403)
            |> send_resp
            |> halt
          _ ->
            origin = hd(origin)
            cond do
              origin == "*" ->
                check_request_headers(conn, config[:allowed_headers])
              Enum.find(config[:allowed_origins], fn(x) -> x == origin end) == nil ->
                conn
                |> put_status(403)
                |> send_resp
                |> halt
              true ->
                check_request_headers(conn, config[:allowed_headers])
            end            
        end
    end
  end

  defp check_request_headers(conn, headers) do
    responses = Enum.each(conn.req_headers, fn(x) ->
      Enum.find(headers, fn({a, _b}) -> String.downcase(a) == String.downcase(x) end)
    end)

    case Enum.find(responses, fn(x) -> x != nil end) do
      nil -> 
        conn
        |> put_status(403)
        |> send_resp
        |> halt
      _ ->
        conn
    end     
  end

end
