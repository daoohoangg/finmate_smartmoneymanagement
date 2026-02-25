package com.finmate.service;

import com.finmate.dto.request.CategoryRequest;
import com.finmate.dto.response.CategoryResponse;
import com.finmate.enums.CategoryType;

import java.util.List;
import java.util.UUID;

public interface CategoryService {
    CategoryResponse createCategory(UUID userId, CategoryRequest request);

    CategoryResponse getCategoryById(Long id);

    List<CategoryResponse> getAllCategoriesByUser(UUID userId);

    List<CategoryResponse> getCategoriesByType(UUID userId, CategoryType type);

    List<CategoryResponse> getSystemCategories();

    CategoryResponse updateCategory(Long id, CategoryRequest request);

    void deleteCategory(UUID userId, Long id);
}
