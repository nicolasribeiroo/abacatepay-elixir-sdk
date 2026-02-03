defmodule AbacatePay.BillingTest do
  use ExUnit.Case

  alias AbacatePay.{Billing, Util}

  describe "struct/0" do
    test "creates a valid Billing struct" do
      billing = %Billing{
        id: "bill_123",
        frequency: :one_time,
        amount: 50000,
        url: "https://abacatepay.com/pay/bill_123",
        status: :pending,
        dev_mode: false,
        methods: [:pix, :card],
        products: []
      }

      assert billing.id == "bill_123"
      assert billing.frequency == :one_time
      assert billing.amount == 50000
      assert billing.status == :pending
    end

    test "creates Billing with nil values" do
      billing = %Billing{}

      assert billing.id == nil
      assert billing.frequency == nil
      assert billing.amount == nil
    end
  end

  describe "build_pretty_billing/1" do
    test "builds Billing from raw API data" do
      raw_data = %{
        "id" => "bill_123",
        "frequency" => "one_time",
        "amount" => 50000,
        "url" => "https://abacatepay.com/pay/bill_123",
        "status" => "PENDING",
        "devMode" => false,
        "methods" => ["pix", "card"],
        "products" => [
          %{"externalId" => "prod_1", "quantity" => 1, "price" => 50000, "name" => "Product"}
        ],
        "customer" => nil,
        "metadata" => %{
          "fee" => 100,
          "returnUrl" => "https://example.com",
          "completionUrl" => "https://example.com/done"
        },
        "nextBilling" => nil,
        "allowCoupons" => true,
        "coupons" => [],
        "createdAt" => "2026-01-01T12:00:00Z",
        "updatedAt" => "2026-01-01T12:00:00Z"
      }

      assert {:ok, billing} = Billing.build_pretty_billing(raw_data)
      assert billing.id == "bill_123"
      assert billing.frequency == :one_time
      assert billing.amount == 50000
      assert billing.status == :pending
      assert billing.dev_mode == false
      assert :pix in billing.methods
      assert :card in billing.methods
      assert length(billing.products) == 1
    end

    test "handles datetime parsing" do
      raw_data = %{
        "id" => "bill_123",
        "frequency" => "one_time",
        "amount" => 50000,
        "url" => "https://abacatepay.com/pay/bill_123",
        "status" => "PENDING",
        "devMode" => false,
        "methods" => ["pix"],
        "products" => [],
        "customer" => nil,
        "metadata" => %{},
        "nextBilling" => nil,
        "allowCoupons" => true,
        "coupons" => [],
        "createdAt" => "2026-01-15T10:30:45Z",
        "updatedAt" => "2026-01-15T10:35:45Z"
      }

      assert {:ok, billing} = Billing.build_pretty_billing(raw_data)
      assert billing.created_at != nil
      assert billing.updated_at != nil
    end

    test "handles nil datetimes" do
      raw_data = %{
        "id" => "bill_123",
        "frequency" => "one_time",
        "amount" => 50000,
        "url" => "https://abacatepay.com/pay/bill_123",
        "status" => "PENDING",
        "devMode" => false,
        "methods" => ["pix"],
        "products" => [],
        "customer" => nil,
        "metadata" => %{},
        "nextBilling" => nil,
        "allowCoupons" => true,
        "coupons" => [],
        "createdAt" => nil,
        "updatedAt" => nil
      }

      assert {:ok, billing} = Billing.build_pretty_billing(raw_data)
      assert billing.created_at == nil
      assert billing.updated_at == nil
    end

    test "handles various billing statuses" do
      statuses = ["PENDING", "PAID", "EXPIRED", "CANCELLED", "REFUNDED"]

      Enum.each(statuses, fn status ->
        raw_data = %{
          "id" => "bill_#{status}",
          "frequency" => "one_time",
          "amount" => 10000,
          "url" => "https://abacatepay.com/pay",
          "status" => status,
          "devMode" => false,
          "methods" => ["pix"],
          "products" => [],
          "customer" => nil,
          "metadata" => %{},
          "nextBilling" => nil,
          "allowCoupons" => true,
          "coupons" => [],
          "createdAt" => nil,
          "updatedAt" => nil
        }

        assert {:ok, billing} = Billing.build_pretty_billing(raw_data)
        assert billing.status == Util.atomize_enum(status)
      end)
    end

    test "handles multiple products" do
      raw_data = %{
        "id" => "bill_123",
        "frequency" => "one_time",
        "amount" => 50000,
        "url" => "https://abacatepay.com/pay/bill_123",
        "status" => "PENDING",
        "devMode" => false,
        "methods" => ["pix"],
        "products" => [
          %{"externalId" => "prod_1", "quantity" => 1, "price" => 20000, "name" => "Product 1"},
          %{"externalId" => "prod_2", "quantity" => 2, "price" => 15000, "name" => "Product 2"}
        ],
        "customer" => nil,
        "metadata" => %{},
        "nextBilling" => nil,
        "allowCoupons" => true,
        "coupons" => [],
        "createdAt" => nil,
        "updatedAt" => nil
      }

      assert {:ok, billing} = Billing.build_pretty_billing(raw_data)
      assert length(billing.products) == 2
    end
  end

  describe "build_api_billing/1" do
    test "builds API map from Billing struct" do
      billing = %Billing{
        id: "bill_123",
        frequency: :one_time,
        amount: 50000,
        url: "https://abacatepay.com/pay/bill_123",
        status: :pending,
        dev_mode: false,
        methods: [:pix, :card],
        products: [],
        customer: nil,
        metadata: nil,
        next_billing: nil,
        allow_coupons: true,
        coupons: [],
        created_at: nil,
        updated_at: nil
      }

      assert {:ok, api_map} = Billing.build_api_billing(billing)
      assert api_map[:id] == "bill_123"
      assert api_map[:frequency] == "one_time"
      assert api_map[:amount] == 50000
      assert api_map[:status] == "PENDING"
    end
  end

  describe "roundtrip conversion" do
    test "converts raw data to struct and back" do
      raw_data = %{
        "id" => "bill_roundtrip",
        "frequency" => "MULTIPLE_PAYMENTS",
        "amount" => 30000,
        "url" => "https://abacatepay.com/pay/bill_roundtrip",
        "status" => "PENDING",
        "devMode" => true,
        "methods" => ["PIX"],
        "products" => [
          %{"externalId" => "prod_1", "quantity" => 1, "price" => 30000, "name" => "Test Product"}
        ],
        "customer" => nil,
        "metadata" => %{},
        "nextBilling" => nil,
        "allowCoupons" => false,
        "coupons" => [],
        "createdAt" => "2026-01-15T10:30:45Z",
        "updatedAt" => "2026-01-15T10:30:45Z"
      }

      assert {:ok, billing} = Billing.build_pretty_billing(raw_data)
      assert {:ok, api_map} = Billing.build_api_billing(billing)

      assert api_map[:id] == raw_data["id"]
      assert api_map[:frequency] == raw_data["frequency"]
      assert api_map[:amount] == raw_data["amount"]
      assert api_map[:status] == raw_data["status"]
      assert api_map[:methods] == raw_data["methods"]
    end
  end
end
