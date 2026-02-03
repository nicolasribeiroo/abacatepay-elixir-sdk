defmodule AbacatePay.Api.CouponTest do
  use ExUnit.Case
  use Mimic

  alias AbacatePay.Api.Coupon
  alias AbacatePay.MockHTTPServer

  @default_billing_id "bill_aebxkhDZNaMmJeKsy0AHS0FQ"

  describe "create_coupon/1" do
    test "creates a percentage discount coupon successfully" do
      body = %{
        code: "DEYVIN_20",
        discountKind: "PERCENTAGE",
        discount: 15
      }

      expected_response = %{
        "id" => "DEYVIN_20",
        "discountKind" => "PERCENTAGE",
        "discount" => 15,
        "status" => "ACTIVE",
        "notes" => nil,
        "maxRedeems" => -1,
        "redeemsCount" => 0,
        "devMode" => false,
        "metadata" => %{},
        "createdAt" => "2025-05-25T23:43:25.250Z",
        "updatedAt" => "2025-05-25T23:43:25.250Z"
      }

      MockHTTPServer.stub_post("/coupon/create", body, expected_response)

      assert {:ok, coupon} = Coupon.create_coupon(body)
      assert coupon["discountKind"] == "PERCENTAGE"
      assert coupon["discount"] == 15
    end

    test "creates a fixed amount discount coupon" do
      body = %{
        code: "SUMMER_5",
        discountKind: "FIXED",
        discount: 500
      }

      expected_response = %{
        "id" => "SUMMER_5",
        "discountKind" => "FIXED",
        "discount" => 500,
        "status" => "ACTIVE",
        "notes" => nil,
        "maxRedeems" => -1,
        "redeemsCount" => 0,
        "devMode" => false,
        "metadata" => %{},
        "createdAt" => "2025-06-15T10:20:30.400Z",
        "updatedAt" => "2025-06-15T10:20:30.400Z"
      }

      MockHTTPServer.stub_post("/coupon/create", body, expected_response)

      assert {:ok, coupon} = Coupon.create_coupon(body)
      assert coupon["discountKind"] == "FIXED"
      assert coupon["discount"] == 500
    end

    test "creates a coupon with all optional fields" do
      body = %{
        code: "FULL_COUPON",
        discountKind: "PERCENTAGE",
        discount: 25,
        notes: "Special promo coupon",
        maxRedeems: 100,
        metadata: %{
          billingId: @default_billing_id
        }
      }

      expected_response = %{
        "id" => "FULL_COUPON",
        "discountKind" => "PERCENTAGE",
        "discount" => 25,
        "status" => "ACTIVE",
        "notes" => "Special promo coupon",
        "maxRedeems" => 100,
        "redeemsCount" => 0,
        "devMode" => false,
        "metadata" => %{
          "billingId" => @default_billing_id
        },
        "createdAt" => "2025-07-01T12:00:00.000Z",
        "updatedAt" => "2025-07-01T12:00:00.000Z"
      }

      MockHTTPServer.stub_post("/coupon/create", body, expected_response)

      assert {:ok, coupon} = Coupon.create_coupon(body)
      assert coupon["notes"] == "Special promo coupon"
      assert coupon["maxRedeems"] == 100
      assert coupon["metadata"]["billingId"] == @default_billing_id
    end

    test "handles validation error with invalid discount kind" do
      body = %{
        "code" => "INVALID",
        "discountKind" => "INVALID_KIND",
        "discount" => 10
      }

      error = MockHTTPServer.mock_error(422, "Invalid discount kind")
      MockHTTPServer.stub_error(:post, "/coupon/create", error)

      assert {:error, returned_error} = Coupon.create_coupon(body)
      assert returned_error.status_code == 422
    end

    test "handles missing required fields error" do
      body = %{
        "code" => "INCOMPLETE"
      }

      error = MockHTTPServer.mock_error(400, "Missing required field: discountKind")
      MockHTTPServer.stub_error(:post, "/coupon/create", error)

      assert {:error, returned_error} = Coupon.create_coupon(body)
      assert returned_error.status_code == 400
    end

    test "handles unauthorized error" do
      body = %{
        "code" => "TEST",
        "discountKind" => "PERCENTAGE",
        "discount" => 10
      }

      error = MockHTTPServer.mock_error(401, "Unauthorized")
      MockHTTPServer.stub_error(:post, "/coupon/create", error)

      assert {:error, returned_error} = Coupon.create_coupon(body)
      assert returned_error.status_code == 401
    end

    test "handles server error" do
      body = %{
        "code" => "ERROR_TEST",
        "discountKind" => "PERCENTAGE",
        "discount" => 10
      }

      error = MockHTTPServer.mock_error(500, "Internal Server Error")
      MockHTTPServer.stub_error(:post, "/coupon/create", error)

      assert {:error, returned_error} = Coupon.create_coupon(body)
      assert returned_error.status_code == 500
    end
  end

  describe "list_coupons/0" do
    test "lists all coupons successfully" do
      expected_response = [
        %{
          "id" => "coupon_1",
          "code" => "SAVE10",
          "discountKind" => "PERCENTAGE",
          "discount" => 10
        },
        %{"id" => "coupon_2", "code" => "WELCOME5", "discountKind" => "FIXED", "discount" => 500},
        %{
          "id" => "coupon_3",
          "code" => "HOLIDAY15",
          "discountKind" => "PERCENTAGE",
          "discount" => 15
        }
      ]

      MockHTTPServer.stub_get("/coupon/list", expected_response)

      assert {:ok, coupons} = Coupon.list_coupons()
      assert is_list(coupons)
      assert length(coupons) == 3
      assert Enum.all?(coupons, &is_map/1)
    end

    test "returns complete coupon data in list" do
      expected_response = [
        %{
          "id" => "coupon_1",
          "code" => "COMPLETE_DATA",
          "discountKind" => "PERCENTAGE",
          "discount" => 10,
          "status" => "ACTIVE",
          "createdAt" => "2025-01-10T10:00:00Z",
          "updatedAt" => "2025-01-10T10:00:00Z",
          "notes" => "10% off on all items",
          "maxRedeems" => 50,
          "redeemsCount" => 5,
          "devMode" => false,
          "metadata" => %{}
        },
        %{
          "id" => "coupon_2",
          "code" => "WELCOME5",
          "discountKind" => "FIXED",
          "discount" => 500,
          "status" => "INACTIVE",
          "createdAt" => "2025-02-15T12:30:00Z",
          "updatedAt" => "2025-03-01T09:15:00Z",
          "notes" => "R$5 off for new customers",
          "maxRedeems" => 100,
          "redeemsCount" => 20,
          "devMode" => false,
          "metadata" => %{}
        },
        %{
          "id" => "coupon_3",
          "code" => "HOLIDAY15",
          "discountKind" => "PERCENTAGE",
          "discount" => 15,
          "status" => "ACTIVE",
          "createdAt" => "2025-12-01T08:00:00Z",
          "updatedAt" => "2025-12-01T08:00:00Z",
          "notes" => "15% off during holidays",
          "maxRedeems" => 200,
          "redeemsCount" => 10,
          "devMode" => false,
          "metadata" => %{}
        }
      ]

      MockHTTPServer.stub_get("/coupon/list", expected_response)

      assert {:ok, coupons} = Coupon.list_coupons()
      coupon = List.first(coupons)
      assert coupon["code"] == "COMPLETE_DATA"
      assert coupon["discountKind"] == "PERCENTAGE"
      assert coupon["discount"] == 10
      assert coupon["status"] == "ACTIVE"
    end

    test "returns empty list when no coupons exist" do
      MockHTTPServer.stub_get("/coupon/list", [])

      assert {:ok, coupons} = Coupon.list_coupons()
      assert coupons == []
    end

    test "handles coupons with different discount kinds" do
      expected_response = [
        %{"id" => "coupon_percentage", "discountKind" => "PERCENTAGE", "discount" => 20},
        %{"id" => "coupon_fixed", "discountKind" => "FIXED", "discount" => 1_000}
      ]

      MockHTTPServer.stub_get("/coupon/list", expected_response)

      assert {:ok, coupons} = Coupon.list_coupons()
      kinds = Enum.map(coupons, &Map.get(&1, "discountKind"))
      assert "PERCENTAGE" in kinds
      assert "FIXED" in kinds
    end

    test "handles coupons with different active statuses" do
      expected_response = [
        %{"id" => "coupon_active", "code" => "ACTIVE_1", "active" => true},
        %{"id" => "coupon_inactive", "code" => "INACTIVE_1", "active" => false},
        %{"id" => "coupon_active_2", "code" => "ACTIVE_2", "active" => true}
      ]

      MockHTTPServer.stub_get("/coupon/list", expected_response)

      assert {:ok, coupons} = Coupon.list_coupons()
      active_count = Enum.count(coupons, &Map.get(&1, "active"))
      inactive_count = Enum.count(coupons, fn c -> !Map.get(c, "active") end)
      assert active_count == 2
      assert inactive_count == 1
    end

    test "handles coupons with various discount values" do
      expected_response = [
        %{"id" => "coupon_1", "discount" => 1},
        %{"id" => "coupon_50", "discount" => 50},
        %{"id" => "coupon_100", "discount" => 100},
        %{"id" => "coupon_5000", "discount" => 5_000}
      ]

      MockHTTPServer.stub_get("/coupon/list", expected_response)

      assert {:ok, coupons} = Coupon.list_coupons()
      discounts = Enum.map(coupons, &Map.get(&1, "discount"))
      assert 1 in discounts
      assert 50 in discounts
      assert 100 in discounts
      assert 5_000 in discounts
    end

    test "handles error when listing coupons - unauthorized" do
      error = MockHTTPServer.mock_error(401, "Unauthorized")
      MockHTTPServer.stub_error(:get, "/coupon/list", error)

      assert {:error, returned_error} = Coupon.list_coupons()
      assert returned_error.status_code == 401
    end

    test "handles error when listing coupons - forbidden" do
      error = MockHTTPServer.mock_error(403, "Forbidden")
      MockHTTPServer.stub_error(:get, "/coupon/list", error)

      assert {:error, returned_error} = Coupon.list_coupons()
      assert returned_error.status_code == 403
    end

    test "handles error when listing coupons - server error" do
      error = MockHTTPServer.mock_error(500, "Internal Server Error")
      MockHTTPServer.stub_error(:get, "/coupon/list", error)

      assert {:error, returned_error} = Coupon.list_coupons()
      assert returned_error.status_code == 500
    end

    test "lists large number of coupons" do
      coupons_list =
        Enum.map(1..50, fn i ->
          %{
            "id" => "coupon_#{i}",
            "code" => "CODE_#{i}",
            "discount" => rem(i, 100),
            "active" => rem(i, 2) == 0
          }
        end)

      MockHTTPServer.stub_get("/coupon/list", coupons_list)

      assert {:ok, coupons} = Coupon.list_coupons()
      assert length(coupons) == 50
    end
  end
end
