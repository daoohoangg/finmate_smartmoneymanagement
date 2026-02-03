package com.finmate.controller;

import com.finmate.dto.request.WalletRequest;
import com.finmate.dto.response.WalletResponse;
import com.finmate.security.UserPrincipal;
import com.finmate.service.WalletService;
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
@RequestMapping("/api/wallets")
@RequiredArgsConstructor
@Tag(name = "Wallets", description = "Wallet management - Tracks money locations (Cash, Bank, E-wallets)")
public class WalletController {

    private final WalletService walletService;

    @PostMapping
    @Operation(summary = "Create new wallet", description = "Creates a new wallet to track where money is located (e.g., Cash, Bank Account, MoMo). Wallets represent money storage locations, not spending purposes.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Wallet created successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid data")
    })
    public ResponseEntity<WalletResponse> createWallet(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody WalletRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        WalletResponse response = walletService.createWallet(resolved, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get wallet details", description = "Retrieves wallet information by ID, including current balance")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Success"),
            @ApiResponse(responseCode = "404", description = "Wallet not found")
    })
    public ResponseEntity<WalletResponse> getWalletById(
            @Parameter(description = "Wallet ID", required = true) @PathVariable Long id) {
        WalletResponse response = walletService.getWalletById(id);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    @Operation(summary = "Get all wallets", description = "Retrieves all wallets for the user with current balances")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<WalletResponse>> getAllWallets(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        List<WalletResponse> responses = walletService.getAllWalletsByUser(resolved);
        return ResponseEntity.ok(responses);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update wallet", description = "Updates wallet information (name, balance, currency, icon)")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Updated successfully"),
            @ApiResponse(responseCode = "404", description = "Wallet not found")
    })
    public ResponseEntity<WalletResponse> updateWallet(
            @Parameter(description = "Wallet ID", required = true) @PathVariable Long id,
            @RequestBody WalletRequest request) {
        WalletResponse response = walletService.updateWallet(id, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete wallet", description = "Deletes wallet from system. Consider soft delete to preserve history.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Deleted successfully"),
            @ApiResponse(responseCode = "404", description = "Wallet not found")
    })
    public ResponseEntity<Void> deleteWallet(
            @Parameter(description = "Wallet ID", required = true) @PathVariable Long id) {
        walletService.deleteWallet(id);
        return ResponseEntity.noContent().build();
    }
}
