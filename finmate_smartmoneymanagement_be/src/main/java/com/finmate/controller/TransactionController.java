package com.finmate.controller;

import com.finmate.dto.request.TransactionRequest;
import com.finmate.dto.response.TransactionResponse;
import com.finmate.security.UserPrincipal;
import com.finmate.service.TransactionService;
import com.finmate.util.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
@Tag(name = "Transactions", description = "Transaction management - Core of ZBB system, single source of truth for all balance changes")
public class TransactionController {

    private final TransactionService transactionService;

    @PostMapping
    @Operation(summary = "Create transaction", description = "Creates a new transaction. Automatically updates wallet balance and budget. "
            +
            "Supports 5 types: INCOME (money in), EXPENSE (spending from budget), TRANSFER (between wallets), SAVINGS_COMMIT (allocate to savings fund), INVESTMENT_EXECUTION (execute investment)")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Transaction created successfully, wallet balance updated"),
            @ApiResponse(responseCode = "400", description = "Invalid data or insufficient balance")
    })
    public ResponseEntity<TransactionResponse> createTransaction(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody TransactionRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        TransactionResponse response = transactionService.createTransaction(resolved, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get transaction details", description = "Retrieves transaction information by ID, including wallet name and category")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Success"),
            @ApiResponse(responseCode = "404", description = "Transaction not found")
    })
    public ResponseEntity<TransactionResponse> getTransactionById(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @Parameter(description = "Transaction ID", required = true) @PathVariable Long id) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        TransactionResponse response = transactionService.getTransactionById(resolved, id);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    @Operation(summary = "Get all transactions", description = "Returns all transactions for a user, sorted by newest date")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<TransactionResponse>> getAllTransactions(
            @Parameter(description = "ID người dùng", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        List<TransactionResponse> responses = transactionService.getAllTransactionsByUser(resolved);
        return ResponseEntity.ok(responses);
    }

    @GetMapping("/filter")
    @Operation(summary = "Filter transactions", description = "Search transactions by wallet, category, and date range. All parameters are optional")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<TransactionResponse>> getTransactionsByFilter(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @Parameter(description = "Wallet ID (optional)") @RequestParam(required = false) Long walletId,
            @Parameter(description = "Category ID (optional)") @RequestParam(required = false) Long categoryId,
            @Parameter(description = "Search keyword in note (optional)") @RequestParam(required = false) String keyword,
            @Parameter(description = "Minimum amount (optional)") @RequestParam(required = false) BigDecimal minAmount,
            @Parameter(description = "Maximum amount (optional)") @RequestParam(required = false) BigDecimal maxAmount,
            @Parameter(description = "Start date (ISO DateTime)", required = true) @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @Parameter(description = "End date (ISO DateTime)", required = true) @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        List<TransactionResponse> responses = transactionService.getTransactionsByFilter(
                resolved, walletId, categoryId, startDate, endDate, keyword, minAmount, maxAmount);
        return ResponseEntity.ok(responses);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update transaction", description = "Updates transaction and recalculates wallet/budget balances")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Updated successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid data"),
            @ApiResponse(responseCode = "404", description = "Transaction not found")
    })
    public ResponseEntity<TransactionResponse> updateTransaction(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @Parameter(description = "Transaction ID", required = true) @PathVariable Long id,
            @RequestBody TransactionRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        TransactionResponse response = transactionService.updateTransaction(resolved, id, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete transaction", description = "Deletes a transaction from the system")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Successfully deleted"),
            @ApiResponse(responseCode = "404", description = "Transaction not found")
    })
    public ResponseEntity<Void> deleteTransaction(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @Parameter(description = "Transaction ID", required = true) @PathVariable Long id) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        transactionService.deleteTransaction(resolved, id);
        return ResponseEntity.noContent().build();
    }
}
