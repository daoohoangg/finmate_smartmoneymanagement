package com.finmate.service;

import com.finmate.dto.request.ForgotPasswordRequest;
import com.finmate.dto.request.GoogleLoginRequest;
import com.finmate.dto.request.LoginRequest;
import com.finmate.dto.request.RegisterRequest;
import com.finmate.dto.request.ResetPasswordRequest;
import com.finmate.dto.request.VerifyOtpRequest;
import com.finmate.dto.response.AuthResponse;
import com.finmate.dto.response.VerifyOtpResponse;

public interface AuthService {
    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    AuthResponse loginWithGoogle(GoogleLoginRequest request);

    void forgotPassword(ForgotPasswordRequest request);

    VerifyOtpResponse verifyOtp(VerifyOtpRequest request);

    void resetPassword(ResetPasswordRequest request);
}
