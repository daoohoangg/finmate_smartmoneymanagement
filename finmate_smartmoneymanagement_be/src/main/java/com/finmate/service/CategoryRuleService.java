package com.finmate.service;

import com.finmate.dto.request.CategoryRuleRequest;
import com.finmate.dto.response.CategoryRuleResponse;
import com.finmate.entities.Category;

import java.util.List;
import java.util.UUID;

public interface CategoryRuleService {
    CategoryRuleResponse createRule(UUID userId, CategoryRuleRequest request);

    CategoryRuleResponse getRuleById(Long id);

    List<CategoryRuleResponse> getRulesByUser(UUID userId);

    CategoryRuleResponse updateRule(Long id, CategoryRuleRequest request);

    void deleteRule(Long id);

    Category suggestCategory(UUID userId, String content);
}
