package com.finmate.service.impl;

import com.finmate.dto.response.*;
import com.finmate.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SyncServiceImpl implements SyncService {

    private final WalletService walletService;
    private final CategoryService categoryService;
    private final BudgetService budgetService;
    private final SavingsGoalService savingsGoalService;
    private final InvestmentPlanService investmentPlanService;
    private final RecurringTransactionService recurringTransactionService;
    private final TransactionService transactionService;
    private final CategoryRuleService categoryRuleService;
    private final UserSettingsService userSettingsService;

    @Override
    public SyncResponse syncAll(UUID userId) {
        return new SyncResponse(
                walletService.getAllWalletsByUser(userId),
                categoryService.getAllCategoriesByUser(userId),
                budgetService.getAllBudgetsByUser(userId),
                savingsGoalService.getAllSavingsGoalsByUser(userId),
                investmentPlanService.getPlansByUser(userId),
                recurringTransactionService.getRecurringByUser(userId),
                transactionService.getAllTransactionsByUser(userId),
                categoryRuleService.getRulesByUser(userId),
                userSettingsService.getUserSettings(userId));
    }
}
