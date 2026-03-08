package com.finmate.service.impl;

import com.finmate.dto.request.CategoryRequest;
import com.finmate.dto.response.CategoryResponse;
import com.finmate.entities.Category;
import com.finmate.entities.User;
import com.finmate.enums.CategoryGroup;
import com.finmate.enums.CategoryType;
import com.finmate.exception.BadRequestException;
import com.finmate.exception.ResourceNotFoundException;
import com.finmate.exception.UnauthorizedException;
import com.finmate.repository.BudgetRepository;
import com.finmate.repository.CategoryRepository;
import com.finmate.repository.CategoryRuleRepository;
import com.finmate.repository.RecurringTransactionRepository;
import com.finmate.repository.TransactionRepository;
import com.finmate.repository.UserRepository;
import com.finmate.service.CategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CategoryServiceImpl implements CategoryService {
    private static final List<DefaultSubcategoryTemplate> NECESSARY_DEFAULT_SUBCATEGORIES = List.of(
            new DefaultSubcategoryTemplate("Market", "local_grocery_store_outlined", "#FB923C"),
            new DefaultSubcategoryTemplate("Food", "restaurant_outlined", "#F97316"),
            new DefaultSubcategoryTemplate("Transport", "directions_car_filled", "#60A5FA"),
            new DefaultSubcategoryTemplate("Bill", "receipt_long", "#34D399"));

    private static final List<DefaultSubcategoryTemplate> ACCUMULATION_DEFAULT_SUBCATEGORIES = List.of(
            new DefaultSubcategoryTemplate("Saving", "savings_outlined", "#2CB67D"),
            new DefaultSubcategoryTemplate("Learning", "account_balance_outlined", "#6366F1"));

    private static final List<DefaultSubcategoryTemplate> FLEXIBILITY_DEFAULT_SUBCATEGORIES = List.of(
            new DefaultSubcategoryTemplate("Shopping", "shopping_cart_outlined", "#F59E0B"),
            new DefaultSubcategoryTemplate("Entertainment", "movie_outlined", "#EC4899"),
            new DefaultSubcategoryTemplate("Charity", "favorite_border", "#F43F5E"));

    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final BudgetRepository budgetRepository;
    private final RecurringTransactionRepository recurringTransactionRepository;
    private final CategoryRuleRepository categoryRuleRepository;

    @Override
    public CategoryResponse createCategory(UUID userId, CategoryRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (request.getType() == null) {
            throw new RuntimeException("Category type is required");
        }

        Category category = new Category();
        category.setUser(user);
        category.setIcon(request.getIcon());
        category.setColor(request.getColor());
        applyHierarchyAndValidate(category, request, userId, true);

        if (Boolean.TRUE.equals(category.getIsPrimary())
                && category.getType() == CategoryType.EXPENSE
                && category.getCategoryGroup() != null) {
            Category existing = findExistingPrimaryByGroup(userId, category.getCategoryGroup());
            if (existing != null) {
                if (StringUtils.hasText(category.getIcon())) {
                    existing.setIcon(category.getIcon());
                }
                if (StringUtils.hasText(category.getColor())) {
                    existing.setColor(category.getColor());
                }
                if (StringUtils.hasText(category.getName())) {
                    existing.setName(category.getName());
                }
                return mapToResponse(categoryRepository.save(existing));
            }
        }

        Category savedCategory = categoryRepository.save(category);
        return mapToResponse(savedCategory);
    }

    @Override
    public CategoryResponse getCategoryById(Long id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found"));
        return mapToResponse(category);
    }

    @Override
    public List<CategoryResponse> getAllCategoriesByUser(UUID userId) {
        return categoryRepository.findByUserId(userId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public List<CategoryResponse> getCategoriesByType(UUID userId, CategoryType type) {
        if (type == CategoryType.EXPENSE) {
            ensureMainExpenseCategories(userId);
            ensureDefaultExpenseSubcategories(userId);
        }
        return categoryRepository.findByUserIdAndType(userId, type).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public List<CategoryResponse> getSystemCategories() {
        return categoryRepository.findByUserIdIsNull().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public CategoryResponse updateCategory(Long id, CategoryRequest request) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Category not found"));

        if (request.getType() == null) {
            throw new RuntimeException("Category type is required");
        }
        category.setIcon(request.getIcon());
        category.setColor(request.getColor());
        applyHierarchyAndValidate(category, request, category.getUser() != null ? category.getUser().getId() : null,
                false);

        if (Boolean.TRUE.equals(category.getIsPrimary())
                && category.getType() == CategoryType.EXPENSE
                && category.getCategoryGroup() != null) {
            UUID ownerId = category.getUser() != null ? category.getUser().getId() : null;
            if (ownerId != null) {
                Category existing = findExistingPrimaryByGroup(ownerId, category.getCategoryGroup());
                if (existing != null && !existing.getId().equals(category.getId())) {
                    throw new RuntimeException("Main group already exists for this user");
                }
            }
        }

        Category updatedCategory = categoryRepository.save(category);
        return mapToResponse(updatedCategory);
    }

    @Override
    public void deleteCategory(UUID userId, Long id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        if (category.getUser() == null) {
            throw new BadRequestException("System category cannot be deleted");
        }
        if (!category.getUser().getId().equals(userId)) {
            throw new UnauthorizedException("Category does not belong to user");
        }
        if (categoryRepository.existsByParentId(id)) {
            throw new BadRequestException("Cannot delete category with subcategories");
        }
        if (transactionRepository.existsByUserIdAndCategoryId(userId, id)) {
            throw new BadRequestException("Category is used in transactions");
        }
        if (budgetRepository.existsByUserIdAndCategoryId(userId, id)) {
            throw new BadRequestException("Category is used in budgets");
        }
        if (recurringTransactionRepository.existsByUserIdAndCategoryId(userId, id)) {
            throw new BadRequestException("Category is used in recurring transactions");
        }
        if (categoryRuleRepository.existsByUserIdAndCategoryId(userId, id)) {
            throw new BadRequestException("Category is used in category rules");
        }

        categoryRepository.delete(category);
    }

    private CategoryResponse mapToResponse(Category category) {
        CategoryGroup resolvedGroup = resolveGroup(category);
        return new CategoryResponse(
                category.getId(),
                category.getName(),
                category.getType(),
                resolvedGroup,
                isPrimaryCategory(category),
                category.getIcon(),
                category.getColor(),
                category.getParent() != null ? category.getParent().getId() : null,
                category.getUser() == null);
    }

    private void applyHierarchyAndValidate(Category category, CategoryRequest request, UUID userId, boolean creating) {
        CategoryType type = request.getType();
        category.setType(type);

        Category parent = null;
        if (request.getParentId() != null) {
            parent = categoryRepository.findById(request.getParentId())
                    .orElseThrow(() -> new RuntimeException("Parent category not found"));
            if (!isParentAccessible(parent, userId)) {
                throw new RuntimeException("Parent category does not belong to user");
            }
            if (!creating && parent.getId().equals(category.getId())) {
                throw new RuntimeException("Category cannot be its own parent");
            }
        }

        if (parent != null) {
            if (parent.getType() != type) {
                throw new RuntimeException("Parent category type must match child category type");
            }
            category.setParent(parent);
            category.setIsPrimary(false);

            if (type == CategoryType.EXPENSE) {
                if (parent.getParent() != null) {
                    throw new RuntimeException("Expense category can only be created under a main category");
                }
                CategoryGroup parentGroup = resolveGroup(parent);
                if (parentGroup == null) {
                    throw new RuntimeException("Parent category must be NECESSARY, ACCUMULATION, or FLEXIBILITY");
                }
                category.setCategoryGroup(parentGroup);
            } else {
                category.setCategoryGroup(null);
            }

            category.setName(requireName(request.getName()));
            return;
        }

        category.setParent(null);
        if (type == CategoryType.EXPENSE) {
            CategoryGroup group = resolveRequestedGroup(request.getGroup(), request.getName());
            if (group == null) {
                group = resolveGroup(category);
            }
            if (group == null) {
                throw new RuntimeException("Expense main category must be NECESSARY, ACCUMULATION, or FLEXIBILITY");
            }
            category.setCategoryGroup(group);
            category.setIsPrimary(true);
            category.setName(resolvePrimaryName(group, request.getName()));
            return;
        }

        category.setCategoryGroup(null);
        category.setIsPrimary(true);
        category.setName(requireName(request.getName()));
    }

    private boolean isParentAccessible(Category parent, UUID userId) {
        if (parent.getUser() == null) {
            return true;
        }
        if (userId == null) {
            return false;
        }
        return parent.getUser().getId().equals(userId);
    }

    private String requireName(String value) {
        if (!StringUtils.hasText(value)) {
            throw new RuntimeException("Category name is required");
        }
        return value.trim();
    }

    private String resolvePrimaryName(CategoryGroup group, String requestedName) {
        if (StringUtils.hasText(requestedName)) {
            return requestedName.trim();
        }
        return switch (group) {
            case NECESSARY -> "Necessary";
            case ACCUMULATION -> "Accumulation";
            case FLEXIBILITY -> "Flexibility";
        };
    }

    private CategoryGroup resolveRequestedGroup(CategoryGroup requestedGroup, String name) {
        if (requestedGroup != null) {
            return requestedGroup;
        }
        if (!StringUtils.hasText(name)) {
            return null;
        }
        String normalized = name.trim().toLowerCase(Locale.ROOT);
        return switch (normalized) {
            case "necessary" -> CategoryGroup.NECESSARY;
            case "accumulation" -> CategoryGroup.ACCUMULATION;
            case "flexibility" -> CategoryGroup.FLEXIBILITY;
            default -> null;
        };
    }

    private CategoryGroup resolveGroup(Category category) {
        if (category == null) {
            return null;
        }
        if (category.getCategoryGroup() != null) {
            return category.getCategoryGroup();
        }
        if (category.getParent() != null) {
            return resolveGroup(category.getParent());
        }
        return resolveRequestedGroup(null, category.getName());
    }

    private boolean isPrimaryCategory(Category category) {
        if (category.getParent() != null) {
            return false;
        }
        if (category.getIsPrimary() != null) {
            return category.getIsPrimary();
        }
        return true;
    }

    private void ensureMainExpenseCategories(UUID userId) {
        List<Category> expenseCategories = categoryRepository.findByUserIdAndType(userId, CategoryType.EXPENSE);
        boolean hasNecessary = hasPrimaryGroup(expenseCategories, CategoryGroup.NECESSARY);
        boolean hasAccumulation = hasPrimaryGroup(expenseCategories, CategoryGroup.ACCUMULATION);
        boolean hasFlexibility = hasPrimaryGroup(expenseCategories, CategoryGroup.FLEXIBILITY);

        if (hasNecessary && hasAccumulation && hasFlexibility) {
            return;
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!hasNecessary) {
            categoryRepository.save(buildPrimaryExpenseCategory(user, CategoryGroup.NECESSARY));
        }
        if (!hasAccumulation) {
            categoryRepository.save(buildPrimaryExpenseCategory(user, CategoryGroup.ACCUMULATION));
        }
        if (!hasFlexibility) {
            categoryRepository.save(buildPrimaryExpenseCategory(user, CategoryGroup.FLEXIBILITY));
        }
    }

    private boolean hasPrimaryGroup(List<Category> categories, CategoryGroup group) {
        return categories.stream()
                .filter(Objects::nonNull)
                .filter(c -> c.getParent() == null)
                .map(this::resolveGroup)
                .anyMatch(group::equals);
    }

    private Category buildPrimaryExpenseCategory(User user, CategoryGroup group) {
        Category category = new Category();
        category.setUser(user);
        category.setType(CategoryType.EXPENSE);
        category.setCategoryGroup(group);
        category.setIsPrimary(true);
        category.setName(resolvePrimaryName(group, null));
        switch (group) {
            case NECESSARY -> {
                category.setIcon("home_outlined");
                category.setColor("#F59E0B");
            }
            case ACCUMULATION -> {
                category.setIcon("savings_outlined");
                category.setColor("#2CB67D");
            }
            case FLEXIBILITY -> {
                category.setIcon("auto_awesome_outlined");
                category.setColor("#6366F1");
            }
        }
        return category;
    }

    private Category findExistingPrimaryByGroup(UUID userId, CategoryGroup group) {
        List<Category> expenseCategories = categoryRepository.findByUserIdAndType(userId, CategoryType.EXPENSE);
        return expenseCategories.stream()
                .filter(c -> c.getParent() == null)
                .filter(c -> group.equals(resolveGroup(c)))
                .findFirst()
                .orElse(null);
    }

    private void ensureDefaultExpenseSubcategories(UUID userId) {
        List<Category> expenseCategories = categoryRepository.findByUserIdAndType(userId, CategoryType.EXPENSE);
        Category necessaryParent = findPrimaryByGroup(expenseCategories, CategoryGroup.NECESSARY);
        Category accumulationParent = findPrimaryByGroup(expenseCategories, CategoryGroup.ACCUMULATION);
        Category flexibilityParent = findPrimaryByGroup(expenseCategories, CategoryGroup.FLEXIBILITY);

        ensureSubcategories(expenseCategories, necessaryParent, NECESSARY_DEFAULT_SUBCATEGORIES);
        ensureSubcategories(expenseCategories, accumulationParent, ACCUMULATION_DEFAULT_SUBCATEGORIES);
        ensureSubcategories(expenseCategories, flexibilityParent, FLEXIBILITY_DEFAULT_SUBCATEGORIES);
    }

    private Category findPrimaryByGroup(List<Category> expenseCategories, CategoryGroup group) {
        return expenseCategories.stream()
                .filter(Objects::nonNull)
                .filter(c -> c.getParent() == null)
                .filter(c -> group.equals(resolveGroup(c)))
                .findFirst()
                .orElse(null);
    }

    private void ensureSubcategories(
            List<Category> existingExpenseCategories,
            Category parent,
            List<DefaultSubcategoryTemplate> templates) {
        if (parent == null || templates == null || templates.isEmpty()) {
            return;
        }

        var existingNames = existingExpenseCategories.stream()
                .filter(Objects::nonNull)
                .filter(c -> c.getParent() != null)
                .filter(c -> Objects.equals(c.getParent().getId(), parent.getId()))
                .map(Category::getName)
                .filter(StringUtils::hasText)
                .map(this::normalizeName)
                .collect(Collectors.toSet());

        for (DefaultSubcategoryTemplate template : templates) {
            String normalized = normalizeName(template.name());
            if (existingNames.contains(normalized)) {
                continue;
            }
            Category child = new Category();
            child.setUser(parent.getUser());
            child.setType(CategoryType.EXPENSE);
            child.setCategoryGroup(resolveGroup(parent));
            child.setIsPrimary(false);
            child.setParent(parent);
            child.setName(template.name());
            child.setIcon(template.icon());
            child.setColor(template.color());
            categoryRepository.save(child);
            existingNames.add(normalized);
        }
    }

    private String normalizeName(String value) {
        if (!StringUtils.hasText(value)) {
            return "";
        }
        return value.trim().toLowerCase(Locale.ROOT);
    }

    private record DefaultSubcategoryTemplate(String name, String icon, String color) {
    }
}
