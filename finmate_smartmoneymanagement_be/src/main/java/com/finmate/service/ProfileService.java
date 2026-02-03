package com.finmate.service;

import com.finmate.dto.request.ChangePasswordRequest;
import com.finmate.dto.request.UpdateProfileRequest;
import com.finmate.dto.response.UserProfileResponse;
import com.finmate.entities.User;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

public interface ProfileService {
    UserProfileResponse getProfile(UUID userId);

    UserProfileResponse updateProfile(UUID userId, UpdateProfileRequest request);

    void changePassword(UUID userId, ChangePasswordRequest request);

    UserProfileResponse updateAvatar(UUID userId, MultipartFile file) throws IOException;

    User getAvatarOwner(UUID userId);

    UserProfileResponse deleteAvatar(UUID userId);
}
