package com.finmate.controller;

import com.finmate.dto.request.TransactionRequest;
import com.finmate.dto.response.TransactionResponse;
import com.finmate.service.TransactionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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
            @Parameter(description = "User ID", required = true) @RequestHeader("User-Id") UUID userId,
            @RequestBody TransactionRequest request) {
        TransactionResponse response = transactionService.createTransaction(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get transaction details", description = "Retrieves transaction information by ID, including wallet name and category")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Success"),
            @ApiResponse(responseCode = "404", description = "Transaction not found")
    })
    public ResponseEntity<TransactionResponse> getTransactionById(
            @Parameter(description = "Transaction ID", required = true) @PathVariable Long id) {
        TransactionResponse response = transactionService.getTransactionById(id);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    @Operation(summary = "Get all transactions", description = "Returns all transactions for a user, sorted by newest date")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<TransactionResponse>> getAllTransactions(
            @Parameter(description = "ID người dùng", required = true) @RequestHeader("User-Id") UUID userId) {
        List<TransactionResponse> responses = transactionService.getAllTransactionsByUser(userId);
        return ResponseEntity.ok(responses);
    }

    @GetMapping("/filter")
    @Operation(summary = "Filter transactions", description = "Search transactions by wallet, category, and date range. All parameters are optional")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<TransactionResponse>> getTransactionsByFilter(
            @Parameter(description = "User ID", required = true) @RequestHeader("User-Id") UUID userId,
            @Parameter(description = "Wallet ID (optional)") @RequestParam(required = false) Long walletId,
            @Parameter(description = "Category ID (optional)") @RequestParam(required = false) Long categoryId,
            @Parameter(description = "Start date (ISO DateTime)", required = true) @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @Parameter(description = "End date (ISO DateTime)", required = true) @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        List<TransactionResponse> responses = transactionService.getTransactionsByFilter(
                userId, walletId, categoryId, startDate, endDate);
        return ResponseEntity.ok(responses);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete transaction", description = "Deletes a transaction from the system")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Successfully deleted"),
            @ApiResponse(responseCode = "404", description = "Transaction not found")
    })
    public ResponseEntity<Void> deleteTransaction(
            @Parameter(description = "Transaction ID", required = true) @PathVariable Long id) {
        transactionService.deleteTransaction(id);
        return ResponseEntity.noContent().build();
    }
}
