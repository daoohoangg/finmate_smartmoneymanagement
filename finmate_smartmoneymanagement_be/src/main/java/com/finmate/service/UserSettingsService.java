package com.finmate.service;

import com.finmate.dto.request.UserSettingsRequest;
import com.finmate.dto.response.UserSettingsResponse;

import java.util.UUID;

public interface UserSettingsService {
    UserSettingsResponse getUserSettings(UUID userId);

    UserSettingsResponse updateUserSettings(UUID userId, UserSettingsRequest request);

    UserSettingsResponse createDefaultSettings(UUID userId);
}
