defmodule AbacatePay.Schema.BillingTest do
  use ExUnit.Case

  alias AbacatePay.Schema.Billing

  describe "create_billing_request/0" do
    test "returns a valid schema definition" do
      schema = Billing.create_billing_request()
      assert is_list(schema)
      assert Enum.all?(schema, fn {_key, opts} -> is_list(opts) end)
    end

    test "validates with all required fields" do
      data = [
        frequency: :one_time,
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Billing.create_billing_request())
      assert result[:frequency] == :one_time
      assert result[:methods] == [:pix]
      assert length(result[:products]) == 1
      assert result[:return_url] == "https://example.com/return"
      assert result[:completion_url] == "https://example.com/completion"
    end

    test "rejects missing frequency" do
      data = [
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Billing.create_billing_request())

      assert key == :frequency
    end

    test "rejects missing methods" do
      data = [
        frequency: :one_time,
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Billing.create_billing_request())

      assert key == :methods
    end

    test "rejects missing products" do
      data = [
        frequency: :one_time,
        methods: [:pix],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Billing.create_billing_request())

      assert key == :products
    end

    test "rejects missing return_url" do
      data = [
        frequency: :one_time,
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        completion_url: "https://example.com/completion"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Billing.create_billing_request())

      assert key == :return_url
    end

    test "accepts one_time frequency" do
      data = [
        frequency: :one_time,
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Billing.create_billing_request())
      assert result[:frequency] == :one_time
    end

    test "accepts multiple_payments frequency" do
      data = [
        frequency: :multiple_payments,
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Billing.create_billing_request())
      assert result[:frequency] == :multiple_payments
    end

    test "rejects invalid frequency" do
      data = [
        frequency: :invalid_frequency,
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Billing.create_billing_request())

      assert key == :frequency
    end

    test "accepts single payment method" do
      data = [
        frequency: :one_time,
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Billing.create_billing_request())
      assert result[:methods] == [:pix]
    end

    test "accepts multiple payment methods" do
      data = [
        frequency: :one_time,
        methods: [:pix, :card],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Billing.create_billing_request())
      assert :pix in result[:methods]
      assert :card in result[:methods]
    end

    test "rejects invalid payment method" do
      data = [
        frequency: :one_time,
        methods: [:invalid_method],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Billing.create_billing_request())

      assert key == :methods
    end

    test "accepts single product" do
      data = [
        frequency: :one_time,
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Billing.create_billing_request())
      assert length(result[:products]) == 1
    end

    test "accepts multiple products" do
      data = [
        frequency: :one_time,
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          },
          %AbacatePay.Product{
            name: "Product 2",
            description: "Description 2",
            quantity: 1,
            price: 3000,
            external_id: "prod_002"
          },
          %AbacatePay.Product{
            name: "Product 3",
            description: "Description 3",
            quantity: 5,
            price: 500,
            external_id: "prod_003"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Billing.create_billing_request())
      assert length(result[:products]) == 3
    end

    test "accepts various URLs" do
      valid_urls = [
        "https://example.com/return",
        "https://subdomain.example.com/return",
        "https://example.com:8080/return",
        "https://example.com/return?param=value",
        "https://example.com/return#anchor"
      ]

      Enum.each(valid_urls, fn url ->
        data = [
          frequency: :one_time,
          methods: [:pix],
          products: [
            %AbacatePay.Product{
              name: "Product 1",
              description: "Description 1",
              quantity: 2,
              price: 1500,
              external_id: "prod_001"
            }
          ],
          return_url: url,
          completion_url: url
        ]

        assert {:ok, _} = NimbleOptions.validate(data, Billing.create_billing_request())
      end)
    end

    test "accepts optional customer" do
      data = [
        frequency: :one_time,
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion",
        customer: %AbacatePay.Customer{
          name: "Daniel Lima",
          email: "daniel_lima@abacatepay.com",
          cellphone: "(11) 4002-8922",
          tax_id: "123.456.789-01"
        }
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Billing.create_billing_request())
      assert is_map(result[:customer])
    end

    test "accepts optional metadata" do
      data = [
        frequency: :one_time,
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion",
        metadata: %{order_id: "123", user_id: "456"}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Billing.create_billing_request())
      assert result[:metadata] == %{order_id: "123", user_id: "456"}
    end

    test "rejects non-atom frequency" do
      data = [
        frequency: "one_time",
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Billing.create_billing_request())

      assert key == :frequency
    end

    test "rejects non-list methods" do
      data = [
        frequency: :one_time,
        methods: :pix,
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Billing.create_billing_request())

      assert key == :methods
    end

    test "rejects non-list products" do
      data = [
        frequency: :one_time,
        methods: [:pix],
        products: %AbacatePay.Product{
          name: "Product 1",
          description: "Description 1",
          quantity: 2,
          price: 1500,
          external_id: "prod_001"
        },
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Billing.create_billing_request())

      assert key == :products
    end

    test "rejects non-string return_url" do
      data = [
        frequency: :one_time,
        methods: [:pix],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: 12345,
        completion_url: "https://example.com/completion"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Billing.create_billing_request())

      assert key == :return_url
    end

    test "accepts empty products list" do
      data = [
        frequency: :one_time,
        methods: [:pix],
        products: [],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:ok, _} = NimbleOptions.validate(data, Billing.create_billing_request())
    end

    test "accepts empty methods list" do
      data = [
        frequency: :one_time,
        methods: [],
        products: [
          %AbacatePay.Product{
            name: "Product 1",
            description: "Description 1",
            quantity: 2,
            price: 1500,
            external_id: "prod_001"
          }
        ],
        return_url: "https://example.com/return",
        completion_url: "https://example.com/completion"
      ]

      assert {:ok, _} = NimbleOptions.validate(data, Billing.create_billing_request())
    end
  end
end
