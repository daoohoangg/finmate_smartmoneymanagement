package com.finmate.service.impl;

import com.finmate.dto.response.BehaviorAnalysisResponse;
import com.finmate.dto.response.CalendarDayTransactionsResponse;
import com.finmate.dto.response.CashflowTrendPointResponse;
import com.finmate.dto.response.SpendingPieSliceResponse;
import com.finmate.dto.response.TransactionResponse;
import com.finmate.entities.Transaction;
import com.finmate.entities.UserSettings;
import com.finmate.enums.TransactionType;
import com.finmate.repository.TransactionRepository;
import com.finmate.repository.UserSettingsRepository;
import com.finmate.service.AnalyticsService;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AnalyticsServiceImpl implements AnalyticsService {

    private final TransactionRepository transactionRepository;
    private final UserSettingsRepository userSettingsRepository;

    @Override
    @Transactional
    public List<SpendingPieSliceResponse> getSpendingPie(UUID userId, YearMonth month) {
        YearMonth target = month != null ? month : YearMonth.now();
        LocalDateTime start = target.atDay(1).atStartOfDay();
        LocalDateTime end = target.atEndOfMonth().atTime(23, 59, 59);

        List<Transaction> transactions = transactionRepository.findByUserIdAndTransactionDateBetween(userId, start, end);
        List<Transaction> expenses = transactions.stream()
                .filter(t -> t.getType() == TransactionType.EXPENSE)
                .toList();

        BigDecimal totalExpense = expenses.stream()
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<CategoryKey, BigDecimal> totals = expenses.stream()
                .collect(Collectors.groupingBy(
                        t -> t.getCategory() != null
                                ? new CategoryKey(t.getCategory().getId(), t.getCategory().getName())
                                : new CategoryKey(null, "Uncategorized"),
                        Collectors.mapping(Transaction::getAmount,
                                Collectors.reducing(BigDecimal.ZERO, BigDecimal::add))));

        UserSettings settings = userSettingsRepository.findByUserId(userId).orElse(null);
        List<SpendingPieSliceResponse> slices = new ArrayList<>();
        for (Map.Entry<CategoryKey, BigDecimal> entry : totals.entrySet()) {
            BigDecimal amount = entry.getValue();
            BigDecimal percentage = BigDecimal.ZERO;
            if (totalExpense.compareTo(BigDecimal.ZERO) > 0) {
                percentage = amount.multiply(BigDecimal.valueOf(100))
                        .divide(totalExpense, 4, RoundingMode.HALF_UP);
            }
            slices.add(new SpendingPieSliceResponse(
                    entry.getKey().categoryId,
                    entry.getKey().categoryName,
                    roundAmount(amount, settings),
                    roundAmount(percentage, settings)));
        }

        return slices.stream()
                .sorted(Comparator.comparing(SpendingPieSliceResponse::getAmount).reversed())
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public List<CashflowTrendPointResponse> getCashflowTrend(UUID userId, int months) {
        int window = months > 0 ? months : 6;
        YearMonth current = YearMonth.now();
        YearMonth startMonth = current.minusMonths(window - 1);

        LocalDateTime start = startMonth.atDay(1).atStartOfDay();
        LocalDateTime end = current.atEndOfMonth().atTime(23, 59, 59);

        List<Transaction> transactions = transactionRepository.findByUserIdAndTransactionDateBetween(userId, start, end);
        Map<YearMonth, List<Transaction>> grouped = transactions.stream()
                .collect(Collectors.groupingBy(t -> YearMonth.from(t.getTransactionDate())));

        UserSettings settings = userSettingsRepository.findByUserId(userId).orElse(null);

        List<CashflowTrendPointResponse> points = new ArrayList<>();
        YearMonth iter = startMonth;
        for (int i = 0; i < window; i++) {
            YearMonth month = iter;
            List<Transaction> monthTx = grouped.getOrDefault(month, List.of());
            BigDecimal income = monthTx.stream()
                    .filter(t -> t.getType() == TransactionType.INCOME)
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            BigDecimal expense = monthTx.stream()
                    .filter(t -> t.getType() == TransactionType.EXPENSE)
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            points.add(new CashflowTrendPointResponse(
                    month.getYear(),
                    month.getMonthValue(),
                    roundAmount(income, settings),
                    roundAmount(expense, settings)));
            iter = iter.plusMonths(1);
        }
        return points;
    }

    @Override
    @Transactional
    public List<CalendarDayTransactionsResponse> getCalendar(UUID userId, LocalDate start, LocalDate end) {
        LocalDate startDate = start != null ? start : LocalDate.now().withDayOfMonth(1);
        LocalDate endDate = end != null ? end : startDate.withDayOfMonth(startDate.lengthOfMonth());

        LocalDateTime startDateTime = startDate.atStartOfDay();
        LocalDateTime endDateTime = endDate.atTime(23, 59, 59);

        List<Transaction> transactions = transactionRepository.findByUserIdAndTransactionDateBetween(userId, startDateTime, endDateTime);

        Map<LocalDate, List<TransactionResponse>> grouped = transactions.stream()
                .sorted(Comparator.comparing(Transaction::getTransactionDate))
                .collect(Collectors.groupingBy(
                        t -> t.getTransactionDate().toLocalDate(),
                        Collectors.mapping(this::mapToResponse, Collectors.toList())));

        return grouped.entrySet().stream()
                .map(entry -> new CalendarDayTransactionsResponse(entry.getKey(), entry.getValue()))
                .sorted(Comparator.comparing(CalendarDayTransactionsResponse::getDate))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public BehaviorAnalysisResponse getBehaviorAnalysis(UUID userId, YearMonth month) {
        YearMonth current = month != null ? month : YearMonth.now();
        YearMonth previous = current.minusMonths(1);

        LocalDateTime currentStart = current.atDay(1).atStartOfDay();
        LocalDateTime currentEnd = current.atEndOfMonth().atTime(23, 59, 59);
        LocalDateTime prevStart = previous.atDay(1).atStartOfDay();
        LocalDateTime prevEnd = previous.atEndOfMonth().atTime(23, 59, 59);

        List<Transaction> currentTx = transactionRepository.findByUserIdAndTransactionDateBetween(userId, currentStart, currentEnd);
        List<Transaction> prevTx = transactionRepository.findByUserIdAndTransactionDateBetween(userId, prevStart, prevEnd);

        BigDecimal currentIncome = sumByType(currentTx, TransactionType.INCOME);
        BigDecimal currentExpense = sumByType(currentTx, TransactionType.EXPENSE);
        BigDecimal prevIncome = sumByType(prevTx, TransactionType.INCOME);
        BigDecimal prevExpense = sumByType(prevTx, TransactionType.EXPENSE);

        BigDecimal incomeChange = calculateChangePercent(prevIncome, currentIncome);
        BigDecimal expenseChange = calculateChangePercent(prevExpense, currentExpense);

        BigDecimal weekendExpense = currentTx.stream()
                .filter(t -> t.getType() == TransactionType.EXPENSE)
                .filter(t -> {
                    DayOfWeek day = t.getTransactionDate().getDayOfWeek();
                    return day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY;
                })
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal weekdayExpense = currentExpense.subtract(weekendExpense);

        long weekendDays = 0;
        long totalDays = current.lengthOfMonth();
        for (int day = 1; day <= totalDays; day++) {
            DayOfWeek dow = current.atDay(day).getDayOfWeek();
            if (dow == DayOfWeek.SATURDAY || dow == DayOfWeek.SUNDAY) {
                weekendDays++;
            }
        }
        long weekdayDays = totalDays - weekendDays;

        BigDecimal weekendAvg = weekendDays > 0 ? weekendExpense.divide(BigDecimal.valueOf(weekendDays), 4, RoundingMode.HALF_UP) : BigDecimal.ZERO;
        BigDecimal weekdayAvg = weekdayDays > 0 ? weekdayExpense.divide(BigDecimal.valueOf(weekdayDays), 4, RoundingMode.HALF_UP) : BigDecimal.ZERO;

        UserSettings settings = userSettingsRepository.findByUserId(userId).orElse(null);

        return new BehaviorAnalysisResponse(
                roundAmount(currentIncome, settings),
                roundAmount(currentExpense, settings),
                roundAmount(prevIncome, settings),
                roundAmount(prevExpense, settings),
                roundAmount(incomeChange, settings),
                roundAmount(expenseChange, settings),
                roundAmount(weekendExpense, settings),
                roundAmount(weekdayExpense, settings),
                roundAmount(weekendAvg, settings),
                roundAmount(weekdayAvg, settings));
    }

    private BigDecimal sumByType(List<Transaction> transactions, TransactionType type) {
        return transactions.stream()
                .filter(t -> t.getType() == type)
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private BigDecimal calculateChangePercent(BigDecimal previous, BigDecimal current) {
        if (previous.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ZERO;
        }
        return current.subtract(previous)
                .multiply(BigDecimal.valueOf(100))
                .divide(previous, 4, RoundingMode.HALF_UP);
    }

    private BigDecimal roundAmount(BigDecimal value, UserSettings settings) {
        if (value == null) {
            return null;
        }
        int scale = settings != null && settings.getRoundingScale() != null ? settings.getRoundingScale() : 2;
        RoundingMode mode = RoundingMode.HALF_UP;
        if (settings != null && settings.getRoundingMode() != null) {
            try {
                mode = RoundingMode.valueOf(settings.getRoundingMode());
            } catch (Exception ignored) {
                mode = RoundingMode.HALF_UP;
            }
        }
        return value.setScale(scale, mode);
    }

    private TransactionResponse mapToResponse(Transaction transaction) {
        return new TransactionResponse(
                transaction.getId(),
                transaction.getWallet().getId(),
                transaction.getWallet().getName(),
                transaction.getCategory() != null ? transaction.getCategory().getId() : null,
                transaction.getCategory() != null ? transaction.getCategory().getName() : null,
                transaction.getType(),
                transaction.getAmount(),
                transaction.getNote(),
                transaction.getTransactionDate(),
                transaction.getImageUrl(),
                transaction.getToWallet() != null ? transaction.getToWallet().getId() : null,
                transaction.getToWallet() != null ? transaction.getToWallet().getName() : null,
                transaction.getSavingsGoal() != null ? transaction.getSavingsGoal().getId() : null,
                transaction.getSavingsGoal() != null ? transaction.getSavingsGoal().getName() : null,
                transaction.getInvestmentPlan() != null ? transaction.getInvestmentPlan().getId() : null,
                transaction.getInvestmentPlan() != null ? transaction.getInvestmentPlan().getName() : null);
    }

    private static class CategoryKey {
        private final Long categoryId;
        private final String categoryName;

        private CategoryKey(Long categoryId, String categoryName) {
            this.categoryId = categoryId;
            this.categoryName = categoryName;
        }

        @Override
        public boolean equals(Object obj) {
            if (this == obj) {
                return true;
            }
            if (obj == null || getClass() != obj.getClass()) {
                return false;
            }
            CategoryKey other = (CategoryKey) obj;
            if (categoryId == null && other.categoryId != null) {
                return false;
            }
            if (categoryId != null && !categoryId.equals(other.categoryId)) {
                return false;
            }
            return categoryName.equals(other.categoryName);
        }

        @Override
        public int hashCode() {
            int result = categoryId != null ? categoryId.hashCode() : 0;
            result = 31 * result + categoryName.hashCode();
            return result;
        }
    }
}
