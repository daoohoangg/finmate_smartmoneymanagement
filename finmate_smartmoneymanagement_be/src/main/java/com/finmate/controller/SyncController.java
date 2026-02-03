package com.finmate.controller;

import com.finmate.dto.response.SyncResponse;
import com.finmate.security.UserPrincipal;
import com.finmate.service.SyncService;
import com.finmate.util.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/sync")
@RequiredArgsConstructor
@Tag(name = "Sync", description = "Multi-device data sync")
public class SyncController {

    private final SyncService syncService;

    @GetMapping
    @Operation(summary = "Sync all data", description = "Returns full snapshot for multi-device sync")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<SyncResponse> syncAll(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        return ResponseEntity.ok(syncService.syncAll(resolved));
    }
}
