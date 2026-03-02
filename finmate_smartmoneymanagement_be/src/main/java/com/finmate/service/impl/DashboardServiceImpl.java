package com.finmate.service.impl;

import com.finmate.dto.response.DashboardResponse;
import com.finmate.entities.Budget;
import com.finmate.entities.InvestmentPlan;
import com.finmate.entities.SavingsGoal;
import com.finmate.entities.Transaction;
import com.finmate.entities.UserSettings;
import com.finmate.entities.Wallet;
import com.finmate.enums.TransactionType;
import com.finmate.repository.*;
import com.finmate.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardServiceImpl implements DashboardService {

    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final BudgetRepository budgetRepository;
    private final SavingsGoalRepository savingsGoalRepository;
    private final InvestmentPlanRepository investmentPlanRepository;
    private final UserSettingsRepository userSettingsRepository;

    @Override
    public DashboardResponse getDashboard(UUID userId) {
        // Net Worth = Total balance from all wallets
        BigDecimal netWorth = walletRepository.findByUserIdAndIsDeletedFalse(userId).stream()
                .map(Wallet::getBalance)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Get current month transactions
        YearMonth currentMonth = YearMonth.now();
        LocalDateTime startOfMonth = currentMonth.atDay(1).atStartOfDay();
        LocalDateTime endOfMonth = currentMonth.atEndOfMonth().atTime(23, 59, 59);

        List<Transaction> monthlyTransactions = transactionRepository
                .findByUserIdAndTransactionDateBetween(userId, startOfMonth, endOfMonth);

        // Calculate income and expense for this month
        BigDecimal totalIncome = monthlyTransactions.stream()
                .filter(t -> t.getType() == TransactionType.INCOME)
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalExpense = monthlyTransactions.stream()
                .filter(t -> t.getType() == TransactionType.EXPENSE)
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal cashflowThisMonth = totalIncome.subtract(totalExpense);

        // Budget metrics (Spending Budget - ZBB)
        List<Budget> budgets = budgetRepository.findByUserId(userId);
        BigDecimal totalAssigned = budgets.stream()
                .map(Budget::getAmountLimit)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalAvailable = budgets.stream()
                .map(budget -> budget.getAmountLimit().subtract(calculateSpentAmount(userId, budget)))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal toBeAssigned = netWorth.subtract(totalAssigned);

        // Savings Fund
        BigDecimal totalSavings = savingsGoalRepository.findByUserId(userId).stream()
                .map(SavingsGoal::getCurrentAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Investment
        BigDecimal totalInvested = investmentPlanRepository.findByUserId(userId).stream()
                .map(InvestmentPlan::getTotalInvested)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalEarmarked = totalSavings.add(totalInvested);

        Integer ageYourMoneyDays = calculateAgeYourMoney(userId);

        TopCategoryResult topCategory = calculateTopExpenseCategory(monthlyTransactions);

        UserSettings settings = userSettingsRepository.findByUserId(userId).orElse(null);
        netWorth = roundAmount(netWorth, settings);
        totalIncome = roundAmount(totalIncome, settings);
        totalExpense = roundAmount(totalExpense, settings);
        cashflowThisMonth = roundAmount(cashflowThisMonth, settings);
        totalAssigned = roundAmount(totalAssigned, settings);
        totalAvailable = roundAmount(totalAvailable, settings);
        toBeAssigned = roundAmount(toBeAssigned, settings);
        totalSavings = roundAmount(totalSavings, settings);
        totalInvested = roundAmount(totalInvested, settings);
        totalEarmarked = roundAmount(totalEarmarked, settings);
        if (topCategory != null && topCategory.amount != null) {
            topCategory.amount = roundAmount(topCategory.amount, settings);
        }

        return new DashboardResponse(
                netWorth,
                totalIncome,
                totalExpense,
                cashflowThisMonth,
                totalAssigned,
                totalAvailable,
                toBeAssigned,
                totalSavings,
                totalInvested,
                totalEarmarked,
                ageYourMoneyDays,
                topCategory != null ? topCategory.name : null,
                topCategory != null ? topCategory.amount : null);
    }

    @Override
    public DashboardResponse postDashboard(UUID userId) {
        return null;
    }

    private BigDecimal calculateSpentAmount(UUID userId, Budget budget) {
        java.time.LocalDateTime startDate;
        java.time.LocalDateTime endDate;

        if (budget.getPeriod() == com.finmate.enums.BudgetPeriod.WEEK) {
            java.time.LocalDateTime now = java.time.LocalDateTime.now();
            java.time.LocalDateTime startOfWeek = now.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY))
                    .withHour(0).withMinute(0).withSecond(0).withNano(0);
            java.time.LocalDateTime endOfWeek = now.with(java.time.temporal.TemporalAdjusters.nextOrSame(java.time.DayOfWeek.SUNDAY))
                    .withHour(23).withMinute(59).withSecond(59).withNano(0);
            startDate = startOfWeek;
            endDate = endOfWeek;
        } else {
            YearMonth currentMonth = YearMonth.now();
            startDate = currentMonth.atDay(1).atStartOfDay();
            endDate = currentMonth.atEndOfMonth().atTime(23, 59, 59);
        }

        List<Transaction> transactions = transactionRepository.findByUserIdAndTransactionDateBetween(
                userId, startDate, endDate);

        return transactions.stream()
                .filter(t -> t.getCategory() != null && t.getCategory().getId().equals(budget.getCategory().getId()))
                .filter(t -> t.getType() == TransactionType.EXPENSE)
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private Integer calculateAgeYourMoney(UUID userId) {
        List<Transaction> transactions = transactionRepository.findByUserIdOrderByTransactionDateDesc(userId);
        if (transactions.isEmpty()) {
            return 0;
        }
        transactions.sort(java.util.Comparator.comparing(Transaction::getTransactionDate));
        java.time.LocalDateTime lastIncomeDate = null;
        long totalDays = 0;
        long count = 0;
        for (Transaction transaction : transactions) {
            if (transaction.getType() == TransactionType.INCOME) {
                lastIncomeDate = transaction.getTransactionDate();
            } else if (transaction.getType() == TransactionType.EXPENSE && lastIncomeDate != null) {
                long days = java.time.Duration.between(lastIncomeDate, transaction.getTransactionDate()).toDays();
                if (days >= 0) {
                    totalDays += days;
                    count++;
                }
            }
        }
        if (count == 0) {
            return 0;
        }
        return Math.toIntExact(totalDays / count);
    }

    private TopCategoryResult calculateTopExpenseCategory(List<Transaction> transactions) {
        Map<String, BigDecimal> totals = transactions.stream()
                .filter(t -> t.getType() == TransactionType.EXPENSE)
                .collect(Collectors.groupingBy(
                        t -> t.getCategory() != null ? t.getCategory().getName() : "Uncategorized",
                        Collectors.mapping(Transaction::getAmount,
                                Collectors.reducing(BigDecimal.ZERO, BigDecimal::add))));
        return totals.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(entry -> new TopCategoryResult(entry.getKey(), entry.getValue()))
                .orElse(null);
    }

    private BigDecimal roundAmount(BigDecimal value, UserSettings settings) {
        if (value == null) {
            return null;
        }
        int scale = settings != null && settings.getRoundingScale() != null ? settings.getRoundingScale() : 2;
        RoundingMode mode = RoundingMode.HALF_UP;
        if (settings != null && settings.getRoundingMode() != null) {
            try {
                mode = RoundingMode.valueOf(settings.getRoundingMode());
            } catch (Exception ignored) {
                mode = RoundingMode.HALF_UP;
            }
        }
        return value.setScale(scale, mode);
    }

    private static class TopCategoryResult {
        private final String name;
        private BigDecimal amount;

        private TopCategoryResult(String name, BigDecimal amount) {
            this.name = name;
            this.amount = amount;
        }
    }



}
