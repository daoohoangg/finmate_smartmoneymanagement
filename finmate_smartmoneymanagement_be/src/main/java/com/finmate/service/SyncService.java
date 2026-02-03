package com.finmate.service;

import com.finmate.dto.response.SyncResponse;

import java.util.UUID;

public interface SyncService {
    SyncResponse syncAll(UUID userId);
}
