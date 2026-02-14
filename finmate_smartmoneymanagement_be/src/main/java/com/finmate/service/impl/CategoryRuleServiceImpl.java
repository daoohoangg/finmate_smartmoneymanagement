package com.finmate.service.impl;

import com.finmate.dto.request.CategoryRuleRequest;
import com.finmate.dto.response.CategoryRuleResponse;
import com.finmate.entities.Category;
import com.finmate.entities.CategoryRule;
import com.finmate.entities.User;
import com.finmate.enums.CategoryType;
import com.finmate.enums.RuleMatchType;
import com.finmate.repository.CategoryRepository;
import com.finmate.repository.CategoryRuleRepository;
import com.finmate.repository.UserRepository;
import com.finmate.service.CategoryRuleService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CategoryRuleServiceImpl implements CategoryRuleService {

    private final CategoryRuleRepository categoryRuleRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;

    @Override
    public CategoryRuleResponse createRule(UUID userId, CategoryRuleRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        if (request.getKeyword() == null || request.getKeyword().isBlank()) {
            throw new RuntimeException("Keyword is required");
        }
        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found"));
        if (category.getUser() != null && !category.getUser().getId().equals(userId)) {
            throw new RuntimeException("Category does not belong to user");
        }
        validateRuleCategory(category);

        CategoryRule rule = new CategoryRule();
        rule.setUser(user);
        rule.setCategory(category);
        rule.setKeyword(normalize(request.getKeyword()));
        rule.setMatchType(request.getMatchType() != null ? request.getMatchType() : RuleMatchType.CONTAINS);
        rule.setPriority(request.getPriority());
        rule.setIsActive(request.getIsActive());

        CategoryRule saved = categoryRuleRepository.save(rule);
        return mapToResponse(saved);
    }

    @Override
    public CategoryRuleResponse getRuleById(Long id) {
        CategoryRule rule = categoryRuleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rule not found"));
        return mapToResponse(rule);
    }

    @Override
    public List<CategoryRuleResponse> getRulesByUser(UUID userId) {
        return categoryRuleRepository.findByUserId(userId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public CategoryRuleResponse updateRule(Long id, CategoryRuleRequest request) {
        CategoryRule rule = categoryRuleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Rule not found"));

        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new RuntimeException("Category not found"));
            if (category.getUser() != null && !category.getUser().getId().equals(rule.getUser().getId())) {
                throw new RuntimeException("Category does not belong to user");
            }
            validateRuleCategory(category);
            rule.setCategory(category);
        }

        if (request.getKeyword() != null) {
            if (request.getKeyword().isBlank()) {
                throw new RuntimeException("Keyword cannot be blank");
            }
            rule.setKeyword(normalize(request.getKeyword()));
        }
        if (request.getMatchType() != null) {
            rule.setMatchType(request.getMatchType());
        }
        if (request.getPriority() != null) {
            rule.setPriority(request.getPriority());
        }
        if (request.getIsActive() != null) {
            rule.setIsActive(request.getIsActive());
        }

        CategoryRule updated = categoryRuleRepository.save(rule);
        return mapToResponse(updated);
    }

    @Override
    public void deleteRule(Long id) {
        if (!categoryRuleRepository.existsById(id)) {
            throw new RuntimeException("Rule not found");
        }
        categoryRuleRepository.deleteById(id);
    }

    @Override
    public Category suggestCategory(UUID userId, String content) {
        if (content == null || content.isBlank()) {
            return null;
        }
        String normalized = normalize(content);
        List<CategoryRule> rules = categoryRuleRepository.findByUserIdAndIsActiveTrueOrderByPriorityDesc(userId);
        for (CategoryRule rule : rules) {
            if (matches(rule, normalized)) {
                return rule.getCategory();
            }
        }
        return null;
    }

    private boolean matches(CategoryRule rule, String content) {
        String keyword = rule.getKeyword();
        if (keyword == null) {
            return false;
        }
        return switch (rule.getMatchType()) {
            case EXACT -> content.equals(keyword);
            case STARTS_WITH -> content.startsWith(keyword);
            case ENDS_WITH -> content.endsWith(keyword);
            case CONTAINS -> content.contains(keyword);
        };
    }

    private String normalize(String text) {
        return text == null ? null : text.trim().toLowerCase();
    }

    private CategoryRuleResponse mapToResponse(CategoryRule rule) {
        return new CategoryRuleResponse(
                rule.getId(),
                rule.getCategory().getId(),
                rule.getCategory().getName(),
                rule.getKeyword(),
                rule.getMatchType(),
                rule.getPriority(),
                rule.getIsActive());
    }

    private void validateRuleCategory(Category category) {
        if (category.getType() != CategoryType.EXPENSE) {
            throw new RuntimeException("Category rule must target an EXPENSE category");
        }
        if (category.getParent() == null || categoryRepository.existsByParentId(category.getId())) {
            throw new RuntimeException("Category rule must target an expense subcategory");
        }
    }
}
