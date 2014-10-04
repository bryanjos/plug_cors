defmodule PlugCorsTest do
  use ExUnit.Case, async: true
  use Plug.Test
  
  defmodule TestRouterPlug do
    import Plug.Conn
    use Plug.Router
    
    plug PlugCors, origins: ["test.origin.test"], methods: ["GET", "POST"], headers: ["Authorization"]
    plug :match
    plug :dispatch
  
    get "/" do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Ok")
    end

    post "/" do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Ok")
    end

    put "/" do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Ok")
    end
  end

  defp call(conn) do
    TestRouterPlug.call(conn, [])
  end

  test "Continues to route when not a CORS request" do
    conn = conn(:get, "/") |> call
    assert conn.status == 200
  end

  test "Sends 403 when origin is invalid" do
    conn = conn(:options, "/", [], headers: [{"Origin", "http://test1.origin.test"}]) |> call
    assert conn.status == 403
  end

  test "Sends 403 when Access-Control-Request-Method is invalid" do
    conn = conn(:options, "/", [], headers: [{"Origin", "http://test.origin.test"}, {"Access-Control-Request-Method", "PUT"}]) |> call
    assert conn.status == 403
  end

  test "Sends 403 when Access-Control-Request-Headers is invalid" do
    conn = conn(:options, "/", [], headers: [{"Origin", "http://test.origin.test"}, {"Access-Control-Request-Method", "POST"}, {"Access-Control-Request-Headers", "X-CHICKEN-NUGGETS"}]) |> call
    assert conn.status == 403
  end

  test "Sends 200 on preflight when all options are ok" do
    conn = conn(:options, "/", [], headers: [{"Origin", "http://test.origin.test"}, {"Access-Control-Request-Method", "POST"}, {"Access-Control-Request-Headers", "Authorization"}]) |> call
    assert conn.status == 200
    assert get_resp_header(conn, "Access-Control-Allow-Origin") == ["http://test.origin.test"]
    assert get_resp_header(conn, "Access-Control-Allow-Methods") == [Enum.join(["GET", "POST"], ",")]
    assert get_resp_header(conn, "Access-Control-Allow-Headers") == [Enum.join(["Authorization"], ",")]
  end

  test "Sends 403 on request when origin is not allowed" do
    conn = conn(:get, "/", [], headers: [{"Origin", "http://test1.origin.test"}]) |> call
    assert conn.status == 403   
  end

  test "Sends 403 on request when method is not allowed" do
    conn = conn(:put, "/", [], headers: [{"Origin", "http://test.origin.test"}]) |> call
    assert conn.status == 403    
  end

  test "Sends request through when ok" do
    conn = conn(:post, "/", [], headers: [{"Origin", "http://test.origin.test"}, {"Authorization", "yes"}]) |> call
    assert conn.status == 200    
  end
end
