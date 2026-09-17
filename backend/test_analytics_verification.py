import json
import urllib.request

BASE_URL = "http://127.0.0.1:5000"

def test_new_artisan_zero_data():
    print("\n" + "="*70)
    print("TEST 1: BRAND NEW ARTISAN (Zero Data Verification)")
    print("="*70)

    artisan_id = "test_new_artisan_brand_new"
    url = f"{BASE_URL}/api/analytics/summary?artisan_id={artisan_id}"
    
    with urllib.request.urlopen(url) as resp:
        res = json.loads(resp.read().decode('utf-8'))
        print("Response status:", resp.status)
        print("Success:", res.get("success"))
        data = res.get("data", {})
        print("Data:\n", json.dumps(data, indent=2, ensure_ascii=False))

        assert data["total_revenue"] == 0.0, f"Expected 0.0, got {data['total_revenue']}"
        assert data["total_orders"] == 0, f"Expected 0, got {data['total_orders']}"
        assert data["completed_orders"] == 0, f"Expected 0, got {data['completed_orders']}"
        assert data["average_order_value"] == 0.0, f"Expected 0.0, got {data['average_order_value']}"
        assert data["revenue_this_month"] == 0.0, f"Expected 0.0, got {data['revenue_this_month']}"
        assert data["revenue_growth_pct"] == 0.0, f"Expected 0.0, got {data['revenue_growth_pct']}"
        assert data["best_selling_product"]["title"] == "No sales yet", f"Expected 'No sales yet', got {data['best_selling_product']['title']}"
        assert data["best_selling_product"]["units_sold"] == 0, f"Expected 0, got {data['best_selling_product']['units_sold']}"
        assert all(m["revenue"] == 0.0 and m["orders"] == 0 for m in data["monthly_trend"]), "All trend bars must be 0 for new user"
        assert all(count == 0 for count in data["order_status_counts"].values()), "All order status counts must be 0"

    # Also test trust score endpoint for new user
    trust_url = f"{BASE_URL}/api/users/{artisan_id}/trust-score"
    with urllib.request.urlopen(trust_url) as resp:
        tres = json.loads(resp.read().decode('utf-8'))
        tdata = tres.get("data", {})
        print("\nTrust Score Data:\n", json.dumps(tdata, indent=2, ensure_ascii=False))
        assert tdata["trust_score"] == 0.0, f"Expected 0.0 trust score, got {tdata['trust_score']}"
        assert tdata["rating"] == 0.0, f"Expected 0.0 rating, got {tdata['rating']}"
        assert tdata["ratings_count"] == 0, f"Expected 0 ratings count, got {tdata['ratings_count']}"
        assert "New Artisan" in tdata["badge"], f"Expected New Artisan badge, got {tdata['badge']}"

    print("\n>>> TEST 1 PASSED: Brand new artisan receives 100% genuine zero numbers with ZERO dummy/mock values.")


def test_existing_artisan_real_data():
    print("\n" + "="*70)
    print("TEST 2: EXISTING ARTISAN (Real 2-orders, ₹700 Revenue Verification)")
    print("="*70)

    artisan_id = "XatExY7HGxd71WbhBoHiF7wMuVm2"
    url = f"{BASE_URL}/api/analytics/summary?artisan_id={artisan_id}"
    
    with urllib.request.urlopen(url) as resp:
        res = json.loads(resp.read().decode('utf-8'))
        print("Response status:", resp.status)
        print("Success:", res.get("success"))
        data = res.get("data", {})
        print("Data:\n", json.dumps(data, indent=2, ensure_ascii=False))

        assert data["total_revenue"] == 700.0, f"Expected 700.0, got {data['total_revenue']}"
        assert data["total_orders"] == 2, f"Expected 2, got {data['total_orders']}"
        assert data["completed_orders"] == 2, f"Expected 2, got {data['completed_orders']}"
        assert data["average_order_value"] == 350.0, f"Expected 350.0, got {data['average_order_value']}"
        assert data["revenue_this_month"] == 700.0, f"Expected 700.0, got {data['revenue_this_month']}"
        assert data["best_selling_product"]["units_sold"] == 2, f"Expected 2 units, got {data['best_selling_product']['units_sold']}"
        assert data["best_selling_product"]["revenue"] == 700.0, f"Expected 700.0, got {data['best_selling_product']['revenue']}"

    print("\n>>> TEST 2 PASSED: Existing artisan data correctly displays exact real numbers (₹700, 2 orders, 2 units).")


if __name__ == "__main__":
    test_new_artisan_zero_data()
    test_existing_artisan_real_data()
    print("\n" + "="*70)
    print("ALL ANALYTICS TESTS PASSED!")
    print("="*70)
