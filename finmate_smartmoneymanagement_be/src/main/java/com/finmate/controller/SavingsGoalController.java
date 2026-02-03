package com.finmate.controller;

import com.finmate.dto.request.SavingsGoalRequest;
import com.finmate.dto.response.SavingsGoalResponse;
import com.finmate.security.UserPrincipal;
import com.finmate.service.SavingsGoalService;
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

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/savings-goals")
@RequiredArgsConstructor
@Tag(name = "Savings Goals (ZBB - Savings Fund)", description = "Savings fund management - ZBB earmarked money for future goals (Emergency Fund, iPhone, etc.)")
public class SavingsGoalController {

    private final SavingsGoalService savingsGoalService;

    @PostMapping
    @Operation(summary = "Create savings goal", description = "Creates a new savings bucket/goal. Examples: Emergency Fund, Buy iPhone, Vacation Fund, etc.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Goal created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid data")
    })
    public ResponseEntity<SavingsGoalResponse> createSavingsGoal(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody SavingsGoalRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        SavingsGoalResponse response = savingsGoalService.createSavingsGoal(resolved, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get goal details", description = "Retrieves savings goal by ID with auto-calculated completion percentage")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Success"),
            @ApiResponse(responseCode = "404", description = "Goal not found")
    })
    public ResponseEntity<SavingsGoalResponse> getSavingsGoalById(
            @Parameter(description = "Goal ID", required = true) @PathVariable Long id) {
        SavingsGoalResponse response = savingsGoalService.getSavingsGoalById(id);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    @Operation(summary = "Get all savings goals", description = "Returns all user savings goals with real-time status")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<SavingsGoalResponse>> getAllSavingsGoals(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        List<SavingsGoalResponse> responses = savingsGoalService.getAllSavingsGoalsByUser(resolved);
        return ResponseEntity.ok(responses);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update savings goal", description = "Updates goal information (name, target amount, deadline, icon)")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Updated successfully"),
            @ApiResponse(responseCode = "404", description = "Goal not found")
    })
    public ResponseEntity<SavingsGoalResponse> updateSavingsGoal(
            @Parameter(description = "Goal ID", required = true) @PathVariable Long id,
            @RequestBody SavingsGoalRequest request) {
        SavingsGoalResponse response = savingsGoalService.updateSavingsGoal(id, request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/{id}/contribute")
    @Operation(summary = "Contribute to goal", description = "Contributes money to savings goal (ZBB Savings Fund). Usually called through Transaction with type SAVINGS_COMMIT.")
    @ApiResponse(responseCode = "200", description = "Contribution successful, completion % updated")
    public ResponseEntity<SavingsGoalResponse> contributeToGoal(
            @Parameter(description = "Goal ID", required = true) @PathVariable Long id,
            @Parameter(description = "Contribution amount", required = true) @RequestParam BigDecimal amount) {
        SavingsGoalResponse response = savingsGoalService.contributeToGoal(id, amount);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete savings goal", description = "Deletes a savings goal from the system")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Deleted successfully"),
            @ApiResponse(responseCode = "404", description = "Goal not found")
    })
    public ResponseEntity<Void> deleteSavingsGoal(
            @Parameter(description = "Goal ID", required = true) @PathVariable Long id) {
        savingsGoalService.deleteSavingsGoal(id);
        return ResponseEntity.noContent().build();
    }
}
