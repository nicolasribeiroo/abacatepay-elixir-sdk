defmodule AbacatePay.Api.BillingTest do
  use ExUnit.Case
  use Mimic

  alias AbacatePay.Api.Billing
  alias AbacatePay.MockHTTPServer

  @default_billing_id "bill_aebxkhDZNaMmJeKsy0AHS0FQ"
  @default_customer_id "cust_aebxkhDZNaMmJeKsy0AHS0FQ"

  describe "create_billing/1" do
    test "creates a billing successfully with required fields" do
      body = %{
        frequency: "ONE_TIME",
        methods: ["PIX"],
        products: [
          %{
            externalId: "prod-1234",
            name: "Assinatura de Programa Fitness",
            description: "Acesso ao programa fitness premium por 1 mês.",
            quantity: 2,
            price: 2_000
          }
        ],
        returnUrl: "https://example.com/billing",
        completionUrl: "https://example.com/completion"
      }

      expected_response = %{
        "id" => @default_billing_id,
        "url" => "https://pay.abacatepay.com/#{@default_billing_id}",
        "status" => "PENDING",
        "devMode" => false,
        "methods" => ["PIX"],
        "products" => [
          %{
            "id" => "prod_123456",
            "externalId" => "prod-1234",
            "quantity" => 2
          }
        ],
        "frequency" => "ONE_TIME",
        "amount" => 4_000,
        "nextBilling" => nil,
        "customer" => nil,
        "allowCoupons" => false,
        "coupons" => []
      }

      MockHTTPServer.stub_post("/billing/create", body, expected_response)

      assert {:ok, billing} = Billing.create_billing(body)
      assert billing["id"] == @default_billing_id
      assert billing["amount"] == 4_000
      assert billing["methods"] == ["PIX"]
      assert billing["url"] == "https://pay.abacatepay.com/#{@default_billing_id}"
      assert billing["frequency"] == "ONE_TIME"
      assert billing["status"] == "PENDING"
      assert billing["customer"] == nil
      assert billing["products"] |> List.first() |> Map.get("externalId") == "prod-1234"
      assert billing["allowCoupons"] == false
      assert billing["coupons"] == []
    end

    test "creates a billing with all optional fields" do
      body = %{
        frequency: "ONE_TIME",
        methods: ["PIX"],
        products: [
          %{
            externalId: "prod-1234",
            name: "Assinatura de Programa Fitness",
            description: "Acesso ao programa fitness premium por 1 mês.",
            quantity: 2,
            price: 2_000
          }
        ],
        returnUrl: "https://example.com/billing",
        completionUrl: "https://example.com/completion",
        customerId: @default_customer_id,
        customer: %{
          name: "Daniel Lima",
          cellphone: "(11) 4002-8922",
          email: "daniel_lima@abacatepay.com",
          taxId: "123.456.789-01"
        },
        allowCoupons: false,
        coupons: ["ABKT10", "ABKT5", "PROMO10"],
        externalId: "123",
        metadata: %{
          externalId: "123"
        }
      }

      expected_response = %{
        "id" => @default_billing_id,
        "url" => "https://pay.abacatepay.com/#{@default_billing_id}",
        "status" => "PENDING",
        "devMode" => false,
        "methods" => ["PIX"],
        "products" => [
          %{
            "id" => "prod_123456",
            "externalId" => "prod-1234",
            "quantity" => 2
          }
        ],
        "frequency" => "ONE_TIME",
        "amount" => 4_000,
        "nextBilling" => nil,
        "customer" => %{
          "id" => @default_customer_id,
          "metadata" => %{
            "name" => "Daniel Lima",
            "cellphone" => "(11) 4002-8922",
            "email" => "daniel_lima@abacatepay.com",
            "taxId" => "123.456.789-01"
          }
        },
        "allowCoupons" => false,
        "coupons" => ["ABKT10", "ABKT5", "PROMO10"]
      }

      MockHTTPServer.stub_post("/billing/create", body, expected_response)

      assert {:ok, billing} = Billing.create_billing(body)
      assert billing["id"] == @default_billing_id
      assert billing["amount"] == 4_000
      assert billing["methods"] == ["PIX"]
      assert billing["url"] == "https://pay.abacatepay.com/#{@default_billing_id}"
      assert billing["frequency"] == "ONE_TIME"
      assert billing["status"] == "PENDING"
      assert billing["customer"]["id"] == @default_customer_id
      assert billing["products"] |> List.first() |> Map.get("externalId") == "prod-1234"
      assert billing["allowCoupons"] == false
      assert billing["coupons"] == ["ABKT10", "ABKT5", "PROMO10"]
    end

    test "handles validation error when creating billing" do
      body = %{
        "frequency" => "invalid",
        "methods" => ["PIX"]
      }

      error = MockHTTPServer.mock_error(422, "Invalid billing parameters")
      MockHTTPServer.stub_error(:post, "/billing/create", error)

      assert {:error, returned_error} = Billing.create_billing(body)
      assert returned_error.status_code == 422
      assert returned_error.message == "Invalid billing parameters"
    end

    test "handles missing required fields error" do
      body = %{"methods" => ["PIX"]}

      error = MockHTTPServer.mock_error(400, "Missing required field: frequency")
      MockHTTPServer.stub_error(:post, "/billing/create", error)

      assert {:error, returned_error} = Billing.create_billing(body)
      assert returned_error.status_code == 400
    end

    test "handles unauthorized error when creating billing" do
      body = %{"frequency" => "one_time", "methods" => ["PIX"]}

      error = MockHTTPServer.mock_error(401, "Unauthorized")
      MockHTTPServer.stub_error(:post, "/billing/create", error)

      assert {:error, returned_error} = Billing.create_billing(body)
      assert returned_error.status_code == 401
    end

    test "handles server error when creating billing" do
      body = %{"frequency" => "one_time", "methods" => ["PIX"]}

      error = MockHTTPServer.mock_error(500, "Internal Server Error")
      MockHTTPServer.stub_error(:post, "/billing/create", error)

      assert {:error, returned_error} = Billing.create_billing(body)
      assert returned_error.status_code == 500
    end
  end

  describe "list_billings/0" do
    test "lists all billings successfully" do
      expected_response = [
        %{
          "id" => @default_billing_id,
          "url" => "https://pay.abacatepay.com/#{@default_billing_id}",
          "status" => "PAID",
          "devMode" => false,
          "methods" => ["PIX"],
          "products" => [
            %{
              "id" => "prod_123456",
              "externalId" => "prod-1234",
              "quantity" => 2
            }
          ],
          "frequency" => "ONE_TIME",
          "amount" => 4_000,
          "nextBilling" => nil,
          "customer" => %{
            "id" => @default_customer_id,
            "metadata" => %{
              "name" => "Daniel Lima",
              "cellphone" => "(11) 4002-8922",
              "email" => "daniel_lima@abacatepay.com",
              "taxId" => "123.456.789-01"
            }
          },
          "allowCoupons" => false,
          "coupons" => []
        },
        %{
          "id" => "bill_bcdxkhDZNaMmJeKsy0AHS0FQ",
          "url" => "https://pay.abacatepay.com/bill_bcdxkhDZNaMmJeKsy0AHS0FQ",
          "status" => "PENDING",
          "devMode" => false,
          "methods" => ["CARD"],
          "products" => [
            %{
              "id" => "prod_654321",
              "externalId" => "prod-5678",
              "quantity" => 1
            }
          ],
          "frequency" => "MULTIPLE_PAYMENTS",
          "amount" => 15_000,
          "nextBilling" => "2024-07-15T10:00:00Z",
          "customer" => nil,
          "allowCoupons" => true,
          "coupons" => ["SUMMER21"]
        }
      ]

      MockHTTPServer.stub_get("/billing/list", expected_response)

      assert {:ok, billings} = Billing.list_billings()
      assert is_list(billings)
      assert length(billings) == 2
      assert Enum.all?(billings, &is_map/1)
    end

    test "returns all billing details in list" do
      expected_response = [
        %{
          "id" => @default_billing_id,
          "url" => "https://pay.abacatepay.com/#{@default_billing_id}",
          "status" => "PAID",
          "devMode" => false,
          "methods" => ["PIX", "CARD"],
          "products" => [
            %{
              "id" => "prod_789012",
              "externalId" => "prod-9012",
              "quantity" => 3
            }
          ],
          "frequency" => "ONE_TIME",
          "amount" => 6_000,
          "nextBilling" => nil,
          "customer" => %{
            "id" => @default_customer_id,
            "metadata" => %{
              "name" => "Daniel Lima",
              "cellphone" => "(11) 4002-8922",
              "email" => "daniel_lima@abacatepay.com",
              "taxId" => "123.456.789-01"
            }
          },
          "allowCoupons" => true,
          "coupons" => ["WELCOME10", "FALL5", "HOLIDAY15"]
        }
      ]

      MockHTTPServer.stub_get("/billing/list", expected_response)

      assert {:ok, billings} = Billing.list_billings()
      billing = List.first(billings)
      assert billing["methods"] == ["PIX", "CARD"]
      assert billing["products"] |> List.first() |> Map.get("externalId") == "prod-9012"
      assert billing["allowCoupons"] == true
      assert billing["coupons"] == ["WELCOME10", "FALL5", "HOLIDAY15"]
    end

    test "returns empty list when no billings exist" do
      MockHTTPServer.stub_get("/billing/list", [])

      assert {:ok, billings} = Billing.list_billings()
      assert billings == []
    end

    test "handles different billing statuses in list" do
      expected_response = [
        %{"id" => "bill_pending", "status" => "pending"},
        %{"id" => "bill_paid", "status" => "paid"},
        %{"id" => "bill_expired", "status" => "expired"},
        %{"id" => "bill_cancelled", "status" => "cancelled"},
        %{"id" => "bill_refunded", "status" => "refunded"}
      ]

      MockHTTPServer.stub_get("/billing/list", expected_response)

      assert {:ok, billings} = Billing.list_billings()
      assert length(billings) == 5
      statuses = Enum.map(billings, &Map.get(&1, "status"))
      assert "pending" in statuses
      assert "paid" in statuses
      assert "expired" in statuses
      assert "cancelled" in statuses
      assert "refunded" in statuses
    end

    test "handles different frequencies in list" do
      expected_response = [
        %{"id" => "bill_onetime", "frequency" => "one_time"},
        %{"id" => "bill_multi", "frequency" => "multiple_payments"}
      ]

      MockHTTPServer.stub_get("/billing/list", expected_response)

      assert {:ok, billings} = Billing.list_billings()
      frequencies = Enum.map(billings, &Map.get(&1, "frequency"))
      assert "one_time" in frequencies
      assert "multiple_payments" in frequencies
    end

    test "handles error when listing billings" do
      error = MockHTTPServer.mock_error(500, "Internal Server Error")
      MockHTTPServer.stub_error(:get, "/billing/list", error)

      assert {:error, returned_error} = Billing.list_billings()
      assert returned_error.status_code == 500
    end

    test "handles unauthorized error when listing billings" do
      error = MockHTTPServer.mock_error(401, "Unauthorized")
      MockHTTPServer.stub_error(:get, "/billing/list", error)

      assert {:error, returned_error} = Billing.list_billings()
      assert returned_error.status_code == 401
    end

    test "handles forbidden error when listing billings" do
      error = MockHTTPServer.mock_error(403, "Forbidden")
      MockHTTPServer.stub_error(:get, "/billing/list", error)

      assert {:error, returned_error} = Billing.list_billings()
      assert returned_error.status_code == 403
    end

    test "lists billings with various amounts" do
      expected_response = [
        %{"id" => "bill_min", "amount" => 100},
        %{"id" => "bill_mid", "amount" => 50_000},
        %{"id" => "bill_max", "amount" => 9_999_999}
      ]

      MockHTTPServer.stub_get("/billing/list", expected_response)

      assert {:ok, billings} = Billing.list_billings()
      amounts = Enum.map(billings, &Map.get(&1, "amount"))
      assert 100 in amounts
      assert 50_000 in amounts
      assert 9_999_999 in amounts
    end
  end
end
