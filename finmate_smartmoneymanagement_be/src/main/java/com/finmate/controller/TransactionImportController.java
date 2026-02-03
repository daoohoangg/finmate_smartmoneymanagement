package com.finmate.controller;

import com.finmate.dto.request.TransactionImportMappingRequest;
import com.finmate.dto.response.TransactionImportPreviewResponse;
import com.finmate.dto.response.TransactionImportResultResponse;
import com.finmate.security.UserPrincipal;
import com.finmate.service.TransactionImportService;
import com.finmate.util.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@RestController
@RequestMapping("/api/imports")
@RequiredArgsConstructor
@Tag(name = "Transaction Import", description = "CSV/Excel import with column mapping, preview, and auto-categorization")
public class TransactionImportController {

    private final TransactionImportService transactionImportService;

    @PostMapping(value = "/transactions/preview", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Preview transaction import", description = "Uploads CSV/Excel, maps columns, and returns preview rows")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Preview generated"),
            @ApiResponse(responseCode = "400", description = "Invalid data")
    })
    public ResponseEntity<TransactionImportPreviewResponse> previewImport(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestPart("file") MultipartFile file,
            @RequestPart("mapping") TransactionImportMappingRequest mapping) throws IOException {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        return ResponseEntity.ok(transactionImportService.preview(resolved, file, mapping));
    }

    @PostMapping(value = "/transactions", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Import transactions", description = "Imports CSV/Excel into transactions")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Import completed"),
            @ApiResponse(responseCode = "400", description = "Invalid data")
    })
    public ResponseEntity<TransactionImportResultResponse> importTransactions(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestPart("file") MultipartFile file,
            @RequestPart("mapping") TransactionImportMappingRequest mapping) throws IOException {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        return ResponseEntity.ok(transactionImportService.importTransactions(resolved, file, mapping));
    }
}
