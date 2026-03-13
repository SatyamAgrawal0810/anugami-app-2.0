import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../widgets/logo_loader.dart';
import '../../../core/models/product_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../api/services/api_config.dart';

class BrandDetailsPage extends StatefulWidget {
  final String brandSlug;

  const BrandDetailsPage({super.key, required this.brandSlug});

  @override
  State<BrandDetailsPage> createState() => _BrandDetailsPageState();
}

class _BrandDetailsPageState extends State<BrandDetailsPage> {
  bool _isLoading = true;
  String? _error;
  BrandModel? _brand;
  List<ProductModel> _brandProducts = [];

  @override
  void initState() {
    super.initState();
    _loadBrandData();
  }

  Future<void> _loadBrandData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ─── Step 1: Saare brands fetch karo ─────────────────────────
      print('🔍 [Brand] Slug: ${widget.brandSlug}');

      final brandsRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/brands/brands/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('📡 [Brands API] Status: ${brandsRes.statusCode}');

      if (brandsRes.statusCode != 200) {
        setState(() {
          _error = 'Brands fetch failed (${brandsRes.statusCode})';
          _isLoading = false;
        });
        return;
      }

      final brandsData = json.decode(brandsRes.body);
      final List brandList =
          brandsData is List ? brandsData : (brandsData['results'] ?? []);

      print('📦 [Brands] Total fetched: ${brandList.length}');

      // ─── Step 2: Frontend pe slug se brand filter karo ───────────
      Map<String, dynamic>? brandJson;

      // Try 1: exact slug match
      for (var b in brandList) {
        if (b['slug']?.toString() == widget.brandSlug) {
          brandJson = b as Map<String, dynamic>;
          break;
        }
      }

      // Try 2: name se match (slug nahi mila to)
      if (brandJson == null) {
        final slugNormalized =
            widget.brandSlug.toLowerCase().replaceAll('-', ' ');
        for (var b in brandList) {
          final name = b['name']?.toString().toLowerCase() ?? '';
          if (name == slugNormalized ||
              name.replaceAll(' ', '-') == widget.brandSlug) {
            brandJson = b as Map<String, dynamic>;
            break;
          }
        }
      }

      // Try 3: pagination hai to saare pages fetch karo
      if (brandJson == null &&
          brandsData is Map &&
          brandsData['next'] != null) {
        print('⚠️ Next page hai, saare brands fetch kar rahe hain...');
        String? nextUrl = brandsData['next']?.toString();

        while (nextUrl != null && brandJson == null) {
          final pageRes = await http.get(
            Uri.parse(nextUrl),
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 15));

          if (pageRes.statusCode == 200) {
            final pageData = json.decode(pageRes.body);
            final List pageList =
                pageData is List ? pageData : (pageData['results'] ?? []);

            print('📦 [Brands page] count: ${pageList.length}');

            for (var b in pageList) {
              if (b['slug']?.toString() == widget.brandSlug) {
                brandJson = b as Map<String, dynamic>;
                break;
              }
            }

            final next = pageData['next'];
            nextUrl = (next != null && next.toString().isNotEmpty)
                ? next.toString()
                : null;
          } else {
            break;
          }
        }
      }

      if (brandJson == null) {
        print('❌ Brand not found for slug: ${widget.brandSlug}');
        setState(() {
          _error = 'Brand nahi mila: ${widget.brandSlug}';
          _isLoading = false;
        });
        return;
      }

      final bj = brandJson!;
      print('✅ [Brand] Found: ${bj['name']} | slug: ${bj['slug']}');

      setState(() {
        _brand = BrandModel(
          id: bj['id']?.toString() ?? '',
          name: bj['name']?.toString() ?? '',
          slug: bj['slug']?.toString() ?? '',
          description: bj['description']?.toString() ?? '',
          logo: bj['logo']?.toString() ?? '',
          isVerified: bj['is_verified'] == true,
          sellerName: bj['seller_name']?.toString() ?? '',
        );
      });

      // ─── Step 3: Saare products fetch karo (website jaisa) ───────
      print('🔍 [Products] Saare products fetch kar rahe hain...');

      final productsRes = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/products/products/?no_page=true'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('📡 [Products API] Status: ${productsRes.statusCode}');

      List<dynamic> allRaw = [];

      if (productsRes.statusCode == 200) {
        final pData = json.decode(productsRes.body);
        allRaw = pData is List ? pData : (pData['results'] ?? []);
        print('📦 [Products] Total fetched: ${allRaw.length}');
      } else {
        // Fallback: paginated fetch
        print('⚠️ no_page kaam nahi kiya, paginated fetch...');
        String? pageUrl =
            '${ApiConfig.baseUrl}/api/v1/products/products/?page=1';

        while (pageUrl != null) {
          final res = await http.get(
            Uri.parse(pageUrl),
            headers: {'Accept': 'application/json'},
          ).timeout(const Duration(seconds: 15));

          if (res.statusCode == 200) {
            final d = json.decode(res.body);
            final List results = d is List ? d : (d['results'] ?? []);
            allRaw.addAll(results);
            final next = d['next'];
            pageUrl = (next != null && next.toString().isNotEmpty)
                ? next.toString()
                : null;
          } else {
            break;
          }
        }
        print('📦 [Paginated Products] Total: ${allRaw.length}');
      }

      // ─── Step 4: Frontend pe brand slug se products filter karo ──
      // Website ka BrandClient yahi karta hai
      final String currentSlug = widget.brandSlug;

      final List<ProductModel> filtered = allRaw
          .where((e) {
            final brand = e['brand'];
            if (brand == null) return false;

            // Brand object hai ya sirf ID?
            if (brand is Map) {
              final brandSlug = brand['slug']?.toString() ?? '';
              final brandName = brand['name']?.toString().toLowerCase() ?? '';
              final slugFromName = brandName.replaceAll(' ', '-');

              return brandSlug == currentSlug || slugFromName == currentSlug;
            }

            // Brand sirf ID hai — brand ke name se match karo
            final brandId = brand.toString();
            final matchedBrandId = bj['id']?.toString() ?? '';
            return brandId == matchedBrandId;
          })
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();

      print(
          '✅ [Filter] Brand "${widget.brandSlug}" ke products: ${filtered.length}');

      setState(() {
        _brandProducts = filtered;
        _isLoading = false;
      });
    } catch (e, stack) {
      print('❌ [Brand] Error: $e');
      print('❌ Stack: $stack');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_brand?.name ?? 'Brand Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: LogoLoader())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadBrandData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _brand == null
                  ? const Center(child: Text('Brand not found'))
                  : RefreshIndicator(
                      onRefresh: _loadBrandData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBrandHeader(),
                            if (_brand!.description.isNotEmpty)
                              _buildDescription(),
                            const SizedBox(height: 16),
                            _buildProductsSection(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          if (_brand!.logo.isNotEmpty)
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: Image.network(
                _brand!.logo,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.business, size: 60, color: Colors.grey.shade400),
              ),
            )
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  Icon(Icons.business, size: 60, color: AppTheme.primaryColor),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _brand!.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_brand!.isVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified,
                          size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text('VERIFIED',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (_brand!.sellerName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Sold by: ${_brand!.sellerName}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_brandProducts.length} Product${_brandProducts.length != 1 ? 's' : ''}',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About Brand',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(_brand!.description,
              style: TextStyle(
                  fontSize: 14, height: 1.6, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.category, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Brand Products',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_brandProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No products found',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _brandProducts.length,
            itemBuilder: (context, index) =>
                _buildProductCard(context, _brandProducts[index]),
          ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: product.primaryImageUrl.isNotEmpty
                          ? Image.network(
                              product.primaryImageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(child: LogoLoader());
                              },
                              errorBuilder: (_, __, ___) => Icon(Icons.image,
                                  color: Colors.grey[400], size: 40),
                            )
                          : Icon(Icons.image,
                              color: Colors.grey[400], size: 40),
                    ),
                  ),
                  if (product.discountPercentage.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4947),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.discountPercentage,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.primaryGradient.createShader(bounds),
                          child: Text(
                            product.formattedSalePrice,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        if (product.discountPercentage.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            product.formattedRegularPrice,
                            style: TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
