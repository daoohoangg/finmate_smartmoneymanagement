package com.finmate.service;

import com.finmate.dto.request.BudgetRequest;
import com.finmate.dto.response.BudgetResponse;

import java.util.List;
import java.util.UUID;

public interface BudgetService {
    BudgetResponse createBudget(UUID userId, BudgetRequest request);

    BudgetResponse getBudgetById(Long id);

    List<BudgetResponse> getAllBudgetsByUser(UUID userId);

    BudgetResponse updateBudget(Long id, BudgetRequest request);

    void deleteBudget(Long id);
}
