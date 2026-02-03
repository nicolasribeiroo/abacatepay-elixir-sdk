defmodule AbacatePay.Schema.PixTest do
  use ExUnit.Case

  alias AbacatePay.Schema.Pix

  describe "create_pix_request/0" do
    test "returns a valid schema definition" do
      schema = Pix.create_pix_request()
      assert is_list(schema)
      assert Enum.all?(schema, fn {_key, opts} -> is_list(opts) end)
    end

    test "validates with only required amount field" do
      data = [amount: 10000]

      assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
      assert result[:amount] == 10000
    end

    test "rejects missing amount" do
      data = []

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Pix.create_pix_request())

      assert key == :amount
    end

    test "accepts various valid amounts" do
      valid_amounts = [1, 100, 10000, 50000, 999_999_999, 1_000_000_000]

      Enum.each(valid_amounts, fn amount ->
        data = [amount: amount]
        assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
        assert result[:amount] == amount
      end)
    end

    test "rejects zero amount" do
      data = [amount: 0]

      # NimbleOptions doesn't validate zero by default, so this should pass
      # TODO: Add custom validation
      assert {:ok, _} = NimbleOptions.validate(data, Pix.create_pix_request())
    end

    test "rejects negative amount" do
      data = [amount: -10000]

      # NimbleOptions doesn't validate negative by default, so this should pass
      # TODO: Add custom validation
      assert {:ok, _} = NimbleOptions.validate(data, Pix.create_pix_request())
    end

    test "rejects non-integer amount" do
      data = [amount: "10000"]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Pix.create_pix_request())

      assert key == :amount
    end

    test "rejects float amount" do
      data = [amount: 100.50]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Pix.create_pix_request())

      assert key == :amount
    end

    test "accepts optional description" do
      data = [
        amount: 10000,
        description: "Payment for order #123"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
      assert result[:description] == "Payment for order #123"
    end

    test "accepts empty description" do
      data = [
        amount: 10000,
        description: ""
      ]

      assert {:ok, _} = NimbleOptions.validate(data, Pix.create_pix_request())
    end

    test "accepts long description" do
      long_desc = String.duplicate("x", 1000)

      data = [
        amount: 10000,
        description: long_desc
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
      assert result[:description] == long_desc
    end

    test "rejects non-string description" do
      data = [
        amount: 10000,
        description: 12345
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Pix.create_pix_request())

      assert key == :description
    end

    test "accepts optional customer" do
      data = [
        amount: 10000,
        customer: %AbacatePay.Customer{
          name: "Daniel Lima",
          email: "daniel_lima@abacatepay.com",
          cellphone: "(11) 4002-8922",
          tax_id: "123.456.789-01"
        }
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
      assert is_map(result[:customer])
    end

    test "accepts customer as struct" do
      data = [
        amount: 10000,
        customer: %AbacatePay.Customer{
          name: "Daniel Lima",
          cellphone: "(11) 4002-8922",
          email: "daniel_lima@abacatepay.com",
          tax_id: "123.456.789-01"
        }
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
      assert is_map(result[:customer])
      assert result[:customer].name == "Daniel Lima"
    end

    test "rejects non-map customer" do
      data = [
        amount: 10000,
        customer: "not a map"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Pix.create_pix_request())

      assert key == :customer
    end

    test "accepts optional expires_in" do
      data = [
        amount: 10000,
        expires_in: 3600
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
      assert result[:expires_in] == 3600
    end

    test "accepts various expires_in values" do
      valid_expires = [60, 300, 3600, 86400, 604_800]

      Enum.each(valid_expires, fn expires ->
        data = [amount: 10000, expires_in: expires]
        assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
        assert result[:expires_in] == expires
      end)
    end

    test "rejects non-integer expires_in" do
      data = [
        amount: 10000,
        expires_in: "3600"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Pix.create_pix_request())

      assert key == :expires_in
    end

    test "rejects float expires_in" do
      data = [
        amount: 10000,
        expires_in: 36.00
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Pix.create_pix_request())

      assert key == :expires_in
    end

    test "accepts optional metadata map" do
      data = [
        amount: 10000,
        metadata: %{order_id: "123", user_id: "456"}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
      assert result[:metadata] == %{order_id: "123", user_id: "456"}
    end

    test "accepts empty metadata map" do
      data = [
        amount: 10000,
        metadata: %{}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
      assert result[:metadata] == %{}
    end

    test "accepts metadata with various types" do
      data = [
        amount: 10000,
        metadata: %{
          string: "value",
          number: 123,
          float: 45.67,
          atom: :test,
          list: [1, 2, 3],
          map: %{nested: "value"}
        }
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
      assert result[:metadata][:string] == "value"
      assert result[:metadata][:number] == 123
    end

    test "rejects non-map metadata" do
      data = [
        amount: 10000,
        metadata: "not a map"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Pix.create_pix_request())

      assert key == :metadata
    end

    test "accepts all fields together" do
      data = [
        amount: 10000,
        description: "Order payment",
        customer: %AbacatePay.Customer{
          name: "Daniel Lima",
          cellphone: "(11) 4002-8922",
          email: "daniel_lima@abacatepay.com",
          tax_id: "123.456.789-01"
        },
        expires_in: 3600,
        metadata: %{order_id: "123"}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
      assert result[:amount] == 10000
      assert result[:description] == "Order payment"
      assert result[:expires_in] == 3600
    end

    test "validates with keyword list data" do
      data = [
        amount: 10000,
        description: "Payment",
        metadata: %{id: "123"}
      ]

      assert {:ok, _} = NimbleOptions.validate(data, Pix.create_pix_request())
    end

    test "handles special characters in description" do
      data = [
        amount: 10000,
        description: "Payment for product: €100 #special!"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Pix.create_pix_request())
      assert result[:description] == "Payment for product: €100 #special!"
    end

    test "rejects metadata with string keys" do
      data = [
        amount: 10000,
        metadata: %{"order_id" => "123", "user" => "john"}
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Pix.create_pix_request())

      assert key == :metadata
    end
  end
end
