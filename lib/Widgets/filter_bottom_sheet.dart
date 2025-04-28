import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _filters;
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
    _priceMinController.text = _filters['priceMin']?.toString() ?? '';
    _priceMaxController.text = _filters['priceMax']?.toString() ?? '';
  }

  @override
  void dispose() {
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _filters = {
        'categories': [],
        'priceMin': null,
        'priceMax': null,
        'rating': 0.0,
        'availability': 'all',
        'sortBy': 'popularity',
      };
      _priceMinController.clear();
      _priceMaxController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Books',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset'),
              ),
            ],
          ),
          const Divider(),
          
          // Scrollable content
          Expanded(
            child: ListView(
              children: [
                // Categories
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildCategoryChip('Fiction'),
                    _buildCategoryChip('Non-Fiction'),
                    _buildCategoryChip('Science'),
                    _buildCategoryChip('Biography'),
                    _buildCategoryChip('History'),
                    _buildCategoryChip('Fantasy'),
                    _buildCategoryChip('Romance'),
                    _buildCategoryChip('Mystery'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Price Range
                const Text(
                  'Price Range',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceMinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _filters['priceMin'] = value.isEmpty ? null : double.tryParse(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _priceMaxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _filters['priceMax'] = value.isEmpty ? null : double.tryParse(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Rating
                const Text(
                  'Rating',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _filters['rating'] ?? 0.0,
                        min: 0.0,
                        max: 5.0,
                        divisions: 10,
                        label: (_filters['rating'] ?? 0.0).toString(),
                        onChanged: (value) {
                          setState(() {
                            _filters['rating'] = value;
                          });
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.amber,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber[700],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(_filters['rating'] ?? 0.0).toStringAsFixed(1)}+',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Availability
                const Text(
                  'Availability',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildAvailabilityChip('All', 'all'),
                    _buildAvailabilityChip('In Stock', 'in_stock'),
                    _buildAvailabilityChip('E-Book', 'ebook'),
                    _buildAvailabilityChip('Audiobook', 'audiobook'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Sort By
                const Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildSortByChip('Popularity', 'popularity'),
                    _buildSortByChip('Price: Low to High', 'price_asc'),
                    _buildSortByChip('Price: High to Low', 'price_desc'),
                    _buildSortByChip('Rating', 'rating'),
                    _buildSortByChip('Newest', 'newest'),
                  ],
                ),
              ],
            ),
          ),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApplyFilters(_filters);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = (_filters['categories'] as List).contains(category);
    
    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            (_filters['categories'] as List).add(category);
          } else {
            (_filters['categories'] as List).remove(category);
          }
        });
      },
    );
  }

  Widget _buildAvailabilityChip(String label, String value) {
    final isSelected = _filters['availability'] == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filters['availability'] = value;
          });
        }
      },
    );
  }

  Widget _buildSortByChip(String label, String value) {
    final isSelected = _filters['sortBy'] == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filters['sortBy'] = value;
          });
        }
      },
    );
  }
}
