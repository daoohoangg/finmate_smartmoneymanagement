package com.finmate.service;

import com.finmate.dto.request.InvestmentPlanRequest;
import com.finmate.dto.response.InvestmentPlanResponse;

import java.util.List;
import java.util.UUID;

public interface InvestmentPlanService {
    InvestmentPlanResponse createPlan(UUID userId, InvestmentPlanRequest request);

    InvestmentPlanResponse getPlanById(Long id);

    List<InvestmentPlanResponse> getPlansByUser(UUID userId);

    InvestmentPlanResponse updatePlan(Long id, InvestmentPlanRequest request);

    void deletePlan(Long id);
}
