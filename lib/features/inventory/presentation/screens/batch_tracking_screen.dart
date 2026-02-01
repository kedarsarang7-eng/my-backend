import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/repository/products_repository.dart';
import '../../../../providers/app_state_providers.dart';
import '../../../../core/database/app_database.dart'; // For ProductBatchEntity
import '../../../../widgets/desktop/desktop_content_container.dart';

/// Batch Tracking Screen
///
/// Manages product batches (expiry, manufacturing, stock).
/// Critical for Pharmacy (FMCG) compliance.
class BatchTrackingScreen extends ConsumerStatefulWidget {
  const BatchTrackingScreen({super.key});

  @override
  ConsumerState<BatchTrackingScreen> createState() =>
      _BatchTrackingScreenState();
}

class _BatchTrackingScreenState extends ConsumerState<BatchTrackingScreen> {
  bool _loading = true;
  List<ProductBatchEntity> _batches = [];
  Map<String, String> _productNames = {};
  String _searchQuery = '';
  bool _showExpiredOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final userId = ref.read(authStateProvider).userId ?? '';
    if (userId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final repo = sl<ProductsRepository>();

      // Load all active batches
      final result = await repo.getAllBatches(userId);
      _batches = result.data ?? [];

      // Load products to map IDs to Names
      final productsResult = await repo.getAll(userId: userId);
      final products = productsResult.data ?? [];
      _productNames = {for (var p in products) p.id: p.name};

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<ProductBatchEntity> get _filteredBatches {
    final now = DateTime.now();
    return _batches.where((batch) {
      final productName = _productNames[batch.productId] ?? '';
      final matchesSearch = batch.batchNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          productName.toLowerCase().contains(_searchQuery.toLowerCase());

      if (_showExpiredOnly) {
        return matchesSearch &&
            batch.expiryDate != null &&
            batch.expiryDate!.isBefore(now);
      }
      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DesktopContentContainer(
      title: 'Batch Tracking',
      subtitle: '${_filteredBatches.length} active batches',
      actions: [
        DesktopIconButton(
          icon: Icons.refresh,
          tooltip: 'Refresh',
          onPressed: _loadData,
        ),
      ],
      child: Column(
        children: [
          // Filters & Search
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search batch number or product...',
                          hintStyle: TextStyle(
                              color:
                                  isDark ? Colors.white38 : Colors.grey[400]),
                          prefixIcon: Icon(Icons.search,
                              color:
                                  isDark ? Colors.white38 : Colors.grey[400]),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0F172A)
                              : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilterChip(
                      label: const Text('Expired Only'),
                      selected: _showExpiredOnly,
                      onSelected: (val) =>
                          setState(() => _showExpiredOnly = val),
                      backgroundColor:
                          isDark ? Colors.black26 : Colors.grey[100],
                      selectedColor: const Color(0xFFEF4444).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _showExpiredOnly
                            ? const Color(0xFFEF4444)
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(child: _buildValues(isDark)),
        ],
      ),
    );
  }

  // Header removed as moved to body/container props

  Widget _buildValues(bool isDark) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_filteredBatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear,
                size: 64, color: isDark ? Colors.white24 : Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No batches found',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredBatches.length,
      itemBuilder: (context, index) {
        final batch = _filteredBatches[index];
        return _buildBatchCard(batch, isDark);
      },
    );
  }

  Widget _buildBatchCard(ProductBatchEntity batch, bool isDark) {
    final productName = _productNames[batch.productId] ?? 'Unknown Product';
    final isExpired =
        batch.expiryDate != null && batch.expiryDate!.isBefore(DateTime.now());
    final expiryColor =
        isExpired ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200]!),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isExpired
                    ? const Color(0xFFEF4444).withOpacity(0.1)
                    : const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isExpired ? Icons.event_busy : Icons.qr_code,
                color: isExpired
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF8B5CF6),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          batch.batchNumber,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Monospace',
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Qty: ${batch.stockQuantity.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: expiryColor),
                      const SizedBox(width: 4),
                      Text(
                        batch.expiryDate != null
                            ? 'Expires: ${DateFormat('dd MMM yyyy').format(batch.expiryDate!)}'
                            : 'No Expiry',
                        style: TextStyle(
                          fontSize: 12,
                          color: expiryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'MRP: ₹${batch.mrp.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
