package com.finmate.service.impl;

import com.finmate.dto.request.TransactionRequest;
import com.finmate.dto.response.TransactionResponse;
import com.finmate.entities.*;
import com.finmate.enums.CategoryType;
import com.finmate.enums.TransactionType;
import com.finmate.repository.*;
import com.finmate.service.CategoryRuleService;
import org.springframework.util.StringUtils;
import com.finmate.service.TransactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TransactionServiceImpl implements TransactionService {

    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final CategoryRepository categoryRepository;
    private final SavingsGoalRepository savingsGoalRepository;
    private final InvestmentPlanRepository investmentPlanRepository;
    private final BudgetRepository budgetRepository;
    private final CategoryRuleService categoryRuleService;

    @Override
    @Transactional
    public TransactionResponse createTransaction(UUID userId, TransactionRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (request.getType() == null || request.getWalletId() == null) {
            throw new RuntimeException("Transaction type and wallet are required");
        }
        if (request.getAmount() == null || request.getAmount().signum() <= 0) {
            throw new RuntimeException("Amount must be greater than zero");
        }

        Wallet wallet = walletRepository.findByIdAndIsDeletedFalse(request.getWalletId())
                .orElseThrow(() -> new RuntimeException("Wallet not found"));
        if (!wallet.getUser().getId().equals(userId)) {
            throw new RuntimeException("Wallet does not belong to user");
        }

        Transaction transaction = new Transaction();
        transaction.setUser(user);
        transaction.setWallet(wallet);
        transaction.setType(request.getType());
        transaction.setAmount(request.getAmount());
        transaction.setNote(request.getNote());
        transaction.setTransactionDate(
                request.getTransactionDate() != null ? request.getTransactionDate() : LocalDateTime.now());
        transaction.setImageUrl(request.getImageUrl());

        Long categoryId = normalizeCategoryId(userId, user, request);
        Category category = null;
        if (categoryId != null) {
            category = categoryRepository.findById(categoryId)
                    .orElseThrow(() -> new RuntimeException("Category not found"));
            validateCategoryForTransaction(userId, request.getType(), category);
            transaction.setCategory(category);
        } else if (request.getType() == TransactionType.EXPENSE && StringUtils.hasText(request.getNote())) {
            Category suggested = categoryRuleService.suggestCategory(userId, request.getNote());
            if (suggested != null) {
                validateCategoryForTransaction(userId, request.getType(), suggested);
                transaction.setCategory(suggested);
                category = suggested;
            }
        }

        // Handle different transaction types
        if (request.getType() == TransactionType.TRANSFER && request.getToWalletId() != null) {
            Wallet toWallet = walletRepository.findByIdAndIsDeletedFalse(request.getToWalletId())
                    .orElseThrow(() -> new RuntimeException("Destination wallet not found"));
            if (!toWallet.getUser().getId().equals(userId)) {
                throw new RuntimeException("Destination wallet does not belong to user");
            }
            if (wallet.getId().equals(toWallet.getId())) {
                throw new RuntimeException("Source and destination wallets must be different");
            }
            transaction.setToWallet(toWallet);

            // Update wallet balances
            ensureSufficientBalance(wallet, request.getAmount());
            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
            toWallet.setBalance(toWallet.getBalance().add(request.getAmount()));
            walletRepository.save(wallet);
            walletRepository.save(toWallet);
        } else if (request.getType() == TransactionType.EXPENSE) {
            if (category == null) {
                throw new RuntimeException("Category is required for expense");
            }
            if (transaction.getBudget() == null) {
                ensureBudgetAvailable(
                        userId,
                        category.getId(),
                        request.getAmount(),
                        null,
                        transaction.getTransactionDate());
            }
            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
            walletRepository.save(wallet);
            if (transaction.getBudget() != null) {
                applyFundContributionIfNeeded(transaction);
            } else {
                applyFundExpenseIfExists(userId, category.getId(), request.getAmount());
            }
        } else if (request.getType() == TransactionType.INCOME) {
            wallet.setBalance(wallet.getBalance().add(request.getAmount()));
            walletRepository.save(wallet);
        } else if (request.getType() == TransactionType.SAVINGS_COMMIT && request.getSavingsGoalId() != null) {
            SavingsGoal savingsGoal = savingsGoalRepository.findById(request.getSavingsGoalId())
                    .orElseThrow(() -> new RuntimeException("Savings goal not found"));
            if (!savingsGoal.getUser().getId().equals(userId)) {
                throw new RuntimeException("Savings goal does not belong to user");
            }
            transaction.setSavingsGoal(savingsGoal);

            ensureSufficientBalance(wallet, request.getAmount());
            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
            savingsGoal.setCurrentAmount(savingsGoal.getCurrentAmount().add(request.getAmount()));
            walletRepository.save(wallet);
            savingsGoalRepository.save(savingsGoal);
        } else if (request.getType() == TransactionType.INVESTMENT_EXECUTION && request.getInvestmentPlanId() != null) {
            InvestmentPlan investmentPlan = investmentPlanRepository.findById(request.getInvestmentPlanId())
                    .orElseThrow(() -> new RuntimeException("Investment plan not found"));
            if (!investmentPlan.getUser().getId().equals(userId)) {
                throw new RuntimeException("Investment plan does not belong to user");
            }
            transaction.setInvestmentPlan(investmentPlan);

            SavingsGoal sourceSavingsGoal = investmentPlan.getSourceSavingsGoal();
            if (sourceSavingsGoal == null && request.getSavingsGoalId() != null) {
                sourceSavingsGoal = savingsGoalRepository.findById(request.getSavingsGoalId())
                        .orElseThrow(() -> new RuntimeException("Savings goal not found"));
            }
            if (sourceSavingsGoal == null) {
                throw new RuntimeException("Savings goal source is required for investment execution");
            }
            if (!sourceSavingsGoal.getUser().getId().equals(userId)) {
                throw new RuntimeException("Savings goal does not belong to user");
            }
            ensureSufficientSavings(sourceSavingsGoal, request.getAmount());
            transaction.setSavingsGoal(sourceSavingsGoal);

            sourceSavingsGoal.setCurrentAmount(sourceSavingsGoal.getCurrentAmount().subtract(request.getAmount()));
            investmentPlan.setTotalInvested(investmentPlan.getTotalInvested().add(request.getAmount()));
            savingsGoalRepository.save(sourceSavingsGoal);
            investmentPlanRepository.save(investmentPlan);
        } else {
            throw new RuntimeException("Invalid transaction type or missing required fields");
        }

        Transaction savedTransaction = transactionRepository.saveAndFlush(transaction);
        return mapToResponse(savedTransaction);
    }

    @Override
    public TransactionResponse getTransactionById(UUID userId, Long id) {
        Transaction transaction = getUserTransactionOrThrow(userId, id);
        return mapToResponse(transaction);
    }

    @Override
    public List<TransactionResponse> getAllTransactionsByUser(UUID userId) {
        return transactionRepository.findByUserIdOrderByTransactionDateDesc(userId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public List<TransactionResponse> getTransactionsByFilter(UUID userId, Long walletId, Long categoryId,
            LocalDateTime startDate, LocalDateTime endDate, String keyword, java.math.BigDecimal minAmount,
            java.math.BigDecimal maxAmount) {
        return transactionRepository.findByFilters(userId, walletId, categoryId, keyword, minAmount, maxAmount,
                startDate, endDate).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public TransactionResponse updateTransaction(UUID userId, Long id, TransactionRequest request) {
        Transaction existing = getUserTransactionOrThrow(userId, id);

        if (request.getType() == null || request.getWalletId() == null) {
            throw new RuntimeException("Transaction type and wallet are required");
        }
        if (request.getAmount() == null || request.getAmount().signum() <= 0) {
            throw new RuntimeException("Amount must be greater than zero");
        }

        reverseTransactionEffects(existing);

        existing.setType(request.getType());
        existing.setAmount(request.getAmount());
        existing.setNote(request.getNote());
        existing.setTransactionDate(
                request.getTransactionDate() != null ? request.getTransactionDate() : existing.getTransactionDate());
        existing.setImageUrl(request.getImageUrl());

        Wallet wallet = walletRepository.findByIdAndIsDeletedFalse(request.getWalletId())
                .orElseThrow(() -> new RuntimeException("Wallet not found"));
        if (!wallet.getUser().getId().equals(existing.getUser().getId())) {
            throw new RuntimeException("Wallet does not belong to user");
        }
        existing.setWallet(wallet);

        Long categoryId = normalizeCategoryId(existing.getUser().getId(), existing.getUser(), request);
        Category category = null;
        if (categoryId != null) {
            category = categoryRepository.findById(categoryId)
                    .orElseThrow(() -> new RuntimeException("Category not found"));
            validateCategoryForTransaction(existing.getUser().getId(), request.getType(), category);
            existing.setCategory(category);
        } else {
            existing.setCategory(null);
        }

        existing.setToWallet(null);
        existing.setSavingsGoal(null);
        existing.setInvestmentPlan(null);
        if (request.getType() != TransactionType.EXPENSE) {
            existing.setBudget(null);
        } else if (existing.getBudget() != null) {
            if (category == null ||
                    !existing.getBudget().getCategory().getId().equals(category.getId())) {
                existing.setBudget(null);
            }
        }

        applyTransactionEffects(existing, request, category, existing.getId());
        Transaction saved = transactionRepository.saveAndFlush(existing);
        return mapToResponse(saved);
    }

    @Override
    @Transactional
    public void deleteTransaction(UUID userId, Long id) {
        Transaction existing = getUserTransactionOrThrow(userId, id);
        reverseTransactionEffects(existing);
        transactionRepository.deleteById(id);
    }

    private Transaction getUserTransactionOrThrow(UUID userId, Long transactionId) {
        return transactionRepository.findByIdAndUserId(transactionId, userId)
                .orElseThrow(() -> new RuntimeException("Transaction not found"));
    }

    private void applyTransactionEffects(Transaction transaction, TransactionRequest request, Category category,
            Long excludeTransactionId) {
        Wallet wallet = transaction.getWallet();

        if (request.getType() == TransactionType.TRANSFER && request.getToWalletId() != null) {
            Wallet toWallet = walletRepository.findByIdAndIsDeletedFalse(request.getToWalletId())
                    .orElseThrow(() -> new RuntimeException("Destination wallet not found"));
            if (!toWallet.getUser().getId().equals(transaction.getUser().getId())) {
                throw new RuntimeException("Destination wallet does not belong to user");
            }
            if (wallet.getId().equals(toWallet.getId())) {
                throw new RuntimeException("Source and destination wallets must be different");
            }
            transaction.setToWallet(toWallet);
            ensureSufficientBalance(wallet, request.getAmount());
            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
            toWallet.setBalance(toWallet.getBalance().add(request.getAmount()));
            walletRepository.save(wallet);
            walletRepository.save(toWallet);
        } else if (request.getType() == TransactionType.EXPENSE) {
            if (category == null) {
                throw new RuntimeException("Category is required for expense");
            }
            if (category.getType() != CategoryType.EXPENSE) {
                throw new RuntimeException("Category type must be EXPENSE for expense transaction");
            }
            if (category.getParent() == null || categoryRepository.existsByParentId(category.getId())) {
                throw new RuntimeException("Please select an expense subcategory");
            }
            if (transaction.getBudget() == null) {
                ensureBudgetAvailable(
                        transaction.getUser().getId(),
                        category.getId(),
                        request.getAmount(),
                        excludeTransactionId,
                        transaction.getTransactionDate());
            }
            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
            walletRepository.save(wallet);
            if (transaction.getBudget() != null) {
                applyFundContributionIfNeeded(transaction);
            } else {
                applyFundExpenseIfExists(transaction.getUser().getId(), category.getId(), request.getAmount());
            }
        } else if (request.getType() == TransactionType.INCOME) {
            wallet.setBalance(wallet.getBalance().add(request.getAmount()));
            walletRepository.save(wallet);
        } else if (request.getType() == TransactionType.SAVINGS_COMMIT && request.getSavingsGoalId() != null) {
            SavingsGoal savingsGoal = savingsGoalRepository.findById(request.getSavingsGoalId())
                    .orElseThrow(() -> new RuntimeException("Savings goal not found"));
            if (!savingsGoal.getUser().getId().equals(transaction.getUser().getId())) {
                throw new RuntimeException("Savings goal does not belong to user");
            }
            transaction.setSavingsGoal(savingsGoal);
            ensureSufficientBalance(wallet, request.getAmount());
            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
            savingsGoal.setCurrentAmount(savingsGoal.getCurrentAmount().add(request.getAmount()));
            walletRepository.save(wallet);
            savingsGoalRepository.save(savingsGoal);
        } else if (request.getType() == TransactionType.INVESTMENT_EXECUTION && request.getInvestmentPlanId() != null) {
            InvestmentPlan investmentPlan = investmentPlanRepository.findById(request.getInvestmentPlanId())
                    .orElseThrow(() -> new RuntimeException("Investment plan not found"));
            if (!investmentPlan.getUser().getId().equals(transaction.getUser().getId())) {
                throw new RuntimeException("Investment plan does not belong to user");
            }
            transaction.setInvestmentPlan(investmentPlan);
            SavingsGoal sourceSavingsGoal = investmentPlan.getSourceSavingsGoal();
            if (sourceSavingsGoal == null && request.getSavingsGoalId() != null) {
                sourceSavingsGoal = savingsGoalRepository.findById(request.getSavingsGoalId())
                        .orElseThrow(() -> new RuntimeException("Savings goal not found"));
            }
            if (sourceSavingsGoal == null) {
                throw new RuntimeException("Savings goal source is required for investment execution");
            }
            if (!sourceSavingsGoal.getUser().getId().equals(transaction.getUser().getId())) {
                throw new RuntimeException("Savings goal does not belong to user");
            }
            ensureSufficientSavings(sourceSavingsGoal, request.getAmount());
            transaction.setSavingsGoal(sourceSavingsGoal);
            sourceSavingsGoal.setCurrentAmount(sourceSavingsGoal.getCurrentAmount().subtract(request.getAmount()));
            investmentPlan.setTotalInvested(investmentPlan.getTotalInvested().add(request.getAmount()));
            savingsGoalRepository.save(sourceSavingsGoal);
            investmentPlanRepository.save(investmentPlan);
        } else {
            throw new RuntimeException("Invalid transaction type or missing required fields");
        }
    }

    private Long normalizeCategoryId(UUID userId, User user, TransactionRequest request) {
        if (request.getType() != TransactionType.INCOME || request.getCategoryId() != null) {
            return request.getCategoryId();
        }
        return resolveDefaultIncomeCategory(userId, user).getId();
    }

    private Category resolveDefaultIncomeCategory(UUID userId, User user) {
        Category preferred = pickPreferredIncomeCategory(
                categoryRepository.findByUserIdAndType(userId, CategoryType.INCOME));
        if (preferred != null) {
            return preferred;
        }

        List<Category> systemIncomeCategories = categoryRepository.findByUserIdIsNull().stream()
                .filter(category -> category.getType() == CategoryType.INCOME)
                .collect(Collectors.toList());
        preferred = pickPreferredIncomeCategory(systemIncomeCategories);
        if (preferred != null) {
            return preferred;
        }

        Category fallback = new Category();
        fallback.setUser(user);
        fallback.setName("Income");
        fallback.setType(CategoryType.INCOME);
        fallback.setIsPrimary(true);
        fallback.setIcon("payments_outlined");
        fallback.setColor("#22C55E");
        return categoryRepository.save(fallback);
    }

    private Category pickPreferredIncomeCategory(List<Category> categories) {
        return categories.stream()
                .filter(category -> category != null && category.getType() == CategoryType.INCOME)
                .min(Comparator
                        .comparing((Category category) -> category.getParent() != null)
                        .thenComparing(category -> !Boolean.TRUE.equals(category.getIsPrimary()))
                        .thenComparing(category -> category.getName() == null ? "" : category.getName().toLowerCase()))
                .orElse(null);
    }

    private void validateCategoryForTransaction(UUID userId, TransactionType transactionType, Category category) {
        if (category.getUser() != null && !category.getUser().getId().equals(userId)) {
            throw new RuntimeException("Category does not belong to user");
        }
        if (transactionType == TransactionType.EXPENSE) {
            if (category.getType() != CategoryType.EXPENSE) {
                throw new RuntimeException("Category type must be EXPENSE for expense transaction");
            }
            if (category.getParent() == null || categoryRepository.existsByParentId(category.getId())) {
                throw new RuntimeException("Please select an expense subcategory");
            }
        } else if (transactionType == TransactionType.INCOME && category.getType() != CategoryType.INCOME) {
            throw new RuntimeException("Category type must be INCOME for income transaction");
        }
    }

    private void reverseTransactionEffects(Transaction transaction) {
        Wallet wallet = transaction.getWallet();
        if (transaction.getType() == TransactionType.TRANSFER && transaction.getToWallet() != null) {
            Wallet toWallet = transaction.getToWallet();
            toWallet.setBalance(toWallet.getBalance().subtract(transaction.getAmount()));
            wallet.setBalance(wallet.getBalance().add(transaction.getAmount()));
            walletRepository.save(wallet);
            walletRepository.save(toWallet);
        } else if (transaction.getType() == TransactionType.EXPENSE) {
            wallet.setBalance(wallet.getBalance().add(transaction.getAmount()));
            walletRepository.save(wallet);
            if (transaction.getBudget() != null) {
                revertFundContributionIfNeeded(transaction);
            } else if (transaction.getCategory() != null) {
                revertFundExpenseIfExists(
                        transaction.getUser().getId(),
                        transaction.getCategory().getId(),
                        transaction.getAmount());
            }
        } else if (transaction.getType() == TransactionType.INCOME) {
            wallet.setBalance(wallet.getBalance().subtract(transaction.getAmount()));
            walletRepository.save(wallet);
        } else if (transaction.getType() == TransactionType.SAVINGS_COMMIT && transaction.getSavingsGoal() != null) {
            SavingsGoal savingsGoal = transaction.getSavingsGoal();
            wallet.setBalance(wallet.getBalance().add(transaction.getAmount()));
            savingsGoal.setCurrentAmount(savingsGoal.getCurrentAmount().subtract(transaction.getAmount()));
            walletRepository.save(wallet);
            savingsGoalRepository.save(savingsGoal);
        } else if (transaction.getType() == TransactionType.INVESTMENT_EXECUTION &&
                transaction.getInvestmentPlan() != null && transaction.getSavingsGoal() != null) {
            SavingsGoal savingsGoal = transaction.getSavingsGoal();
            InvestmentPlan investmentPlan = transaction.getInvestmentPlan();
            savingsGoal.setCurrentAmount(savingsGoal.getCurrentAmount().add(transaction.getAmount()));
            investmentPlan.setTotalInvested(investmentPlan.getTotalInvested().subtract(transaction.getAmount()));
            savingsGoalRepository.save(savingsGoal);
            investmentPlanRepository.save(investmentPlan);
        }
    }

    private void ensureSufficientBalance(Wallet wallet, java.math.BigDecimal amount) {
        if (wallet.getBalance().compareTo(amount) < 0) {
            throw new RuntimeException("Insufficient wallet balance");
        }
    }

    private void ensureSufficientSavings(SavingsGoal savingsGoal, java.math.BigDecimal amount) {
        if (savingsGoal.getCurrentAmount().compareTo(amount) < 0) {
            throw new RuntimeException("Insufficient savings balance");
        }
    }

    private void applyFundContributionIfNeeded(Transaction transaction) {
        Budget linkedBudget = transaction.getBudget();
        if (linkedBudget == null) {
            return;
        }
        BigDecimal currentSaved = linkedBudget.getSavedAmount() == null
                ? BigDecimal.ZERO
                : linkedBudget.getSavedAmount();
        linkedBudget.setSavedAmount(currentSaved.add(transaction.getAmount()));
        budgetRepository.save(linkedBudget);
    }

    private void revertFundContributionIfNeeded(Transaction transaction) {
        Budget linkedBudget = transaction.getBudget();
        if (linkedBudget == null) {
            return;
        }
        BigDecimal currentSaved = linkedBudget.getSavedAmount() == null
                ? BigDecimal.ZERO
                : linkedBudget.getSavedAmount();
        BigDecimal updatedSaved = currentSaved.subtract(transaction.getAmount());
        if (updatedSaved.compareTo(BigDecimal.ZERO) < 0) {
            updatedSaved = BigDecimal.ZERO;
        }
        linkedBudget.setSavedAmount(updatedSaved);
        budgetRepository.save(linkedBudget);
    }

    private void applyFundExpenseIfExists(UUID userId, Long categoryId, BigDecimal amount) {
        budgetRepository.findByUserIdAndCategoryId(userId, categoryId).ifPresent(budget -> {
            BigDecimal currentSaved = budget.getSavedAmount() == null ? BigDecimal.ZERO : budget.getSavedAmount();
            budget.setSavedAmount(currentSaved.subtract(amount));
            budgetRepository.save(budget);
        });
    }

    private void revertFundExpenseIfExists(UUID userId, Long categoryId, BigDecimal amount) {
        budgetRepository.findByUserIdAndCategoryId(userId, categoryId).ifPresent(budget -> {
            BigDecimal currentSaved = budget.getSavedAmount() == null ? BigDecimal.ZERO : budget.getSavedAmount();
            budget.setSavedAmount(currentSaved.add(amount));
            budgetRepository.save(budget);
        });
    }

    private void ensureBudgetAvailable(
            UUID userId,
            Long categoryId,
            java.math.BigDecimal amount,
            Long excludeTransactionId,
            LocalDateTime referenceDate) {
        java.util.Optional<Budget> budgetOpt = budgetRepository.findByUserIdAndCategoryId(userId, categoryId);
        if (budgetOpt.isEmpty()) {
            // No budget assigned - we allow saving the transaction anyway.
            return;
        }
        Budget budget = budgetOpt.get();
        BigDecimal spent = calculateSpentForBudget(userId, budget, excludeTransactionId, referenceDate);
        BigDecimal available = budget.getAmountLimit().subtract(spent);
        // Exceeding the budget is allowed, so we no longer throw an exception here.
    }

    private BigDecimal calculateSpentForBudget(
            UUID userId,
            Budget budget,
            Long excludeTransactionId,
            LocalDateTime referenceDate) {
        java.time.LocalDateTime startDate;
        java.time.LocalDateTime endDate;
        java.time.LocalDateTime anchorDate = referenceDate != null ? referenceDate : java.time.LocalDateTime.now();

        if (budget.getPeriod() == com.finmate.enums.BudgetPeriod.WEEK) {
            java.time.LocalDateTime startOfWeek = anchorDate
                    .with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY))
                    .withHour(0).withMinute(0).withSecond(0).withNano(0);
            java.time.LocalDateTime endOfWeek = anchorDate
                    .with(java.time.temporal.TemporalAdjusters.nextOrSame(java.time.DayOfWeek.SUNDAY))
                    .withHour(23).withMinute(59).withSecond(59).withNano(0);
            startDate = startOfWeek;
            endDate = endOfWeek;
        } else {
            java.time.YearMonth currentMonth = java.time.YearMonth.from(anchorDate);
            startDate = currentMonth.atDay(1).atStartOfDay();
            endDate = currentMonth.atEndOfMonth().atTime(23, 59, 59);
        }

        List<Transaction> transactions = transactionRepository.findByUserIdAndTransactionDateBetween(
                userId, startDate, endDate);

        return transactions.stream()
                .filter(t -> excludeTransactionId == null || !t.getId().equals(excludeTransactionId))
                .filter(t -> t.getCategory() != null && t.getCategory().getId().equals(budget.getCategory().getId()))
                .filter(t -> t.getBudget() == null)
                .filter(t -> t.getType() == TransactionType.EXPENSE)
                .map(Transaction::getAmount)
                .reduce(java.math.BigDecimal.ZERO, java.math.BigDecimal::add);
    }

    private TransactionResponse mapToResponse(Transaction transaction) {
        return new TransactionResponse(
                transaction.getId(),
                transaction.getWallet().getId(),
                transaction.getWallet().getName(),
                transaction.getCategory() != null ? transaction.getCategory().getId() : null,
                transaction.getCategory() != null ? transaction.getCategory().getName() : null,
                transaction.getType(),
                transaction.getAmount(),
                transaction.getNote(),
                transaction.getTransactionDate(),
                transaction.getImageUrl(),
                transaction.getToWallet() != null ? transaction.getToWallet().getId() : null,
                transaction.getToWallet() != null ? transaction.getToWallet().getName() : null,
                transaction.getSavingsGoal() != null ? transaction.getSavingsGoal().getId() : null,
                transaction.getSavingsGoal() != null ? transaction.getSavingsGoal().getName() : null,
                transaction.getInvestmentPlan() != null ? transaction.getInvestmentPlan().getId() : null,
                transaction.getInvestmentPlan() != null ? transaction.getInvestmentPlan().getName() : null);
    }
}
