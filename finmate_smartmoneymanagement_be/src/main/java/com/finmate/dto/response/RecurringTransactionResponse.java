package com.finmate.dto.response;

import com.finmate.enums.RecurringFrequency;
import com.finmate.enums.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@AllArgsConstructor
public class RecurringTransactionResponse {
    private Long id;
    private Long walletId;
    private String walletName;
    private Long categoryId;
    private String categoryName;
    private String name;
    private TransactionType type;
    private BigDecimal amount;
    private String note;
    private RecurringFrequency frequency;
    private LocalDate nextOccurrenceDate;
    private LocalDate endDate;
    private Boolean isActive;
}
