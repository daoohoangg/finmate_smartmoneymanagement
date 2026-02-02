package com.finmate.dto.request;

import com.finmate.enums.TransactionType;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class TransactionRequest {
    private Long walletId;
    private Long categoryId;
    private TransactionType type;
    private BigDecimal amount;
    private String note;
    private LocalDateTime transactionDate;
    private String imageUrl;

    // For TRANSFER
    private Long toWalletId;

    // For SAVINGS_COMMIT
    private Long savingsGoalId;

    // For INVESTMENT_EXECUTION
    private Long investmentPlanId;
}
