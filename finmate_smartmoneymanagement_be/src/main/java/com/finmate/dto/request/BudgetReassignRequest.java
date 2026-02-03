package com.finmate.dto.request;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class BudgetReassignRequest {
    private Long fromCategoryId;
    private Long toCategoryId;
    private BigDecimal amount;
}
