package com.finmate.dto.response;

import com.finmate.enums.RuleMatchType;
import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class CategoryRuleResponse {
    private Long id;
    private Long categoryId;
    private String categoryName;
    private String keyword;
    private RuleMatchType matchType;
    private Integer priority;
    private Boolean isActive;
}
