defmodule AbacatePay.Api.PublicMRRTest do
  use ExUnit.Case
  use Mimic

  alias AbacatePay.Api.PublicMRR
  alias AbacatePay.MockHTTPServer

  describe "get_mrr/0" do
    test "retrieves MRR and active subscriptions successfully" do
      expected_response = %{
        "mrr" => 150_000,
        "totalActiveSubscriptions" => 45
      }

      MockHTTPServer.stub_get("/public-mrr/mrr", expected_response)

      assert {:ok, result} = PublicMRR.get_mrr()
      assert result["mrr"] == 150_000
      assert result["totalActiveSubscriptions"] == 45
    end

    test "retrieves MRR with zero subscriptions" do
      expected_response = %{
        "mrr" => 0,
        "totalActiveSubscriptions" => 0
      }

      MockHTTPServer.stub_get("/public-mrr/mrr", expected_response)

      assert {:ok, result} = PublicMRR.get_mrr()
      assert result["mrr"] == 0
      assert result["totalActiveSubscriptions"] == 0
    end

    test "retrieves MRR with large values" do
      expected_response = %{
        "mrr" => 9_999_999_999,
        "totalActiveSubscriptions" => 50000
      }

      MockHTTPServer.stub_get("/public-mrr/mrr", expected_response)

      assert {:ok, result} = PublicMRR.get_mrr()
      assert result["mrr"] == 9_999_999_999
      assert result["totalActiveSubscriptions"] == 50000
    end

    test "handles unauthorized error" do
      error = MockHTTPServer.mock_error(401, "Unauthorized")
      MockHTTPServer.stub_error(:get, "/public-mrr/mrr", error)

      assert {:error, returned_error} = PublicMRR.get_mrr()
      assert returned_error.status_code == 401
    end

    test "handles forbidden error" do
      error = MockHTTPServer.mock_error(403, "Forbidden")
      MockHTTPServer.stub_error(:get, "/public-mrr/mrr", error)

      assert {:error, returned_error} = PublicMRR.get_mrr()
      assert returned_error.status_code == 403
    end

    test "handles not found error" do
      error = MockHTTPServer.mock_error(404, "Not Found")
      MockHTTPServer.stub_error(:get, "/public-mrr/mrr", error)

      assert {:error, returned_error} = PublicMRR.get_mrr()
      assert returned_error.status_code == 404
    end

    test "handles server error" do
      error = MockHTTPServer.mock_error(500, "Internal Server Error")
      MockHTTPServer.stub_error(:get, "/public-mrr/mrr", error)

      assert {:error, returned_error} = PublicMRR.get_mrr()
      assert returned_error.status_code == 500
    end

    test "retrieves MRR data as a map" do
      expected_response = %{
        "mrr" => 100_000,
        "totalActiveSubscriptions" => 30
      }

      MockHTTPServer.stub_get("/public-mrr/mrr", expected_response)

      assert {:ok, result} = PublicMRR.get_mrr()
      assert is_map(result)
      assert map_size(result) >= 2
    end
  end

  describe "get_merchant_info/0" do
    test "retrieves merchant information successfully" do
      expected_response = %{
        "name" => "Example Tech",
        "website" => "https://www.example.com",
        "createdAt" => "2024-12-06T18:53:31.756Z"
      }

      MockHTTPServer.stub_get("/public-mrr/merchant-info", expected_response)

      assert {:ok, result} = PublicMRR.get_merchant_info()
      assert result["name"] == "Example Tech"
      assert result["website"] == "https://www.example.com"
      assert result["createdAt"] == "2024-12-06T18:53:31.756Z"
    end

    test "retrieves merchant info with special characters in name" do
      expected_response = %{
        "name" => "Açaí & Smoothies Ltda.",
        "website" => "https://acaismoothies.com.br",
        "createdAt" => "2024-06-15T10:30:00Z"
      }

      MockHTTPServer.stub_get("/public-mrr/merchant-info", expected_response)

      assert {:ok, result} = PublicMRR.get_merchant_info()
      assert result["name"] == "Açaí & Smoothies Ltda."
    end

    test "handles unauthorized error" do
      error = MockHTTPServer.mock_error(401, "Unauthorized")
      MockHTTPServer.stub_error(:get, "/public-mrr/merchant-info", error)

      assert {:error, returned_error} = PublicMRR.get_merchant_info()
      assert returned_error.status_code == 401
    end

    test "handles forbidden error" do
      error = MockHTTPServer.mock_error(403, "Forbidden")
      MockHTTPServer.stub_error(:get, "/public-mrr/merchant-info", error)

      assert {:error, returned_error} = PublicMRR.get_merchant_info()
      assert returned_error.status_code == 403
    end

    test "handles not found error" do
      error = MockHTTPServer.mock_error(404, "Merchant not found")
      MockHTTPServer.stub_error(:get, "/public-mrr/merchant-info", error)

      assert {:error, returned_error} = PublicMRR.get_merchant_info()
      assert returned_error.status_code == 404
    end

    test "handles server error" do
      error = MockHTTPServer.mock_error(500, "Internal Server Error")
      MockHTTPServer.stub_error(:get, "/public-mrr/merchant-info", error)

      assert {:error, returned_error} = PublicMRR.get_merchant_info()
      assert returned_error.status_code == 500
    end

    test "retrieves merchant info as a map" do
      expected_response = %{
        "name" => "Test Merchant",
        "website" => "https://test.com",
        "createdAt" => "2024-01-01T00:00:00Z"
      }

      MockHTTPServer.stub_get("/public-mrr/merchant-info", expected_response)

      assert {:ok, result} = PublicMRR.get_merchant_info()
      assert is_map(result)
    end
  end

  describe "get_revenue/2" do
    test "retrieves revenue for date range successfully" do
      start_date = "2024-01-01"
      end_date = "2024-01-31"

      expected_response = %{
        "totalRevenue" => 150_000,
        "totalTransactions" => 45,
        "transactionsPerDay" => %{
          "2024-01-01" => %{"amount" => 5000, "count" => 2},
          "2024-01-02" => %{"amount" => 7000, "count" => 3},
          "2024-01-03" => %{"amount" => 8000, "count" => 4}
        }
      }

      query = URI.encode_query(%{"startDate" => start_date, "endDate" => end_date})
      MockHTTPServer.stub_get("/public-mrr/revenue?" <> query, expected_response)

      assert {:ok, result} = PublicMRR.get_revenue(start_date, end_date)
      assert result["totalRevenue"] == 150_000
      assert result["totalTransactions"] == 45
      assert result["transactionsPerDay"]["2024-01-01"]["amount"] == 5000
      assert result["transactionsPerDay"]["2024-01-01"]["count"] == 2
      assert result["transactionsPerDay"]["2024-01-02"]["amount"] == 7000
      assert result["transactionsPerDay"]["2024-01-02"]["count"] == 3
      assert result["transactionsPerDay"]["2024-01-03"]["amount"] == 8000
      assert result["transactionsPerDay"]["2024-01-03"]["count"] == 4
    end

    test "retrieves revenue with zero transactions" do
      start_date = "2025-01-01"
      end_date = "2025-01-31"

      expected_response = %{
        "totalRevenue" => 0,
        "totalTransactions" => 0,
        "transactionsPerDay" => %{
          "2025-01-01" => %{"amount" => 0, "count" => 0},
          "2025-01-02" => %{"amount" => 0, "count" => 0},
          "2025-01-03" => %{"amount" => 0, "count" => 0}
        }
      }

      query = URI.encode_query(%{"startDate" => start_date, "endDate" => end_date})
      MockHTTPServer.stub_get("/public-mrr/revenue?" <> query, expected_response)

      assert {:ok, result} = PublicMRR.get_revenue(start_date, end_date)
      assert result["totalRevenue"] == 0
      assert result["totalTransactions"] == 0
      assert result["transactionsPerDay"]["2025-01-01"]["amount"] == 0
      assert result["transactionsPerDay"]["2025-01-01"]["count"] == 0
      assert result["transactionsPerDay"]["2025-01-02"]["amount"] == 0
      assert result["transactionsPerDay"]["2025-01-02"]["count"] == 0
      assert result["transactionsPerDay"]["2025-01-03"]["amount"] == 0
      assert result["transactionsPerDay"]["2025-01-03"]["count"] == 0
    end

    test "retrieves revenue with large amounts" do
      start_date = "2024-01-01"
      end_date = "2024-12-31"

      expected_response = %{
        "totalRevenue" => 9_999_999_999,
        "totalTransactions" => 10000,
        "transactionsPerDay" => %{
          "2024-06-01" => %{"amount" => 500_000, "count" => 50},
          "2024-06-02" => %{"amount" => 600_000, "count" => 60},
          "2024-06-03" => %{"amount" => 700_000, "count" => 70}
        }
      }

      query = URI.encode_query(%{"startDate" => start_date, "endDate" => end_date})
      MockHTTPServer.stub_get("/public-mrr/revenue?" <> query, expected_response)

      assert {:ok, result} = PublicMRR.get_revenue(start_date, end_date)
      assert result["totalRevenue"] == 9_999_999_999
      assert result["totalTransactions"] == 10000
    end

    test "handles missing date parameter error" do
      start_date = "2024-01-01"
      end_date = ""

      error = MockHTTPServer.mock_error(400, "Start date and end date are required")
      query = URI.encode_query(%{"startDate" => start_date, "endDate" => end_date})
      MockHTTPServer.stub_error(:get, "/public-mrr/revenue?" <> query, error)

      assert {:error, returned_error} = PublicMRR.get_revenue(start_date, end_date)
      assert returned_error.status_code == 400
    end

    test "handles unauthorized error" do
      start_date = "2024-01-01"
      end_date = "2024-01-31"

      error = MockHTTPServer.mock_error(401, "Unauthorized")
      query = URI.encode_query(%{"startDate" => start_date, "endDate" => end_date})
      MockHTTPServer.stub_error(:get, "/public-mrr/revenue?" <> query, error)

      assert {:error, returned_error} = PublicMRR.get_revenue(start_date, end_date)
      assert returned_error.status_code == 401
    end

    test "handles forbidden error" do
      start_date = "2024-01-01"
      end_date = "2024-01-31"

      error = MockHTTPServer.mock_error(403, "Forbidden")
      query = URI.encode_query(%{"startDate" => start_date, "endDate" => end_date})
      MockHTTPServer.stub_error(:get, "/public-mrr/revenue?" <> query, error)

      assert {:error, returned_error} = PublicMRR.get_revenue(start_date, end_date)
      assert returned_error.status_code == 403
    end

    test "handles server error" do
      start_date = "2024-01-01"
      end_date = "2024-01-31"

      error = MockHTTPServer.mock_error(500, "Internal Server Error")
      query = URI.encode_query(%{"startDate" => start_date, "endDate" => end_date})
      MockHTTPServer.stub_error(:get, "/public-mrr/revenue?" <> query, error)

      assert {:error, returned_error} = PublicMRR.get_revenue(start_date, end_date)
      assert returned_error.status_code == 500
    end

    test "retrieves revenue data as a map" do
      start_date = "2024-04-01"
      end_date = "2024-04-30"

      expected_response = %{
        "totalRevenue" => 80_000,
        "totalTransactions" => 20,
        "transactionsPerDay" => %{
          "2024-04-01" => %{"amount" => 3000, "count" => 1},
          "2024-04-02" => %{"amount" => 4000, "count" => 2}
        }
      }

      query = URI.encode_query(%{"startDate" => start_date, "endDate" => end_date})
      MockHTTPServer.stub_get("/public-mrr/revenue?" <> query, expected_response)

      assert {:ok, result} = PublicMRR.get_revenue(start_date, end_date)
      assert is_map(result)
    end
  end
end
