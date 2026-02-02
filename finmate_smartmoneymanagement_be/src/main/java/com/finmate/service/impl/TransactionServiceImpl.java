package com.finmate.service.impl;

import com.finmate.dto.request.TransactionRequest;
import com.finmate.dto.response.TransactionResponse;
import com.finmate.entities.*;
import com.finmate.enums.TransactionType;
import com.finmate.repository.*;
import com.finmate.service.TransactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
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

    @Override
    @Transactional
    public TransactionResponse createTransaction(UUID userId, TransactionRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Wallet wallet = walletRepository.findById(request.getWalletId())
                .orElseThrow(() -> new RuntimeException("Wallet not found"));

        Transaction transaction = new Transaction();
        transaction.setUser(user);
        transaction.setWallet(wallet);
        transaction.setType(request.getType());
        transaction.setAmount(request.getAmount());
        transaction.setNote(request.getNote());
        transaction.setTransactionDate(
                request.getTransactionDate() != null ? request.getTransactionDate() : LocalDateTime.now());
        transaction.setImageUrl(request.getImageUrl());

        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new RuntimeException("Category not found"));
            transaction.setCategory(category);
        }

        // Handle different transaction types
        if (request.getType() == TransactionType.TRANSFER && request.getToWalletId() != null) {
            Wallet toWallet = walletRepository.findById(request.getToWalletId())
                    .orElseThrow(() -> new RuntimeException("Destination wallet not found"));
            transaction.setToWallet(toWallet);

            // Update wallet balances
            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
            toWallet.setBalance(toWallet.getBalance().add(request.getAmount()));
            walletRepository.save(wallet);
            walletRepository.save(toWallet);
        } else if (request.getType() == TransactionType.EXPENSE) {
            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
            walletRepository.save(wallet);
        } else if (request.getType() == TransactionType.INCOME) {
            wallet.setBalance(wallet.getBalance().add(request.getAmount()));
            walletRepository.save(wallet);
        } else if (request.getType() == TransactionType.SAVINGS_COMMIT && request.getSavingsGoalId() != null) {
            SavingsGoal savingsGoal = savingsGoalRepository.findById(request.getSavingsGoalId())
                    .orElseThrow(() -> new RuntimeException("Savings goal not found"));
            transaction.setSavingsGoal(savingsGoal);

            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
            savingsGoal.setCurrentAmount(savingsGoal.getCurrentAmount().add(request.getAmount()));
            walletRepository.save(wallet);
            savingsGoalRepository.save(savingsGoal);
        } else if (request.getType() == TransactionType.INVESTMENT_EXECUTION && request.getInvestmentPlanId() != null) {
            InvestmentPlan investmentPlan = investmentPlanRepository.findById(request.getInvestmentPlanId())
                    .orElseThrow(() -> new RuntimeException("Investment plan not found"));
            transaction.setInvestmentPlan(investmentPlan);

            wallet.setBalance(wallet.getBalance().subtract(request.getAmount()));
            investmentPlan.setTotalInvested(investmentPlan.getTotalInvested().add(request.getAmount()));
            walletRepository.save(wallet);
            investmentPlanRepository.save(investmentPlan);
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
            LocalDateTime startDate, LocalDateTime endDate) {
        return transactionRepository.findByFilters(userId, walletId, categoryId, startDate, endDate).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void deleteTransaction(Long id) {
        if (!transactionRepository.existsById(id)) {
            throw new RuntimeException("Transaction not found");
        }
        // TODO: Implement reversal of wallet balance changes
        transactionRepository.deleteById(id);
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
