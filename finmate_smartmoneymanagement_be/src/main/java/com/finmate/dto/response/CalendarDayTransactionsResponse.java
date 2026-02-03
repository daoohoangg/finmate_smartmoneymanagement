package com.finmate.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.time.LocalDate;
import java.util.List;

@Data
@AllArgsConstructor
public class CalendarDayTransactionsResponse {
    private LocalDate date;
    private List<TransactionResponse> transactions;
}
