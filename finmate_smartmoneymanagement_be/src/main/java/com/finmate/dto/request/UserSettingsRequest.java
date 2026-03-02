package com.finmate.dto.request;

import lombok.Data;

@Data
public class UserSettingsRequest {
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
