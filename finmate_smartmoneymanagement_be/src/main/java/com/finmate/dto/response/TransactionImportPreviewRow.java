package com.finmate.dto.response;

import com.finmate.enums.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
public class TransactionImportPreviewRow {
    private LocalDateTime transactionDate;
    private BigDecimal amount;
    private TransactionType type;
    private String note;
    private Long categoryId;
    private String categoryName;
    private String rawCategory;
    private String rawType;
}
