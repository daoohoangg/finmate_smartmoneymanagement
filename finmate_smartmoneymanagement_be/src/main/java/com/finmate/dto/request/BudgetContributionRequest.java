package com.finmate.dto.request;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class BudgetContributionRequest {
    private BigDecimal amount;
    private Long walletId;
    private String note;
}
