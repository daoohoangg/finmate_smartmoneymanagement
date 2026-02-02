package com.finmate.service;

import com.finmate.dto.request.SavingsGoalRequest;
import com.finmate.dto.response.SavingsGoalResponse;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public interface SavingsGoalService {
    SavingsGoalResponse createSavingsGoal(UUID userId, SavingsGoalRequest request);

    SavingsGoalResponse getSavingsGoalById(Long id);

    List<SavingsGoalResponse> getAllSavingsGoalsByUser(UUID userId);

    SavingsGoalResponse updateSavingsGoal(Long id, SavingsGoalRequest request);

    SavingsGoalResponse contributeToGoal(Long id, BigDecimal amount);

    void deleteSavingsGoal(Long id);
}
