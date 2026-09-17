"""
payments.py — Online payment gateway integration removed.
HunarSathi uses Cash on Delivery (COD) for all transactions.
"""
from flask import Blueprint, jsonify

payments_bp = Blueprint('payments', __name__)

@payments_bp.route('/<path:subpath>', methods=['GET', 'POST', 'PUT', 'DELETE'])
def payment_disabled(subpath):
    return jsonify({
        "success": False,
        "message": "Online payments are disabled. HunarSathi exclusively uses Cash on Delivery (COD)."
    }), 410
