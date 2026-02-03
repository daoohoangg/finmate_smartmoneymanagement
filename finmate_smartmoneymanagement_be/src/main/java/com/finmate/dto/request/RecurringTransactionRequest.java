package com.finmate.dto.request;

import com.finmate.enums.RecurringFrequency;
import com.finmate.enums.TransactionType;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class RecurringTransactionRequest {
    private Long walletId;
    private Long categoryId;
    private String name;
    private TransactionType type;
    private BigDecimal amount;
    private String note;
    private RecurringFrequency frequency;
    private LocalDate nextOccurrenceDate;
    private LocalDate endDate;
    private Boolean isActive;
}
