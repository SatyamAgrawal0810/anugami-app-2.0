// lib/presentation/pages/product/widgets/product_filter_sheet.dart

import 'package:flutter/material.dart';
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/core/models/product_filter_model.dart';

class ProductFilterSheet extends StatefulWidget {
  final ProductFilterModel currentFilters;
  final List<String> availableBrands;
  final Function(ProductFilterModel) onApplyFilters;

  const ProductFilterSheet({
    Key? key,
    required this.currentFilters,
    required this.availableBrands,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late ProductFilterModel _filters;
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _filters = ProductFilterModel(
      minPrice: widget.currentFilters.minPrice,
      maxPrice: widget.currentFilters.maxPrice,
      selectedBrands: List.from(widget.currentFilters.selectedBrands),
      minRating: widget.currentFilters.minRating,
      minDiscount: widget.currentFilters.minDiscount,
      inStockOnly: widget.currentFilters.inStockOnly,
      emiAvailable: widget.currentFilters.emiAvailable,
      sortBy: widget.currentFilters.sortBy,
    );
    _priceRange = RangeValues(_filters.minPrice, _filters.maxPrice);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              const Divider(height: 1),

              // Filters Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildPriceFilter(),
                    const SizedBox(height: 24),
                    _buildBrandFilter(),
                    const SizedBox(height: 24),
                    _buildRatingFilter(),
                    const SizedBox(height: 24),
                    _buildDiscountFilter(),
                    const SizedBox(height: 24),
                    _buildStockFilter(),
                    const SizedBox(height: 24),
                    _buildEMIFilter(),
                    const SizedBox(height: 80), // Space for bottom buttons
                  ],
                ),
              ),

              // Bottom Buttons
              _buildBottomButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filter Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_filters.hasActiveFilters)
            TextButton(
              onPressed: () {
                setState(() {
                  _filters.reset();
                  _priceRange = RangeValues(0, 100000);
                });
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 100000,
          divisions: 100,
          labels: RangeLabels(
            '₹${_priceRange.start.round()}',
            '₹${_priceRange.end.round()}',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _priceRange = values;
              _filters.minPrice = values.start;
              _filters.maxPrice = values.end;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹${_priceRange.start.round()}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '₹${_priceRange.end.round()}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrandFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Brand',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.availableBrands.isEmpty)
          const Text(
            'No brands available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          )
        else
          ...widget.availableBrands.map((brand) {
            final isSelected = _filters.selectedBrands.contains(brand);
            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(brand),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _filters.selectedBrands.add(brand);
                  } else {
                    _filters.selectedBrands.remove(brand);
                  }
                });
              },
            );
          }).toList(),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Minimum Rating',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [4.0, 3.5, 3.0, 2.5, 2.0].map((rating) {
            final isSelected = _filters.minRating == rating;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('$rating+'),
                ],
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  _filters.minRating = selected ? rating : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDiscountFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Minimum Discount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [50.0, 40.0, 30.0, 20.0, 10.0].map((discount) {
            final isSelected = _filters.minDiscount == discount;
            return ChoiceChip(
              label: Text('$discount% or more'),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  _filters.minDiscount = selected ? discount : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStockFilter() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text(
        'In Stock Only',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: const Text('Show only available products'),
      value: _filters.inStockOnly ?? false,
      onChanged: (bool value) {
        setState(() {
          _filters.inStockOnly = value ? true : null;
        });
      },
    );
  }

  Widget _buildEMIFilter() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text(
        'EMI Available',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: const Text('Products with EMI options'),
      value: _filters.emiAvailable ?? false,
      onChanged: (bool value) {
        setState(() {
          _filters.emiAvailable = value ? true : null;
        });
      },
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _filters.reset();
                    _priceRange = RangeValues(0, 100000);
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () {
                  widget.onApplyFilters(_filters);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Apply Filters',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
