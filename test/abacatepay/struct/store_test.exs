defmodule AbacatePay.StoreTest do
  use ExUnit.Case

  alias AbacatePay.Store

  describe "struct/0" do
    test "creates a valid Store struct" do
      store = %Store{
        id: "store_ABC123",
        name: "My Store",
        balance: %{
          available: 100_000,
          pending: 5_000,
          blocked: 2_000
        }
      }

      assert store.id == "store_ABC123"
      assert store.name == "My Store"
      assert store.balance.available == 100_000
      assert store.balance.pending == 5_000
      assert store.balance.blocked == 2_000
    end

    test "creates Store with nil values" do
      store = %Store{}

      assert store.id == nil
      assert store.name == nil
      assert store.balance == nil
    end
  end

  describe "build_pretty_store/1" do
    test "builds Store from raw API data" do
      raw_data = %{
        "id" => "store_ABC123",
        "name" => "My Store",
        "balance" => %{
          "available" => 100_000,
          "pending" => 5_000,
          "blocked" => 2_000
        }
      }

      assert {:ok, store} = Store.build_pretty_store(raw_data)
      assert store.id == "store_ABC123"
      assert store.name == "My Store"
      assert store.balance.available == 100_000
      assert store.balance.pending == 5_000
      assert store.balance.blocked == 2_000
    end

    test "handles zero balances" do
      raw_data = %{
        "id" => "store_ABC123",
        "name" => "New Store",
        "balance" => %{
          "available" => 0,
          "pending" => 0,
          "blocked" => 0
        }
      }

      assert {:ok, store} = Store.build_pretty_store(raw_data)
      assert store.balance.available == 0
      assert store.balance.pending == 0
      assert store.balance.blocked == 0
    end

    test "handles large balance values" do
      raw_data = %{
        "id" => "store_ABC123",
        "name" => "Big Store",
        "balance" => %{
          "available" => 999_999_999,
          "pending" => 100_000_000,
          "blocked" => 50_000_000
        }
      }

      assert {:ok, store} = Store.build_pretty_store(raw_data)
      assert store.balance.available == 999_999_999
      assert store.balance.pending == 100_000_000
      assert store.balance.blocked == 50_000_000
    end

    test "handles special characters in name" do
      raw_data = %{
        "id" => "store_ABC123",
        "name" => "Loja do José & Maria",
        "balance" => %{
          "available" => 10_000,
          "pending" => 0,
          "blocked" => 0
        }
      }

      assert {:ok, store} = Store.build_pretty_store(raw_data)
      assert store.name == "Loja do José & Maria"
    end

    test "handles missing balance fields" do
      raw_data = %{
        "id" => "store_ABC123",
        "name" => "Test Store",
        "balance" => %{
          "available" => 10_000
        }
      }

      assert {:ok, store} = Store.build_pretty_store(raw_data)
      assert store.balance.available == 10_000
      assert store.balance.pending == nil
      assert store.balance.blocked == nil
    end
  end

  describe "build_api_store/1" do
    test "builds API map from Store struct" do
      store = %Store{
        id: "store_ABC123",
        name: "My Store",
        balance: %{
          available: 100_000,
          pending: 5_000,
          blocked: 2_000
        }
      }

      assert {:ok, api_map} = Store.build_api_store(store)
      assert api_map[:id] == "store_ABC123"
      assert api_map[:name] == "My Store"
      assert api_map[:balance][:available] == 100_000
      assert api_map[:balance][:pending] == 5_000
      assert api_map[:balance][:blocked] == 2_000
    end

    test "handles zero balances in API format" do
      store = %Store{
        id: "store_ABC123",
        name: "Test Store",
        balance: %{
          available: 0,
          pending: 0,
          blocked: 0
        }
      }

      assert {:ok, api_map} = Store.build_api_store(store)
      assert api_map[:balance][:available] == 0
      assert api_map[:balance][:pending] == 0
      assert api_map[:balance][:blocked] == 0
    end

    test "preserves all balance fields" do
      store = %Store{
        id: "store_ABC123",
        name: "Test Store",
        balance: %{
          available: 50_000,
          pending: 10_000,
          blocked: 5_000
        }
      }

      assert {:ok, api_map} = Store.build_api_store(store)
      assert map_size(api_map) == 3
      assert map_size(api_map[:balance]) == 3
    end
  end

  describe "roundtrip conversion" do
    test "converts raw data to struct and back to API format" do
      raw_data = %{
        "id" => "store_roundtrip",
        "name" => "Roundtrip Store",
        "balance" => %{
          "available" => 75_000,
          "pending" => 15_000,
          "blocked" => 3_000
        }
      }

      assert {:ok, store} = Store.build_pretty_store(raw_data)
      assert {:ok, api_map} = Store.build_api_store(store)

      assert api_map[:id] == raw_data["id"]
      assert api_map[:name] == raw_data["name"]
      assert api_map[:balance][:available] == raw_data["balance"]["available"]
      assert api_map[:balance][:pending] == raw_data["balance"]["pending"]
      assert api_map[:balance][:blocked] == raw_data["balance"]["blocked"]
    end

    test "maintains balance precision through roundtrip" do
      raw_data = %{
        "id" => "store_ABC123",
        "name" => "Precise Store",
        "balance" => %{
          "available" => 123_456_789,
          "pending" => 987_654_321,
          "blocked" => 111_222_333
        }
      }

      assert {:ok, store} = Store.build_pretty_store(raw_data)
      assert {:ok, api_map} = Store.build_api_store(store)

      assert api_map[:balance][:available] == raw_data["balance"]["available"]
      assert api_map[:balance][:pending] == raw_data["balance"]["pending"]
      assert api_map[:balance][:blocked] == raw_data["balance"]["blocked"]
    end
  end

  describe "balance calculations" do
    test "calculates total balance" do
      store = %Store{
        id: "store_ABC123",
        name: "Test Store",
        balance: %{
          available: 100_000,
          pending: 50_000,
          blocked: 25_000
        }
      }

      total = store.balance.available + store.balance.pending + store.balance.blocked
      assert total == 175_000
    end

    test "handles balance in cents to reais conversion" do
      store = %Store{
        id: "store_ABC123",
        name: "Test Store",
        balance: %{
          available: 15_000,
          pending: 0,
          blocked: 0
        }
      }

      reais = store.balance.available / 100
      assert reais == 150.0
    end
  end
end
