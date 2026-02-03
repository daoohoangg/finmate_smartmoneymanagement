package com.finmate.service.impl;

import com.finmate.dto.request.TransactionRequest;
import com.finmate.dto.response.TransactionResponse;
import com.finmate.entities.*;
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

        Category category = null;
        if (request.getCategoryId() != null) {
            category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new RuntimeException("Category not found"));
            if (category.getUser() != null && !category.getUser().getId().equals(userId)) {
                throw new RuntimeException("Category does not belong to user");
            }
            transaction.setCategory(category);
        } else if (request.getType() == TransactionType.EXPENSE && StringUtils.hasText(request.getNote())) {
            Category suggested = categoryRuleService.suggestCategory(userId, request.getNote());
            if (suggested != null) {
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
            ensureBudgetAvailable(userId, category.getId(), request.getAmount(), null);
            ensureSufficientBalance(wallet, request.getAmount());
            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
            walletRepository.save(wallet);
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

        Transaction savedTransaction = transactionRepository.save(transaction);
        return mapToResponse(savedTransaction);
    }

    @Override
    public TransactionResponse getTransactionById(Long id) {
        Transaction transaction = transactionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Transaction not found"));
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
    public TransactionResponse updateTransaction(Long id, TransactionRequest request) {
        Transaction existing = transactionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Transaction not found"));

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

        Category category = null;
        if (request.getCategoryId() != null) {
            category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new RuntimeException("Category not found"));
            if (category.getUser() != null && !category.getUser().getId().equals(existing.getUser().getId())) {
                throw new RuntimeException("Category does not belong to user");
            }
            existing.setCategory(category);
        } else {
            existing.setCategory(null);
        }

        existing.setToWallet(null);
        existing.setSavingsGoal(null);
        existing.setInvestmentPlan(null);

        applyTransactionEffects(existing, request, category, existing.getId());
        Transaction saved = transactionRepository.save(existing);
        return mapToResponse(saved);
    }

    @Override
    @Transactional
    public void deleteTransaction(Long id) {
        Transaction existing = transactionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Transaction not found"));
        reverseTransactionEffects(existing);
        transactionRepository.deleteById(id);
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
            ensureBudgetAvailable(transaction.getUser().getId(), category.getId(), request.getAmount(), excludeTransactionId);
            ensureSufficientBalance(wallet, request.getAmount());
            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
            walletRepository.save(wallet);
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

    private void ensureBudgetAvailable(UUID userId, Long categoryId, java.math.BigDecimal amount,
            Long excludeTransactionId) {
        Budget budget = budgetRepository.findByUserIdAndCategoryId(userId, categoryId)
                .orElseThrow(() -> new RuntimeException("No budget assigned for this category"));
        BigDecimal spent = calculateSpentForBudget(userId, budget, excludeTransactionId);
        BigDecimal available = budget.getAmountLimit().subtract(spent);
        if (available.compareTo(amount) < 0) {
            throw new RuntimeException("Insufficient budget available");
        }
    }

    private BigDecimal calculateSpentForBudget(UUID userId, Budget budget, Long excludeTransactionId) {
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
            java.time.YearMonth currentMonth = java.time.YearMonth.now();
            startDate = currentMonth.atDay(1).atStartOfDay();
            endDate = currentMonth.atEndOfMonth().atTime(23, 59, 59);
        }

        List<Transaction> transactions = transactionRepository.findByUserIdAndTransactionDateBetween(
                userId, startDate, endDate);

        return transactions.stream()
                .filter(t -> excludeTransactionId == null || !t.getId().equals(excludeTransactionId))
                .filter(t -> t.getCategory() != null && t.getCategory().getId().equals(budget.getCategory().getId()))
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
