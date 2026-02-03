defmodule AbacatePay.Schema.CouponTest do
  use ExUnit.Case

  alias AbacatePay.Schema.Coupon

  describe "create_coupon_request/0" do
    test "returns a valid schema definition" do
      schema = Coupon.create_coupon_request()
      assert is_list(schema)
      assert Enum.all?(schema, fn {_key, opts} -> is_list(opts) end)
    end

    test "validates with required fields only" do
      data = [
        code: "DEYVIN_20",
        discount_kind: :percentage,
        discount: 10
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      assert result[:code] == "DEYVIN_20"
      assert result[:discount_kind] == :percentage
      assert result[:discount] == 10
    end

    test "rejects missing code" do
      data = [
        discount_kind: :percentage,
        discount: 10
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Coupon.create_coupon_request())

      assert key == :code
    end

    test "rejects missing discount_kind" do
      data = [
        code: "DEYVIN_20",
        discount: 10
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Coupon.create_coupon_request())

      assert key == :discount_kind
    end

    test "rejects missing discount" do
      data = [
        code: "DEYVIN_20",
        discount_kind: :percentage
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Coupon.create_coupon_request())

      assert key == :discount
    end

    test "accepts percentage discount_kind" do
      data = [
        code: "DEYVIN_20",
        discount_kind: :percentage,
        discount: 10
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      assert result[:discount_kind] == :percentage
    end

    test "accepts fixed discount_kind" do
      data = [
        code: "DEYVIN_20",
        discount_kind: :fixed,
        discount: 5_000
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      assert result[:discount_kind] == :fixed
    end

    test "rejects invalid discount_kind" do
      data = [
        code: "DEYVIN_20",
        discount_kind: :invalid,
        discount: 10
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Coupon.create_coupon_request())

      assert key == :discount_kind
    end

    test "rejects non-string code" do
      data = [
        code: 12_345,
        discount_kind: :percentage,
        discount: 10
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Coupon.create_coupon_request())

      assert key == :code
    end

    test "accepts various discount values for fixed" do
      valid_discounts = [1, 100, 1_000, 10_000, 100_000, 1_000_000]

      Enum.each(valid_discounts, fn discount ->
        data = [
          code: "COUPON",
          discount_kind: :fixed,
          discount: discount
        ]

        assert {:ok, _} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      end)
    end

    test "rejects non-integer discount" do
      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: "10"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Coupon.create_coupon_request())

      assert key == :discount
    end

    test "rejects float discount" do
      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: 10.5
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Coupon.create_coupon_request())

      assert key == :discount
    end

    test "accepts optional notes" do
      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: 10,
        notes: "Summer promotion 2024"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      assert result[:notes] == "Summer promotion 2024"
    end

    test "accepts empty notes" do
      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: 10,
        notes: ""
      ]

      assert {:ok, _} = NimbleOptions.validate(data, Coupon.create_coupon_request())
    end

    test "accepts long notes" do
      long_notes = String.duplicate("x", 1_000)

      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: 10,
        notes: long_notes
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      assert result[:notes] == long_notes
    end

    test "rejects non-string notes" do
      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: 10,
        notes: 12_345
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Coupon.create_coupon_request())

      assert key == :notes
    end

    test "accepts optional max_redeems" do
      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: 10,
        max_redeems: 100
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      assert result[:max_redeems] == 100
    end

    test "rejects float max_redeems" do
      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: 10,
        max_redeems: 100.5
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Coupon.create_coupon_request())

      assert key == :max_redeems
    end

    test "accepts optional metadata map" do
      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: 10,
        metadata: %{campaign_id: "123", region: "south"}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      assert result[:metadata] == %{campaign_id: "123", region: "south"}
    end

    test "accepts empty metadata map" do
      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: 10,
        metadata: %{}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      assert result[:metadata] == %{}
    end

    test "accepts metadata with various types" do
      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: 10,
        metadata: %{
          string: "value",
          number: 123,
          float: 45.67,
          list: [1, 2, 3]
        }
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      assert is_map(result[:metadata])
    end

    test "rejects non-map metadata" do
      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: 10,
        metadata: "not a map"
      ]

      assert {:error, %NimbleOptions.ValidationError{key: key}} =
               NimbleOptions.validate(data, Coupon.create_coupon_request())

      assert key == :metadata
    end

    test "accepts all fields together" do
      data = [
        code: "SUMMER2024",
        discount_kind: :percentage,
        discount: 15,
        notes: "Summer promo",
        max_redeems: 1_000,
        metadata: %{campaign: "summer"}
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      assert result[:code] == "SUMMER2024"
      assert result[:discount_kind] == :percentage
      assert result[:discount] == 15
      assert result[:notes] == "Summer promo"
      assert result[:max_redeems] == 1_000
    end

    test "handles special characters in code" do
      data = [
        code: "CODE-2024_SPECIAL",
        discount_kind: :percentage,
        discount: 10
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      assert result[:code] == "CODE-2024_SPECIAL"
    end

    test "handles special characters in notes" do
      data = [
        code: "COUPON",
        discount_kind: :percentage,
        discount: 10,
        notes: "Black Friday! €50 off. Use: #code-2024"
      ]

      assert {:ok, result} = NimbleOptions.validate(data, Coupon.create_coupon_request())
      assert String.contains?(result[:notes], ["€", "#"])
    end
  end
end
