"""
Analytics Summary Routes
Aggregates sales metrics, monthly trends, AOV, and best-selling products for artisans.
Used to render summary cards and fl_chart visualizations.
Returns genuine zero data for new artisans with 0 orders/products (never fake/dummy figures).
"""
from flask import Blueprint, jsonify, request
from services.firebase_service import get_firestore_client
from datetime import datetime, timezone
from collections import defaultdict

analytics_bp = Blueprint('analytics', __name__)


def _get_zero_analytics(artisan_id: str) -> dict:
    """Genuine zero/empty analytics for an artisan with no recorded sales yet."""
    now = datetime.now(timezone.utc)
    months_order = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    current_idx = now.month - 1
    trend_months = [months_order[(current_idx - 5 + i) % 12] for i in range(6)]

    return {
        "artisan_id": artisan_id,
        "total_revenue": 0.0,
        "total_orders": 0,
        "completed_orders": 0,
        "average_order_value": 0.0,
        "revenue_this_month": 0.0,
        "revenue_last_month": 0.0,
        "revenue_growth_pct": 0.0,
        "best_selling_product": {
            "id": "",
            "title": "No sales yet",
            "units_sold": 0,
            "revenue": 0.0
        },
        "order_status_counts": {
            "pending": 0,
            "confirmed": 0,
            "shipped": 0,
            "delivered": 0,
            "cancelled": 0
        },
        "monthly_trend": [
            {"month": m, "revenue": 0.0, "orders": 0} for m in trend_months
        ],
        "category_breakdown": []
    }


@analytics_bp.route('/summary', methods=['GET'])
def get_analytics_summary():
    """
    GET /api/analytics/summary?artisan_id=<id>
    Aggregates orders and product metrics from Firestore for the given artisan.
    Returns 100% genuine zero numbers for new users without orders.
    """
    artisan_id = request.args.get('artisan_id', '').strip()
    if not artisan_id:
        return jsonify({"success": False, "error": "artisan_id query param is required"}), 400

    db = get_firestore_client()
    if not db:
        return jsonify({"success": True, "source": "zero_fallback", "data": _get_zero_analytics(artisan_id)}), 200

    try:
        # Fetch artisan's orders
        orders_query = db.collection('orders').where('artisan_id', '==', artisan_id).stream()
        orders = []
        for doc in orders_query:
            d = doc.to_dict()
            d['id'] = doc.id
            orders.append(d)

        if not orders:
            # Genuine zero baseline for new artisans without orders
            return jsonify({"success": True, "source": "firestore", "data": _get_zero_analytics(artisan_id)}), 200

        total_orders = len(orders)
        total_revenue = 0.0
        status_counts = defaultdict(int)
        product_sales = defaultdict(lambda: {"units": 0, "revenue": 0.0, "title": ""})
        
        # Track monthly revenue
        now = datetime.now(timezone.utc)
        current_month = now.month
        current_year = now.year
        prev_month = 12 if current_month == 1 else current_month - 1
        prev_year = current_year - 1 if current_month == 1 else current_year

        rev_this_month = 0.0
        rev_last_month = 0.0
        monthly_buckets = defaultdict(lambda: {"revenue": 0.0, "orders": 0})

        for o in orders:
            status = o.get('status', 'pending').lower()
            status_counts[status] += 1
            price = float(o.get('total_price', 0.0))
            qty = int(o.get('quantity', 1))
            pid = str(o.get('product_id', 'unknown'))
            ptitle = o.get('product_title') or o.get('item_name') or f"Product {pid[:6]}"

            # Only count valid commercial orders
            if status in ['confirmed', 'shipped', 'delivered', 'pending', 'paid']:
                total_revenue += price
                product_sales[pid]["units"] += qty
                product_sales[pid]["revenue"] += price
                if not product_sales[pid]["title"]:
                    product_sales[pid]["title"] = ptitle

            # Parse created_at timestamp
            cat = o.get('created_at')
            created_dt = None
            if isinstance(cat, str):
                try:
                    created_dt = datetime.fromisoformat(cat.replace('Z', '+00:00'))
                except Exception:
                    pass
            elif isinstance(cat, datetime):
                created_dt = cat

            if created_dt:
                m_label = created_dt.strftime('%b')
                monthly_buckets[m_label]["revenue"] += price
                monthly_buckets[m_label]["orders"] += 1

                if created_dt.year == current_year and created_dt.month == current_month:
                    rev_this_month += price
                elif created_dt.year == prev_year and created_dt.month == prev_month:
                    rev_last_month += price

        growth_pct = 0.0
        if rev_last_month > 0:
            growth_pct = round(((rev_this_month - rev_last_month) / rev_last_month) * 100, 1)
        elif rev_this_month > 0:
            growth_pct = 100.0

        aov = round(total_revenue / total_orders, 1) if total_orders > 0 else 0.0

        # Best selling product
        best_pid = None
        best_info = {"id": "", "title": "No sales yet", "units_sold": 0, "revenue": 0.0}
        if product_sales:
            best_pid = max(product_sales.keys(), key=lambda k: product_sales[k]["revenue"])
            b = product_sales[best_pid]
            if b["units"] > 0:
                best_info = {
                    "id": best_pid,
                    "title": b["title"] or "Handcrafted Item",
                    "units_sold": b["units"],
                    "revenue": round(b["revenue"], 1)
                }

        # Format monthly trend for the last 6 months (genuine data, 0.0 if no orders that month)
        months_order = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        current_idx = now.month - 1
        trend_months = [months_order[(current_idx - 5 + i) % 12] for i in range(6)]
        monthly_trend = []
        for m in trend_months:
            b = monthly_buckets.get(m, {"revenue": 0.0, "orders": 0})
            monthly_trend.append({
                "month": m,
                "revenue": round(b["revenue"], 1),
                "orders": b["orders"]
            })

        data = {
            "artisan_id": artisan_id,
            "total_revenue": round(total_revenue, 1),
            "total_orders": total_orders,
            "completed_orders": status_counts['delivered'],
            "average_order_value": aov,
            "revenue_this_month": round(rev_this_month, 1),
            "revenue_last_month": round(rev_last_month, 1),
            "revenue_growth_pct": growth_pct,
            "best_selling_product": best_info,
            "order_status_counts": dict(status_counts),
            "monthly_trend": monthly_trend,
            "category_breakdown": []
        }
        return jsonify({"success": True, "source": "firestore", "data": data}), 200

    except Exception as e:
        # Fallback to genuine zero response on error
        return jsonify({"success": True, "source": "zero_fallback", "data": _get_zero_analytics(artisan_id), "note": str(e)}), 200
