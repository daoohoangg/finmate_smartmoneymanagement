package com.finmate.dto.response;

import com.finmate.enums.BudgetPeriod;
import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;

@Data
@AllArgsConstructor
public class BudgetResponse {
    private Long id;
    private String name;
    private Long categoryId;
    private String categoryName;
    private BigDecimal amountLimit;
    private BigDecimal savedAmount;
    private BigDecimal remainingToGoal;
    private Integer savingProgressPercentage;
    private BigDecimal spent;
    private BigDecimal available;
    private BudgetPeriod period;
    private Integer percentageUsed;
    private com.finmate.enums.BudgetStatus status;
}
