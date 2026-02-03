defmodule AbacatePay.Schema.CustomerTest do
  use ExUnit.Case

  alias AbacatePay.Schema.Customer

  describe "create_customer_request/0" do
    test "returns a valid schema definition" do
      schema = Customer.create_customer_request()
      assert is_list(schema)
      assert Enum.all?(schema, fn {_key, opts} -> is_list(opts) end)
    end

    test "schema has required fields" do
      schema = Customer.create_customer_request()
      keys = Enum.map(schema, &elem(&1, 0))

      assert :name in keys
      assert :cellphone in keys
      assert :email in keys
      assert :tax_id in keys
    end

    test "validates with all required fields" do
      data = [
        name: "Daniel Lima",
        cellphone: "(11) 4002-8922",
        email: "daniel_lima@abacatepay.com",
        tax_id: "123.456.789-01"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Customer.create_customer_request())
      assert result[:name] == "Daniel Lima"
      assert result[:cellphone] == "(11) 4002-8922"
      assert result[:email] == "daniel_lima@abacatepay.com"
      assert result[:tax_id] == "123.456.789-01"
    end

    test "rejects missing name" do
      data = [
        cellphone: "(11) 4002-8922",
        email: "daniel_lima@abacatepay.com",
        tax_id: "123.456.789-01"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Customer.create_customer_request())

      assert key == :name
    end

    test "rejects missing cellphone" do
      data = [
        name: "Daniel Lima",
        email: "daniel_lima@abacatepay.com",
        tax_id: "123.456.789-01"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Customer.create_customer_request())

      assert key == :cellphone
    end

    test "rejects missing email" do
      data = [
        name: "Daniel Lima",
        cellphone: "(11) 4002-8922",
        tax_id: "123.456.789-01"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Customer.create_customer_request())

      assert key == :email
    end

    test "rejects missing tax_id" do
      data = [
        name: "Daniel Lima",
        cellphone: "(11) 4002-8922",
        email: "daniel_lima@abacatepay.com"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Customer.create_customer_request())

      assert key == :tax_id
    end

    test "accepts valid name variations" do
      valid_names = [
        "Daniel Lima",
        "Maria da Silva",
        "José María",
        "A",
        "Very Long Name With Many Words And Spaces"
      ]

      Enum.each(valid_names, fn name ->
        data = [
          name: name,
          cellphone: "(11) 4002-8922",
          email: "daniel_lima@abacatepay.com",
          tax_id: "123.456.789-01"
        ]

        assert {:ok, _} = NimbleOptions.validate(data, Customer.create_customer_request())
      end)
    end

    test "accepts valid cellphone numbers" do
      valid_phones = [
        "11999999999",
        "21987654321",
        "85912345678",
        "1140028922"
      ]

      Enum.each(valid_phones, fn phone ->
        data = [
          name: "Daniel Lima",
          cellphone: phone,
          email: "daniel_lima@abacatepay.com",
          tax_id: "123.456.789-01"
        ]

        assert {:ok, _} = NimbleOptions.validate(data, Customer.create_customer_request())
      end)
    end

    test "accepts valid email addresses" do
      valid_emails = [
        "daniel_lima@abacatepay.com",
        "user.name+tag@example.co.uk",
        "test@subdomain.example.com",
        "a@b.c"
      ]

      Enum.each(valid_emails, fn email ->
        data = [
          name: "Daniel Lima",
          cellphone: "(11) 4002-8922",
          email: email,
          tax_id: "123.456.789-01"
        ]

        assert {:ok, _} = NimbleOptions.validate(data, Customer.create_customer_request())
      end)
    end

    test "accepts various tax_id formats" do
      valid_tax_ids = [
        "123.456.789-01",
        "000.000.000-00",
        "999.999.999-99"
      ]

      Enum.each(valid_tax_ids, fn tax_id ->
        data = [
          name: "Daniel Lima",
          cellphone: "(11) 4002-8922",
          email: "daniel_lima@abacatepay.com",
          tax_id: tax_id
        ]

        assert {:ok, _} = NimbleOptions.validate(data, Customer.create_customer_request())
      end)
    end

    test "rejects non-string name" do
      data = [
        name: 12345,
        cellphone: "(11) 4002-8922",
        email: "daniel_lima@abacatepay.com",
        tax_id: "123.456.789-01"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Customer.create_customer_request())

      assert key == :name
    end

    test "rejects non-string cellphone" do
      data = [
        name: "Daniel Lima",
        cellphone: 11_999_999_999,
        email: "daniel_lima@abacatepay.com",
        tax_id: "123.456.789-01"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Customer.create_customer_request())

      assert key == :cellphone
    end

    test "rejects non-string email" do
      data = [
        name: "Daniel Lima",
        cellphone: "(11) 4002-8922",
        email: :invalid,
        tax_id: "123.456.789-01"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Customer.create_customer_request())

      assert key == :email
    end

    test "rejects non-string tax_id" do
      data = [
        name: "Daniel Lima",
        cellphone: "(11) 4002-8922",
        email: "daniel_lima@abacatepay.com",
        tax_id: []
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Customer.create_customer_request())

      assert key == :tax_id
    end
  end
end
