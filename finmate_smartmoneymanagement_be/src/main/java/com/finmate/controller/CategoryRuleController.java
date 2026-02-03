package com.finmate.controller;

import com.finmate.dto.request.CategoryRuleRequest;
import com.finmate.dto.response.CategoryRuleResponse;
import com.finmate.security.UserPrincipal;
import com.finmate.service.CategoryRuleService;
import com.finmate.util.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/category-rules")
@RequiredArgsConstructor
@Tag(name = "Category Rules", description = "Rule-based auto-categorization by merchant/keyword/content")
public class CategoryRuleController {

    private final CategoryRuleService categoryRuleService;

    @PostMapping
    @Operation(summary = "Create category rule", description = "Creates a keyword rule to auto-categorize transactions")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Rule created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid data")
    })
    public ResponseEntity<CategoryRuleResponse> createRule(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody CategoryRuleRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        CategoryRuleResponse response = categoryRuleService.createRule(resolved, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get rule by ID")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<CategoryRuleResponse> getRuleById(
            @Parameter(description = "Rule ID", required = true) @PathVariable Long id) {
        return ResponseEntity.ok(categoryRuleService.getRuleById(id));
    }

    @GetMapping
    @Operation(summary = "Get all rules by user")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<CategoryRuleResponse>> getRulesByUser(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        return ResponseEntity.ok(categoryRuleService.getRulesByUser(resolved));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update rule")
    @ApiResponse(responseCode = "200", description = "Updated successfully")
    public ResponseEntity<CategoryRuleResponse> updateRule(
            @Parameter(description = "Rule ID", required = true) @PathVariable Long id,
            @RequestBody CategoryRuleRequest request) {
        return ResponseEntity.ok(categoryRuleService.updateRule(id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete rule")
    @ApiResponse(responseCode = "204", description = "Deleted successfully")
    public ResponseEntity<Void> deleteRule(
            @Parameter(description = "Rule ID", required = true) @PathVariable Long id) {
        categoryRuleService.deleteRule(id);
        return ResponseEntity.noContent().build();
    }
}
