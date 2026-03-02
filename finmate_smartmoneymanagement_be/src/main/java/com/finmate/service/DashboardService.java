package com.finmate.service;

import com.finmate.dto.response.DashboardResponse;

import java.util.UUID;

public interface DashboardService {
    DashboardResponse getDashboard(UUID userId);
    DashboardResponse postDashboard(UUID userId);
}
