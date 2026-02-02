package com.finmate.service.impl;

import com.finmate.dto.request.UserSettingsRequest;
import com.finmate.dto.response.UserSettingsResponse;
import com.finmate.entities.User;
import com.finmate.entities.UserSettings;
import com.finmate.repository.UserRepository;
import com.finmate.repository.UserSettingsRepository;
import com.finmate.service.UserSettingsService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserSettingsServiceImpl implements UserSettingsService {

    private final UserSettingsRepository userSettingsRepository;
    private final UserRepository userRepository;

    @Override
    public UserSettingsResponse getUserSettings(UUID userId) {
        UserSettings settings = userSettingsRepository.findByUserId(userId)
                .orElse(null);
        if (settings == null) {
            return createDefaultSettings(userId);
        }
        return mapToResponse(settings);
    }

    @Override
    public UserSettingsResponse updateUserSettings(UUID userId, UserSettingsRequest request) {
        UserSettings settings = userSettingsRepository.findByUserId(userId)
                .orElseGet(() -> {
                    User user = userRepository.findById(userId)
                            .orElseThrow(() -> new RuntimeException("User not found"));
                    UserSettings newSettings = new UserSettings();
                    newSettings.setUser(user);
                    return newSettings;
                });

        if (request.getDarkMode() != null) {
            settings.setDarkMode(request.getDarkMode());
        }
        if (request.getLanguage() != null) {
            settings.setLanguage(request.getLanguage());
        }
        if (request.getDefaultCurrency() != null) {
            settings.setDefaultCurrency(request.getDefaultCurrency());
        }
        if (request.getNotificationEnabled() != null) {
            settings.setNotificationEnabled(request.getNotificationEnabled());
        }
        if (request.getBudgetAlertThreshold() != null) {
            settings.setBudgetAlertThreshold(request.getBudgetAlertThreshold());
        }

        UserSettings updatedSettings = userSettingsRepository.save(settings);
        return mapToResponse(updatedSettings);
    }

    @Override
    public UserSettingsResponse createDefaultSettings(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        UserSettings settings = new UserSettings();
        settings.setUser(user);
        settings.setDarkMode(false);
        settings.setLanguage("VI");
        settings.setDefaultCurrency("VND");
        settings.setNotificationEnabled(true);
        settings.setBudgetAlertThreshold(80);

        UserSettings savedSettings = userSettingsRepository.save(settings);
        return mapToResponse(savedSettings);
    }

    private UserSettingsResponse mapToResponse(UserSettings settings) {
        return new UserSettingsResponse(
                settings.getId(),
                settings.getDarkMode(),
                settings.getLanguage(),
                settings.getDefaultCurrency(),
                settings.getNotificationEnabled(),
                settings.getBudgetAlertThreshold());
    }
}
