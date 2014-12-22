defmodule PlugCorsTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @additonal_headers  ["Authorization"]
  @opts PlugCors.init([origins: ["test.origin.test", "*.domain.test"], methods: ["GET", "POST"], headers: @additonal_headers])

  @expected_headers Enum.uniq(Enum.concat(PlugCors.Preflight.default_accept_headers,@additonal_headers))


  test "Passes conn when not a CORS request" do
    conn = conn(:get, "/")
    conn = PlugCors.call(conn, @opts)
    assert conn.status == nil
  end

  test "Passes conn on OPTIONS when not a CORS request" do
    conn = conn(:options, "/")
    conn = PlugCors.call(conn, @opts)
    assert conn.status == nil
  end

  test "Sends 403 on preflight request when origin is invalid" do
    conn = conn(:options, "/", [], headers: [{"origin", "http://test1.origin.test"}, {"access-control-request-method", "OPTIONS"}])
    conn = PlugCors.call(conn, @opts)
    assert conn.status == 403
  end

  test "Sends 403 on preflight request when access-control-request-method is invalid" do
    conn = conn(:options, "/", [], headers: [{"origin", "http://test.origin.test"}, {"access-control-request-method", "PUT"}])
    conn = PlugCors.call(conn, @opts)
    assert conn.status == 403
  end

  test "Sends 403 on preflight request when access-control-request-headers is invalid" do
    conn = conn(:options, "/", [], headers: [{"origin", "http://test.origin.test"}, {"access-control-request-method", "POST"}, {"access-control-request-headers", "X-CHICKEN-NUGGETS"}])
    conn = PlugCors.call(conn, @opts)
    assert conn.status == 403
  end

  test "Sends 200 on preflight request when all options are ok" do
    conn = conn(:options, "/", [], headers: [{"origin", "http://test.origin.test"}, {"access-control-request-method", "POST"}, {"access-control-request-headers", "Authorization"}])
    conn = PlugCors.call(conn, @opts)
    assert conn.status == 200
    assert get_resp_header(conn, "access-control-allow-origin") == ["http://test.origin.test"]
    assert get_resp_header(conn, "access-control-allow-methods") == [Enum.join(["GET", "POST"], ",")]
    assert get_resp_header(conn, "access-control-allow-headers") == [Enum.join(@expected_headers, ",")]
  end

  test "Sends 200 when subdomain allowed" do
    conn = conn(:options, "/", [], headers: [{"origin", "sub.domain.test"}, {"access-control-request-method", "POST"}, {"access-control-request-headers", "Authorization"}])
    conn = PlugCors.call(conn, @opts)
    assert conn.status == 200
    assert get_resp_header(conn, "access-control-allow-origin") == ["sub.domain.test"]
    assert get_resp_header(conn, "access-control-allow-methods") == [Enum.join(["GET", "POST"], ",")]
    assert get_resp_header(conn, "access-control-allow-headers") == [Enum.join(@expected_headers, ",")]
  end

  test "Sends 200 when main domain allowed" do
    conn = conn(:options, "/", [], headers: [{"origin", "domain.test"}, {"access-control-request-method", "POST"}, {"access-control-request-headers", "Authorization"}])
    conn = PlugCors.call(conn, @opts)
    assert conn.status == 200
    assert get_resp_header(conn, "access-control-allow-origin") == ["domain.test"]
    assert get_resp_header(conn, "access-control-allow-methods") == [Enum.join(["GET", "POST"], ",")]
    assert get_resp_header(conn, "access-control-allow-headers") == [Enum.join(@expected_headers, ",")]
  end

  test "Passes conn on actual request when origin is not allowed" do
    conn = conn(:get, "/", [], headers: [{"origin", "http://test1.origin.test"}])
    conn = PlugCors.call(conn, @opts)
    assert conn.status == nil   
  end

  test "Passes conn on actual request when method is not allowed" do
    conn = conn(:put, "/", [], headers: [{"origin", "http://test.origin.test"}])
    conn = PlugCors.call(conn, @opts)
    assert conn.status == nil  
  end

  test "Passes conn on when ok" do
    conn = conn(:post, "/", [], headers: [{"origin", "http://test.origin.test"}, {"authorization", "yes"}])
    conn = PlugCors.call(conn, @opts)
    assert conn.status == nil
    assert get_resp_header(conn, "access-control-allow-origin") == ["http://test.origin.test"]
  end
end
