defmodule PlugCorsTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @additonal_headers  ["Authorization"]
  @opts PlugCors.init([origins: ["test.origin.test", "*.domain.test"], methods: ["GET", "POST"], headers: @additonal_headers])

  @expected_headers Enum.uniq(Enum.concat(PlugCors.Preflight.default_accept_headers, @additonal_headers))


  test "Passes conn when not a CORS request" do
    conn = conn(:get, "/")
    |> PlugCors.call(@opts)

    assert conn.status == nil
  end

  test "Passes conn on OPTIONS when not a CORS request" do
    conn = conn(:options, "/")
    |> PlugCors.call(@opts)

    assert conn.status == nil
  end

  test "Sends 403 on preflight request when origin is invalid" do
    conn = conn(:options, "/", [])
    |> put_req_header("origin", "http://test1.origin.test")
    |> put_req_header("access-control-request-method", "OPTIONS")
    |> PlugCors.call(@opts)

    assert conn.status == 403
  end

  test "Sends 403 on preflight request when access-control-request-method is invalid" do
    conn = conn(:options, "/", [])
    |> put_req_header("origin", "http://test1.origin.test")
    |> put_req_header("access-control-request-method", "PUT")
    |> PlugCors.call(@opts)

    assert conn.status == 403
  end

  test "Sends 403 on preflight request when access-control-request-headers is invalid" do
    conn = conn(:options, "/", [])
    |> put_req_header("origin", "http://test1.origin.test")
    |> put_req_header("access-control-request-method", "POST")
    |> put_req_header("access-control-request-headers", "X-CHICKEN-NUGGETS")
    |> PlugCors.call(@opts)

    assert conn.status == 403
  end

  test "Sends 200 on preflight request when all options are ok" do
    conn = conn(:options, "/", [])
    |> put_req_header("origin", "http://test.origin.test")
    |> put_req_header("access-control-request-method", "POST")
    |> put_req_header("access-control-request-headers", "Authorization")
    |> PlugCors.call(@opts)

    assert conn.status == 200
    assert get_resp_header(conn, "access-control-allow-origin") == ["http://test.origin.test"]
    assert get_resp_header(conn, "access-control-allow-methods") == [Enum.join(["GET", "POST"], ",")]
    assert get_resp_header(conn, "access-control-allow-headers") == [Enum.join(@expected_headers, ",")]
  end

  test "Sends 200 when wildcard(*) origin allowed" do
    conn = conn(:options, "/", [])
    |> put_req_header("origin", "http://test.origin.test")
    |> put_req_header("access-control-request-method", "POST")
    |> put_req_header("access-control-request-headers", "Authorization")
    |> PlugCors.call(PlugCors.init([origins: "*", methods: ["GET", "POST"], headers: @additonal_headers]))

    assert conn.status == 200
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
    assert get_resp_header(conn, "access-control-allow-methods") == [Enum.join(["GET", "POST"], ",")]
    assert get_resp_header(conn, "access-control-allow-headers") == [Enum.join(@expected_headers, ",")]
  end

  test "Sends 200 when wildcard(*) origin in allowed list" do
    conn = conn(:options, "/", [])
    |> put_req_header("origin", "http://test.origin.test")
    |> put_req_header("access-control-request-method", "POST")
    |> put_req_header("access-control-request-headers", "Authorization")
    |> PlugCors.call(PlugCors.init([origins: ["*"], methods: ["GET", "POST"], headers: @additonal_headers]))

    assert conn.status == 200
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
    assert get_resp_header(conn, "access-control-allow-methods") == [Enum.join(["GET", "POST"], ",")]
    assert get_resp_header(conn, "access-control-allow-headers") == [Enum.join(@expected_headers, ",")]
  end

  test "Sends 200 when wildcard(*) origin added to allowed list" do
    conn = conn(:options, "/", [])
    |> put_req_header("origin", "http://test.origin.test")
    |> put_req_header("access-control-request-method", "POST")
    |> put_req_header("access-control-request-headers", "Authorization")
    |> PlugCors.call(PlugCors.init([origins: ["*", "*.domain.test"], methods: ["GET", "POST"], headers: @additonal_headers]))

    assert conn.status == 200
    assert get_resp_header(conn, "access-control-allow-origin") == ["http://test.origin.test"]
    assert get_resp_header(conn, "access-control-allow-methods") == [Enum.join(["GET", "POST"], ",")]
    assert get_resp_header(conn, "access-control-allow-headers") == [Enum.join(@expected_headers, ",")]
  end

  test "Sends 200 when subdomain allowed" do
    conn = conn(:options, "/", [])
    |> put_req_header("origin", "http://sub.domain.test")
    |> put_req_header("access-control-request-method", "POST")
    |> put_req_header("access-control-request-headers", "Authorization")
    |> PlugCors.call(@opts)

    assert conn.status == 200
    assert get_resp_header(conn, "access-control-allow-origin") == ["http://sub.domain.test"]
    assert get_resp_header(conn, "access-control-allow-methods") == [Enum.join(["GET", "POST"], ",")]
    assert get_resp_header(conn, "access-control-allow-headers") == [Enum.join(@expected_headers, ",")]
  end

  test "Sends 200 when main domain allowed" do
    conn = conn(:options, "/", [])
    |> put_req_header("origin", "http://domain.test")
    |> put_req_header("access-control-request-method", "POST")
    |> put_req_header("access-control-request-headers", "Authorization")
    |> PlugCors.call(@opts)

    assert conn.status == 200
    assert get_resp_header(conn, "access-control-allow-origin") == ["http://domain.test"]
    assert get_resp_header(conn, "access-control-allow-methods") == [Enum.join(["GET", "POST"], ",")]
    assert get_resp_header(conn, "access-control-allow-headers") == [Enum.join(@expected_headers, ",")]
  end

  test "Passes conn on actual request when origin is not allowed" do
    conn = conn(:get, "/", [])
    |> put_req_header("origin", "http://test1.origin.test")
    |> PlugCors.call(@opts)

    assert conn.status == nil
    assert get_resp_header(conn, "access-control-allow-origin") == []
  end

  test "Passes conn on actual request when method is not allowed" do
    conn = conn(:put, "/", [])
    |> put_req_header("origin", "http://test1.origin.test")
    |> PlugCors.call(@opts)

    assert conn.status == nil  
  end

  test "Passes conn on when ok" do
    conn = conn(:post, "/", [])
    |> put_req_header("origin", "http://test.origin.test")
    |> put_req_header("authorization", "yes")
    |> PlugCors.call(@opts)

    assert conn.status == nil
    assert get_resp_header(conn, "access-control-allow-origin") == ["http://test.origin.test"]
  end


  test "only allows the specific domain when no wildcard specified" do
    conn = conn(:options, "/", [])
    |> put_req_header("origin", "http://sub.domain.test")
    |> put_req_header("access-control-request-method", "POST")
    |> put_req_header("access-control-request-headers", "Authorization")
    |> PlugCors.call(PlugCors.init([origins: ["domain.test"], methods: ["GET", "POST"], headers: @additonal_headers]))

    assert conn.status == 403


    conn = conn(:options, "/", [])
    |> put_req_header("origin", "http://domain.test")
    |> put_req_header("access-control-request-method", "POST")
    |> put_req_header("access-control-request-headers", "Authorization")
    |> PlugCors.call(PlugCors.init([origins: ["domain.test"], methods: ["GET", "POST"], headers: @additonal_headers]))

    assert conn.status == 200
    assert get_resp_header(conn, "access-control-allow-origin") == ["http://domain.test"]
    assert get_resp_header(conn, "access-control-allow-methods") == [Enum.join(["GET", "POST"], ",")]
    assert get_resp_header(conn, "access-control-allow-headers") == [Enum.join(@expected_headers, ",")]
  end
end
