package com.finmate.controller;

import com.finmate.dto.request.ForgotPasswordRequest;
import com.finmate.dto.request.GoogleLoginRequest;
import com.finmate.dto.request.LoginRequest;
import com.finmate.dto.request.RegisterRequest;
import com.finmate.dto.request.ResetPasswordRequest;
import com.finmate.dto.request.VerifyOtpRequest;
import com.finmate.dto.response.AuthResponse;
import com.finmate.dto.response.VerifyOtpResponse;
import com.finmate.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "User authentication endpoints")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @Operation(summary = "Register new user account")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "User registered successfully"),
            @ApiResponse(responseCode = "400", description = "Email already exists or invalid data")
    })
    public ResponseEntity<AuthResponse> register(@RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.register(request));
    }

    @PostMapping("/login")
    @Operation(summary = "User login")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Login successful"),
            @ApiResponse(responseCode = "401", description = "Invalid email or password")
    })
    public ResponseEntity<AuthResponse> login(@RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/google")
    @Operation(summary = "Google Sign-In")
    @ApiResponse(responseCode = "200", description = "Login successful")
    public ResponseEntity<AuthResponse> loginWithGoogle(@RequestBody GoogleLoginRequest request) {
        return ResponseEntity.ok(authService.loginWithGoogle(request));
    }

    @PostMapping("/forgot-password")
    @Operation(summary = "Request password reset OTP", description = "Sends a 6-digit OTP to the registered email. Silently succeeds if email not found.")
    @ApiResponse(responseCode = "200", description = "OTP sent")
    public ResponseEntity<Void> forgotPassword(@RequestBody ForgotPasswordRequest request) {
        authService.forgotPassword(request);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/verify-otp")
    @Operation(summary = "Verify OTP and get reset token", description = "Validates the 6-digit OTP and returns a one-time reset token.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "OTP valid"),
            @ApiResponse(responseCode = "400", description = "Invalid or expired OTP")
    })
    public ResponseEntity<VerifyOtpResponse> verifyOtp(@RequestBody VerifyOtpRequest request) {
        return ResponseEntity.ok(authService.verifyOtp(request));
    }

    @PostMapping("/reset-password")
    @Operation(summary = "Reset password with token", description = "Sets a new password using the reset token from verify-otp.")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Password reset successfully"),
            @ApiResponse(responseCode = "400", description = "Invalid or expired reset token")
    })
    public ResponseEntity<Void> resetPassword(@RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request);
        return ResponseEntity.ok().build();
    }
}
