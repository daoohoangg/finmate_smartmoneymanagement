package com.finmate.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;

@Data
@AllArgsConstructor
public class DashboardResponse {
    private BigDecimal netWorth;
    private BigDecimal totalIncome;
    private BigDecimal totalExpense;
    private BigDecimal cashflowThisMonth;
    private BigDecimal totalAssigned;
    private BigDecimal totalAvailable;
    private BigDecimal totalSavings;
    private BigDecimal totalInvested;
}
