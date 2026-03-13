// lib/presentation/pages/orders/order_details_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../api/services/order_service.dart';
import '../../../core/models/order_model.dart';
import '../../../config/theme.dart';
import '../shared/custom_app_bar.dart';
import 'widgets/order_item_card.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import '../../../constants/cancel_reasons.dart';
import 'package:go_router/go_router.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final double? codChargePerItem;

  const OrderDetailsPage({
    Key? key,
    required this.orderId,
    this.codChargePerItem,
  }) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final OrderService _orderService = OrderService();
  OrderModel? _order;
  bool _isLoading = true;
  String? _error;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result =
          await _orderService.getOrderDetails(int.parse(widget.orderId));
      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _order = OrderModel.fromJson(result['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load order details';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading order';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder() async {
    if (_order == null || !_order!.canBeCancelled) {
      _showSnack('This order cannot be cancelled');
      return;
    }

    String selectedReason = cancelReasons.first.value;
    final TextEditingController noteController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red.shade600, size: 22),
              const SizedBox(width: 8),
              const Text('Cancel Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Reason for cancellation',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: cancelReasons
                      .map((r) => DropdownMenuItem<String>(
                            value: r.value,
                            child: Text(r.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedReason = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Additional note (optional)',
                    hintText: 'Any details…',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Order'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    final result = await _orderService.cancelOrder(
      orderId: _order!.id,
      reason: selectedReason,
      note: noteController.text.trim(),
    );
    setState(() => _isProcessing = false);
    if (!mounted) return;

    if (result['success']) {
      _showSnack('Order cancelled successfully');
      _loadOrderDetails();
    } else {
      _showSnack(result['message'] ?? 'Cancellation failed');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ✅ FIXED: Sum each item's individual cod_charge using fold
  double get _totalCodCharge {
    if (_order == null || !_order!.isCODOrder) return 0.0;

    // Primary: fold each item's cod_charge from API response
    final fromItems = _order!.items.fold(
      0.0,
      (sum, item) => sum + (item.codCharge ?? 0.0),
    );
    if (fromItems > 0) return fromItems;

    // Fallback 1: model-level totalCodCharge field
    if (_order!.totalCodCharge > 0) return _order!.totalCodCharge;

    // Fallback 2: passed-in codChargePerItem × number of items
    if ((widget.codChargePerItem ?? 0.0) > 0) {
      return _order!.items.length * widget.codChargePerItem!;
    }

    return 0.0;
  }

  // ✅ Grand total = API total_amount + COD charges
  double get _grandTotal {
    if (_order == null) return 0.0;
    return _order!.totalAmount + _totalCodCharge;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar(
        title:
            _order != null ? 'Order #${_order!.orderNumber}' : 'Order Details',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () => context.push('/contact'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const LogoLoader(),
          const SizedBox(height: 16),
          Text('Loading order details…',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
        ]),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 60),
            const SizedBox(height: 16),
            const Text('Failed to load order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrderDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white),
            ),
          ]),
        ),
      );
    }

    if (_order == null) return const Center(child: Text('Order not found'));

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadOrderDetails,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusTimeline(),
                const SizedBox(height: 16),
                _buildOrderItemsCard(),
                const SizedBox(height: 16),
                _buildPriceDetailsCard(),
                const SizedBox(height: 16),
                if (_order!.shippingAddress != null)
                  _buildShippingAddressCard(),
                const SizedBox(height: 16),
                if (_order!.payment != null) _buildPaymentInfoCard(),
                if (_order!.shipping != null) ...[
                  const SizedBox(height: 16),
                  _buildShippingInfoCard(),
                ],
              ],
            ),
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.45),
            child: const Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  LogoLoader(),
                  SizedBox(height: 16),
                  Text('Processing…',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ])),
          ),
        if (_order!.canBeCancelled)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCancelButton(),
          ),
      ],
    );
  }

  // ── Status Timeline ─────────────────────────────────────────────────────────
  Widget _buildStatusTimeline() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _iconBox(Icons.timeline_rounded, AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Status',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('Placed on ${_order!.formattedCreatedDate}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ]),
            ),
            _statusBadge(),
          ]),
          const SizedBox(height: 20),
          _buildTimelineSteps(),
          if (_order!.status.toLowerCase() == 'pending' &&
              _order!.payment?.isPaid != true) ...[
            const SizedBox(height: 14),
            _buildPaymentWarning(),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge() {
    final s = _order!.status.toLowerCase();
    Color c;
    IconData icon;
    switch (s) {
      case 'delivered':
        c = const Color(0xFF2E7D32);
        icon = Icons.check_circle_rounded;
        break;
      case 'shipped':
        c = Colors.blue;
        icon = Icons.local_shipping_rounded;
        break;
      case 'processing':
        c = Colors.purple;
        icon = Icons.settings_rounded;
        break;
      case 'confirmed':
        c = Colors.lightBlue;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'pending':
        c = Colors.orange;
        icon = Icons.schedule_rounded;
        break;
      case 'cancelled':
        c = Colors.red;
        icon = Icons.cancel_rounded;
        break;
      default:
        c = Colors.grey;
        icon = Icons.help_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 6),
        Text(
          _order!.status[0].toUpperCase() + _order!.status.substring(1),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c),
        ),
      ]),
    );
  }

  Widget _buildTimelineSteps() {
    final steps = _getTimelineSteps();
    return Column(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final step = e.value;
        final isLast = i == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      step['isCompleted'] ? AppTheme.primaryGradient : null,
                  color: step['isCompleted'] ? null : Colors.grey.shade200,
                  border: Border.all(
                    color: step['isCompleted']
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: step['isCompleted']
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient:
                        step['isCompleted'] ? AppTheme.primaryGradient : null,
                    color: step['isCompleted'] ? null : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 2),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step['title'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: step['isCompleted']
                                ? AppTheme.primaryColor
                                : Colors.grey.shade500,
                          )),
                      if (step['subtitle'] != null) ...[
                        const SizedBox(height: 2),
                        Text(step['subtitle'],
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ]),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getTimelineSteps() {
    final s = _order!.status.toLowerCase();
    if (s == 'cancelled') {
      return [
        {
          'title': 'Order Placed',
          'subtitle': 'Order was received',
          'isCompleted': true
        },
        {
          'title': 'Order Cancelled',
          'subtitle': 'Order has been cancelled',
          'isCompleted': true
        },
      ];
    }
    if (s == 'returned') {
      return [
        {
          'title': 'Order Placed',
          'subtitle': 'Order was received',
          'isCompleted': true
        },
        {
          'title': 'Delivered',
          'subtitle': 'Order was delivered',
          'isCompleted': true
        },
        {
          'title': 'Returned',
          'subtitle': 'Order returned',
          'isCompleted': true
        },
      ];
    }
    return [
      {
        'title': 'Order Placed',
        'subtitle': 'Placed on ${_order!.formattedCreatedDate}',
        'isCompleted': true
      },
      {
        'title': 'Order Confirmed',
        'subtitle': _order!.payment?.isPaid == true
            ? 'Payment confirmed'
            : 'Awaiting payment confirmation',
        'isCompleted':
            ['confirmed', 'processing', 'shipped', 'delivered'].contains(s),
      },
      {
        'title': 'Processing',
        'subtitle': 'Preparing your order',
        'isCompleted': ['processing', 'shipped', 'delivered'].contains(s),
      },
      {
        'title': 'Shipped',
        'subtitle': _order!.shipping?.courierName != null
            ? 'Via ${_order!.shipping!.courierName}'
            : 'Out for delivery',
        'isCompleted': ['shipped', 'delivered'].contains(s),
      },
      {
        'title': 'Delivered',
        'subtitle': 'Delivered successfully',
        'isCompleted': s == 'delivered'
      },
    ];
  }

  Widget _buildPaymentWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded,
            color: Colors.amber.shade700, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Payment pending — your order is awaiting confirmation.',
            style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
          ),
        ),
      ]),
    );
  }

  // ── Order Items Card ─────────────────────────────────────────────────────────
  Widget _buildOrderItemsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _iconBox(Icons.shopping_bag_outlined, AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text(
              'Order Items (${_order!.items.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 16),
          ..._order!.items.map((item) => _buildOrderItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    final hasDiscount = item.hasDiscount;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.image != null
                ? Image.network(item.image!,
                    width: 64,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _itemImagePlaceholder())
                : _itemImagePlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (item.sku != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      'SKU: ${item.sku}',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                if (item.variantValues != null &&
                    item.variantValues!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: item.variantValues!.entries
                        .map((e) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('${e.key}: ${e.value}',
                                  style: const TextStyle(fontSize: 10)),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Qty: ${item.quantity}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            '₹${item.mrp.round()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Row(children: [
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (b) =>
                                  AppTheme.primaryGradient.createShader(b),
                              child: Text(
                                '₹${item.effectivePrice.round()}',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${item.discountPercent}% OFF',
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ]),
                        ] else ...[
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (b) =>
                                AppTheme.primaryGradient.createShader(b),
                            child: Text(
                              '₹${item.effectivePrice.round()}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                        Text(
                          'Total: ₹${item.totalValue.round()}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemImagePlaceholder() {
    return Container(
      width: 64,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_outlined, size: 28, color: Colors.grey.shade300),
    );
  }

  // ── Price Details Card ───────────────────────────────────────────────────────
  Widget _buildPriceDetailsCard() {
    final subtotal = _order!.subtotal;
    final discount = _order!.discountAmount ?? _order!.discount;
    final shipping = _order!.shipping?.shippingCost;
    final isCOD = _order!.isCODOrder;
    final codCharge = _totalCodCharge;
    // ✅ Grand total = items total + all COD charges
    final grandTotal = _grandTotal;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _iconBox(Icons.receipt_long_rounded, AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('Price Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),

          if (subtotal != null) _priceRow('Subtotal', '₹${subtotal.round()}'),
          if (shipping != null)
            _priceRow(
              'Delivery Charges',
              shipping > 0 ? '₹${shipping.round()}' : 'FREE',
              valueColor: shipping == 0 ? Colors.green : null,
            ),
          if (discount != null && discount > 0)
            _priceRow(
              'Coupon Discount',
              '− ₹${discount.round()}',
              valueColor: Colors.green,
            ),
          if (_order!.promoCode != null && _order!.promoCode!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Row(children: [
                Icon(Icons.local_offer_rounded,
                    size: 13, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    _order!.promoCode!,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade700),
                  ),
                ),
              ]),
            ),
          // ✅ COD charges row — shown if COD order
          if (isCOD && codCharge > 0)
            _priceRow(
              'COD Charges',
              '+ ₹${codCharge.round()}',
              valueColor: Colors.red.shade600,
              highlight: true,
            ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),

          // ✅ Grand total includes COD
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Amount',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (isCOD && codCharge > 0)
                    Text(
                      'incl. ₹${codCharge.round()} COD',
                      style:
                          TextStyle(fontSize: 11, color: Colors.red.shade400),
                    ),
                ],
              ),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: Text(
                  '₹${grandTotal.round()}',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value,
      {Color? valueColor, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          Text(value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.grey.shade800,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    );
  }

  // ── Shipping Address Card ────────────────────────────────────────────────────
  Widget _buildShippingAddressCard() {
    final addr = _order!.shippingAddress!;
    return _buildCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _iconBox(Icons.location_on_rounded, AppTheme.primaryColor),
          const SizedBox(width: 12),
          const Text('Shipping Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(addr.fullName,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(addr.fullAddress,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 6),
            _infoRow(Icons.phone_outlined, addr.phone),
            if (addr.email.isNotEmpty)
              _infoRow(Icons.email_outlined, addr.email),
          ]),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Flexible(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
      ]),
    );
  }

  // ── Payment Info Card ────────────────────────────────────────────────────────
  Widget _buildPaymentInfoCard() {
    final payment = _order!.payment!;
    final isCOD = payment.isCOD;
    final codCharge = _totalCodCharge;

    // ✅ For COD: amount paid = API amount_paid + COD charges
    // For online: amount paid = as returned by API
    double displayAmountPaid = payment.amountPaid ?? 0.0;
    if (isCOD && codCharge > 0 && displayAmountPaid > 0) {
      displayAmountPaid = displayAmountPaid + codCharge;
    }
    // If COD and nothing paid yet (pay on delivery), show grand total as payable
    final bool isCODUnpaid = isCOD && !payment.isPaid;
    final double codPayableOnDelivery = isCODUnpaid ? _grandTotal : 0.0;

    // Determine status label & color
    String displayStatus;
    Color statusColor;
    if (isCOD) {
      if (!payment.isPaid) {
        displayStatus = 'Pay on Delivery';
        statusColor = Colors.orange;
      } else {
        displayStatus = 'Paid';
        statusColor = Colors.green;
      }
    } else {
      displayStatus = payment.displayStatus;
      statusColor = payment.isPaid
          ? Colors.green
          : payment.isFailed
              ? Colors.red
              : Colors.orange;
    }

    return _buildCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _iconBox(Icons.payment_rounded, AppTheme.primaryColor),
          const SizedBox(width: 12),
          const Text('Payment Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(children: [
            // Payment method row
            _paymentRow(
              'Payment Method',
              Row(children: [
                Icon(
                  isCOD ? Icons.payments_rounded : Icons.credit_card_rounded,
                  size: 16,
                  color: isCOD ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 6),
                Text(
                  payment.method.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
            const SizedBox(height: 10),

            // Status row
            _paymentRow(
              'Status',
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  displayStatus,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor),
                ),
              ),
            ),

            // ✅ Amount Paid — shows COD-inclusive total
            if (!isCODUnpaid && displayAmountPaid > 0) ...[
              const SizedBox(height: 10),
              _paymentRow(
                'Amount Paid',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${displayAmountPaid.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    if (isCOD && codCharge > 0)
                      Text(
                        'incl. ₹${codCharge.round()} COD',
                        style:
                            TextStyle(fontSize: 10, color: Colors.red.shade400),
                      ),
                  ],
                ),
              ),
            ],

            // ✅ COD: show amount payable on delivery (grand total)
            if (isCODUnpaid && codPayableOnDelivery > 0) ...[
              const SizedBox(height: 10),
              _paymentRow(
                'Payable on Delivery',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${codPayableOnDelivery.round()}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade700),
                    ),
                    if (codCharge > 0)
                      Text(
                        'incl. ₹${codCharge.round()} COD',
                        style:
                            TextStyle(fontSize: 10, color: Colors.red.shade400),
                      ),
                  ],
                ),
              ),
            ],

            // Transaction ID (online payments)
            if (payment.transactionId != null &&
                payment.transactionId!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _paymentRow(
                'Transaction ID',
                Flexible(
                  child: Text(
                    payment.transactionId!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _paymentRow(String label, Widget value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        value,
      ],
    );
  }

  // ── Shipping Info Card ───────────────────────────────────────────────────────
  Widget _buildShippingInfoCard() {
    final shipping = _order!.shipping!;
    return _buildCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _iconBox(Icons.local_shipping_rounded, AppTheme.primaryColor),
          const SizedBox(width: 12),
          const Text('Shipping Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(children: [
            _paymentRow(
              'Status',
              Text(shipping.displayStatus,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            if (shipping.courierName != null) ...[
              const SizedBox(height: 8),
              _paymentRow(
                'Courier',
                Text(shipping.courierName!,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
            if (shipping.awbNumber != null) ...[
              const SizedBox(height: 8),
              _paymentRow(
                'AWB Number',
                Text(shipping.awbNumber!,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
            if (shipping.expectedDelivery != null) ...[
              const SizedBox(height: 8),
              _paymentRow(
                'Expected Delivery',
                Text(
                  '${shipping.expectedDelivery!.day}/${shipping.expectedDelivery!.month}/${shipping.expectedDelivery!.year}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  // ── Cancel Button ────────────────────────────────────────────────────────────
  Widget _buildCancelButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade300, width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Text(
                  'Cancel window: ${_order!.timeRemainingToCancel}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700),
                ),
              ]),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _cancelOrder,
                icon: const Icon(Icons.cancel_outlined,
                    size: 20, color: Colors.white),
                label: const Text(
                  'Cancel Order',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  disabledBackgroundColor: Colors.red.shade200,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  // ── Shared UI helpers ────────────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
