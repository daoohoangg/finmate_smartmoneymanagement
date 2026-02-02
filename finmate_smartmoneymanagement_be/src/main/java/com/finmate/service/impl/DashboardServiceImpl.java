package com.finmate.service.impl;

import com.finmate.dto.response.DashboardResponse;
import com.finmate.entities.Budget;
import com.finmate.entities.InvestmentPlan;
import com.finmate.entities.SavingsGoal;
import com.finmate.entities.Transaction;
import com.finmate.entities.Wallet;
import com.finmate.enums.TransactionType;
import com.finmate.repository.*;
import com.finmate.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DashboardServiceImpl implements DashboardService {

    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final BudgetRepository budgetRepository;
    private final SavingsGoalRepository savingsGoalRepository;
    private final InvestmentPlanRepository investmentPlanRepository;

    @Override
    public DashboardResponse getDashboard(UUID userId) {
        // Net Worth = Total balance from all wallets
        BigDecimal netWorth = walletRepository.findByUserId(userId).stream()
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

        // Available = Assigned - Spent (simplified, actual should calculate per
        // category)
        BigDecimal totalAvailable = totalAssigned.subtract(totalExpense);

        // Savings Fund
        BigDecimal totalSavings = savingsGoalRepository.findByUserId(userId).stream()
                .map(SavingsGoal::getCurrentAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Investment
        BigDecimal totalInvested = investmentPlanRepository.findByUserId(userId).stream()
                .map(InvestmentPlan::getTotalInvested)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new DashboardResponse(
                netWorth,
                totalIncome,
                totalExpense,
                cashflowThisMonth,
                totalAssigned,
                totalAvailable,
                totalSavings,
                totalInvested);
    }
}
