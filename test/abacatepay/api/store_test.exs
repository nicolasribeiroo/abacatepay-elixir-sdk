defmodule AbacatePay.Api.StoreTest do
  use ExUnit.Case
  use Mimic

  alias AbacatePay.Api.Store
  alias AbacatePay.MockHTTPServer

  describe "get_store/0" do
    test "retrieves store details successfully" do
      expected_response = %{
        "id" => "store_123456",
        "name" => "Minha Loja Online",
        "balance" => %{
          "available" => 15000,
          "pending" => 5000,
          "blocked" => 2000
        }
      }

      MockHTTPServer.stub_get("/store/get", expected_response)

      assert {:ok, store} = Store.get_store()
      assert store["id"] == "store_123456"
      assert store["name"] == "Minha Loja Online"
      assert store["balance"]["available"] == 15000
      assert store["balance"]["pending"] == 5000
      assert store["balance"]["blocked"] == 2000
    end

    test "retrieves store with zero balance" do
      expected_response = %{
        "id" => "store_000000",
        "name" => "Empty Balance Store",
        "balance" => %{
          "available" => 0,
          "pending" => 0,
          "blocked" => 0
        }
      }

      MockHTTPServer.stub_get("/store/get", expected_response)

      assert {:ok, store} = Store.get_store()
      assert store["balance"]["available"] == 0
      assert store["balance"]["pending"] == 0
      assert store["balance"]["blocked"] == 0
    end

    test "retrieves store with large balance" do
      expected_response = %{
        "id" => "store_rich",
        "name" => "Rich Store",
        "email" => "rich@store.com",
        "balance" => %{
          "available" => 9_999_999_999,
          "pending" => 0,
          "blocked" => 0
        },
        "status" => "active"
      }

      MockHTTPServer.stub_get("/store/get", expected_response)

      assert {:ok, store} = Store.get_store()
      assert store["balance"]["available"] == 9_999_999_999
      assert store["email"] == "rich@store.com"
    end

    test "handles unauthorized error" do
      error = MockHTTPServer.mock_error(401, "Unauthorized")
      MockHTTPServer.stub_error(:get, "/store/get", error)

      assert {:error, returned_error} = Store.get_store()
      assert returned_error.status_code == 401
      assert returned_error.message == "Unauthorized"
    end

    test "handles forbidden error" do
      error = MockHTTPServer.mock_error(403, "Forbidden")
      MockHTTPServer.stub_error(:get, "/store/get", error)

      assert {:error, returned_error} = Store.get_store()
      assert returned_error.status_code == 403
    end

    test "handles not found error" do
      error = MockHTTPServer.mock_error(404, "Store not found")
      MockHTTPServer.stub_error(:get, "/store/get", error)

      assert {:error, returned_error} = Store.get_store()
      assert returned_error.status_code == 404
    end

    test "handles server error" do
      error = MockHTTPServer.mock_error(500, "Internal Server Error")
      MockHTTPServer.stub_error(:get, "/store/get", error)

      assert {:error, returned_error} = Store.get_store()
      assert returned_error.status_code == 500
    end

    test "handles service unavailable error" do
      error = MockHTTPServer.mock_error(503, "Service Unavailable")
      MockHTTPServer.stub_error(:get, "/store/get", error)

      assert {:error, returned_error} = Store.get_store()
      assert returned_error.status_code == 503
    end

    test "retrieves store and validates all fields are present" do
      expected_response = %{
        "id" => "store_full",
        "name" => "Full Store",
        "email" => "full@store.com",
        "balance" => %{
          "available" => 25000,
          "pending" => 10000,
          "blocked" => 3000
        }
      }

      MockHTTPServer.stub_get("/store/get", expected_response)

      assert {:ok, store} = Store.get_store()
      assert is_map(store)
      assert Map.has_key?(store, "id")
      assert Map.has_key?(store, "name")
      assert Map.has_key?(store, "email")
      assert Map.has_key?(store, "balance")
      assert Map.has_key?(store["balance"], "available")
      assert Map.has_key?(store["balance"], "pending")
      assert Map.has_key?(store["balance"], "blocked")
    end

    test "returns the store data as a map" do
      expected_response = %{
        "id" => "store_map",
        "name" => "Map Store",
        "balance" => %{
          "available" => 5000,
          "pending" => 2000,
          "blocked" => 1000
        }
      }

      MockHTTPServer.stub_get("/store/get", expected_response)

      assert {:ok, store} = Store.get_store()
      assert is_map(store)
      assert Enum.count(store) == 3
    end

    test "handles request timeout" do
      error = MockHTTPServer.mock_error(504, "Gateway Timeout")
      MockHTTPServer.stub_error(:get, "/store/get", error)

      assert {:error, returned_error} = Store.get_store()
      assert returned_error.status_code == 504
    end
  end
end
