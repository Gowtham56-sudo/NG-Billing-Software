import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/categories_provider.dart';
import '../../products/providers/products_provider.dart';
import '../../../models/category.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Categories',
            onPressed: () {
              ref.read(categoriesProvider.notifier).loadCategories();
            },
          ),
        ],
      ),
      body: categoriesState.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No categories found. Add some!', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.3,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _AnimatedCategoryCard(
                  category: category,
                  index: index,
                  onDelete: () => _confirmDeleteCategory(context, ref, category),
                  onEdit: () => _showEditCategoryDialog(context, ref, category),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddCategoryDialog(context, ref);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Category Name *',
              border: OutlineInputBorder(),
              hintText: 'e.g. Frozen Foods, Stationery',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final category = Category(name: name);
                  await ref.read(categoriesProvider.notifier).addCategory(category);
                  ref.read(productsProvider.notifier).loadProducts();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Category "$name" created successfully!')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, Category category) {
    final nameController = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Category: ${category.name}'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Category Name *',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final updatedCategory = Category(id: category.id, name: name);
                  await ref.read(categoriesProvider.notifier).updateCategory(updatedCategory);
                  ref.read(productsProvider.notifier).loadProducts();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Category updated to "$name"!')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await ref.read(categoriesProvider.notifier).deleteCategory(category.id!);
              ref.read(productsProvider.notifier).loadProducts();
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "${category.name}" deleted.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCategoryCard extends StatefulWidget {
  final Category category;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _AnimatedCategoryCard({
    required this.category,
    required this.index,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<_AnimatedCategoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval((widget.index * 0.08).clamp(0.0, 1.0), 1.0, curve: Curves.easeOutBack),
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval((widget.index * 0.08).clamp(0.0, 1.0), 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<List<Color>> gradients = [
      [Colors.purple.shade400, Colors.deepPurple.shade700],
      [Colors.orange.shade400, Colors.deepOrange.shade700],
      [Colors.teal.shade400, Colors.teal.shade700],
      [Colors.pink.shade400, Colors.red.shade700],
      [Colors.blue.shade400, Colors.indigo.shade700],
      [Colors.amber.shade700, Colors.orange.shade800],
    ];
    
    final gradientColors = gradients[widget.index % gradients.length];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.last.withValues(alpha: _isHovered ? 0.45 : 0.2),
                      blurRadius: _isHovered ? 14 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.category.name.isNotEmpty ? widget.category.name.substring(0, 1).toUpperCase() : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.category.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                            onPressed: widget.onEdit,
                            tooltip: 'Edit Category',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
                            onPressed: widget.onDelete,
                            tooltip: 'Delete Category',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
