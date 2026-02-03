package com.finmate.service.impl;

import com.finmate.dto.request.ChangePasswordRequest;
import com.finmate.dto.request.UpdateProfileRequest;
import com.finmate.dto.response.UserProfileResponse;
import com.finmate.entities.User;
import com.finmate.repository.UserRepository;
import com.finmate.service.ProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ProfileServiceImpl implements ProfileService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public UserProfileResponse getProfile(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return mapToResponse(user);
    }

    @Override
    public UserProfileResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        if (request.getFullName() != null) {
            user.setFullName(request.getFullName());
        }
        User updated = userRepository.save(user);
        return mapToResponse(updated);
    }

    @Override
    public void changePassword(UUID userId, ChangePasswordRequest request) {
        if (request.getCurrentPassword() == null || request.getNewPassword() == null) {
            throw new RuntimeException("Current password and new password are required");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            throw new RuntimeException("Current password is incorrect");
        }
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }

    @Override
    public UserProfileResponse updateAvatar(UUID userId, MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new RuntimeException("Avatar file is required");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setAvatar(file.getBytes());
        user.setAvatarContentType(file.getContentType());
        user.setAvatarFileName(file.getOriginalFilename());
        User updated = userRepository.save(user);
        return mapToResponse(updated);
    }

    @Override
    public User getAvatarOwner(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    @Override
    public UserProfileResponse deleteAvatar(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setAvatar(null);
        user.setAvatarContentType(null);
        user.setAvatarFileName(null);
        User updated = userRepository.save(user);
        return mapToResponse(updated);
    }

    private UserProfileResponse mapToResponse(User user) {
        return new UserProfileResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getAvatar() != null,
                user.getUpdatedAt());
    }
}
