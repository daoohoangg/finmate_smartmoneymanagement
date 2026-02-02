package com.finmate.dto.response;

import com.finmate.enums.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
public class TransactionResponse {
    private Long id;
    private Long walletId;
    private String walletName;
    private Long categoryId;
    private String categoryName;
    private TransactionType type;
    private BigDecimal amount;
    private String note;
    private LocalDateTime transactionDate;
    private String imageUrl;

    // For TRANSFER
    private Long toWalletId;
    private String toWalletName;

    // For SAVINGS_COMMIT
    private Long savingsGoalId;
    private String savingsGoalName;

    // For INVESTMENT_EXECUTION
    private Long investmentPlanId;
    private String investmentPlanName;
}
