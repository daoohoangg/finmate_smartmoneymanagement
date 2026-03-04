import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'models/category.dart';
import 'services/category_service.dart';
import 'utils/category_ui.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';

class CreateCategoryArgs {
  const CreateCategoryArgs({
    required this.type,
    this.parentCategoryId,
    this.lockParentSelection = false,
  });

  final CategoryType type;
  final int? parentCategoryId;
  final bool lockParentSelection;
}

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  static const String routeName = '/categories/create';

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  static const List<_ParentTemplate> _requiredParents = [
    _ParentTemplate(
      name: 'Necessary',
      group: CategoryGroup.necessary,
      icon: Icons.home_outlined,
      color: Color(0xFFF59E0B),
    ),
    _ParentTemplate(
      name: 'Accumulation',
      group: CategoryGroup.accumulation,
      icon: Icons.savings_outlined,
      color: Color(0xFF2CB67D),
    ),
    _ParentTemplate(
      name: 'Flexibility',
      group: CategoryGroup.flexibility,
      icon: Icons.auto_awesome_outlined,
      color: Color(0xFF6366F1),
    ),
  ];

  final TextEditingController _nameController = TextEditingController();
  Color _color = const Color(0xFFE11D48);
  IconData _icon = Icons.shopping_basket_outlined;
  CategoryType _type = CategoryType.expense;
  int? _parentCategoryId;
  List<Category> _parentOptions = [];
  bool _isLoadingParents = false;
  bool _isSaving = false;
  bool _didLoadArgs = false;
  bool _lockParentSelection = false;

  CategoryService? _categoryService;

  CategoryService get _service => _categoryService ??= CategoryService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is CategoryType) {
      _type = args;
    } else if (args is CreateCategoryArgs) {
      _type = args.type;
      _parentCategoryId = args.parentCategoryId;
      _lockParentSelection = args.lockParentSelection;
    }
    _didLoadArgs = true;
    _loadParents();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadParents() async {
    if (_type != CategoryType.expense) {
      setState(() {
        _parentOptions = const <Category>[];
        _parentCategoryId = null;
      });
      return;
    }
    setState(() => _isLoadingParents = true);
    try {
      final categories = await _service.getCategories(type: _type);
      final topLevel = categories.where((category) => category.parentId == null).toList();
      final seededParents = await _ensureRequiredParents(topLevel);
      if (!mounted) return;
      setState(() {
        _parentOptions = seededParents;
        _parentCategoryId ??= seededParents.isNotEmpty ? seededParents.first.id : null;
        if (_parentCategoryId != null &&
            !seededParents.any((category) => category.id == _parentCategoryId)) {
          _parentCategoryId = seededParents.isNotEmpty ? seededParents.first.id : null;
        }
      });
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingParents = false);
    }
  }

  Future<List<Category>> _ensureRequiredParents(List<Category> topLevel) async {
    final byNormalizedName = <String, Category>{
      for (final category in topLevel) _normalize(category.name): category,
    };
    final result = <Category>[];
    for (final template in _requiredParents) {
      final key = _normalize(template.name);
      var category = byNormalizedName[key];
      if (category == null) {
        category = await _service.createCategory(
          name: template.name,
          type: _type,
          group: template.group,
          icon: CategoryUi.iconToString(template.icon),
          color: CategoryUi.colorToString(template.color),
        );
        byNormalizedName[key] = category;
      }
      result.add(category);
    }
    return result;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Category name is required');
      return;
    }
    final parentId = _parentCategoryId;
    if (parentId == null) {
      _showSnack('Please select a parent category');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _service.createCategory(
        name: name,
        type: _type,
        icon: CategoryUi.iconToString(_icon),
        color: CategoryUi.colorToString(_color),
        parentId: parentId,
      );
      if (!mounted) return;
      _showSnack('Category created successfully');
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Category? selectedParent;
    if (_parentCategoryId != null) {
      for (final option in _parentOptions) {
        if (option.id == _parentCategoryId) {
          selectedParent = option;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: Text(_lockParentSelection ? 'Add Subcategory' : 'Create Category'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const FinMateBottomNav(active: FinMateNavItem.utilities),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 6),
                  _PreviewBadge(icon: _icon, color: _color),
                  const SizedBox(height: 10),
                  Text(
                    'Preview',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Category Name',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Groceries',
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Parent Category',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_isLoadingParents)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (_lockParentSelection && selectedParent != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        selectedParent.name,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    DropdownButtonFormField<int?>(
                      value: _parentCategoryId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: [
                        ..._parentOptions.map(
                          (category) => DropdownMenuItem<int?>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        ),
                      ],
                      onChanged: _isLoadingParents || _lockParentSelection
                          ? null
                          : (value) => setState(() => _parentCategoryId = value),
                    ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _lockParentSelection ? 'Add Subcategory' : 'Save Category',
                    color: AppColors.primaryRed,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _handleSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentTemplate {
  const _ParentTemplate({
    required this.name,
    required this.group,
    required this.icon,
    required this.color,
  });

  final String name;
  final CategoryGroup group;
  final IconData icon;
  final Color color;
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
      ),
    );
  }
}
