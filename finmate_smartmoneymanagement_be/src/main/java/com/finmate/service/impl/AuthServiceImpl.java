package com.finmate.service.impl;

import com.finmate.dto.request.ForgotPasswordRequest;
import com.finmate.dto.request.GoogleLoginRequest;
import com.finmate.dto.request.LoginRequest;
import com.finmate.dto.request.RegisterRequest;
import com.finmate.dto.request.ResetPasswordRequest;
import com.finmate.dto.request.VerifyOtpRequest;
import com.finmate.dto.response.AuthResponse;
import com.finmate.dto.response.VerifyOtpResponse;
import com.finmate.entities.PasswordResetOtp;
import com.finmate.entities.User;
import com.finmate.entities.UserSettings;
import com.finmate.repository.PasswordResetOtpRepository;
import com.finmate.repository.UserRepository;
import com.finmate.repository.UserSettingsRepository;
import com.finmate.security.JwtService;
import com.finmate.service.AuthService;
import com.finmate.service.EmailService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final UserSettingsRepository userSettingsRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final EmailService emailService;
    private final PasswordResetOtpRepository otpRepository;

    @Value("#{'${google.oauth.allowed-client-ids:}'.split(',')}")
    private java.util.List<String> allowedClientIds;

    @Value("${app.otp.expiry-minutes:10}")
    private int otpExpiryMinutes;

    @Override
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already exists");
        }
        User user = new User();
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setFullName(request.getFullName());
        user.setCreatedAt(LocalDateTime.now());
        User savedUser = userRepository.save(user);
        createDefaultSettings(savedUser);
        String token = jwtService.generateToken(savedUser);
        return new AuthResponse(savedUser.getId(), savedUser.getEmail(), savedUser.getFullName(), token);
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Invalid email or password"));
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Invalid email or password");
        }
        String token = jwtService.generateToken(user);
        return new AuthResponse(user.getId(), user.getEmail(), user.getFullName(), token);
    }

    @Override
    public AuthResponse loginWithGoogle(GoogleLoginRequest request) {
        final List<String> normalizedAllowedClientIds = allowedClientIds == null
                ? List.of()
                : allowedClientIds.stream()
                        .map(String::trim)
                        .filter(id -> !id.isEmpty())
                        .toList();

        String email;
        String name;

        if (request.getAccessToken() != null && !request.getAccessToken().isBlank()) {
            RestTemplate restTemplate = new RestTemplate();
            try {
                ResponseEntity<Map> response = restTemplate.getForEntity(
                        "https://www.googleapis.com/oauth2/v3/userinfo?access_token=" + request.getAccessToken(),
                        Map.class);
                if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                    throw new RuntimeException("Invalid Google access token");
                }
                Map<String, Object> userInfo = response.getBody();
                Object emailObj = userInfo.get("email");
                Object emailVerified = userInfo.get("email_verified");
                if (emailObj == null)
                    throw new RuntimeException("Google token missing email");
                if (emailVerified != null && !Boolean.TRUE.equals(emailVerified))
                    throw new RuntimeException("Google email is not verified");
                email = emailObj.toString();
                name = userInfo.get("name") != null ? userInfo.get("name").toString() : email;
            } catch (Exception e) {
                throw new RuntimeException("Failed to verify Google access token: " + e.getMessage());
            }
        } else if (request.getIdToken() != null && !request.getIdToken().isBlank()) {
            if (normalizedAllowedClientIds.isEmpty()) {
                throw new RuntimeException("Google Sign-In is not configured");
            }
            RestTemplate restTemplate = new RestTemplate();
            ResponseEntity<Map> response = restTemplate.getForEntity(
                    "https://oauth2.googleapis.com/tokeninfo?id_token=" + request.getIdToken(), Map.class);
            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                throw new RuntimeException("Invalid Google token");
            }
            Map<String, Object> tokenInfo = response.getBody();
            Object aud = tokenInfo.get("aud");
            Object emailObj = tokenInfo.get("email");
            Object emailVerified = tokenInfo.get("email_verified");
            if (aud == null || !normalizedAllowedClientIds.contains(aud.toString()))
                throw new RuntimeException("Google token audience mismatch");
            if (emailObj == null)
                throw new RuntimeException("Google token missing email");
            if (emailVerified != null && !"true".equalsIgnoreCase(emailVerified.toString()))
                throw new RuntimeException("Google email is not verified");
            email = emailObj.toString();
            name = tokenInfo.get("name") != null ? tokenInfo.get("name").toString() : email;
        } else {
            throw new RuntimeException("Google ID token or access token is required");
        }

        User user = userRepository.findByEmail(email).orElseGet(() -> {
            User newUser = new User();
            newUser.setEmail(email);
            newUser.setFullName(name);
            newUser.setPassword(passwordEncoder.encode(generateRandomPassword()));
            newUser.setCreatedAt(LocalDateTime.now());
            User saved = userRepository.save(newUser);
            createDefaultSettings(saved);
            return saved;
        });
        String token = jwtService.generateToken(user);
        return new AuthResponse(user.getId(), user.getEmail(), user.getFullName(), token);
    }

    @Override
    public void forgotPassword(ForgotPasswordRequest request) {
        userRepository.findByEmail(request.getEmail()).ifPresent(user -> {
            otpRepository.markAllUsedByEmail(request.getEmail());
            String otp = generateOtp();
            PasswordResetOtp resetOtp = new PasswordResetOtp();
            resetOtp.setEmail(request.getEmail());
            resetOtp.setOtp(otp);
            resetOtp.setExpiresAt(LocalDateTime.now().plusMinutes(otpExpiryMinutes));
            otpRepository.save(resetOtp);
            emailService.sendOtpEmail(request.getEmail(), otp);
        });
    }

    @Override
    public VerifyOtpResponse verifyOtp(VerifyOtpRequest request) {
        PasswordResetOtp otpRecord = otpRepository
                .findTopByEmailAndUsedFalseOrderByCreatedAtDesc(request.getEmail())
                .orElseThrow(() -> new RuntimeException("OTP not found or already used"));
        if (otpRecord.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("OTP has expired. Please request a new one.");
        }
        if (!otpRecord.getOtp().equals(request.getOtp())) {
            throw new RuntimeException("Invalid OTP code");
        }
        otpRecord.setUsed(true);
        otpRepository.save(otpRecord);
        String resetToken = UUID.nameUUIDFromBytes(
                (otpRecord.getId() + ":" + otpRecord.getEmail()).getBytes()).toString();
        return new VerifyOtpResponse(resetToken);
    }

    @Override
    public void resetPassword(ResetPasswordRequest request) {
        PasswordResetOtp otpRecord = otpRepository.findAll().stream()
                .filter(o -> o.isUsed() && !o.getExpiresAt().isBefore(LocalDateTime.now().minusMinutes(30)))
                .filter(o -> {
                    String expected = UUID.nameUUIDFromBytes(
                            (o.getId() + ":" + o.getEmail()).getBytes()).toString();
                    return expected.equals(request.getResetToken());
                })
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Invalid or expired reset token"));

        User user = userRepository.findByEmail(otpRecord.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
        otpRecord.setExpiresAt(LocalDateTime.now().minusSeconds(1));
        otpRepository.save(otpRecord);
    }

    private String generateOtp() {
        SecureRandom random = new SecureRandom();
        int otp = 100000 + random.nextInt(900000);
        return String.valueOf(otp);
    }

    private String generateRandomPassword() {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 16; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }

    private void createDefaultSettings(User user) {
        if (userSettingsRepository.findByUserId(user.getId()).isEmpty()) {
            UserSettings settings = new UserSettings();
            settings.setUser(user);
            userSettingsRepository.save(settings);
        }
    }
}
