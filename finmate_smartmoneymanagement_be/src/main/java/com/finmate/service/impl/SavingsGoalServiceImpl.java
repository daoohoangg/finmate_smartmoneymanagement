package com.finmate.service.impl;

import com.finmate.dto.request.SavingsGoalRequest;
import com.finmate.dto.response.SavingsGoalResponse;
import com.finmate.entities.SavingsGoal;
import com.finmate.entities.User;
import com.finmate.repository.SavingsGoalRepository;
import com.finmate.repository.UserRepository;
import com.finmate.service.SavingsGoalService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SavingsGoalServiceImpl implements SavingsGoalService {

    private final SavingsGoalRepository savingsGoalRepository;
    private final UserRepository userRepository;

    @Override
    public SavingsGoalResponse createSavingsGoal(UUID userId, SavingsGoalRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        SavingsGoal savingsGoal = new SavingsGoal();
        savingsGoal.setUser(user);
        savingsGoal.setName(request.getName());
        savingsGoal.setTargetAmount(request.getTargetAmount());
        savingsGoal.setCurrentAmount(BigDecimal.ZERO);
        savingsGoal.setMonthlyContribution(request.getMonthlyContribution());
        savingsGoal.setDeadline(request.getDeadline());
        savingsGoal.setIcon(request.getIcon());
        savingsGoal.setCreatedAt(LocalDate.now());

        SavingsGoal savedGoal = savingsGoalRepository.save(savingsGoal);
        return mapToResponse(savedGoal);
    }

    @Override
    public SavingsGoalResponse getSavingsGoalById(Long id) {
        SavingsGoal savingsGoal = savingsGoalRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Savings goal not found"));
        return mapToResponse(savingsGoal);
    }

    @Override
    public List<SavingsGoalResponse> getAllSavingsGoalsByUser(UUID userId) {
        return savingsGoalRepository.findByUserId(userId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public SavingsGoalResponse updateSavingsGoal(Long id, SavingsGoalRequest request) {
        SavingsGoal savingsGoal = savingsGoalRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Savings goal not found"));

        savingsGoal.setName(request.getName());
        savingsGoal.setTargetAmount(request.getTargetAmount());
        savingsGoal.setMonthlyContribution(request.getMonthlyContribution());
        savingsGoal.setDeadline(request.getDeadline());
        savingsGoal.setIcon(request.getIcon());

        SavingsGoal updatedGoal = savingsGoalRepository.save(savingsGoal);
        return mapToResponse(updatedGoal);
    }

    @Override
    public SavingsGoalResponse contributeToGoal(Long id, BigDecimal amount) {
        SavingsGoal savingsGoal = savingsGoalRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Savings goal not found"));

        savingsGoal.setCurrentAmount(savingsGoal.getCurrentAmount().add(amount));
        SavingsGoal updatedGoal = savingsGoalRepository.save(savingsGoal);
        return mapToResponse(updatedGoal);
    }

    @Override
    public void deleteSavingsGoal(Long id) {
        if (!savingsGoalRepository.existsById(id)) {
            throw new RuntimeException("Savings goal not found");
        }
        savingsGoalRepository.deleteById(id);
    }

    private SavingsGoalResponse mapToResponse(SavingsGoal savingsGoal) {
        int percentageAchieved = 0;
        if (savingsGoal.getTargetAmount() != null &&
                savingsGoal.getTargetAmount().compareTo(BigDecimal.ZERO) > 0) {
            percentageAchieved = savingsGoal.getCurrentAmount()
                    .multiply(BigDecimal.valueOf(100))
                    .divide(savingsGoal.getTargetAmount(), 0, RoundingMode.HALF_UP)
                    .intValue();
        }

        return new SavingsGoalResponse(
                savingsGoal.getId(),
                savingsGoal.getName(),
                savingsGoal.getTargetAmount(),
                savingsGoal.getCurrentAmount(),
                savingsGoal.getMonthlyContribution(),
                savingsGoal.getDeadline(),
                savingsGoal.getIcon(),
                percentageAchieved);
    }
}
