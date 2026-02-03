defmodule AbacatePay.PublicMRRTest do
  use ExUnit.Case

  alias AbacatePay.PublicMRR

  describe "struct/0" do
    test "creates a valid PublicMRR struct" do
      public_mrr = %PublicMRR{
        mrr: 50000,
        total_active_subscriptions: 10,
        name: "My Store",
        total_revenue: 150_000,
        total_transactions: 45,
        transactions_per_day: %{},
        website: "https://mystore.com",
        created_at: nil
      }

      assert public_mrr.mrr == 50000
      assert public_mrr.total_active_subscriptions == 10
      assert public_mrr.name == "My Store"
      assert public_mrr.total_revenue == 150_000
    end

    test "creates PublicMRR with nil values" do
      public_mrr = %PublicMRR{}

      assert public_mrr.mrr == nil
      assert public_mrr.total_active_subscriptions == nil
      assert public_mrr.name == nil
    end
  end

  describe "build_pretty_public_mrr/1" do
    test "builds PublicMRR from raw API data" do
      raw_data = %{
        "mrr" => 50000,
        "totalActiveSubscriptions" => 10,
        "name" => "My Store",
        "totalRevenue" => 150_000,
        "totalTransactions" => 45,
        "transactionsPerDay" => %{
          "2024-01-15" => %{"amount" => 5000, "count" => 3},
          "2024-01-16" => %{"amount" => 3000, "count" => 2}
        },
        "website" => "https://mystore.com",
        "createdAt" => "2023-12-01T12:00:00Z"
      }

      assert {:ok, mrr} = PublicMRR.build_pretty_public_mrr(raw_data)
      assert mrr.mrr == 50000
      assert mrr.total_active_subscriptions == 10
      assert mrr.name == "My Store"
      assert mrr.total_revenue == 150_000
      assert mrr.total_transactions == 45
      assert mrr.website == "https://mystore.com"
    end

    test "handles transactions_per_day parsing" do
      raw_data = %{
        "mrr" => 10000,
        "totalActiveSubscriptions" => 5,
        "name" => "Test Store",
        "totalRevenue" => 50000,
        "totalTransactions" => 20,
        "transactionsPerDay" => %{
          "2024-01-15" => %{"amount" => 5000, "count" => 3},
          "2024-01-16" => %{"amount" => 3000, "count" => 2}
        },
        "website" => nil,
        "createdAt" => nil
      }

      assert {:ok, mrr} = PublicMRR.build_pretty_public_mrr(raw_data)
      assert is_map(mrr.transactions_per_day)
      assert mrr.transactions_per_day["2024-01-15"].amount == 5000
      assert mrr.transactions_per_day["2024-01-15"].count == 3
      assert mrr.transactions_per_day["2024-01-16"].amount == 3000
      assert mrr.transactions_per_day["2024-01-16"].count == 2
    end

    test "handles empty transactions_per_day" do
      raw_data = %{
        "mrr" => 0,
        "totalActiveSubscriptions" => 0,
        "name" => "New Store",
        "totalRevenue" => 0,
        "totalTransactions" => 0,
        "transactionsPerDay" => %{},
        "website" => nil,
        "createdAt" => nil
      }

      assert {:ok, mrr} = PublicMRR.build_pretty_public_mrr(raw_data)
      assert is_map(mrr.transactions_per_day)
      assert map_size(mrr.transactions_per_day) == 0
    end

    test "handles nil transactions_per_day" do
      raw_data = %{
        "mrr" => 10000,
        "totalActiveSubscriptions" => 5,
        "name" => "Test Store",
        "totalRevenue" => 50000,
        "totalTransactions" => 20,
        "transactionsPerDay" => nil,
        "website" => "https://example.com",
        "createdAt" => nil
      }

      assert {:ok, mrr} = PublicMRR.build_pretty_public_mrr(raw_data)
      assert is_map(mrr.transactions_per_day)
    end

    test "handles datetime parsing" do
      raw_data = %{
        "mrr" => 10000,
        "totalActiveSubscriptions" => 5,
        "name" => "Test Store",
        "totalRevenue" => 50000,
        "totalTransactions" => 20,
        "transactionsPerDay" => %{},
        "website" => nil,
        "createdAt" => "2023-12-01T12:00:00Z"
      }

      assert {:ok, mrr} = PublicMRR.build_pretty_public_mrr(raw_data)
      assert mrr.created_at != nil
    end

    test "handles nil datetime" do
      raw_data = %{
        "mrr" => 10000,
        "totalActiveSubscriptions" => 5,
        "name" => "Test Store",
        "totalRevenue" => 50000,
        "totalTransactions" => 20,
        "transactionsPerDay" => %{},
        "website" => nil,
        "createdAt" => nil
      }

      assert {:ok, mrr} = PublicMRR.build_pretty_public_mrr(raw_data)
      assert mrr.created_at == nil
    end

    test "handles large MRR values" do
      raw_data = %{
        "mrr" => 999_999_999,
        "totalActiveSubscriptions" => 10000,
        "name" => "Big Store",
        "totalRevenue" => 9_999_999_999,
        "totalTransactions" => 100_000,
        "transactionsPerDay" => %{},
        "website" => "https://bigstore.com",
        "createdAt" => nil
      }

      assert {:ok, mrr} = PublicMRR.build_pretty_public_mrr(raw_data)
      assert mrr.mrr == 999_999_999
      assert mrr.total_revenue == 9_999_999_999
      assert mrr.total_transactions == 100_000
    end

    test "handles multiple days in transactions_per_day" do
      raw_data = %{
        "mrr" => 50000,
        "totalActiveSubscriptions" => 10,
        "name" => "Test Store",
        "totalRevenue" => 150_000,
        "totalTransactions" => 45,
        "transactionsPerDay" => %{
          "2024-01-13" => %{"amount" => 2000, "count" => 1},
          "2024-01-14" => %{"amount" => 4000, "count" => 2},
          "2024-01-15" => %{"amount" => 5000, "count" => 3},
          "2024-01-16" => %{"amount" => 3000, "count" => 2}
        },
        "website" => "https://example.com",
        "createdAt" => nil
      }

      assert {:ok, mrr} = PublicMRR.build_pretty_public_mrr(raw_data)
      assert map_size(mrr.transactions_per_day) == 4
    end
  end

  describe "build_api_public_mrr/1" do
    test "builds API map from PublicMRR struct" do
      public_mrr = %PublicMRR{
        mrr: 50000,
        total_active_subscriptions: 10,
        name: "My Store",
        total_revenue: 150_000,
        total_transactions: 45,
        transactions_per_day: %{
          "2024-01-15" => %{amount: 5000, count: 3},
          "2024-01-16" => %{amount: 3000, count: 2}
        },
        website: "https://mystore.com",
        created_at: ~U[2023-12-01T12:00:00Z]
      }

      assert {:ok, api_map} = PublicMRR.build_api_public_mrr(public_mrr)
      assert api_map[:mrr] == 50000
      assert api_map[:totalActiveSubscriptions] == 10
      assert api_map[:name] == "My Store"
      assert api_map[:totalRevenue] == 150_000
      assert api_map[:totalTransactions] == 45
      assert api_map[:website] == "https://mystore.com"
    end

    test "handles transactions_per_day conversion to API format" do
      public_mrr = %PublicMRR{
        mrr: 10000,
        total_active_subscriptions: 5,
        name: "Test Store",
        total_revenue: 50000,
        total_transactions: 20,
        transactions_per_day: %{
          "2024-01-15" => %{amount: 5000, count: 3},
          "2024-01-16" => %{amount: 3000, count: 2}
        },
        website: nil,
        created_at: nil
      }

      assert {:ok, api_map} = PublicMRR.build_api_public_mrr(public_mrr)
      assert api_map[:transactionsPerDay]["2024-01-15"]["amount"] == 5000
      assert api_map[:transactionsPerDay]["2024-01-15"]["count"] == 3
    end

    test "handles empty transactions_per_day" do
      public_mrr = %PublicMRR{
        mrr: 0,
        total_active_subscriptions: 0,
        name: "New Store",
        total_revenue: 0,
        total_transactions: 0,
        transactions_per_day: %{},
        website: nil,
        created_at: nil
      }

      assert {:ok, api_map} = PublicMRR.build_api_public_mrr(public_mrr)
      assert api_map[:transactionsPerDay] == %{}
    end

    test "handles datetime conversion" do
      public_mrr = %PublicMRR{
        mrr: 10000,
        total_active_subscriptions: 5,
        name: "Test Store",
        total_revenue: 50000,
        total_transactions: 20,
        transactions_per_day: %{},
        website: nil,
        created_at: ~U[2023-12-01T12:00:00Z]
      }

      assert {:ok, api_map} = PublicMRR.build_api_public_mrr(public_mrr)
      assert String.contains?(api_map[:createdAt], "2023-12-01")
    end

    test "handles nil datetime" do
      public_mrr = %PublicMRR{
        mrr: 10000,
        total_active_subscriptions: 5,
        name: "Test Store",
        total_revenue: 50000,
        total_transactions: 20,
        transactions_per_day: %{},
        website: nil,
        created_at: nil
      }

      assert {:ok, api_map} = PublicMRR.build_api_public_mrr(public_mrr)
      assert api_map[:createdAt] == nil
    end
  end

  describe "roundtrip conversion" do
    test "converts raw data to struct and back" do
      raw_data = %{
        "mrr" => 75000,
        "totalActiveSubscriptions" => 15,
        "name" => "Roundtrip Store",
        "totalRevenue" => 225_000,
        "totalTransactions" => 60,
        "transactionsPerDay" => %{
          "2024-01-15" => %{"amount" => 5000, "count" => 3},
          "2024-01-16" => %{"amount" => 3000, "count" => 2}
        },
        "website" => "https://roundtrip.com",
        "createdAt" => "2023-12-01T12:00:00Z"
      }

      assert {:ok, mrr} = PublicMRR.build_pretty_public_mrr(raw_data)
      assert {:ok, api_map} = PublicMRR.build_api_public_mrr(mrr)

      assert api_map[:mrr] == raw_data["mrr"]
      assert api_map[:totalActiveSubscriptions] == raw_data["totalActiveSubscriptions"]
      assert api_map[:name] == raw_data["name"]
      assert api_map[:totalRevenue] == raw_data["totalRevenue"]
    end

    test "maintains transactions_per_day through roundtrip" do
      raw_data = %{
        "mrr" => 50000,
        "totalActiveSubscriptions" => 10,
        "name" => "Test Store",
        "totalRevenue" => 150_000,
        "totalTransactions" => 45,
        "transactionsPerDay" => %{
          "2024-01-15" => %{"amount" => 5000, "count" => 3},
          "2024-01-16" => %{"amount" => 3000, "count" => 2}
        },
        "website" => "https://example.com",
        "createdAt" => nil
      }

      assert {:ok, mrr} = PublicMRR.build_pretty_public_mrr(raw_data)
      assert {:ok, api_map} = PublicMRR.build_api_public_mrr(mrr)

      assert api_map[:transactionsPerDay]["2024-01-15"]["amount"] ==
               raw_data["transactionsPerDay"]["2024-01-15"]["amount"]

      assert api_map[:transactionsPerDay]["2024-01-16"]["count"] ==
               raw_data["transactionsPerDay"]["2024-01-16"]["count"]
    end
  end
end
