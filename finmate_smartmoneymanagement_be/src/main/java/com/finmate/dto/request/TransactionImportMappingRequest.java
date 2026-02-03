package com.finmate.dto.request;

import com.finmate.enums.TransactionType;
import lombok.Data;

@Data
public class TransactionImportMappingRequest {
    private Long walletId;
    private String dateColumn;
    private String amountColumn;
    private String noteColumn;
    private String merchantColumn;
    private String categoryColumn;
    private String typeColumn;
    private String dateFormat;
    private Boolean amountNegativeIsExpense;
    private TransactionType defaultType;
}
