package com.finmate.dto.request;

import com.finmate.enums.InvestmentFrequency;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class InvestmentPlanRequest {
    private String name;
    private String description;
    private BigDecimal periodicAmount;
    private InvestmentFrequency frequency;
    private LocalDate nextExecutionDate;
    private Long sourceSavingsGoalId;
    private BigDecimal currentValue;
    private Boolean isActive;
}
