package com.finmate.dto.request;

import com.finmate.enums.CategoryGroup;
import com.finmate.enums.CategoryType;
import lombok.Data;

@Data
public class CategoryRequest {
    private String name;
    private CategoryType type;
    private CategoryGroup group;
    private String icon;
    private String color;
    private Long parentId;
}
