package com.finmate.dto.request;

import com.finmate.enums.BudgetPeriod;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class BudgetRequest {
    private String name;
    private Long categoryId;
    private BigDecimal amountLimit;
    private BudgetPeriod period;
    private String status;
}
