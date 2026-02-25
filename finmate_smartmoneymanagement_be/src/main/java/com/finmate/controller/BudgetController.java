package com.finmate.controller;

import com.finmate.dto.request.BudgetReassignRequest;
import com.finmate.dto.request.BudgetContributionRequest;
import com.finmate.dto.request.BudgetRequest;
import com.finmate.dto.response.BudgetResponse;
import com.finmate.security.UserPrincipal;
import com.finmate.service.BudgetService;
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
@RequestMapping("/api/budgets")
@RequiredArgsConstructor
@Tag(name = "Budgets (ZBB - Spending)", description = "Budget management - Zero-Based Budgeting spending allocations per category")
public class BudgetController {

    private final BudgetService budgetService;

    @PostMapping
    @Operation(summary = "Create budget", description = "Creates a spending budget for a category (ZBB Spending Budget). System automatically calculates spent amount, available amount, and percentage used from transactions.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Budget created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid data")
    })
    public ResponseEntity<BudgetResponse> createBudget(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody BudgetRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        BudgetResponse response = budgetService.createBudget(resolved, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get budget details", description = "Retrieves budget by ID with real-time spent/available amounts")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Success"),
            @ApiResponse(responseCode = "404", description = "Budget not found")
    })
    public ResponseEntity<BudgetResponse> getBudgetById(
            @Parameter(description = "Budget ID", required = true) @PathVariable Long id) {
        BudgetResponse response = budgetService.getBudgetById(id);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    @Operation(summary = "Get all budgets", description = "Retrieves all user budgets with real-time spent/available information")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<BudgetResponse>> getAllBudgets(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        List<BudgetResponse> responses = budgetService.getAllBudgetsByUser(resolved);
        return ResponseEntity.ok(responses);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update budget", description = "Updates budget limit or time period (WEEK/MONTH)")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Updated successfully"),
            @ApiResponse(responseCode = "404", description = "Budget not found")
    })
    public ResponseEntity<BudgetResponse> updateBudget(
            @Parameter(description = "Budget ID", required = true) @PathVariable Long id,
            @RequestBody BudgetRequest request) {
        BudgetResponse response = budgetService.updateBudget(id, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete budget", description = "Deletes a budget from the system")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Deleted successfully"),
            @ApiResponse(responseCode = "404", description = "Budget not found")
    })
    public ResponseEntity<Void> deleteBudget(
            @Parameter(description = "Budget ID", required = true) @PathVariable Long id) {
        budgetService.deleteBudget(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/reassign")
    @Operation(summary = "Reassign budget", description = "Moves assigned amount from one category to another (Roll With the Punches)")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Reassigned successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid data")
    })
    public ResponseEntity<BudgetResponse> reassignBudget(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody BudgetReassignRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        BudgetResponse response = budgetService.reassignBudget(resolved, request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{id}/contributions")
    @Operation(summary = "Add contribution to fund", description = "Adds money from a wallet to a fund, records an expense transaction, and updates saving progress")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Contribution added successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid data"),
            @ApiResponse(responseCode = "404", description = "Budget not found")
    })
    public ResponseEntity<BudgetResponse> addContribution(
            @Parameter(description = "Budget ID", required = true) @PathVariable Long id,
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody BudgetContributionRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        BudgetResponse response = budgetService.addContribution(resolved, id, request);
        return ResponseEntity.ok(response);
    }
}
