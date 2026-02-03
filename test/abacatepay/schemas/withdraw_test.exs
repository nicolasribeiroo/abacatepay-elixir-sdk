defmodule AbacatePay.Schema.WithdrawTest do
  use ExUnit.Case

  alias AbacatePay.Schema.Withdraw

  @default_withdraw_id "tran_123456"

  describe "create_withdraw_request/0" do
    test "returns a valid schema definition" do
      schema = Withdraw.create_withdraw_request()
      assert is_list(schema)
      assert Enum.all?(schema, fn {_key, opts} -> is_list(opts) end)
    end

    test "validates with all required fields" do
      data = [
        external_id: @default_withdraw_id,
        method: :pix,
        amount: 50000,
        pix: %{
          key: "test@example.com",
          type: :email
        }
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert result[:external_id] == @default_withdraw_id
      assert result[:method] == :pix
      assert result[:amount] == 50000
      assert is_map(result[:pix])
    end

    test "rejects missing external_id" do
      data = [
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :external_id
    end

    test "rejects missing method" do
      data = [
        external_id: "withdraw_123",
        amount: 50000,
        pix: %{key: "test@example.com", type: :email}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :method
    end

    test "rejects missing amount" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        pix: %{key: "test@example.com", type: :email}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :amount
    end

    test "rejects missing pix" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :pix
    end

    test "accepts pix as method" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert result[:method] == :pix
    end

    test "rejects invalid method" do
      data = [
        external_id: "withdraw_123",
        method: :invalid_method,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :method
    end

    test "rejects non-string external_id" do
      data = [
        external_id: 12345,
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :external_id
    end

    test "accepts various external_id formats" do
      valid_ids = [
        "withdraw_123",
        "WD-2024-001",
        "a",
        "very_long_external_id_with_many_characters_12345"
      ]

      Enum.each(valid_ids, fn id ->
        data = [
          external_id: id,
          method: :pix,
          amount: 50000,
          pix: %{key: "test@example.com", type: :email}
        ]

        assert {:ok, _} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      end)
    end

    test "accepts various valid amounts" do
      valid_amounts = [1, 100, 10000, 50000, 999_999_999, 1_000_000_000]

      Enum.each(valid_amounts, fn amount ->
        data = [
          external_id: "withdraw_#{amount}",
          method: :pix,
          amount: amount,
          pix: %{key: "test@example.com", type: :email}
        ]

        assert {:ok, _} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      end)
    end

    test "rejects non-integer amount" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: "50000",
        pix: %{key: "test@example.com", type: :email}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :amount
    end

    test "rejects float amount" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 500.50,
        pix: %{key: "test@example.com", type: :email}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :amount
    end

    test "validates pix with cpf type" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "12345678901", type: :cpf}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert result[:pix][:type] == :cpf
    end

    test "validates pix with cnpj type" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "12345678901234", type: :cnpj}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert result[:pix][:type] == :cnpj
    end

    test "validates pix with phone type" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "+5511999999999", type: :phone}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert result[:pix][:type] == :phone
    end

    test "validates pix with email type" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert result[:pix][:type] == :email
    end

    test "validates pix with random type" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "random-key-123", type: :random}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert result[:pix][:type] == :random
    end

    test "validates pix with br_code type" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "12345678901234567890", type: :br_code}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert result[:pix][:type] == :br_code
    end

    test "rejects invalid pix type" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "test", type: :invalid}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :type
    end

    test "rejects pix without key" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{type: :email}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :key
    end

    test "rejects pix without type" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com"}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :type
    end

    test "rejects non-string pix key" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: 12345, type: :email}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :key
    end

    test "rejects non-atom pix type" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: "email"}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :type
    end

    test "accepts optional description" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email},
        description: "Monthly withdrawal"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert result[:description] == "Monthly withdrawal"
    end

    test "accepts empty description" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email},
        description: ""
      ]

      assert {:ok, _} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
    end

    test "accepts long description" do
      long_desc = String.duplicate("x", 1000)

      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email},
        description: long_desc
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert result[:description] == long_desc
    end

    test "rejects non-string description" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email},
        description: 12345
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Withdraw.create_withdraw_request())

      assert key == :description
    end

    test "accepts all fields together" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email},
        description: "Monthly withdrawal"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert result[:external_id] == "withdraw_123"
      assert result[:method] == :pix
      assert result[:amount] == 50000
      assert result[:description] == "Monthly withdrawal"
    end

    test "validates with keyword list data" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email}
      ]

      assert {:ok, _} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
    end

    test "handles special characters in external_id" do
      data = [
        external_id: "withdraw-2024_123-test",
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert result[:external_id] == "withdraw-2024_123-test"
    end

    test "handles special characters in description" do
      data = [
        external_id: "withdraw_123",
        method: :pix,
        amount: 50000,
        pix: %{key: "test@example.com", type: :email},
        description: "Withdrawal €5,000 #monthly 2024"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
      assert String.contains?(result[:description], ["€", "#"])
    end

    test "workflow: multiple withdrawals with different pix types" do
      pix_types = [:cpf, :cnpj, :phone, :email, :random, :br_code]

      Enum.each(pix_types, fn pix_type ->
        data = [
          external_id: "withdraw_#{pix_type}",
          method: :pix,
          amount: 10000,
          pix: %{key: "value_for_#{pix_type}", type: pix_type}
        ]

        assert {:ok, result} = NimbleOptions.validate(data, Withdraw.create_withdraw_request())
        assert result[:pix][:type] == pix_type
      end)
    end
  end
end
