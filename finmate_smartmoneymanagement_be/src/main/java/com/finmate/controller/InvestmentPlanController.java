package com.finmate.controller;

import com.finmate.dto.request.InvestmentPlanRequest;
import com.finmate.dto.response.InvestmentPlanResponse;
import com.finmate.security.UserPrincipal;
import com.finmate.service.InvestmentPlanService;
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
@RequestMapping("/api/investment-plans")
@RequiredArgsConstructor
@Tag(name = "Investment Plans", description = "Periodic investment planning sourced from Savings Fund")
public class InvestmentPlanController {

    private final InvestmentPlanService investmentPlanService;

    @PostMapping
    @Operation(summary = "Create investment plan")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Plan created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid data")
    })
    public ResponseEntity<InvestmentPlanResponse> createPlan(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody InvestmentPlanRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        InvestmentPlanResponse response = investmentPlanService.createPlan(resolved, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get plan by ID")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<InvestmentPlanResponse> getPlanById(
            @Parameter(description = "Plan ID", required = true) @PathVariable Long id) {
        return ResponseEntity.ok(investmentPlanService.getPlanById(id));
    }

    @GetMapping
    @Operation(summary = "Get all plans for user")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<InvestmentPlanResponse>> getPlansByUser(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        return ResponseEntity.ok(investmentPlanService.getPlansByUser(resolved));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update plan")
    @ApiResponse(responseCode = "200", description = "Updated successfully")
    public ResponseEntity<InvestmentPlanResponse> updatePlan(
            @Parameter(description = "Plan ID", required = true) @PathVariable Long id,
            @RequestBody InvestmentPlanRequest request) {
        return ResponseEntity.ok(investmentPlanService.updatePlan(id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete plan")
    @ApiResponse(responseCode = "204", description = "Deleted successfully")
    public ResponseEntity<Void> deletePlan(
            @Parameter(description = "Plan ID", required = true) @PathVariable Long id) {
        investmentPlanService.deletePlan(id);
        return ResponseEntity.noContent().build();
    }
}
