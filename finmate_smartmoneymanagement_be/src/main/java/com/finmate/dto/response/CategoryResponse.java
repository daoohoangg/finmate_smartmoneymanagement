package com.finmate.dto.response;

import com.finmate.enums.CategoryGroup;
import com.finmate.enums.CategoryType;
import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class CategoryResponse {
    private Long id;
    private String name;
    private CategoryType type;
    private CategoryGroup group;
    private Boolean isPrimary;
    private String icon;
    private String color;
    private Long parentId;
    private Boolean isSystemCategory;
}
