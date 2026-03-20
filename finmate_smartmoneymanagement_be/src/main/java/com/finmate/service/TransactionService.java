package com.finmate.service;

import com.finmate.dto.request.TransactionRequest;
import com.finmate.dto.response.TransactionResponse;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface TransactionService {

    TransactionResponse createTransaction(UUID userId, TransactionRequest request);

    TransactionResponse getTransactionById(UUID userId, Long transactionId);

    List<TransactionResponse> getTransactionsByWalletAndDateRange(UUID userId, Long walletId, LocalDateTime start, LocalDateTime end);

    void deleteTransaction(UUID userId, Long transactionId);
}
