defmodule AbacatePay.ProductTest do
  use ExUnit.Case

  alias AbacatePay.Product

  describe "struct/0" do
    test "creates a valid Product struct" do
      product = %Product{
        external_id: "prod_12345",
        quantity: 2,
        price: 1500,
        description: "Test product description",
        name: "Test Product"
      }

      assert product.external_id == "prod_12345"
      assert product.quantity == 2
      assert product.price == 1500
      assert product.description == "Test product description"
      assert product.name == "Test Product"
    end

    test "creates Product with nil values" do
      product = %Product{}

      assert product.external_id == nil
      assert product.quantity == nil
      assert product.price == nil
      assert product.description == nil
      assert product.name == nil
    end
  end

  describe "build_pretty_product/1" do
    test "builds Product from raw API data" do
      raw_data = %{
        "externalId" => "prod_12345",
        "quantity" => 2,
        "price" => 1500,
        "description" => "Test product description",
        "name" => "Test Product"
      }

      assert {:ok, product} = Product.build_pretty_product(raw_data)
      assert product.external_id == "prod_12345"
      assert product.quantity == 2
      assert product.price == 1500
      assert product.description == "Test product description"
      assert product.name == "Test Product"
    end

    test "handles missing description" do
      raw_data = %{
        "externalId" => "prod_12345",
        "quantity" => 2,
        "price" => 1500,
        "name" => "Test Product"
      }

      assert {:ok, product} = Product.build_pretty_product(raw_data)
      assert product.description == nil
    end

    test "handles zero quantity" do
      raw_data = %{
        "externalId" => "prod_12345",
        "quantity" => 0,
        "price" => 1500,
        "name" => "Test Product"
      }

      assert {:ok, product} = Product.build_pretty_product(raw_data)
      assert product.quantity == 0
    end

    test "handles large values" do
      raw_data = %{
        "externalId" => "prod_12345",
        "quantity" => 1000,
        "price" => 999_999_999,
        "name" => "Expensive Product"
      }

      assert {:ok, product} = Product.build_pretty_product(raw_data)
      assert product.quantity == 1000
      assert product.price == 999_999_999
    end

    test "handles special characters in strings" do
      raw_data = %{
        "externalId" => "prod-2024_special!",
        "quantity" => 1,
        "price" => 1000,
        "description" => "Product with € symbol",
        "name" => "Special Product #1"
      }

      assert {:ok, product} = Product.build_pretty_product(raw_data)
      assert product.external_id == "prod-2024_special!"
      assert String.contains?(product.description, "€")
    end
  end

  describe "build_api_product/1" do
    test "builds API map from Product struct" do
      product = %Product{
        external_id: "prod_12345",
        quantity: 2,
        price: 1500,
        description: "Test product description",
        name: "Test Product"
      }

      assert {:ok, api_map} = Product.build_api_product(product)
      assert api_map[:externalId] == "prod_12345"
      assert api_map[:quantity] == 2
      assert api_map[:price] == 1500
      assert api_map[:description] == "Test product description"
      assert api_map[:name] == "Test Product"
    end

    test "handles nil description" do
      product = %Product{
        external_id: "prod_12345",
        quantity: 1,
        price: 1000,
        description: nil,
        name: "Test Product"
      }

      assert {:ok, api_map} = Product.build_api_product(product)
      assert api_map[:description] == nil
    end

    test "preserves all field values" do
      product = %Product{
        external_id: "prod_ABC",
        quantity: 10,
        price: 50000,
        description: "Premium product",
        name: "Premium"
      }

      assert {:ok, api_map} = Product.build_api_product(product)
      assert map_size(api_map) == 5
    end
  end

  describe "roundtrip conversion" do
    test "converts raw data to struct and back to API format" do
      raw_data = %{
        "externalId" => "prod_roundtrip",
        "quantity" => 5,
        "price" => 2500,
        "description" => "Roundtrip test",
        "name" => "Test Product"
      }

      assert {:ok, product} = Product.build_pretty_product(raw_data)
      assert {:ok, api_map} = Product.build_api_product(product)

      assert api_map[:externalId] == raw_data["externalId"]
      assert api_map[:quantity] == raw_data["quantity"]
      assert api_map[:price] == raw_data["price"]
      assert api_map[:description] == raw_data["description"]
      assert api_map[:name] == raw_data["name"]
    end
  end
end
