package com.finmate.controller;

import com.finmate.dto.response.TransactionAttachmentResponse;
import com.finmate.entities.TransactionAttachment;
import com.finmate.security.UserPrincipal;
import com.finmate.service.TransactionAttachmentService;
import com.finmate.util.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Tag(name = "Transaction Attachments", description = "Receipt image storage (BLOB) linked to transactions")
public class TransactionAttachmentController {

    private final TransactionAttachmentService transactionAttachmentService;

    @PostMapping("/transactions/{id}/attachments")
    @Operation(summary = "Upload receipt attachment", description = "Uploads receipt image as BLOB and attaches to transaction")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Uploaded successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid data")
    })
    public ResponseEntity<TransactionAttachmentResponse> uploadAttachment(
            @Parameter(description = "Transaction ID", required = true) @PathVariable Long id,
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam("file") MultipartFile file) throws IOException {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        TransactionAttachmentResponse response = transactionAttachmentService.addAttachment(id, file);
        TransactionAttachment attachment = transactionAttachmentService.getAttachment(response.getId());
        if (!attachment.getTransaction().getUser().getId().equals(resolved)) {
            transactionAttachmentService.deleteAttachment(response.getId());
            throw new RuntimeException("Transaction does not belong to user");
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/transactions/{id}/attachments")
    @Operation(summary = "List attachments by transaction")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<List<TransactionAttachmentResponse>> getAttachments(
            @Parameter(description = "Transaction ID", required = true) @PathVariable Long id,
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        List<TransactionAttachmentResponse> attachments = transactionAttachmentService.getAttachments(id);
        if (!attachments.isEmpty()) {
            TransactionAttachment attachment = transactionAttachmentService.getAttachment(attachments.get(0).getId());
            if (!attachment.getTransaction().getUser().getId().equals(resolved)) {
                throw new RuntimeException("Transaction does not belong to user");
            }
        }
        return ResponseEntity.ok(attachments);
    }

    @GetMapping("/attachments/{id}")
    @Operation(summary = "Download attachment")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<byte[]> downloadAttachment(
            @Parameter(description = "Attachment ID", required = true) @PathVariable Long id,
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        TransactionAttachment attachment = transactionAttachmentService.getAttachment(id);
        if (!attachment.getTransaction().getUser().getId().equals(resolved)) {
            throw new RuntimeException("Attachment does not belong to user");
        }
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(attachment.getContentType()))
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + attachment.getFileName() + "\"")
                .body(attachment.getData());
    }

    @DeleteMapping("/attachments/{id}")
    @Operation(summary = "Delete attachment")
    @ApiResponse(responseCode = "204", description = "Deleted successfully")
    public ResponseEntity<Void> deleteAttachment(
            @Parameter(description = "Attachment ID", required = true) @PathVariable Long id,
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        TransactionAttachment attachment = transactionAttachmentService.getAttachment(id);
        if (!attachment.getTransaction().getUser().getId().equals(resolved)) {
            throw new RuntimeException("Attachment does not belong to user");
        }
        transactionAttachmentService.deleteAttachment(id);
        return ResponseEntity.noContent().build();
    }
}
