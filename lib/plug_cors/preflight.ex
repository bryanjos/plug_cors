defmodule PlugCors.Preflight do
  import Plug.Conn
  
  def handlePreflight(conn, config) do
    conn
    |> get_request_method
    |> check_request_method(config)
  end

  defp get_request_method(conn) do
    method = get_req_header(conn, "Access-Control-Request-Method") |> hd
    {conn, method }
  end

  defp check_request_method({ conn, method }, config) do
    case are_all_allowed?(method, config[:methods]) do
      false -> 
        send_unauthorized(conn) 
      _ ->
        conn
        |> get_request_headers      
        |> check_access_control_headers(config)
    end 
  end

  defp get_request_headers(conn) do
    headers = get_req_header(conn, "Access-Control-Request-Headers")
    {conn, headers}
  end

  defp check_access_control_headers({conn, []}, config) do
    send_ok(conn, config) 
  end

  defp check_access_control_headers({ conn, headers }, config) do
    headers = hd(headers) |> String.split(",")

    case are_all_allowed?(headers, config[:headers] ) do
      true ->  
        send_ok(conn, config)
      _ ->
        send_unauthorized(conn) 
    end
  end

  defp are_all_allowed?(list_to_check, allowed_list) do
    responses = Enum.map(list_to_check, fn(x) ->
      Enum.find(allowed_list, fn(y) -> String.downcase(y) == String.downcase(x) end)
    end)

    responses = Enum.map(responses, fn(x) ->
      if is_nil(x), do: "nil", else: x
    end)

    case Enum.find(responses, fn(x) -> x == "nil" end) do
      nil ->  
        true
      _ ->
        false
    end
  end

  defp send_ok(conn, config) do
    origin = if config[:origins] == "*", do: "*", else: hd(get_req_header(conn, "Origin"))

    conn = conn     
    |> put_resp_header("Access-Control-Allow-Origin", origin)
    |> put_resp_header("Access-Control-Allow-Methods", Enum.join(config[:methods], ",")) 
    |> put_resp_header("Access-Control-Allow-Headers", Enum.join(config[:headers], ","))

    if config[:max_age] > 0 do
      conn = put_resp_header(conn, "Access-Control-Max-Age", config[:max_age])
    end

    if config[:supports_credentials] do
      conn = put_resp_header(conn, "Access-Control-Allow-Credentials", true)
    end

    if Enum.count(config[:expose_headers]) > 0 do
      conn = put_resp_header(conn, "Access-Control-Expose-Headers", Enum.join(config[:expose_headers], ","))
    end

    conn
    |> resp(200, "")
    |> halt 
  end

  defp send_unauthorized(conn) do
    conn      
    |> resp(403, "")
    |> halt
  end
end