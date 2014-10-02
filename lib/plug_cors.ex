defmodule PlugCors do
  import Plug.Conn, only: [get_req_header: 2, put_resp_header: 3, send_resp: 3, send_resp: 2, halt: 1]
  
  def init(opts) do
    auto_allowed_headers = ["Accept", "Accept-Language", "Content-Language", "Last-Event-ID", "Content-Type"] 
    [
      allowed_origins: Keyword.fetch!(opts, :allowed_origins),
      allowed_methods: Keyword.fetch!(opts, :allowed_methods),
      allowed_headers: auto_allowed_headers ++ Keyword.fetch!(opts, :allowed_headers) 
    ]
  end

  def call(%Conn{method: "OPTIONS"} = conn, config) do
    conn
    |> get_origin
    |> check_origin(config)
  end

  defp get_origin(conn, config) do
    origin = get_req_header(conn, "origin")
    {conn, origin}
  end

  defp check_origin({conn, []}, _config) do
    conn
  end

  defp check_origin({conn, origin}, config) do
    origin = hd(origin)
    if origin == "*" do
      check_request_method(conn, config)
    else
      case Enum.find(config[:allowed_origins], fn(x) -> x == origin end) do
        nil -> 
          send_resp(conn, 403) |> halt
        _ ->
          check_request_method(conn, config)
      end
    end
  end

  defp check_request_method(conn, config) do
    request_method = get_req_header(conn, "Access-Control-Request-Method") |> hd
    case Enum.find(config[:allowed_methods], fn(x) -> x == request_method end) do
      nil -> 
        send_resp(conn, 403) |> halt
      _ ->
        check_request_method(conn, config)
    end 
  end

  defp check_access_control_headers(conn, config) do
    headers = get_req_header(conn, "Access-Control-Request-Headers")
    case Enum.empty? do
      true ->
        send_resp(conn, 200) |> halt
      false ->

        headers = hd(headers) |> Split.split(",")
        responses = Enum.each(headers, fn(x) ->
          Enum.find(config[:allowed_headers], fn(y) -> String.downcase(y) == String.downcase(x) end)
        end)

        case Enum.find(responses, fn(x) -> x == nil end) do
          nil -> 
            send_resp(conn, 200) |> halt
          _ ->
            send_resp(conn, 403) |> halt
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
            send_resp(conn, 403) |> halt
          _ ->
            origin = hd(origin)
            cond do
              origin == "*" ->
                check_request_headers(conn, config[:allowed_headers])
              Enum.find(config[:allowed_origins], fn(x) -> x == origin end) == nil ->
                send_resp(conn, 403) |> halt
              true ->
                check_request_headers(conn, config[:allowed_headers])
            end            
        end
    end
  end

  defp check_request_headers(conn, headers) do
    responses = Enum.each(conn.req_headers, fn(x) ->
      Enum.find(headers, fn({a, b}) -> String.downcase(a) == String.downcase(x) end)
    end)

    case Enum.find(responses, fn(x) -> x != nil end) do
      nil -> 
        send_resp(conn, 403) |> halt
      _ ->
        conn
    end     
  end

end
