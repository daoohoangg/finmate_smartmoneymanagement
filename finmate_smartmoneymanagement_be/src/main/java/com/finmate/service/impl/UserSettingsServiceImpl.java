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

    private static final int DEFAULT_NECESSARY_ALLOCATION_PERCENT = 60;
    private static final int DEFAULT_ACCUMULATION_ALLOCATION_PERCENT = 20;
    private static final int DEFAULT_FLEXIBILITY_ALLOCATION_PERCENT = 20;

    private final UserSettingsRepository userSettingsRepository;
    private final UserRepository userRepository;

    @Override
    public UserSettingsResponse getUserSettings(UUID userId) {
        UserSettings settings = userSettingsRepository.findByUserId(userId)
                .orElse(null);
        if (settings == null) {
            return createDefaultSettings(userId);
        }
        if (applyAllocationDefaults(settings)) {
            settings = userSettingsRepository.save(settings);
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
        if (request.getRoundingScale() != null) {
            settings.setRoundingScale(request.getRoundingScale());
        }
        if (request.getRoundingMode() != null) {
            settings.setRoundingMode(request.getRoundingMode());
        }
        if (request.getNecessaryAllocationPercent() != null) {
            settings.setNecessaryAllocationPercent(request.getNecessaryAllocationPercent());
        }
        if (request.getAccumulationAllocationPercent() != null) {
            settings.setAccumulationAllocationPercent(request.getAccumulationAllocationPercent());
        }
        if (request.getFlexibilityAllocationPercent() != null) {
            settings.setFlexibilityAllocationPercent(request.getFlexibilityAllocationPercent());
        }
        applyAllocationDefaults(settings);

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
        settings.setLanguage("EN");
        settings.setDefaultCurrency("VND");
        settings.setNotificationEnabled(true);
        settings.setBudgetAlertThreshold(80);
        settings.setRoundingScale(2);
        settings.setRoundingMode("HALF_UP");
        settings.setNecessaryAllocationPercent(DEFAULT_NECESSARY_ALLOCATION_PERCENT);
        settings.setAccumulationAllocationPercent(DEFAULT_ACCUMULATION_ALLOCATION_PERCENT);
        settings.setFlexibilityAllocationPercent(DEFAULT_FLEXIBILITY_ALLOCATION_PERCENT);

        UserSettings savedSettings = userSettingsRepository.save(settings);
        return mapToResponse(savedSettings);
    }

    private boolean applyAllocationDefaults(UserSettings settings) {
        boolean updated = false;
        if (settings.getNecessaryAllocationPercent() == null) {
            settings.setNecessaryAllocationPercent(DEFAULT_NECESSARY_ALLOCATION_PERCENT);
            updated = true;
        }
        if (settings.getAccumulationAllocationPercent() == null) {
            settings.setAccumulationAllocationPercent(DEFAULT_ACCUMULATION_ALLOCATION_PERCENT);
            updated = true;
        }
        if (settings.getFlexibilityAllocationPercent() == null) {
            settings.setFlexibilityAllocationPercent(DEFAULT_FLEXIBILITY_ALLOCATION_PERCENT);
            updated = true;
        }
        return updated;
    }

    private UserSettingsResponse mapToResponse(UserSettings settings) {
        return new UserSettingsResponse(
                settings.getId(),
                settings.getDarkMode(),
                settings.getLanguage(),
                settings.getDefaultCurrency(),
                settings.getNotificationEnabled(),
                settings.getBudgetAlertThreshold(),
                settings.getRoundingScale(),
                settings.getRoundingMode(),
                settings.getNecessaryAllocationPercent(),
                settings.getAccumulationAllocationPercent(),
                settings.getFlexibilityAllocationPercent());
    }
}
