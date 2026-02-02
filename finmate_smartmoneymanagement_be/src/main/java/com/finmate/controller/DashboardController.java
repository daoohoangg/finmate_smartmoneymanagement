package com.finmate.controller;

import com.finmate.dto.response.DashboardResponse;
import com.finmate.service.DashboardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
@Tag(name = "Dashboard & Analytics", description = "Financial overview - Real-time Zero-Based Budgeting metrics")
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping
    @Operation(summary = "Get financial dashboard", description = "Retrieves financial overview: Net Worth, Cash Flow, Budget (Assigned/Available), Savings Fund, Investments. "
            +
            "All metrics calculated in real-time from transactions following Zero-Based Budgeting principles.")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<DashboardResponse> getDashboard(
            @Parameter(description = "User ID", required = true) @RequestHeader("User-Id") UUID userId) {
        DashboardResponse response = dashboardService.getDashboard(userId);
        return ResponseEntity.ok(response);
    }
}
