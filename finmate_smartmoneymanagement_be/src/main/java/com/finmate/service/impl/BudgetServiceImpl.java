package com.finmate.service.impl;

import com.finmate.dto.request.BudgetRequest;
import com.finmate.dto.response.BudgetResponse;
import com.finmate.entities.Budget;
import com.finmate.entities.Category;
import com.finmate.entities.Transaction;
import com.finmate.entities.User;
import com.finmate.enums.TransactionType;
import com.finmate.repository.BudgetRepository;
import com.finmate.repository.CategoryRepository;
import com.finmate.repository.TransactionRepository;
import com.finmate.repository.UserRepository;
import com.finmate.service.BudgetService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BudgetServiceImpl implements BudgetService {

    private final BudgetRepository budgetRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;

    @Override
    public BudgetResponse createBudget(UUID userId, BudgetRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found"));

        Budget budget = new Budget();
        budget.setUser(user);
        budget.setCategory(category);
        budget.setAmountLimit(request.getAmountLimit());
        budget.setPeriod(request.getPeriod());

        Budget savedBudget = budgetRepository.save(budget);
        return mapToResponse(savedBudget, userId);
    }

    @Override
    public BudgetResponse getBudgetById(Long id) {
        Budget budget = budgetRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Budget not found"));
        return mapToResponse(budget, budget.getUser().getId());
    }

    @Override
    public List<BudgetResponse> getAllBudgetsByUser(UUID userId) {
        return budgetRepository.findByUserId(userId).stream()
                .map(budget -> mapToResponse(budget, userId))
                .collect(Collectors.toList());
    }

    @Override
    public BudgetResponse updateBudget(Long id, BudgetRequest request) {
        Budget budget = budgetRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Budget not found"));

        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new RuntimeException("Category not found"));
            budget.setCategory(category);
        }

        budget.setAmountLimit(request.getAmountLimit());
        budget.setPeriod(request.getPeriod());

        Budget updatedBudget = budgetRepository.save(budget);
        return mapToResponse(updatedBudget, budget.getUser().getId());
    }

    @Override
    public void deleteBudget(Long id) {
        if (!budgetRepository.existsById(id)) {
            throw new RuntimeException("Budget not found");
        }
        budgetRepository.deleteById(id);
    }

    private BudgetResponse mapToResponse(Budget budget, UUID userId) {
        // Calculate spent amount for this budget period
        BigDecimal spent = calculateSpentAmount(userId, budget.getCategory().getId());
        BigDecimal available = budget.getAmountLimit().subtract(spent);

        // Calculate percentage
        int percentageUsed = 0;
        if (budget.getAmountLimit().compareTo(BigDecimal.ZERO) > 0) {
            percentageUsed = spent.multiply(BigDecimal.valueOf(100))
                    .divide(budget.getAmountLimit(), 0, RoundingMode.HALF_UP)
                    .intValue();
        }

        return new BudgetResponse(
                budget.getId(),
                budget.getCategory().getId(),
                budget.getCategory().getName(),
                budget.getAmountLimit(),
                spent,
                available,
                budget.getPeriod(),
                percentageUsed);
    }

    private BigDecimal calculateSpentAmount(UUID userId, Long categoryId) {
        // Get current month transactions for this category
        YearMonth currentMonth = YearMonth.now();
        LocalDateTime startOfMonth = currentMonth.atDay(1).atStartOfDay();
        LocalDateTime endOfMonth = currentMonth.atEndOfMonth().atTime(23, 59, 59);

        List<Transaction> transactions = transactionRepository.findByUserIdAndTransactionDateBetween(
                userId, startOfMonth, endOfMonth);

        return transactions.stream()
                .filter(t -> t.getCategory() != null && t.getCategory().getId().equals(categoryId))
                .filter(t -> t.getType() == TransactionType.EXPENSE)
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
