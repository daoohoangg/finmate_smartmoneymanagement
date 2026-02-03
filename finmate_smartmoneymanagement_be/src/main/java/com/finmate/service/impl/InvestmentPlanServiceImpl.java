package com.finmate.service.impl;

import com.finmate.dto.request.InvestmentPlanRequest;
import com.finmate.dto.response.InvestmentPlanResponse;
import com.finmate.entities.InvestmentPlan;
import com.finmate.entities.SavingsGoal;
import com.finmate.entities.User;
import com.finmate.repository.InvestmentPlanRepository;
import com.finmate.repository.SavingsGoalRepository;
import com.finmate.repository.UserRepository;
import com.finmate.service.InvestmentPlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class InvestmentPlanServiceImpl implements InvestmentPlanService {

    private final InvestmentPlanRepository investmentPlanRepository;
    private final UserRepository userRepository;
    private final SavingsGoalRepository savingsGoalRepository;

    @Override
    public InvestmentPlanResponse createPlan(UUID userId, InvestmentPlanRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (request.getSourceSavingsGoalId() == null) {
            throw new RuntimeException("Source savings goal is required for investment plan");
        }

        InvestmentPlan plan = new InvestmentPlan();
        plan.setUser(user);
        plan.setName(request.getName());
        plan.setDescription(request.getDescription());
        plan.setPeriodicAmount(request.getPeriodicAmount());
        plan.setFrequency(request.getFrequency());
        plan.setNextExecutionDate(request.getNextExecutionDate());
        plan.setCurrentValue(request.getCurrentValue());
        plan.setIsActive(request.getIsActive());

        SavingsGoal savingsGoal = savingsGoalRepository.findById(request.getSourceSavingsGoalId())
                .orElseThrow(() -> new RuntimeException("Savings goal not found"));
        if (!savingsGoal.getUser().getId().equals(userId)) {
            throw new RuntimeException("Savings goal does not belong to user");
        }
        plan.setSourceSavingsGoal(savingsGoal);

        InvestmentPlan saved = investmentPlanRepository.save(plan);
        return mapToResponse(saved);
    }

    @Override
    public InvestmentPlanResponse getPlanById(Long id) {
        InvestmentPlan plan = investmentPlanRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Investment plan not found"));
        return mapToResponse(plan);
    }

    @Override
    public List<InvestmentPlanResponse> getPlansByUser(UUID userId) {
        return investmentPlanRepository.findByUserId(userId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public InvestmentPlanResponse updatePlan(Long id, InvestmentPlanRequest request) {
        InvestmentPlan plan = investmentPlanRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Investment plan not found"));

        plan.setName(request.getName());
        plan.setDescription(request.getDescription());
        plan.setPeriodicAmount(request.getPeriodicAmount());
        plan.setFrequency(request.getFrequency());
        plan.setNextExecutionDate(request.getNextExecutionDate());
        plan.setCurrentValue(request.getCurrentValue());
        if (request.getIsActive() != null) {
            plan.setIsActive(request.getIsActive());
        }

        if (request.getSourceSavingsGoalId() != null) {
            SavingsGoal savingsGoal = savingsGoalRepository.findById(request.getSourceSavingsGoalId())
                    .orElseThrow(() -> new RuntimeException("Savings goal not found"));
            if (!savingsGoal.getUser().getId().equals(plan.getUser().getId())) {
                throw new RuntimeException("Savings goal does not belong to user");
            }
            plan.setSourceSavingsGoal(savingsGoal);
        }

        InvestmentPlan updated = investmentPlanRepository.save(plan);
        return mapToResponse(updated);
    }

    @Override
    public void deletePlan(Long id) {
        if (!investmentPlanRepository.existsById(id)) {
            throw new RuntimeException("Investment plan not found");
        }
        investmentPlanRepository.deleteById(id);
    }

    private InvestmentPlanResponse mapToResponse(InvestmentPlan plan) {
        return new InvestmentPlanResponse(
                plan.getId(),
                plan.getName(),
                plan.getDescription(),
                plan.getPeriodicAmount(),
                plan.getFrequency(),
                plan.getNextExecutionDate(),
                plan.getTotalInvested(),
                plan.getCurrentValue(),
                plan.getIsActive(),
                plan.getSourceSavingsGoal() != null ? plan.getSourceSavingsGoal().getId() : null,
                plan.getSourceSavingsGoal() != null ? plan.getSourceSavingsGoal().getName() : null);
    }
}
