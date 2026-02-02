package com.finmate.service.impl;

import com.finmate.dto.request.LoginRequest;
import com.finmate.dto.request.RegisterRequest;
import com.finmate.dto.response.AuthResponse;
import com.finmate.entities.User;
import com.finmate.repository.UserRepository;
import com.finmate.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

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

        // TODO: Generate JWT token
        String token = "mock-jwt-token";

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

        // TODO: Generate JWT token
        String token = "mock-jwt-token";

        return new AuthResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                token);
    }
}
