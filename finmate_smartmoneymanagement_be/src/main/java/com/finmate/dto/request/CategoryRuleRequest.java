package com.finmate.dto.request;

import com.finmate.enums.RuleMatchType;
import lombok.Data;

@Data
public class CategoryRuleRequest {
    private Long categoryId;
    private String keyword;
    private RuleMatchType matchType;
    private Integer priority;
    private Boolean isActive;
}
