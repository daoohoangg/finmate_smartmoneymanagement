package com.finmate.service.impl;

import com.finmate.dto.request.RecurringTransactionRequest;
import com.finmate.dto.response.RecurringTransactionResponse;
import com.finmate.entities.Category;
import com.finmate.entities.RecurringTransaction;
import com.finmate.entities.User;
import com.finmate.entities.Wallet;
import com.finmate.enums.CategoryType;
import com.finmate.enums.TransactionType;
import com.finmate.repository.CategoryRepository;
import com.finmate.repository.RecurringTransactionRepository;
import com.finmate.repository.UserRepository;
import com.finmate.repository.WalletRepository;
import com.finmate.service.RecurringTransactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RecurringTransactionServiceImpl implements RecurringTransactionService {

    private final RecurringTransactionRepository recurringTransactionRepository;
    private final UserRepository userRepository;
    private final WalletRepository walletRepository;
    private final CategoryRepository categoryRepository;

    @Override
    public RecurringTransactionResponse createRecurring(UUID userId, RecurringTransactionRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (request.getWalletId() == null || request.getCategoryId() == null || request.getType() == null ||
                request.getAmount() == null || request.getFrequency() == null || request.getNextOccurrenceDate() == null) {
            throw new RuntimeException("Missing required fields for recurring transaction");
        }
        if (request.getAmount().signum() <= 0) {
            throw new RuntimeException("Amount must be greater than zero");
        }

        Wallet wallet = walletRepository.findByIdAndIsDeletedFalse(request.getWalletId())
                .orElseThrow(() -> new RuntimeException("Wallet not found"));
        if (!wallet.getUser().getId().equals(userId)) {
            throw new RuntimeException("Wallet does not belong to user");
        }

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new RuntimeException("Category not found"));
        if (category.getUser() != null && !category.getUser().getId().equals(userId)) {
            throw new RuntimeException("Category does not belong to user");
        }
        validateRecurringCategory(request.getType(), category);

        if (request.getType() == TransactionType.TRANSFER) {
            throw new RuntimeException("Recurring transfers are not supported");
        }

        RecurringTransaction recurring = new RecurringTransaction();
        recurring.setUser(user);
        recurring.setWallet(wallet);
        recurring.setCategory(category);
        recurring.setName(request.getName());
        recurring.setType(request.getType());
        recurring.setAmount(request.getAmount());
        recurring.setNote(request.getNote());
        recurring.setFrequency(request.getFrequency());
        recurring.setNextOccurrenceDate(request.getNextOccurrenceDate());
        recurring.setEndDate(request.getEndDate());
        recurring.setIsActive(request.getIsActive());

        RecurringTransaction saved = recurringTransactionRepository.save(recurring);
        return mapToResponse(saved);
    }

    @Override
    public RecurringTransactionResponse getRecurringById(Long id) {
        RecurringTransaction recurring = recurringTransactionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Recurring transaction not found"));
        return mapToResponse(recurring);
    }

    @Override
    public List<RecurringTransactionResponse> getRecurringByUser(UUID userId) {
        return recurringTransactionRepository.findByUserId(userId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public RecurringTransactionResponse updateRecurring(Long id, RecurringTransactionRequest request) {
        RecurringTransaction recurring = recurringTransactionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Recurring transaction not found"));

        if (request.getWalletId() != null) {
            Wallet wallet = walletRepository.findByIdAndIsDeletedFalse(request.getWalletId())
                    .orElseThrow(() -> new RuntimeException("Wallet not found"));
            if (!wallet.getUser().getId().equals(recurring.getUser().getId())) {
                throw new RuntimeException("Wallet does not belong to user");
            }
            recurring.setWallet(wallet);
        }
        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new RuntimeException("Category not found"));
            if (category.getUser() != null && !category.getUser().getId().equals(recurring.getUser().getId())) {
                throw new RuntimeException("Category does not belong to user");
            }
            validateRecurringCategory(
                    request.getType() != null ? request.getType() : recurring.getType(),
                    category);
            recurring.setCategory(category);
        }
        if (request.getType() != null) {
            if (request.getType() == TransactionType.TRANSFER) {
                throw new RuntimeException("Recurring transfers are not supported");
            }
            validateRecurringCategory(request.getType(), recurring.getCategory());
            recurring.setType(request.getType());
        }
        if (request.getName() != null) {
            recurring.setName(request.getName());
        }
        if (request.getAmount() != null) {
            recurring.setAmount(request.getAmount());
        }
        if (request.getNote() != null) {
            recurring.setNote(request.getNote());
        }
        if (request.getFrequency() != null) {
            recurring.setFrequency(request.getFrequency());
        }
        if (request.getNextOccurrenceDate() != null) {
            recurring.setNextOccurrenceDate(request.getNextOccurrenceDate());
        }
        if (request.getEndDate() != null) {
            recurring.setEndDate(request.getEndDate());
        }
        if (request.getIsActive() != null) {
            recurring.setIsActive(request.getIsActive());
        }

        RecurringTransaction updated = recurringTransactionRepository.save(recurring);
        return mapToResponse(updated);
    }

    @Override
    public void deleteRecurring(Long id) {
        RecurringTransaction recurring = recurringTransactionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Recurring transaction not found"));
        recurring.setIsActive(false);
        recurringTransactionRepository.save(recurring);
    }

    private RecurringTransactionResponse mapToResponse(RecurringTransaction recurring) {
        return new RecurringTransactionResponse(
                recurring.getId(),
                recurring.getWallet().getId(),
                recurring.getWallet().getName(),
                recurring.getCategory().getId(),
                recurring.getCategory().getName(),
                recurring.getName(),
                recurring.getType(),
                recurring.getAmount(),
                recurring.getNote(),
                recurring.getFrequency(),
                recurring.getNextOccurrenceDate(),
                recurring.getEndDate(),
                recurring.getIsActive());
    }

    private void validateRecurringCategory(TransactionType transactionType, Category category) {
        if (transactionType == null || category == null) {
            return;
        }
        if (transactionType == TransactionType.EXPENSE) {
            if (category.getType() != CategoryType.EXPENSE) {
                throw new RuntimeException("Category type must be EXPENSE for recurring expense");
            }
            if (category.getParent() == null || categoryRepository.existsByParentId(category.getId())) {
                throw new RuntimeException("Please select an expense subcategory");
            }
        } else if (transactionType == TransactionType.INCOME && category.getType() != CategoryType.INCOME) {
            throw new RuntimeException("Category type must be INCOME for recurring income");
        }
    }
}
