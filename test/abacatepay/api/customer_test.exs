defmodule AbacatePay.Api.CustomerTest do
  use ExUnit.Case
  use Mimic

  alias AbacatePay.Api.Customer
  alias AbacatePay.MockHTTPServer

  @default_customer_id "cust_aebxkhDZNaMmJeKsy0AHS0FQ"

  describe "create_customer/1" do
    test "creates a customer successfully" do
      body = %{
        name: "Daniel Lima",
        cellphone: "(11) 4002-8922",
        email: "daniel_lima@abacatepay.com",
        taxId: "123.456.789-01"
      }

      expected_response = %{
        "id" => @default_customer_id,
        "metadata" => %{
          "name" => "Daniel Lima",
          "cellphone" => "(11) 4002-8922",
          "email" => "daniel_lima@abacatepay.com",
          "taxId" => "123.456.789-01"
        }
      }

      MockHTTPServer.stub_post("/customers/create", body, expected_response)

      assert {:ok, customer} = Customer.create_customer(body)
      assert customer["id"] == @default_customer_id
      assert customer["metadata"]["name"] == "Daniel Lima"
      assert customer["metadata"]["email"] == "daniel_lima@abacatepay.com"
      assert customer["metadata"]["cellphone"] == "(11) 4002-8922"
      assert customer["metadata"]["taxId"] == "123.456.789-01"
    end

    test "handles error response when creating customer" do
      body = %{
        name: "Invalid Customer",
        email: "invalid-email"
      }

      error = MockHTTPServer.mock_error(422, "Invalid email format")
      MockHTTPServer.stub_error(:post, "/customers/create", error)

      assert {:error, returned_error} = Customer.create_customer(body)
      assert returned_error.status_code == 422
    end
  end

  describe "list_customers/0" do
    test "lists all customers successfully" do
      expected_response = [
        %{
          "id" => @default_customer_id,
          "metadata" => %{
            "name" => "Daniel Lima",
            "cellphone" => "(11) 4002-8922",
            "email" => "daniel_lima@abacatepay.com",
            "taxId" => "123.456.789-01"
          }
        },
        %{
          "id" => "cust_bcdxkhDZNaMmJeKsy0AHS0FQ",
          "metadata" => %{
            "name" => "Customer 2",
            "email" => "customer2@example.com",
            "cellphone" => "(21) 3003-7788",
            "taxId" => "987.654.321-00"
          }
        }
      ]

      MockHTTPServer.stub_get("/customers/list", expected_response)

      assert {:ok, customers} = Customer.list_customers()
      assert is_list(customers)
      assert length(customers) == 2
      assert Enum.all?(customers, &is_map/1)
    end

    test "returns empty list when no customers exist" do
      MockHTTPServer.stub_get("/customers/list", [])

      assert {:ok, customers} = Customer.list_customers()
      assert customers == []
    end

    test "handles error response when listing customers" do
      error = MockHTTPServer.mock_error(401, "Token de autenticação inválido ou ausente.")
      MockHTTPServer.stub_error(:get, "/customers/list", error)

      assert {:error, returned_error} = Customer.list_customers()
      assert returned_error.status_code == 401
    end
  end
end
