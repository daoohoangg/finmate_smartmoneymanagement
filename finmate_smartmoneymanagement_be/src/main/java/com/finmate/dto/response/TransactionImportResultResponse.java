package com.finmate.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

@Data
@AllArgsConstructor
public class TransactionImportResultResponse {
    private int totalRows;
    private int importedRows;
    private int failedRows;
    private List<String> errors;
}
