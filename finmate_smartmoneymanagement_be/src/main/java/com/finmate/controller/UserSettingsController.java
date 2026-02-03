package com.finmate.controller;

import com.finmate.dto.request.UserSettingsRequest;
import com.finmate.dto.response.UserSettingsResponse;
import com.finmate.security.UserPrincipal;
import com.finmate.service.UserSettingsService;
import com.finmate.util.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
@Tag(name = "User Settings", description = "Application settings - Dark mode, language, currency, notifications")
public class UserSettingsController {

    private final UserSettingsService userSettingsService;

    @GetMapping
    @Operation(summary = "Get user settings", description = "Retrieves all application settings for user. Automatically creates default settings if not exists.")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<UserSettingsResponse> getUserSettings(
            @Parameter(description = "ID người dùng", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        UserSettingsResponse response = userSettingsService.getUserSettings(resolved);
        return ResponseEntity.ok(response);
    }

    @PutMapping
    @Operation(summary = "Update settings", description = "Updates application settings (dark mode, language VI/EN, currency VND/USD, notifications, budget warning threshold)")
    @ApiResponse(responseCode = "200", description = "Updated successfully")
    public ResponseEntity<UserSettingsResponse> updateUserSettings(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody UserSettingsRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        UserSettingsResponse response = userSettingsService.updateUserSettings(resolved, request);
        return ResponseEntity.ok(response);
    }
}
