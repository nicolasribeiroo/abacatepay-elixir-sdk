defmodule AbacatePay.Api.WithdrawTest do
  use ExUnit.Case
  use Mimic

  alias AbacatePay.Api.Withdraw
  alias AbacatePay.MockHTTPServer

  @default_withdraw_id "tran_123456"

  describe "create_withdraw/1" do
    test "creates a withdraw successfully with required fields" do
      body = %{
        externalId: "withdraw-1234",
        method: "PIX",
        amount: 5_000,
        pix: %{
          type: "CPF",
          key: "123.456.789-01"
        }
      }

      expected_response = %{
        "id" => @default_withdraw_id,
        "status" => "PENDING",
        "devMode" => false,
        "receiptUrl" => "https://abacatepay.com/receipt/#{@default_withdraw_id}",
        "kind" => "WITHDRAW",
        "amount" => 5_000,
        "platformFee" => 80,
        "externalId" => "withdraw-1234",
        "createdAt" => "2025-03-24T21:50:20.772Z",
        "updatedAt" => "2025-03-24T21:50:20.772Z"
      }

      MockHTTPServer.stub_post("/withdraw/create", body, expected_response)

      assert {:ok, withdraw} = Withdraw.create_withdraw(body)
      assert withdraw["id"] == @default_withdraw_id
      assert withdraw["status"] == "PENDING"
      assert withdraw["amount"] == 5_000
      assert withdraw["externalId"] == "withdraw-1234"
      assert withdraw["devMode"] == false
      assert withdraw["receiptUrl"] == "https://abacatepay.com/receipt/#{@default_withdraw_id}"
      assert withdraw["kind"] == "WITHDRAW"
      assert withdraw["platformFee"] == 80
      assert withdraw["createdAt"] == "2025-03-24T21:50:20.772Z"
      assert withdraw["updatedAt"] == "2025-03-24T21:50:20.772Z"
    end

    test "creates a withdraw with all optional fields" do
      body = %{
        externalId: "withdraw-1234",
        method: "PIX",
        amount: 5_000,
        pix: %{
          type: "CPF",
          key: "123.456.789-01"
        },
        description: "Withdraw for monthly expenses"
      }

      expected_response = %{
        "id" => @default_withdraw_id,
        "status" => "PENDING",
        "devMode" => false,
        "receiptUrl" => "https://abacatepay.com/receipt/#{@default_withdraw_id}",
        "kind" => "WITHDRAW",
        "amount" => 5_000,
        "platformFee" => 80,
        "externalId" => "withdraw-1234",
        "createdAt" => "2025-03-24T21:50:20.772Z",
        "updatedAt" => "2025-03-24T21:50:20.772Z"
      }

      MockHTTPServer.stub_post("/withdraw/create", body, expected_response)

      assert {:ok, withdraw} = Withdraw.create_withdraw(body)
      assert withdraw["id"] == @default_withdraw_id
      assert withdraw["status"] == "PENDING"
      assert withdraw["amount"] == 5_000
      assert withdraw["externalId"] == "withdraw-1234"
      assert withdraw["devMode"] == false
      assert withdraw["receiptUrl"] == "https://abacatepay.com/receipt/#{@default_withdraw_id}"
      assert withdraw["kind"] == "WITHDRAW"
      assert withdraw["platformFee"] == 80
      assert withdraw["createdAt"] == "2025-03-24T21:50:20.772Z"
      assert withdraw["updatedAt"] == "2025-03-24T21:50:20.772Z"
    end

    # https://docs.abacatepay.com/pages/withdraw/create#body-amount
    # Required range: x >= 350
    test "creates a withdraw with minimum amount" do
      body = %{
        "amount" => 350,
        "externalId" => "withdraw_min"
      }

      expected_response = %{
        "id" => "wd_min",
        "amount" => 350,
        "externalId" => "withdraw_min",
        "status" => "PENDING"
      }

      MockHTTPServer.stub_post("/withdraw/create", body, expected_response)

      assert {:ok, withdraw} = Withdraw.create_withdraw(body)
      assert withdraw["amount"] == 350
    end

    test "creates a withdraw with large amount" do
      body = %{
        amount: 9_999_999_999,
        externalId: "withdraw_large"
      }

      expected_response = %{
        "id" => "wd_large",
        "amount" => 9_999_999_999,
        "externalId" => "withdraw_large",
        "status" => "PENDING"
      }

      MockHTTPServer.stub_post("/withdraw/create", body, expected_response)

      assert {:ok, withdraw} = Withdraw.create_withdraw(body)
      assert withdraw["amount"] == 9_999_999_999
    end

    test "handles validation error - negative amount" do
      body = %{
        amount: -1000,
        externalId: "withdraw_invalid"
      }

      error = MockHTTPServer.mock_error(422, "Amount must be positive")
      MockHTTPServer.stub_error(:post, "/withdraw/create", error)

      assert {:error, returned_error} = Withdraw.create_withdraw(body)
      assert returned_error.status_code == 422
    end

    test "handles insufficient balance error" do
      body = %{
        amount: 9_999_999_999_999,
        externalId: "withdraw_insufficient"
      }

      error = MockHTTPServer.mock_error(400, "Insufficient balance")
      MockHTTPServer.stub_error(:post, "/withdraw/create", error)

      assert {:error, returned_error} = Withdraw.create_withdraw(body)
      assert returned_error.status_code == 400
    end

    test "handles missing required field" do
      body = %{
        amount: 50_000
      }

      error = MockHTTPServer.mock_error(422, "Missing required field: externalId")
      MockHTTPServer.stub_error(:post, "/withdraw/create", error)

      assert {:error, returned_error} = Withdraw.create_withdraw(body)
      assert returned_error.status_code == 422
    end

    test "handles server error" do
      body = %{
        amount: 50_000,
        externalId: "withdraw_error"
      }

      error = MockHTTPServer.mock_error(500, "Internal Server Error")
      MockHTTPServer.stub_error(:post, "/withdraw/create", error)

      assert {:error, returned_error} = Withdraw.create_withdraw(body)
      assert returned_error.status_code == 500
    end
  end

  describe "get_withdraw/1" do
    test "retrieves a withdraw by external ID" do
      external_id = "withdraw-1234"

      expected_response = %{
        "id" => @default_withdraw_id,
        "status" => "PENDING",
        "devMode" => true,
        "receiptUrl" => "https://abacatepay.com/receipt/#{@default_withdraw_id}",
        "kind" => "WITHDRAW",
        "amount" => 5_000,
        "platformFee" => 80,
        "createdAt" => "2025-03-24T21:50:20.772Z",
        "updatedAt" => "2025-03-24T21:50:20.772Z",
        "externalId" => "withdraw-1234"
      }

      query = URI.encode_query(%{"externalId" => external_id})
      MockHTTPServer.stub_get("/withdraw/get?" <> query, expected_response)

      assert {:ok, withdraw} = Withdraw.get_withdraw(external_id)
      assert withdraw["id"] == @default_withdraw_id
      assert withdraw["externalId"] == external_id
    end

    test "handles not found error" do
      external_id = "withdraw_nonexistent"

      error = MockHTTPServer.mock_error(404, "Withdraw not found")
      query = URI.encode_query(%{"externalId" => external_id})

      MockHTTPServer.stub_error(:get, "/withdraw/get?" <> query, error)

      assert {:error, returned_error} = Withdraw.get_withdraw(external_id)
      assert returned_error.status_code == 404
    end

    test "handles unauthorized error" do
      external_id = "withdraw_test"

      error = MockHTTPServer.mock_error(401, "Unauthorized")
      query = URI.encode_query(%{"externalId" => external_id})

      MockHTTPServer.stub_error(:get, "/withdraw/get?" <> query, error)

      assert {:error, returned_error} = Withdraw.get_withdraw(external_id)
      assert returned_error.status_code == 401
    end

    test "handles server error" do
      external_id = "withdraw_error"

      error = MockHTTPServer.mock_error(500, "Internal Server Error")
      query = URI.encode_query(%{"externalId" => external_id})

      MockHTTPServer.stub_error(:get, "/withdraw/get?" <> query, error)

      assert {:error, returned_error} = Withdraw.get_withdraw(external_id)
      assert returned_error.status_code == 500
    end

    test "retrieves withdraw with special characters in external ID" do
      external_id = "withdraw_special-abc_123"

      expected_response = %{
        "id" => @default_withdraw_id,
        "status" => "PENDING",
        "devMode" => true,
        "receiptUrl" => "https://abacatepay.com/receipt/#{@default_withdraw_id}",
        "kind" => "WITHDRAW",
        "amount" => 5_000,
        "platformFee" => 80,
        "createdAt" => "2025-03-24T21:50:20.772Z",
        "updatedAt" => "2025-03-24T21:50:20.772Z",
        "externalId" => external_id
      }

      query = URI.encode_query(%{"externalId" => external_id})
      MockHTTPServer.stub_get("/withdraw/get?" <> query, expected_response)

      assert {:ok, withdraw} = Withdraw.get_withdraw(external_id)
      assert withdraw["externalId"] == external_id
    end
  end

  describe "list_withdraws/0" do
    test "lists all withdraws successfully" do
      expected_response = [
        %{
          "id" => "wd_1",
          "amount" => 10_000,
          "externalId" => "withdraw_1",
          "status" => "COMPLETED"
        },
        %{
          "id" => "wd_2",
          "amount" => 25_000,
          "externalId" => "withdraw_2",
          "status" => "PENDING"
        },
        %{
          "id" => "wd_3",
          "amount" => 5_000,
          "externalId" => "withdraw_3",
          "status" => "FAILED"
        }
      ]

      MockHTTPServer.stub_get("/withdraw/list", expected_response)

      assert {:ok, withdraws} = Withdraw.list_withdraws()
      assert is_list(withdraws)
      assert length(withdraws) == 3
      assert Enum.all?(withdraws, &is_map/1)
    end

    test "returns empty list when no withdraws exist" do
      MockHTTPServer.stub_get("/withdraw/list", [])

      assert {:ok, withdraws} = Withdraw.list_withdraws()
      assert withdraws == []
    end

    test "includes all withdraw statuses in list" do
      expected_response = [
        %{"id" => "wd_pending", "status" => "PENDING"},
        %{"id" => "wd_completed", "status" => "COMPLETED"},
        %{"id" => "wd_failed", "status" => "FAILED"},
        %{"id" => "wd_cancelled", "status" => "CANCELLED"}
      ]

      MockHTTPServer.stub_get("/withdraw/list", expected_response)

      assert {:ok, withdraws} = Withdraw.list_withdraws()
      statuses = Enum.map(withdraws, &Map.get(&1, "status"))
      assert "PENDING" in statuses
      assert "COMPLETED" in statuses
      assert "FAILED" in statuses
      assert "CANCELLED" in statuses
    end

    test "lists withdraws with various amounts" do
      expected_response = [
        %{"id" => "wd_small", "amount" => 10_000},
        %{"id" => "wd_medium", "amount" => 500_000},
        %{"id" => "wd_large", "amount" => 9_999_999}
      ]

      MockHTTPServer.stub_get("/withdraw/list", expected_response)

      assert {:ok, withdraws} = Withdraw.list_withdraws()
      amounts = Enum.map(withdraws, &Map.get(&1, "amount"))
      assert 10_000 in amounts
      assert 500_000 in amounts
      assert 9_999_999 in amounts
    end

    test "lists large number of withdraws" do
      withdraws_list =
        Enum.map(1..50, fn i ->
          %{
            "id" => "wd_#{i}",
            "externalId" => "withdraw_#{i}",
            "amount" => i * 1000,
            "status" => if(rem(i, 2) == 0, do: "COMPLETED", else: "PENDING")
          }
        end)

      MockHTTPServer.stub_get("/withdraw/list", withdraws_list)

      assert {:ok, withdraws} = Withdraw.list_withdraws()
      assert length(withdraws) == 50
    end

    test "handles error when listing withdraws - unauthorized" do
      error = MockHTTPServer.mock_error(401, "Unauthorized")
      MockHTTPServer.stub_error(:get, "/withdraw/list", error)

      assert {:error, returned_error} = Withdraw.list_withdraws()
      assert returned_error.status_code == 401
    end

    test "handles error when listing withdraws - forbidden" do
      error = MockHTTPServer.mock_error(403, "Forbidden")
      MockHTTPServer.stub_error(:get, "/withdraw/list", error)

      assert {:error, returned_error} = Withdraw.list_withdraws()
      assert returned_error.status_code == 403
    end

    test "handles error when listing withdraws - server error" do
      error = MockHTTPServer.mock_error(500, "Internal Server Error")
      MockHTTPServer.stub_error(:get, "/withdraw/list", error)

      assert {:error, returned_error} = Withdraw.list_withdraws()
      assert returned_error.status_code == 500
    end
  end
end
