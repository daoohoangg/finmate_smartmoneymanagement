package com.finmate.controller;

import com.finmate.dto.request.CategoryRequest;
import com.finmate.dto.response.CategoryResponse;
import com.finmate.enums.CategoryType;
import com.finmate.security.UserPrincipal;
import com.finmate.service.CategoryService;
import com.finmate.util.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
@Tag(name = "Categories", description = "Category management - System categories and custom user categories")
public class CategoryController {

    private final CategoryService categoryService;

    @PostMapping
    @Operation(summary = "Create category", description = "Creates a custom category for user (INCOME or EXPENSE type)")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Category created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid data")
    })
    public ResponseEntity<CategoryResponse> createCategory(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody CategoryRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        CategoryResponse response = categoryService.createCategory(resolved, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get category by ID", description = "Returns details of a single category")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Successful"),
            @ApiResponse(responseCode = "404", description = "Category not found")
    })
    public ResponseEntity<CategoryResponse> getCategoryById(
            @Parameter(description = "ID of the category", required = true) @PathVariable Long id) {
        CategoryResponse response = categoryService.getCategoryById(id);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    @Operation(summary = "Get all categories", description = "Retrieves all user categories, optionally filtered by type (INCOME/EXPENSE)")
    @ApiResponse(responseCode = "200", description = "Successful")
    public ResponseEntity<List<CategoryResponse>> getAllCategories(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @Parameter(description = "Category type: INCOME or EXPENSE (optional)") @RequestParam(required = false) CategoryType type) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        List<CategoryResponse> responses;
        if (type != null) {
            responses = categoryService.getCategoriesByType(resolved, type);
        } else {
            responses = categoryService.getAllCategoriesByUser(resolved);
        }
        return ResponseEntity.ok(responses);
    }

    @GetMapping("/system")
    @Operation(summary = "Get system categories", description = "Retrieves default system categories shared across all users")
    @ApiResponse(responseCode = "200", description = "Successful")
    public ResponseEntity<List<CategoryResponse>> getSystemCategories() {
        List<CategoryResponse> responses = categoryService.getSystemCategories();
        return ResponseEntity.ok(responses);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update category", description = "Updates category information (name, type, icon)")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Updated successfully"),
            @ApiResponse(responseCode = "404", description = "Category not found")
    })
    public ResponseEntity<CategoryResponse> updateCategory(
            @Parameter(description = "Category ID", required = true) @PathVariable Long id,
            @RequestBody CategoryRequest request) {
        CategoryResponse response = categoryService.updateCategory(id, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete category", description = "Deletes a custom category from the system")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Deleted successfully"),
            @ApiResponse(responseCode = "404", description = "Category not found")
    })
    public ResponseEntity<Void> deleteCategory(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @Parameter(description = "Category ID", required = true) @PathVariable Long id) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        categoryService.deleteCategory(resolved, id);
        return ResponseEntity.noContent().build();
    }
}
