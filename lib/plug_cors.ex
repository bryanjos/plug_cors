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
    origin = get_req_header(conn, "Origin")
    {conn, origin}
  end

  defp check_origin({conn, []}, _config) do
    conn
    |> resp(200, "")
    |> halt  
  end

  defp check_origin({conn, origin}, config) do
    origin = hd(origin)

    cond do
      is_origin_allowed?(origin, config) ->
        conn 
        |> put_resp_header("Access-Control-Allow-Origin", origin)
        |> get_request_method
        |> check_request_method(config)
      true ->
        conn
        |> resp(403, "")
        |> halt        
    end
  end

  defp is_origin_allowed?(origin, config) do
    origin = String.replace(origin, "http://", "") |> String.replace("https://", "")
    cond do
      hd(config[:allowed_origins]) == "*" ->
        true
      true ->
        Enum.find(config[:allowed_origins], fn(x) -> x == origin end) != nil 
    end
  end

  defp get_request_method(conn) do
    method = get_req_header(conn, "Access-Control-Request-Method")
    {conn, method}
  end

  defp check_request_method({conn, []}, _config) do
    conn
    |> resp(200, "")
    |> halt   
  end

  defp check_request_method({ conn, request_method }, config) do
    case is_method_allowed?(hd(request_method), config) do
      false -> 
        conn
        |> resp(403, "")
        |> halt  
      _ ->
        conn
        |> put_resp_header("Access-Control-Allow-Methods", Enum.join(config[:allowed_methods], ",")) 
        |> get_request_headers      
        |> check_access_control_headers(config)
    end 
  end

  defp is_method_allowed?(request_method, config) do
    response = Enum.find(config[:allowed_methods], fn(x) -> x == request_method end)
    response != nil
  end

  defp get_request_headers(conn) do
    headers = get_req_header(conn, "Access-Control-Request-Headers")
    {conn, headers}
  end

  defp check_access_control_headers({conn, []}, _config) do
    conn
    |> resp(200, "")
    |> halt   
  end

  defp check_access_control_headers({ conn, headers }, config) do
    headers = hd(headers) |> String.split(",")
    responses = Enum.map(headers, fn(x) ->
      Enum.find(config[:allowed_headers], fn(y) -> String.downcase(y) == String.downcase(x) end)
    end)

    responses = Enum.map(responses, fn(x) ->
      if is_nil(x) do
        "nil"
      else
        x
      end
    end)

    case Enum.find(responses, fn(x) -> x == "nil" end) do
      nil -> 
        conn 
        |> put_resp_header("Access-Control-Allow-Headers", Enum.join(config[:allowed_headers], ","))       
        |> resp(200, "")
        |> halt
      _ ->
        conn 
        |> put_resp_header("Access-Control-Allow-Headers", Enum.join(config[:allowed_headers], ","))       
        |> resp(403, "")
        |> halt
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
