defmodule PlugCorsTest do
  use ExUnit.Case, async: true
  use Plug.Test
  
  defmodule TestRouterPlug do
    import Plug.Conn
    use Plug.Router

    def verify(_payload), do: true
    
    plug PlugCors, allowed_origins: ["test.origin.test"], allowed_methods: ["GET", "POST"], allowed_headers: ["Authorization"]
    plug :match
    plug :dispatch
  
    get "/" do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Hello Tester")
    end

    post "/" do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Hello Tester")
    end

    put "/" do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(200, "Hello Tester")
    end
  end

  defp call(conn) do
    TestRouterPlug.call(conn, [])
  end

  test "Sends 200 on preflight when no origin header found" do
    conn = conn(:options, "/") |> call
    assert conn.status == 200
  end

  test "Sends 403 on preflight when origin not allowed" do
    conn = conn(:options, "/", [], headers: [{"Origin", "http://test1.origin.test"}]) |> call
    assert conn.status == 403
  end

  test "Sends 200 on preflight when origin is allowed" do
    conn = conn(:options, "/", [], headers: [{"Origin", "http://test.origin.test"}]) |> call
    assert conn.status == 200
  end

  test "Sends 403 on preflight when method not allowed" do
    conn = conn(:options, "/", [], headers: [{"Origin", "http://test.origin.test"}, {"Access-Control-Request-Method", "PUT"}]) |> call
    assert conn.status == 403    
  end

  test "Sends 403 on preflight when header not allowed without Access-Control-Request-Method" do
    conn = conn(:options, "/", [], headers: [{"Origin", "http://test.origin.test"}, {"Access-Control-Request-Headers", "X-CHICKEN-NUGGETS"}]) |> call
    assert conn.status == 403  
  end

  test "Sends 403 on preflight when header not allowed" do
    conn = conn(:options, "/", [], headers: [{"Origin", "http://test.origin.test"}, {"Access-Control-Request-Method", "POST"}, {"Access-Control-Request-Headers", "X-CHICKEN-NUGGETS"}]) |> call
    assert conn.status == 403  
  end

  test "Sends 403 on preflight when one header is not allowed" do
    conn = conn(:options, "/", [], headers: [{"Origin", "http://test.origin.test"}, {"Access-Control-Request-Method", "POST"}, {"Access-Control-Request-Headers", "Authorization, X-CHICKEN-NUGGETS"}]) |> call
    assert conn.status == 403  
  end

  test "Sends 200 on preflight request is ok" do
    conn = conn(:options, "/", [], headers: [{"Origin", "http://test.origin.test"}, {"Access-Control-Request-Method", "POST"}, {"Access-Control-Request-Headers", "Authorization"}]) |> call
    assert conn.status == 200      
  end

  test "Sends request through when origin header is not present" do
    
  end

  test "Sends 403 on request when origin is not allowed" do
    
  end

  test "Sends 403 on request when method is not allowed" do
    
  end

  test "Sends 403 on request when a header is not allowed" do
    
  end

  test "Sends request through when ok" do
    
  end
end
