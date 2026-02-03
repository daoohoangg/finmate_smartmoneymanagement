package com.finmate.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

@Data
@AllArgsConstructor
public class SyncResponse {
    private List<WalletResponse> wallets;
    private List<CategoryResponse> categories;
    private List<BudgetResponse> budgets;
    private List<SavingsGoalResponse> savingsGoals;
    private List<InvestmentPlanResponse> investmentPlans;
    private List<RecurringTransactionResponse> recurringTransactions;
    private List<TransactionResponse> transactions;
    private List<CategoryRuleResponse> categoryRules;
    private UserSettingsResponse settings;
}
