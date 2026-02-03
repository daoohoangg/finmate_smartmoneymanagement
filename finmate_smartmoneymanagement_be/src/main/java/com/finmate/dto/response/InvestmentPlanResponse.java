package com.finmate.dto.response;

import com.finmate.enums.InvestmentFrequency;
import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@AllArgsConstructor
public class InvestmentPlanResponse {
    private Long id;
    private String name;
    private String description;
    private BigDecimal periodicAmount;
    private InvestmentFrequency frequency;
    private LocalDate nextExecutionDate;
    private BigDecimal totalInvested;
    private BigDecimal currentValue;
    private Boolean isActive;
    private Long sourceSavingsGoalId;
    private String sourceSavingsGoalName;
}
