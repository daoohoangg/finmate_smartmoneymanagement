package com.finmate.scheduler;

import com.finmate.dto.request.TransactionRequest;
import com.finmate.entities.InvestmentPlan;
import com.finmate.enums.InvestmentFrequency;
import com.finmate.enums.TransactionType;
import com.finmate.repository.InvestmentPlanRepository;
import com.finmate.repository.WalletRepository;
import com.finmate.service.TransactionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class InvestmentPlanScheduler {

    private final InvestmentPlanRepository investmentPlanRepository;
    private final TransactionService transactionService;
    private final WalletRepository walletRepository;

    @Scheduled(cron = "0 15 2 * * *")
    public void executeInvestmentPlans() {
        LocalDate today = LocalDate.now();
        List<InvestmentPlan> duePlans = investmentPlanRepository
                .findByIsActiveAndNextExecutionDateLessThanEqual(true, today);

        for (InvestmentPlan plan : duePlans) {
            if (plan.getNextExecutionDate() == null) {
                continue;
            }
            try {
                TransactionRequest request = new TransactionRequest();
                Long fallbackWalletId = walletRepository.findByUserIdAndIsDeletedFalse(plan.getUser().getId())
                        .stream()
                        .findFirst()
                        .map(w -> w.getId())
                        .orElse(null);
                request.setWalletId(fallbackWalletId);
                if (request.getWalletId() == null) {
                    log.warn("Investment plan {} skipped: no wallet available", plan.getId());
                    continue;
                }
                request.setType(TransactionType.INVESTMENT_EXECUTION);
                request.setAmount(plan.getPeriodicAmount());
                request.setInvestmentPlanId(plan.getId());
                request.setSavingsGoalId(plan.getSourceSavingsGoal() != null ? plan.getSourceSavingsGoal().getId() : null);
                request.setTransactionDate(LocalDateTime.of(plan.getNextExecutionDate(), java.time.LocalTime.NOON));

                transactionService.createTransaction(plan.getUser().getId(), request);

                plan.setNextExecutionDate(calculateNextDate(plan.getNextExecutionDate(), plan.getFrequency()));
                investmentPlanRepository.save(plan);
            } catch (Exception ex) {
                log.warn("Failed to execute investment plan {}: {}", plan.getId(), ex.getMessage());
            }
        }
    }

    private LocalDate calculateNextDate(LocalDate current, InvestmentFrequency frequency) {
        if (frequency == null) {
            return current.plusMonths(1);
        }
        return switch (frequency) {
            case DAILY -> current.plusDays(1);
            case WEEKLY -> current.plusWeeks(1);
            case MONTHLY -> current.plusMonths( 1);
            case QUARTERLY -> current.plusMonths(3);
        };
    }
}
