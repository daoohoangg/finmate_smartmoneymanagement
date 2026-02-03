package com.finmate.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

@Data
@AllArgsConstructor
public class TransactionImportPreviewResponse {
    private int totalRows;
    private List<TransactionImportPreviewRow> previewRows;
}
