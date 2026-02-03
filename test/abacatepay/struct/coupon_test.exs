defmodule AbacatePay.CouponTest do
  use ExUnit.Case

  alias AbacatePay.{Coupon, Util}

  describe "struct/0" do
    test "creates a valid Coupon struct" do
      coupon = %Coupon{
        id: "SUMMER2024",
        discount_kind: :percentage,
        discount: 10,
        max_redeems: 100,
        redeems_count: 5,
        status: :active,
        dev_mode: false,
        notes: "10% off summer",
        metadata: %{}
      }

      assert coupon.id == "SUMMER2024"
      assert coupon.discount_kind == :percentage
      assert coupon.discount == 10
      assert coupon.status == :active
    end

    test "creates Coupon with nil values" do
      coupon = %Coupon{}

      assert coupon.id == nil
      assert coupon.discount_kind == nil
      assert coupon.discount == nil
    end
  end

  describe "build_pretty_coupon/1" do
    test "builds Coupon from raw API data" do
      raw_data = %{
        "id" => "coupon_123",
        "discountKind" => "PERCENTAGE",
        "discount" => 10,
        "maxRedeems" => 100,
        "redeemsCount" => 5,
        "status" => "active",
        "devMode" => false,
        "notes" => "10% off on all products",
        "metadata" => %{"campaign" => "summer"},
        "createdAt" => "2026-01-01T00:00:00Z",
        "updatedAt" => "2026-01-10T00:00:00Z"
      }

      assert {:ok, coupon} = Coupon.build_pretty_coupon(raw_data)
      assert coupon.id == "coupon_123"
      assert coupon.discount_kind == :percentage
      assert coupon.discount == 10
      assert coupon.max_redeems == 100
      assert coupon.redeems_count == 5
      assert coupon.status == :active
      assert coupon.dev_mode == false
      assert coupon.notes == "10% off on all products"
    end

    test "handles fixed discount_kind" do
      raw_data = %{
        "id" => "coupon_fixed",
        "discountKind" => "FIXED",
        "discount" => 5000,
        "maxRedeems" => 50,
        "redeemsCount" => 0,
        "status" => "active",
        "devMode" => false,
        "notes" => "R$ 50 off",
        "metadata" => nil,
        "createdAt" => nil,
        "updatedAt" => nil
      }

      assert {:ok, coupon} = Coupon.build_pretty_coupon(raw_data)
      assert coupon.discount_kind == :fixed
      assert coupon.discount == 5000
    end

    test "handles datetime parsing" do
      raw_data = %{
        "id" => "coupon_123",
        "discountKind" => "PERCENTAGE",
        "discount" => 10,
        "maxRedeems" => 100,
        "redeemsCount" => 0,
        "status" => "active",
        "devMode" => false,
        "notes" => nil,
        "metadata" => nil,
        "createdAt" => "2026-01-15T10:30:45Z",
        "updatedAt" => "2026-01-15T10:35:45Z"
      }

      assert {:ok, coupon} = Coupon.build_pretty_coupon(raw_data)
      assert coupon.created_at != nil
      assert coupon.updated_at != nil
    end

    test "handles nil datetimes" do
      raw_data = %{
        "id" => "coupon_123",
        "discountKind" => "PERCENTAGE",
        "discount" => 10,
        "maxRedeems" => 100,
        "redeemsCount" => 0,
        "status" => "active",
        "devMode" => false,
        "notes" => nil,
        "metadata" => nil,
        "createdAt" => nil,
        "updatedAt" => nil
      }

      assert {:ok, coupon} = Coupon.build_pretty_coupon(raw_data)
      assert coupon.created_at == nil
      assert coupon.updated_at == nil
    end

    test "handles various coupon statuses" do
      statuses = ["ACTIVE", "DELETED", "DISABLED"]

      Enum.each(statuses, fn status ->
        raw_data = %{
          "id" => "coupon_#{status}",
          "discountKind" => "PERCENTAGE",
          "discount" => 10,
          "maxRedeems" => 100,
          "redeemsCount" => 0,
          "status" => status,
          "devMode" => false,
          "notes" => nil,
          "metadata" => nil,
          "createdAt" => nil,
          "updatedAt" => nil
        }

        assert {:ok, coupon} = Coupon.build_pretty_coupon(raw_data)
        assert coupon.status == Util.atomize_enum(status)
      end)
    end

    test "handles metadata object" do
      raw_data = %{
        "id" => "coupon_meta",
        "discountKind" => "PERCENTAGE",
        "discount" => 15,
        "maxRedeems" => 200,
        "redeemsCount" => 10,
        "status" => "active",
        "devMode" => false,
        "notes" => "Holiday promo",
        "metadata" => %{
          "campaign_id" => "camp_123",
          "region" => "south",
          "created_by" => "user_456"
        },
        "createdAt" => nil,
        "updatedAt" => nil
      }

      assert {:ok, coupon} = Coupon.build_pretty_coupon(raw_data)
      assert coupon.metadata["campaign_id"] == "camp_123"
      assert coupon.metadata["region"] == "south"
    end

    test "handles unlimited redeems" do
      raw_data = %{
        "id" => "coupon_unlimited",
        "discountKind" => "PERCENTAGE",
        "discount" => 5,
        "maxRedeems" => -1,
        "redeemsCount" => 1000,
        "status" => "active",
        "devMode" => false,
        "notes" => "Unlimited uses",
        "metadata" => nil,
        "createdAt" => nil,
        "updatedAt" => nil
      }

      assert {:ok, coupon} = Coupon.build_pretty_coupon(raw_data)
      assert coupon.max_redeems == -1
      assert coupon.redeems_count == 1000
    end
  end

  describe "build_api_coupon/1" do
    test "builds API map from Coupon struct" do
      coupon = %Coupon{
        id: "coupon_123",
        discount_kind: :percentage,
        discount: 10,
        max_redeems: 100,
        redeems_count: 5,
        status: :active,
        dev_mode: false,
        notes: "10% off on all products",
        metadata: %{"campaign" => "summer"},
        created_at: ~U[2026-01-01T00:00:00Z],
        updated_at: ~U[2026-01-10T00:00:00Z]
      }

      assert {:ok, api_map} = Coupon.build_api_coupon(coupon)
      assert api_map[:id] == "coupon_123"
      assert api_map[:discountKind] == "PERCENTAGE"
      assert api_map[:discount] == 10
      assert api_map[:maxRedeems] == 100
      assert api_map[:status] == "ACTIVE"
    end

    test "converts discount_kind to uppercase" do
      coupon = %Coupon{
        id: "coupon_fixed",
        discount_kind: :fixed,
        discount: 5000,
        max_redeems: 50,
        redeems_count: 0,
        status: :active,
        dev_mode: false,
        notes: nil,
        metadata: nil,
        created_at: nil,
        updated_at: nil
      }

      assert {:ok, api_map} = Coupon.build_api_coupon(coupon)
      assert api_map[:discountKind] == "FIXED"
    end

    test "handles datetime conversion to ISO8601" do
      coupon = %Coupon{
        id: "coupon_datetime",
        discount_kind: :percentage,
        discount: 10,
        max_redeems: 100,
        redeems_count: 0,
        status: :active,
        dev_mode: false,
        notes: nil,
        metadata: nil,
        created_at: ~U[2026-01-15T10:30:45Z],
        updated_at: ~U[2026-01-15T10:35:45Z]
      }

      assert {:ok, api_map} = Coupon.build_api_coupon(coupon)
      assert String.contains?(api_map[:createdAt], "2026-01-15")
      assert String.contains?(api_map[:updatedAt], "2026-01-15")
    end

    test "handles nil datetimes in API format" do
      coupon = %Coupon{
        id: "coupon_nil",
        discount_kind: :percentage,
        discount: 10,
        max_redeems: 100,
        redeems_count: 0,
        status: :active,
        dev_mode: false,
        notes: nil,
        metadata: nil,
        created_at: nil,
        updated_at: nil
      }

      assert {:ok, api_map} = Coupon.build_api_coupon(coupon)
      assert api_map[:createdAt] == nil
      assert api_map[:updatedAt] == nil
    end
  end

  describe "roundtrip conversion" do
    test "converts raw data to struct and back" do
      raw_data = %{
        "id" => "coupon_roundtrip",
        "discountKind" => "PERCENTAGE",
        "discount" => 20,
        "maxRedeems" => 500,
        "redeemsCount" => 50,
        "status" => "ACTIVE",
        "devMode" => false,
        "notes" => "Roundtrip coupon",
        "metadata" => %{"test" => "value"},
        "createdAt" => "2026-01-15T10:30:45Z",
        "updatedAt" => "2026-01-15T10:35:45Z"
      }

      assert {:ok, coupon} = Coupon.build_pretty_coupon(raw_data)
      assert {:ok, api_map} = Coupon.build_api_coupon(coupon)

      assert api_map[:id] == raw_data["id"]
      assert api_map[:discount] == raw_data["discount"]
      assert api_map[:maxRedeems] == raw_data["maxRedeems"]
    end
  end
end
