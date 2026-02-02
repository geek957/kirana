import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/image_upload_service.dart';
import '../../models/category.dart';

class ProductFormScreen extends StatefulWidget {
  final String? productId; // null for add, non-null for edit

  const ProductFormScreen({super.key, this.productId});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imageUploadService = ImageUploadService();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _unitSizeController = TextEditingController();
  final _stockController = TextEditingController();
  final _minimumOrderQuantityController = TextEditingController();
  final _maximumOrderQuantityController = TextEditingController();

  String? _selectedCategoryId;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.productId != null;
    // Load categories first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
    if (_isEditMode) {
      _loadProductData();
    } else {
      // Set default minimum order quantity for new products
      _minimumOrderQuantityController.text = '1';
    }
  }

  Future<void> _loadProductData() async {
    setState(() => _isLoading = true);
    try {
      final adminProvider = context.read<AdminProvider>();
      final product = await adminProvider.getProductById(widget.productId!);

      if (product != null) {
        setState(() {
          _nameController.text = product.name;
          _descriptionController.text = product.description;
          _priceController.text = product.price.toString();
          if (product.discountPrice != null) {
            _discountPriceController.text = product.discountPrice.toString();
          }
          _unitSizeController.text = product.unitSize;
          _stockController.text = product.stockQuantity.toString();
          _selectedCategoryId = product.categoryId;
          _minimumOrderQuantityController.text = product.minimumOrderQuantity
              .toString();
          if (product.maximumOrderQuantity != null) {
            _maximumOrderQuantityController.text = product.maximumOrderQuantity
                .toString();
          }
          _existingImageUrl = product.imageUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading product: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _unitSizeController.dispose();
    _stockController.dispose();
    _minimumOrderQuantityController.dispose();
    _maximumOrderQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Product' : 'Add Product')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Upload Section
                    _buildImageSection(),
                    const SizedBox(height: 24),

                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        hintText: 'Enter product name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter product name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter product description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price and Unit Size Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price (₹) *',
                              hintText: '0.00',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price <= 0) {
                                return 'Invalid price';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _unitSizeController,
                            decoration: const InputDecoration(
                              labelText: 'Unit Size *',
                              hintText: 'e.g., 1kg, 500ml',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Discount Price Field
                    TextFormField(
                      controller: _discountPriceController,
                      decoration: InputDecoration(
                        labelText: 'Discount Price (₹)',
                        hintText: 'Optional - Leave empty for no discount',
                        border: const OutlineInputBorder(),
                        prefixText: '₹ ',
                        suffixIcon: _discountPriceController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _discountPriceController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {}); // Rebuild to show/hide clear button
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null; // Optional field
                        }
                        final discountPrice = double.tryParse(value);
                        if (discountPrice == null || discountPrice <= 0) {
                          return 'Invalid discount price';
                        }
                        final price = double.tryParse(_priceController.text);
                        if (price != null && discountPrice >= price) {
                          return 'Must be less than regular price';
                        }
                        return null;
                      },
                    ),
                    // Discount percentage display
                    if (_discountPriceController.text.isNotEmpty &&
                        _priceController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                        child: _buildDiscountPercentageDisplay(),
                      ),
                    const SizedBox(height: 16),

                    // Category and Stock Row
                    Row(
                      children: [
                        Expanded(
                          child: Consumer<CategoryProvider>(
                            builder: (context, categoryProvider, child) {
                              final categories = categoryProvider.categories;
                              return DropdownButtonFormField<String>(
                                value: _selectedCategoryId,
                                decoration: const InputDecoration(
                                  labelText: 'Category *',
                                  border: OutlineInputBorder(),
                                ),
                                items: categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category.id,
                                    child: Text(category.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategoryId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select category';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(
                              labelText: 'Stock Quantity *',
                              hintText: '0',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final stock = int.tryParse(value);
                              if (stock == null || stock < 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Order Quantity Fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minimumOrderQuantityController,
                            decoration: const InputDecoration(
                              labelText: 'Min. Order Qty *',
                              hintText: '1',
                              border: OutlineInputBorder(),
                              helperText: 'Minimum quantity (default: 1)',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final minQty = int.tryParse(value);
                              if (minQty == null || minQty < 1) {
                                return 'Must be at least 1';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maximumOrderQuantityController,
                            decoration: InputDecoration(
                              labelText: 'Max. Order Qty',
                              hintText: 'Unlimited',
                              border: const OutlineInputBorder(),
                              helperText: 'Optional - Leave empty for unlimited',
                              suffixIcon: _maximumOrderQuantityController
                                      .text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _maximumOrderQuantityController
                                              .clear();
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (value) {
                              setState(
                                () {},
                              ); // Rebuild to show/hide clear button
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null; // Optional field
                              }
                              final maxQty = int.tryParse(value);
                              if (maxQty == null || maxQty < 1) {
                                return 'Must be at least 1';
                              }
                              final minQty = int.tryParse(
                                _minimumOrderQuantityController.text,
                              );
                              if (minQty != null && maxQty < minQty) {
                                return 'Must be >= min qty';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isEditMode ? 'Update Product' : 'Save Product',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Image', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
          ),
          child: _selectedImage != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _existingImageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _existingImageUrl = null;
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final image = await _imageUploadService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _existingImageUrl =
              null; // Clear existing URL when new image selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await _imageUploadService.pickImageFromCamera();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _existingImageUrl =
              null; // Clear existing URL when new image selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error capturing image: $e')));
      }
    }
  }

  Widget _buildDiscountPercentageDisplay() {
    final price = double.tryParse(_priceController.text);
    final discountPrice = double.tryParse(_discountPriceController.text);

    if (price == null || discountPrice == null || discountPrice >= price) {
      return const SizedBox.shrink();
    }

    final percentage = ((price - discountPrice) / price) * 100;
    final savings = price - discountPrice;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${percentage.toStringAsFixed(0)}% OFF',
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Save ₹${savings.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get the selected category to retrieve the category name
    final categoryProvider = context.read<CategoryProvider>();
    final selectedCategory = categoryProvider.getCategoryById(
      _selectedCategoryId!,
    );

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected category not found')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final adminProvider = context.read<AdminProvider>();

      // Upload image if a new one was selected
      String? imageUrl = _existingImageUrl;
      if (_selectedImage != null) {
        // Generate a temporary product ID for image upload if adding new product
        final productId = _isEditMode
            ? widget.productId!
            : DateTime.now().millisecondsSinceEpoch.toString();

        imageUrl = await _imageUploadService.uploadProductImage(
          productId: productId,
          imageFile: _selectedImage!,
        );
      }

      // Parse discount price (null if empty)
      double? discountPrice;
      if (_discountPriceController.text.trim().isNotEmpty) {
        discountPrice = double.parse(_discountPriceController.text);
      }

      // Parse minimum order quantity
      final minimumOrderQuantity = int.parse(
        _minimumOrderQuantityController.text,
      );

      // Parse maximum order quantity (null if empty)
      int? maximumOrderQuantity;
      if (_maximumOrderQuantityController.text.trim().isNotEmpty) {
        maximumOrderQuantity = int.parse(_maximumOrderQuantityController.text);
      }

      if (_isEditMode) {
        // Update existing product
        await adminProvider.updateProduct(
          productId: widget.productId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          discountPrice: discountPrice,
          category: selectedCategory.name,
          categoryId: _selectedCategoryId!,
          unitSize: _unitSizeController.text.trim(),
          stockQuantity: int.parse(_stockController.text),
          minimumOrderQuantity: minimumOrderQuantity,
          maximumOrderQuantity: maximumOrderQuantity,
          imageUrl: imageUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Add new product
        await adminProvider.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          discountPrice: discountPrice,
          category: selectedCategory.name,
          categoryId: _selectedCategoryId!,
          unitSize: _unitSizeController.text.trim(),
          stockQuantity: int.parse(_stockController.text),
          minimumOrderQuantity: minimumOrderQuantity,
          maximumOrderQuantity: maximumOrderQuantity,
          imageUrl: imageUrl ?? '',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving product: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
