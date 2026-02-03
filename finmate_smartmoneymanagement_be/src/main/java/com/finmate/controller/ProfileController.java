package com.finmate.controller;

import com.finmate.dto.request.ChangePasswordRequest;
import com.finmate.dto.request.UpdateProfileRequest;
import com.finmate.dto.response.UserProfileResponse;
import com.finmate.entities.User;
import com.finmate.security.UserPrincipal;
import com.finmate.service.ProfileService;
import com.finmate.util.UserIdResolver;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@RestController
@RequestMapping("/api/profile")
@RequiredArgsConstructor
@Tag(name = "Profile", description = "User profile management")
public class ProfileController {

    private final ProfileService profileService;

    @GetMapping
    @Operation(summary = "Get profile")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<UserProfileResponse> getProfile(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        return ResponseEntity.ok(profileService.getProfile(resolved));
    }

    @PutMapping
    @Operation(summary = "Update profile")
    @ApiResponse(responseCode = "200", description = "Updated successfully")
    public ResponseEntity<UserProfileResponse> updateProfile(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody UpdateProfileRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        return ResponseEntity.ok(profileService.updateProfile(resolved, request));
    }

    @PutMapping("/password")
    @Operation(summary = "Change password")
    @ApiResponse(responseCode = "204", description = "Password changed")
    public ResponseEntity<Void> changePassword(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody ChangePasswordRequest request) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        profileService.changePassword(resolved, request);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/avatar")
    @Operation(summary = "Upload avatar")
    @ApiResponse(responseCode = "200", description = "Avatar updated")
    public ResponseEntity<UserProfileResponse> uploadAvatar(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam("file") MultipartFile file) throws IOException {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        return ResponseEntity.ok(profileService.updateAvatar(resolved, file));
    }

    @GetMapping("/avatar")
    @Operation(summary = "Download avatar")
    @ApiResponse(responseCode = "200", description = "Success")
    public ResponseEntity<byte[]> downloadAvatar(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        User user = profileService.getAvatarOwner(resolved);
        if (user.getAvatar() == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(
                        user.getAvatarContentType() != null ? user.getAvatarContentType() : MediaType.APPLICATION_OCTET_STREAM_VALUE))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "inline; filename=\"" + (user.getAvatarFileName() != null ? user.getAvatarFileName() : "avatar") + "\"")
                .body(user.getAvatar());
    }

    @DeleteMapping("/avatar")
    @Operation(summary = "Delete avatar")
    @ApiResponse(responseCode = "200", description = "Avatar deleted")
    public ResponseEntity<UserProfileResponse> deleteAvatar(
            @Parameter(description = "User ID", required = false) @RequestHeader(value = "User-Id", required = false) UUID userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        UUID resolved = UserIdResolver.resolve(userId, principal);
        return ResponseEntity.ok(profileService.deleteAvatar(resolved));
    }
}
