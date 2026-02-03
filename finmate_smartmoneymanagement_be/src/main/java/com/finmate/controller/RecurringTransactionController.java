package com.finmate.controller;

import com.finmate.dto.request.RecurringTransactionRequest;
import com.finmate.dto.response.RecurringTransactionResponse;
import com.finmate.security.UserPrincipal;
import com.finmate.service.RecurringTransactionService;
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
@RequestMapping("/api/recurring-transactions")
@RequiredArgsConstructor
@Tag(name = "Recurring Transactions", description = "Create recurring templates and auto-generate transactions on schedule")
public class RecurringTransactionController {

    private final RecurringTransactionService recurringTransactionService;

    @PostMapping
    @Operation(summary = "Create recurring transaction")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid data")
    })
    public ResponseEntity<RecurringTransactionResponse> createRecurring(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody RecurringTransactionRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        RecurringTransactionResponse response = recurringTransactionService.createRecurring(resolved, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get recurring transaction by ID")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<RecurringTransactionResponse> getRecurringById(
            @Parameter(description = "Recurring ID", required = true) @PathVariable Long id) {
        return ResponseEntity.ok(recurringTransactionService.getRecurringById(id));
    }

    @GetMapping
    @Operation(summary = "Get all recurring transactions")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<RecurringTransactionResponse>> getRecurringByUser(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        return ResponseEntity.ok(recurringTransactionService.getRecurringByUser(resolved));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update recurring transaction")
    @ApiResponse(responseCode = "200", description = "Updated successfully")
    public ResponseEntity<RecurringTransactionResponse> updateRecurring(
            @Parameter(description = "Recurring ID", required = true) @PathVariable Long id,
            @RequestBody RecurringTransactionRequest request) {
        return ResponseEntity.ok(recurringTransactionService.updateRecurring(id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Deactivate recurring transaction")
    @ApiResponse(responseCode = "204", description = "Deactivated successfully")
    public ResponseEntity<Void> deleteRecurring(
            @Parameter(description = "Recurring ID", required = true) @PathVariable Long id) {
        recurringTransactionService.deleteRecurring(id);
        return ResponseEntity.noContent().build();
    }
}
