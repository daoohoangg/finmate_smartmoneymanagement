package com.finmate.service;

import com.finmate.dto.response.BehaviorAnalysisResponse;
import com.finmate.dto.response.CalendarDayTransactionsResponse;
import com.finmate.dto.response.CashflowTrendPointResponse;
import com.finmate.dto.response.SpendingPieSliceResponse;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;

public interface AnalyticsService {
    List<SpendingPieSliceResponse> getSpendingPie(UUID userId, YearMonth month);

    List<CashflowTrendPointResponse> getCashflowTrend(UUID userId, int months);

    List<CalendarDayTransactionsResponse> getCalendar(UUID userId, LocalDate start, LocalDate end);

    BehaviorAnalysisResponse getBehaviorAnalysis(UUID userId, YearMonth month);
}
