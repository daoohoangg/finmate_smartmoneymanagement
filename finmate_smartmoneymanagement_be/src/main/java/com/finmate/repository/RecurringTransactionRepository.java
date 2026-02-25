package com.finmate.repository;

import com.finmate.entities.RecurringTransaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface RecurringTransactionRepository extends JpaRepository<RecurringTransaction, Long> {
    List<RecurringTransaction> findByUserId(UUID userId);

    List<RecurringTransaction> findByUserIdAndIsActive(UUID userId, Boolean isActive);

    boolean existsByUserIdAndCategoryId(UUID userId, Long categoryId);

    List<RecurringTransaction> findByIsActiveAndNextOccurrenceDateLessThanEqual(Boolean isActive, LocalDate date);
}
