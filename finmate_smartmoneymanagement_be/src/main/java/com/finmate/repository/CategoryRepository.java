package com.finmate.repository;

import com.finmate.entities.Category;
import com.finmate.enums.CategoryType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, Long> {
    List<Category> findByUserId(UUID userId);

    List<Category> findByUserIdAndType(UUID userId, CategoryType type);

    List<Category> findByUserIdIsNull(); // System categories

    List<Category> findByUserIdAndNameIgnoreCase(UUID userId, String name);

    List<Category> findByUserIdIsNullAndNameIgnoreCase(String name);

    boolean existsByParentId(Long parentId);
}
