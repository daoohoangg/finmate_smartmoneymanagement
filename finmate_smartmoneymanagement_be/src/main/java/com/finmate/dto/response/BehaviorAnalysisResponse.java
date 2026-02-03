package com.finmate.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;

@Data
@AllArgsConstructor
public class BehaviorAnalysisResponse {
    private BigDecimal currentMonthIncome;
    private BigDecimal currentMonthExpense;
    private BigDecimal previousMonthIncome;
    private BigDecimal previousMonthExpense;
    private BigDecimal incomeChangePercent;
    private BigDecimal expenseChangePercent;
    private BigDecimal weekendExpense;
    private BigDecimal weekdayExpense;
    private BigDecimal weekendAverageExpense;
    private BigDecimal weekdayAverageExpense;
}
