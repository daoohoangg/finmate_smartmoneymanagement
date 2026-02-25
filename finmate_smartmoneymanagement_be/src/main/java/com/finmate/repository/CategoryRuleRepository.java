package com.finmate.repository;

import com.finmate.entities.CategoryRule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface CategoryRuleRepository extends JpaRepository<CategoryRule, Long> {
    List<CategoryRule> findByUserId(UUID userId);

    List<CategoryRule> findByUserIdAndIsActiveTrueOrderByPriorityDesc(UUID userId);

    boolean existsByUserIdAndCategoryId(UUID userId, Long categoryId);
}
