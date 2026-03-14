package com.finmate.service.impl;

import com.finmate.dto.request.BudgetReassignRequest;
import com.finmate.dto.request.BudgetContributionRequest;
import com.finmate.dto.request.BudgetRequest;
import com.finmate.dto.response.BudgetResponse;
import com.finmate.entities.Budget;
import com.finmate.entities.Category;
import com.finmate.entities.Transaction;
import com.finmate.entities.User;
import com.finmate.entities.Wallet;
import com.finmate.enums.CategoryType;
import com.finmate.enums.TransactionType;
import com.finmate.exception.BadRequestException;
import com.finmate.exception.ResourceNotFoundException;
import com.finmate.repository.BudgetRepository;
import com.finmate.repository.CategoryRepository;
import com.finmate.repository.TransactionRepository;
import com.finmate.repository.UserRepository;
import com.finmate.repository.WalletRepository;
import com.finmate.service.BudgetService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.temporal.TemporalAdjusters;
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
    private final WalletRepository walletRepository;

    @Override
    public BudgetResponse createBudget(UUID userId, BudgetRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found"));
        validateBudgetCategory(userId, category);

        Budget budget = new Budget();
        budget.setUser(user);
        budget.setCategory(category);
        budget.setName(resolveBudgetName(request.getName(), category.getName()));
        budget.setAmountLimit(request.getAmountLimit());
        budget.setSavedAmount(BigDecimal.ZERO);
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
            validateBudgetCategory(budget.getUser().getId(), category);
            budget.setCategory(category);
        }

        if (request.getName() != null) {
            if (!StringUtils.hasText(request.getName())) {
                throw new RuntimeException("Budget name is required");
            }
            budget.setName(request.getName().trim());
        } else if (!StringUtils.hasText(budget.getName())) {
            budget.setName(budget.getCategory().getName());
        }

        budget.setAmountLimit(request.getAmountLimit());
        budget.setPeriod(request.getPeriod());

        if (StringUtils.hasText(request.getStatus())) {
            try {
                budget.setStatus(com.finmate.enums.BudgetStatus.valueOf(request.getStatus().toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new RuntimeException("Invalid budget status");
            }
        }

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

    @Override
    public BudgetResponse reassignBudget(UUID userId, BudgetReassignRequest request) {
        if (request.getAmount() == null || request.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new RuntimeException("Amount must be greater than zero");
        }

        Budget fromBudget = budgetRepository.findByUserIdAndCategoryId(userId, request.getFromCategoryId())
                .orElseThrow(() -> new RuntimeException("Source budget not found"));
        Budget toBudget = budgetRepository.findByUserIdAndCategoryId(userId, request.getToCategoryId())
                .orElseThrow(() -> new RuntimeException("Target budget not found"));

        if (!fromBudget.getPeriod().equals(toBudget.getPeriod())) {
            throw new RuntimeException("Budgets must have the same period to reassign");
        }

        BigDecimal fromAvailable = calculateAvailable(userId, fromBudget);
        if (fromAvailable.compareTo(request.getAmount()) < 0) {
            throw new RuntimeException("Insufficient available amount to reassign");
        }

        fromBudget.setAmountLimit(fromBudget.getAmountLimit().subtract(request.getAmount()));
        toBudget.setAmountLimit(toBudget.getAmountLimit().add(request.getAmount()));

        budgetRepository.save(fromBudget);
        budgetRepository.save(toBudget);

        return mapToResponse(toBudget, userId);
    }

    @Override
    @Transactional
    public BudgetResponse addContribution(UUID userId, Long budgetId, BudgetContributionRequest request) {
        if (request == null || request.getAmount() == null || request.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BadRequestException("Contribution amount must be greater than zero");
        }
        if (request.getWalletId() == null) {
            throw new BadRequestException("Wallet is required");
        }

        Budget budget = budgetRepository.findById(budgetId)
                .orElseThrow(() -> new ResourceNotFoundException("Budget not found"));

        if (!budget.getUser().getId().equals(userId)) {
            throw new BadRequestException("Budget does not belong to user");
        }

        Wallet wallet = walletRepository.findByIdAndIsDeletedFalse(request.getWalletId())
                .orElseThrow(() -> new ResourceNotFoundException("Wallet not found"));
        if (!wallet.getUser().getId().equals(userId)) {
            throw new BadRequestException("Wallet does not belong to user");
        }

        wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
        walletRepository.save(wallet);

        Transaction transaction = new Transaction();
        transaction.setUser(budget.getUser());
        transaction.setWallet(wallet);
        transaction.setCategory(budget.getCategory());
        transaction.setBudget(budget);
        transaction.setType(TransactionType.EXPENSE);
        transaction.setAmount(request.getAmount());
        transaction.setNote(resolveContributionNote(request.getNote(), budget));
        transaction.setTransactionDate(LocalDateTime.now());
        transactionRepository.save(transaction);

        BigDecimal updatedSavedAmount = getSafeSavedAmount(budget).add(request.getAmount());
        budget.setSavedAmount(updatedSavedAmount);
        Budget updatedBudget = budgetRepository.save(budget);
        return mapToResponse(updatedBudget, userId);
    }

    private BudgetResponse mapToResponse(Budget budget, UUID userId) {
        // Calculate spent amount for this budget period
        BigDecimal spent = calculateSpentAmount(userId, budget);
        BigDecimal available = budget.getAmountLimit().subtract(spent);
        BigDecimal savedAmount = getSafeSavedAmount(budget);
        BigDecimal remainingToGoal = budget.getAmountLimit().subtract(savedAmount);

        // Calculate percentage
        int percentageUsed = 0;
        if (budget.getAmountLimit().compareTo(BigDecimal.ZERO) > 0) {
            percentageUsed = spent.multiply(BigDecimal.valueOf(100))
                    .divide(budget.getAmountLimit(), 0, RoundingMode.HALF_UP)
                    .intValue();
        }

        int savingProgressPercentage = 0;
        if (budget.getAmountLimit().compareTo(BigDecimal.ZERO) > 0) {
            savingProgressPercentage = savedAmount.multiply(BigDecimal.valueOf(100))
                    .divide(budget.getAmountLimit(), 0, RoundingMode.HALF_UP)
                    .intValue();
        }

        return new BudgetResponse(
                budget.getId(),
                StringUtils.hasText(budget.getName()) ? budget.getName() : budget.getCategory().getName(),
                budget.getCategory().getId(),
                budget.getCategory().getName(),
                budget.getAmountLimit(),
                savedAmount,
                remainingToGoal,
                savingProgressPercentage,
                spent,
                available,
                budget.getPeriod(),
                percentageUsed,
                budget.getStatus());
    }

    private String resolveBudgetName(String requestedName, String categoryName) {
        if (StringUtils.hasText(requestedName)) {
            return requestedName.trim();
        }
        return "Savings goal - " + categoryName;
    }

    private String resolveContributionNote(String requestedNote, Budget budget) {
        if (StringUtils.hasText(requestedNote)) {
            return requestedNote.trim();
        }
        String fundName = StringUtils.hasText(budget.getName()) ? budget.getName() : budget.getCategory().getName();
        return "Fund contribution - " + fundName;
    }

    private BigDecimal calculateAvailable(UUID userId, Budget budget) {
        BigDecimal spent = calculateSpentAmount(userId, budget);
        return budget.getAmountLimit().subtract(spent);
    }

    private BigDecimal getSafeSavedAmount(Budget budget) {
        return budget.getSavedAmount() == null ? BigDecimal.ZERO : budget.getSavedAmount();
    }

    private BigDecimal calculateSpentAmount(UUID userId, Budget budget) {
        LocalDateTime startDate;
        LocalDateTime endDate;

        if (budget.getPeriod() == com.finmate.enums.BudgetPeriod.WEEK) {
            LocalDateTime now = LocalDateTime.now();
            LocalDateTime startOfWeek = now.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                    .withHour(0).withMinute(0).withSecond(0).withNano(0);
            LocalDateTime endOfWeek = now.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY))
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
                .filter(t -> t.getBudget() == null)
                .filter(t -> t.getType() == TransactionType.EXPENSE)
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private void validateBudgetCategory(UUID userId, Category category) {
        if (category.getUser() != null && !category.getUser().getId().equals(userId)) {
            throw new RuntimeException("Category does not belong to user");
        }
        if (category.getType() != CategoryType.EXPENSE) {
            throw new RuntimeException("Budget category must be an expense category");
        }
        if (category.getParent() == null || categoryRepository.existsByParentId(category.getId())) {
            throw new RuntimeException("Please select a subcategory for budget");
        }
    }
}
