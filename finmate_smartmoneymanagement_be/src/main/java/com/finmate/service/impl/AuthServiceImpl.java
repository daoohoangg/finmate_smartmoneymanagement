package com.finmate.service.impl;

import com.finmate.dto.request.GoogleLoginRequest;
import com.finmate.dto.request.LoginRequest;
import com.finmate.dto.request.RegisterRequest;
import com.finmate.dto.response.AuthResponse;
import com.finmate.entities.User;
import com.finmate.entities.UserSettings;
import com.finmate.repository.UserRepository;
import com.finmate.repository.UserSettingsRepository;
import com.finmate.security.JwtService;
import com.finmate.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final UserSettingsRepository userSettingsRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Value("${google.oauth.client-id:}")
    private String googleClientId;

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

        return new AuthResponse(
                savedUser.getId(),
                savedUser.getEmail(),
                savedUser.getFullName(),
                token);
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Invalid email or password");
        }

        String token = jwtService.generateToken(user);

        return new AuthResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                token);
    }

    @Override
    public AuthResponse loginWithGoogle(GoogleLoginRequest request) {
        if (request.getIdToken() == null || request.getIdToken().isBlank()) {
            throw new RuntimeException("Google ID token is required");
        }
        if (googleClientId == null || googleClientId.isBlank()) {
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

        if (aud == null || !googleClientId.equals(aud.toString())) {
            throw new RuntimeException("Google token audience mismatch");
        }
        if (emailObj == null) {
            throw new RuntimeException("Google token missing email");
        }
        if (emailVerified != null && !"true".equalsIgnoreCase(emailVerified.toString())) {
            throw new RuntimeException("Google email is not verified");
        }

        String email = emailObj.toString();
        String name = tokenInfo.get("name") != null ? tokenInfo.get("name").toString() : email;

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

        return new AuthResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                token);
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
