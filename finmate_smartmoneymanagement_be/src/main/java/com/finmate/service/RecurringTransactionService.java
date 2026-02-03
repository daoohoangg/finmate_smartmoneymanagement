package com.finmate.service;

import com.finmate.dto.request.RecurringTransactionRequest;
import com.finmate.dto.response.RecurringTransactionResponse;

import java.util.List;
import java.util.UUID;

public interface RecurringTransactionService {
    RecurringTransactionResponse createRecurring(UUID userId, RecurringTransactionRequest request);

    RecurringTransactionResponse getRecurringById(Long id);

    List<RecurringTransactionResponse> getRecurringByUser(UUID userId);

    RecurringTransactionResponse updateRecurring(Long id, RecurringTransactionRequest request);

    void deleteRecurring(Long id);
}
