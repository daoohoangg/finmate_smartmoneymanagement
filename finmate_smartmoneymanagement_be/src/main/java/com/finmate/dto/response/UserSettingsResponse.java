package com.finmate.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class UserSettingsResponse {
    private Long id;
    private Boolean darkMode;
    private String language;
    private String defaultCurrency;
    private Boolean notificationEnabled;
    private Integer budgetAlertThreshold;
    private Integer roundingScale;
    private String roundingMode;
    private Integer necessaryAllocationPercent;
    private Integer accumulationAllocationPercent;
    private Integer flexibilityAllocationPercent;
}
