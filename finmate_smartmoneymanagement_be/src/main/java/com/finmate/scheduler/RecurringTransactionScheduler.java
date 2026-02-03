package com.finmate.scheduler;

import com.finmate.dto.request.TransactionRequest;
import com.finmate.entities.RecurringTransaction;
import com.finmate.enums.RecurringFrequency;
import com.finmate.enums.TransactionType;
import com.finmate.repository.RecurringTransactionRepository;
import com.finmate.service.TransactionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class RecurringTransactionScheduler {

    private final RecurringTransactionRepository recurringTransactionRepository;
    private final TransactionService transactionService;

    @Scheduled(cron = "0 0 2 * * *")
    public void generateDueTransactions() {
        LocalDate today = LocalDate.now();
        List<RecurringTransaction> due = recurringTransactionRepository
                .findByIsActiveAndNextOccurrenceDateLessThanEqual(true, today);

        for (RecurringTransaction recurring : due) {
            if (recurring.getEndDate() != null && recurring.getNextOccurrenceDate().isAfter(recurring.getEndDate())) {
                recurring.setIsActive(false);
                recurringTransactionRepository.save(recurring);
                continue;
            }

            try {
                TransactionRequest request = new TransactionRequest();
                request.setWalletId(recurring.getWallet().getId());
                request.setCategoryId(recurring.getCategory().getId());
                request.setType(recurring.getType() != null ? recurring.getType() : TransactionType.EXPENSE);
                request.setAmount(recurring.getAmount());
                request.setNote(recurring.getNote());
                request.setTransactionDate(LocalDateTime.of(recurring.getNextOccurrenceDate(), java.time.LocalTime.NOON));

                transactionService.createTransaction(recurring.getUser().getId(), request);

                recurring.setNextOccurrenceDate(calculateNextDate(recurring.getNextOccurrenceDate(), recurring.getFrequency()));
                if (recurring.getEndDate() != null && recurring.getNextOccurrenceDate().isAfter(recurring.getEndDate())) {
                    recurring.setIsActive(false);
                }
                recurringTransactionRepository.save(recurring);
            } catch (Exception ex) {
                log.warn("Failed to create recurring transaction {}: {}", recurring.getId(), ex.getMessage());
            }
        }
    }

    private LocalDate calculateNextDate(LocalDate current, RecurringFrequency frequency) {
        if (frequency == null) {
            return current.plusMonths(1);
        }
        return switch (frequency) {
            case DAILY -> current.plusDays(1);
            case WEEKLY -> current.plusWeeks(1);
            case MONTHLY -> current.plusMonths(1);
            case YEARLY -> current.plusYears(1);
        };
    }
}
