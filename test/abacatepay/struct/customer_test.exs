defmodule AbacatePay.CustomerTest do
  use ExUnit.Case

  alias AbacatePay.Customer

  describe "struct/0" do
    test "creates a valid Customer struct" do
      customer = %Customer{
        id: "cust_aebxkhDZNaMmJeKsy0AHS0FQ",
        name: "Daniel Lima",
        cellphone: "(11) 4002-8922",
        tax_id: "123.456.789-01",
        email: "daniel_lima@abacatepay.com"
      }

      assert customer.id == "cust_aebxkhDZNaMmJeKsy0AHS0FQ"
      assert customer.name == "Daniel Lima"
      assert customer.cellphone == "(11) 4002-8922"
      assert customer.tax_id == "123.456.789-01"
      assert customer.email == "daniel_lima@abacatepay.com"
    end

    test "creates Customer with nil values" do
      customer = %Customer{}

      assert customer.id == nil
      assert customer.name == nil
      assert customer.cellphone == nil
      assert customer.tax_id == nil
      assert customer.email == nil
    end
  end

  describe "build_pretty_customer/1" do
    test "builds Customer from raw API data" do
      raw_data = %{
        "id" => "cust_aebxkhDZNaMmJeKsy0AHS0FQ",
        "metadata" => %{
          "name" => "Daniel Lima",
          "cellphone" => "(11) 4002-8922",
          "taxId" => "123.456.789-01",
          "email" => "daniel_lima@abacatepay.com"
        }
      }

      assert {:ok, customer} = Customer.build_pretty_customer(raw_data)
      assert customer.id == "cust_aebxkhDZNaMmJeKsy0AHS0FQ"
      assert customer.name == "Daniel Lima"
      assert customer.cellphone == "(11) 4002-8922"
      assert customer.tax_id == "123.456.789-01"
      assert customer.email == "daniel_lima@abacatepay.com"
    end

    test "handles missing metadata fields" do
      raw_data = %{
        "id" => "cust_aebxkhDZNaMmJeKsy0AHS0FQ",
        "metadata" => %{
          "email" => "daniel_lima@abacatepay.com"
        }
      }

      assert {:ok, customer} = Customer.build_pretty_customer(raw_data)
      assert customer.id == "cust_aebxkhDZNaMmJeKsy0AHS0FQ"
      assert customer.name == nil
      assert customer.cellphone == nil
      assert customer.tax_id == nil
      assert customer.email == "daniel_lima@abacatepay.com"
    end

    test "handles missing metadata entirely" do
      raw_data = %{
        "id" => "cust_aebxkhDZNaMmJeKsy0AHS0FQ"
      }

      assert {:ok, customer} = Customer.build_pretty_customer(raw_data)
      assert customer.id == "cust_aebxkhDZNaMmJeKsy0AHS0FQ"
      assert customer.name == nil
      assert customer.cellphone == nil
      assert customer.tax_id == nil
      assert customer.email == nil
    end

    test "handles various phone formats" do
      raw_data = %{
        "id" => "cust_aebxkhDZNaMmJeKsy0AHS0FQ",
        "metadata" => %{
          "cellphone" => "+55 (11) 4002-8922",
          "email" => "daniel_lima@abacatepay.com"
        }
      }

      assert {:ok, customer} = Customer.build_pretty_customer(raw_data)
      assert customer.cellphone == "+55 (11) 4002-8922"
    end

    test "handles various tax_id formats" do
      raw_data = %{
        "id" => "cust_aebxkhDZNaMmJeKsy0AHS0FQ",
        "metadata" => %{
          "taxId" => "12.345.678/0001-90",
          "email" => "daniel_lima@abacatepay.com"
        }
      }

      assert {:ok, customer} = Customer.build_pretty_customer(raw_data)
      assert customer.tax_id == "12.345.678/0001-90"
    end

    test "handles special characters in name" do
      raw_data = %{
        "id" => "cust_aebxkhDZNaMmJeKsy0AHS0FQ",
        "metadata" => %{
          "name" => "José María da Silva",
          "email" => "jose@example.com"
        }
      }

      assert {:ok, customer} = Customer.build_pretty_customer(raw_data)
      assert customer.name == "José María da Silva"
    end
  end

  describe "build_api_customer/1" do
    test "builds API map from Customer struct" do
      customer = %Customer{
        id: "cust_aebxkhDZNaMmJeKsy0AHS0FQ",
        name: "Daniel Lima",
        cellphone: "(11) 4002-8922",
        email: "daniel_lima@abacatepay.com",
        tax_id: "123.456.789-01"
      }

      assert {:ok, api_map} = Customer.build_api_customer(customer)
      assert api_map[:id] == "cust_aebxkhDZNaMmJeKsy0AHS0FQ"
      assert api_map[:metadata][:name] == "Daniel Lima"
      assert api_map[:metadata][:cellphone] == "(11) 4002-8922"
      assert api_map[:metadata][:taxId] == "123.456.789-01"
      assert api_map[:metadata][:email] == "daniel_lima@abacatepay.com"
    end

    test "handles nil optional fields" do
      customer = %Customer{
        id: "cust_aebxkhDZNaMmJeKsy0AHS0FQ",
        name: nil,
        cellphone: nil,
        tax_id: nil,
        email: "daniel_lima@abacatepay.com"
      }

      assert {:ok, api_map} = Customer.build_api_customer(customer)
      assert api_map[:metadata][:name] == nil
      assert api_map[:metadata][:cellphone] == nil
      assert api_map[:metadata][:taxId] == nil
      assert api_map[:metadata][:email] == "daniel_lima@abacatepay.com"
    end

    test "preserves all metadata fields" do
      customer = %Customer{
        id: "cust_aebxkhDZNaMmJeKsy0AHS0FQ",
        name: "Daniel Lima",
        cellphone: "+55 (11) 99999-9999",
        tax_id: "123.456.789-01",
        email: "daniel_lima@abacatepay.com"
      }

      assert {:ok, api_map} = Customer.build_api_customer(customer)
      assert map_size(api_map) == 2
      assert map_size(api_map[:metadata]) == 4
    end
  end

  describe "roundtrip conversion" do
    test "converts raw data to struct and back to API format" do
      raw_data = %{
        "id" => "cust_aebxkhDZNaMmJeKsy0AHS0FQ",
        "metadata" => %{
          "name" => "Daniel Lima",
          "cellphone" => "(11) 4002-8922",
          "taxId" => "123.456.789-01",
          "email" => "daniel_lima@abacatepay.com"
        }
      }

      assert {:ok, customer} = Customer.build_pretty_customer(raw_data)
      assert {:ok, api_map} = Customer.build_api_customer(customer)

      assert api_map[:id] == raw_data["id"]
      assert api_map[:metadata][:name] == raw_data["metadata"]["name"]
      assert api_map[:metadata][:cellphone] == raw_data["metadata"]["cellphone"]
      assert api_map[:metadata][:taxId] == raw_data["metadata"]["taxId"]
      assert api_map[:metadata][:email] == raw_data["metadata"]["email"]
    end

    test "handles partial metadata in roundtrip" do
      raw_data = %{
        "id" => "cust_aebxkhDZNaMmJeKsy0AHS0FQ",
        "metadata" => %{
          "email" => "daniel_lima@abacatepay.com"
        }
      }

      assert {:ok, customer} = Customer.build_pretty_customer(raw_data)
      assert {:ok, api_map} = Customer.build_api_customer(customer)

      assert api_map[:id] == raw_data["id"]
      assert api_map[:metadata][:email] == raw_data["metadata"]["email"]
      assert api_map[:metadata][:name] == nil
    end
  end
end
