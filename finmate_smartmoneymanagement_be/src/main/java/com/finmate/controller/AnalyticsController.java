package com.finmate.controller;

import com.finmate.dto.response.BehaviorAnalysisResponse;
import com.finmate.dto.response.CalendarDayTransactionsResponse;
import com.finmate.dto.response.CashflowTrendPointResponse;
import com.finmate.dto.response.SpendingPieSliceResponse;
import com.finmate.security.UserPrincipal;
import com.finmate.service.AnalyticsService;
import com.finmate.util.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
@Tag(name = "Analytics", description = "Reports and analytics endpoints")
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    @GetMapping("/spending-pie")
    @Operation(summary = "Spending pie by category")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<SpendingPieSliceResponse>> getSpendingPie(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @Parameter(description = "Month (YYYY-MM)") @RequestParam(required = false) String month) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        YearMonth yearMonth = month != null ? YearMonth.parse(month) : YearMonth.now();
        return ResponseEntity.ok(analyticsService.getSpendingPie(resolved, yearMonth));
    }

    @GetMapping("/cashflow-trend")
    @Operation(summary = "Cashflow trend")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<CashflowTrendPointResponse>> getCashflowTrend(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @Parameter(description = "Number of months") @RequestParam(defaultValue = "6") int months) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        return ResponseEntity.ok(analyticsService.getCashflowTrend(resolved, months));
    }

    @GetMapping("/calendar")
    @Operation(summary = "Calendar view")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<CalendarDayTransactionsResponse>> getCalendar(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @Parameter(description = "Start date") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @Parameter(description = "End date") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        return ResponseEntity.ok(analyticsService.getCalendar(resolved, startDate, endDate));
    }

    @GetMapping("/behavior")
    @Operation(summary = "Behavior analysis")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<BehaviorAnalysisResponse> getBehaviorAnalysis(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @Parameter(description = "Month (YYYY-MM)") @RequestParam(required = false) String month) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        YearMonth yearMonth = month != null ? YearMonth.parse(month) : YearMonth.now();
        return ResponseEntity.ok(analyticsService.getBehaviorAnalysis(resolved, yearMonth));
    }
}
