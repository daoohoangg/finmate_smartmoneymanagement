package com.finmate.dto.request;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class SavingsGoalRequest {
    private String name;
    private BigDecimal targetAmount;
    private BigDecimal monthlyContribution;
    private LocalDate deadline;
    private String icon;
}
