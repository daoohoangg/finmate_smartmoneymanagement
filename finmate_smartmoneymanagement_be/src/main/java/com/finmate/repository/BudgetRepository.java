package com.finmate.repository;

import com.finmate.entities.Budget;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BudgetRepository extends JpaRepository<Budget, Long> {
    List<Budget> findByUserId(UUID userId);

    Optional<Budget> findByUserIdAndCategoryId(UUID userId, Long categoryId);

    boolean existsByUserIdAndCategoryId(UUID userId, Long categoryId);


}
