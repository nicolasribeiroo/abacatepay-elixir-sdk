defmodule AbacatePay.WithdrawTest do
  use ExUnit.Case

  alias AbacatePay.{Util, Withdraw}

  describe "struct/0" do
    test "creates a valid Withdraw struct" do
      withdraw = %Withdraw{
        id: "wd_123",
        status: :pending,
        description: "Monthly withdrawal",
        dev_mode: false,
        amount: 50000,
        platform_fee: 100,
        external_id: "ext_123"
      }

      assert withdraw.id == "wd_123"
      assert withdraw.status == :pending
      assert withdraw.amount == 50000
    end

    test "creates Withdraw with nil values" do
      withdraw = %Withdraw{}

      assert withdraw.id == nil
      assert withdraw.status == nil
      assert withdraw.amount == nil
    end
  end

  describe "build_pretty_withdraw/1" do
    test "builds Withdraw from raw API data" do
      raw_data = %{
        "id" => "wd_123",
        "status" => "PENDING",
        "description" => "Monthly withdrawal",
        "devMode" => false,
        "receiptUrl" => nil,
        "kind" => "withdraw",
        "amount" => 50000,
        "platformFee" => 100,
        "externalId" => "ext_123",
        "createdAt" => "2026-01-01T12:00:00Z",
        "updatedAt" => "2026-01-01T12:00:00Z"
      }

      assert {:ok, withdraw} = Withdraw.build_pretty_withdraw(raw_data)
      assert withdraw.id == "wd_123"
      assert withdraw.status == :pending
      assert withdraw.description == "Monthly withdrawal"
      assert withdraw.dev_mode == false
      assert withdraw.amount == 50000
      assert withdraw.platform_fee == 100
      assert withdraw.external_id == "ext_123"
    end

    test "handles datetime parsing" do
      raw_data = %{
        "id" => "wd_123",
        "status" => "PENDING",
        "description" => nil,
        "devMode" => false,
        "receiptUrl" => nil,
        "kind" => "withdraw",
        "amount" => 50000,
        "platformFee" => 0,
        "externalId" => "ext_123",
        "createdAt" => "2026-01-15T10:30:45Z",
        "updatedAt" => "2026-01-15T10:35:45Z"
      }

      assert {:ok, withdraw} = Withdraw.build_pretty_withdraw(raw_data)
      assert withdraw.created_at != nil
      assert withdraw.updated_at != nil
    end

    test "handles nil datetimes" do
      raw_data = %{
        "id" => "wd_123",
        "status" => "PENDING",
        "description" => nil,
        "devMode" => false,
        "receiptUrl" => nil,
        "kind" => "withdraw",
        "amount" => 50000,
        "platformFee" => 0,
        "externalId" => "ext_123",
        "createdAt" => nil,
        "updatedAt" => nil
      }

      assert {:ok, withdraw} = Withdraw.build_pretty_withdraw(raw_data)
      assert withdraw.created_at == nil
      assert withdraw.updated_at == nil
    end

    test "handles various withdraw statuses" do
      statuses = ["PENDING", "EXPIRED", "CANCELLED", "COMPLETE", "REFUNDED"]

      Enum.each(statuses, fn status ->
        raw_data = %{
          "id" => "wd_#{status}",
          "status" => status,
          "description" => nil,
          "devMode" => false,
          "receiptUrl" => nil,
          "kind" => "WITHDRAW",
          "amount" => 10000,
          "platformFee" => 0,
          "externalId" => "ext_123",
          "createdAt" => nil,
          "updatedAt" => nil
        }

        assert {:ok, withdraw} = Withdraw.build_pretty_withdraw(raw_data)
        assert withdraw.status == Util.atomize_enum(status)
      end)
    end

    test "handles large amounts" do
      raw_data = %{
        "id" => "wd_large",
        "status" => "complete",
        "description" => "Large withdrawal",
        "devMode" => false,
        "receiptUrl" => "https://example.com/receipt",
        "kind" => "withdraw",
        "amount" => 999_999_999,
        "platformFee" => 50000,
        "externalId" => "ext_large",
        "createdAt" => nil,
        "updatedAt" => nil
      }

      assert {:ok, withdraw} = Withdraw.build_pretty_withdraw(raw_data)
      assert withdraw.amount == 999_999_999
      assert withdraw.platform_fee == 50000
    end

    test "handles receipt URL" do
      raw_data = %{
        "id" => "wd_receipt",
        "status" => "complete",
        "description" => nil,
        "devMode" => false,
        "receiptUrl" => "https://example.com/receipt/wd_receipt",
        "kind" => "withdraw",
        "amount" => 50000,
        "platformFee" => 0,
        "externalId" => "ext_123",
        "createdAt" => nil,
        "updatedAt" => nil
      }

      assert {:ok, withdraw} = Withdraw.build_pretty_withdraw(raw_data)
      assert withdraw.receipt_url == "https://example.com/receipt/wd_receipt"
    end
  end

  describe "build_api_withdraw/1" do
    test "builds API map from Withdraw struct" do
      withdraw = %Withdraw{
        id: "wd_123",
        status: :pending,
        description: "Monthly withdrawal",
        dev_mode: false,
        receipt_url: nil,
        kind: :withdraw,
        amount: 50000,
        platform_fee: 100,
        external_id: "ext_123",
        created_at: ~U[2026-01-01T12:00:00Z],
        updated_at: ~U[2026-01-01T12:00:00Z]
      }

      assert {:ok, api_map} = Withdraw.build_api_withdraw(withdraw)
      assert api_map[:id] == "wd_123"
      assert api_map[:status] == "PENDING"
      assert api_map[:description] == "Monthly withdrawal"
      assert api_map[:devMode] == false
      assert api_map[:amount] == 50000
      assert api_map[:platformFee] == 100
      assert api_map[:externalId] == "ext_123"
    end

    test "handles datetime conversion" do
      withdraw = %Withdraw{
        id: "wd_datetime",
        status: :complete,
        description: nil,
        dev_mode: false,
        receipt_url: nil,
        kind: :withdraw,
        amount: 50000,
        platform_fee: 0,
        external_id: "ext_123",
        created_at: ~U[2026-01-15T10:30:45Z],
        updated_at: ~U[2026-01-15T10:35:45Z]
      }

      assert {:ok, api_map} = Withdraw.build_api_withdraw(withdraw)
      assert String.contains?(api_map[:createdAt], "2026-01-15")
      assert String.contains?(api_map[:updatedAt], "2026-01-15")
    end

    test "handles nil datetimes" do
      withdraw = %Withdraw{
        id: "wd_nil",
        status: :pending,
        description: nil,
        dev_mode: false,
        receipt_url: nil,
        kind: :withdraw,
        amount: 50000,
        platform_fee: 0,
        external_id: "ext_123",
        created_at: nil,
        updated_at: nil
      }

      assert {:ok, api_map} = Withdraw.build_api_withdraw(withdraw)
      assert api_map[:createdAt] == nil
      assert api_map[:updatedAt] == nil
    end
  end

  describe "roundtrip conversion" do
    test "converts raw data to struct and back" do
      raw_data = %{
        "id" => "wd_roundtrip",
        "status" => "complete",
        "description" => "Roundtrip withdrawal",
        "devMode" => true,
        "receiptUrl" => "https://example.com/receipt",
        "kind" => "withdraw",
        "amount" => 75000,
        "platformFee" => 75,
        "externalId" => "ext_roundtrip",
        "createdAt" => "2026-01-15T10:30:45Z",
        "updatedAt" => "2026-01-15T10:35:45Z"
      }

      assert {:ok, withdraw} = Withdraw.build_pretty_withdraw(raw_data)
      assert {:ok, api_map} = Withdraw.build_api_withdraw(withdraw)

      assert api_map[:id] == raw_data["id"]
      assert api_map[:amount] == raw_data["amount"]
      assert api_map[:externalId] == raw_data["externalId"]
    end
  end
end
