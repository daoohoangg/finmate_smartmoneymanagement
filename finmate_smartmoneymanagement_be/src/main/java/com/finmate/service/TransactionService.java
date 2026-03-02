package com.finmate.service;

import com.finmate.dto.request.TransactionRequest;
import com.finmate.dto.response.TransactionResponse;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface TransactionService {
    TransactionResponse createTransaction(UUID userId, TransactionRequest request);

    TransactionResponse getTransactionById(UUID userId, Long id);

    List<TransactionResponse> getAllTransactionsByUser(UUID userId);

    List<TransactionResponse> getTransactionsByFilter(UUID userId, Long walletId, Long categoryId,
            LocalDateTime startDate, LocalDateTime endDate, String keyword, java.math.BigDecimal minAmount,
            java.math.BigDecimal maxAmount);

    TransactionResponse updateTransaction(UUID userId, Long id, TransactionRequest request);

    void deleteTransaction(UUID userId, Long id);
}
