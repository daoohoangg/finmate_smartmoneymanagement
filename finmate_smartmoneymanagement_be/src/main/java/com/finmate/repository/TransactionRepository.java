package com.finmate.repository;

import com.finmate.entities.Transaction;
import com.finmate.enums.TransactionType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByUserId(UUID userId);

    List<Transaction> findByUserIdOrderByTransactionDateDesc(UUID userId);

    List<Transaction> findByWalletId(Long walletId);

    List<Transaction> findByUserIdAndTransactionDateBetween(UUID userId, LocalDateTime start, LocalDateTime end);

    List<Transaction> findByUserIdAndType(UUID userId, TransactionType type);

    @Query("SELECT t FROM Transaction t WHERE t.user.id = :userId AND " +
            "(:walletId IS NULL OR t.wallet.id = :walletId) AND " +
            "(:categoryId IS NULL OR t.category.id = :categoryId) AND " +
            "t.transactionDate BETWEEN :startDate AND :endDate")
    List<Transaction> findByFilters(@Param("userId") UUID userId,
            @Param("walletId") Long walletId,
            @Param("categoryId") Long categoryId,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate);
}
