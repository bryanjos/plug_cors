defmodule PlugCors.Preflight do
  import Plug.Conn
  @moduledoc false

  @default_accept_headers [
    "accept",
    "accept-language",
    "content-language",
    "last-event-id",
    "content-type"
    ]

  def call(conn, config) do
    origin = get_req_header(conn, "origin")
    case is_invalid_origin?(origin, config[:origins]) do
      true ->
        send_unauthorized(conn)
      _ ->
        conn
        |> get_request_method
        |> check_request_method(config)
    end
  end

  defp is_invalid_origin?(_origin, "*") do
    false
  end

  defp is_invalid_origin?([origin], origins) do
    Enum.find(origins, fn(x) -> is_origin_allowed?(origin, x) end) == nil
  end

  defp is_origin_allowed?(origin_to_test, allowed_origin) do
    case allowed_origin do
      "*." <> domain -> 
        String.contains?(origin_to_test, domain)
      _ -> 
        String.contains?(origin_to_test, allowed_origin)
    end
  end

  defp get_request_method(conn) do
    method = get_req_header(conn, "access-control-request-method") |> hd
    {conn, method }
  end

  defp check_request_method({ conn, method }, config) do
    case are_all_allowed?([method], config[:methods]) do
      false -> 
        send_unauthorized(conn) 
      _ ->
        conn
        |> get_request_headers      
        |> check_access_control_headers(config)
    end 
  end

  defp get_request_headers(conn) do
    headers = get_req_header(conn, "access-control-request-headers")
    {conn, headers}
  end

  defp check_access_control_headers({conn, []}, config) do
    send_ok(conn, config) 
  end

  defp check_access_control_headers({ conn, headers }, config) do
    headers = hd(headers) |> String.split(",") |> Enum.map(fn(x) -> String.strip(x) end)
    case are_all_allowed?(headers, config[:headers] ) do
      true ->  
        send_ok(conn, config)
      _ ->
        send_unauthorized(conn) 
    end
  end

  defp are_all_allowed?(_,[]) do
    true
  end

  defp are_all_allowed?(list_to_check, configured_list) do
   allowed_list = configured_list ++ @default_accept_headers 
   responses = Enum.map(list_to_check, fn(x) ->
      Enum.find(allowed_list, fn(y) -> String.downcase(y) == String.downcase(x) end)
    end)

    responses = Enum.map(responses, fn(x) ->
      if is_nil(x), do: "nil", else: x
    end)

    Enum.find(responses, fn(x) -> x == "nil" end) == nil
  end

  defp allow_headers(config) do
    Enum.uniq(Enum.concat(config[:headers],@default_accept_headers))
  end

  defp send_ok(conn, config) do
    origin = if config[:origins] == "*", do: "*", else: hd(get_req_header(conn, "origin"))

    conn = conn     
    |> put_resp_header("access-control-allow-origin", origin)
    |> put_resp_header("access-control-allow-methods", Enum.join(config[:methods], ",")) 
    |> put_resp_header("access-control-allow-headers", Enum.join(allow_headers(config), ","))

    if config[:max_age] > 0 do
      conn = put_resp_header(conn, "access-control-max-age", config[:max_age])
    end

    if config[:supports_credentials] do
      conn = put_resp_header(conn, "access-control-allow-credentials", true)
    end

    if Enum.count(config[:expose_headers]) > 0 do
      conn = put_resp_header(conn, "access-control-expose-headers", Enum.join(config[:expose_headers], ","))
    end
    conn |> send_resp( 200, "") |> halt
    
  end

  defp send_unauthorized(conn) do
    conn |> send_resp( 403, "") |> halt
  end
end
