defmodule PlugCors.Actual do
  import Plug.Conn

  @moduledoc false

  def call(conn, config) do
    check_method(conn, config)
  end

  defp check_method(conn, config) do
    case Enum.find(config[:methods], fn(x) -> String.downcase(x) == String.downcase(conn.method) end) do
      nil ->
        conn
      _ ->
        if PlugCors.is_valid_origin?(get_req_header(conn, "origin"), config[:origins]) do                         
          origin = if config[:origins] == "*", do: "*", else: hd(get_req_header(conn, "origin"))
          conn = conn |> put_resp_header("access-control-allow-origin", origin)

          if config[:supports_credentials] do
            conn = put_resp_header(conn, "access-control-allow-credentials", "true")
          end

          if Enum.count(config[:expose_headers]) > 0 do
            conn = put_resp_header(conn, "access-control-expose-headers", Enum.join(config[:expose_headers], ","))
          end
        end
                                        
        conn
    end
  end
end
