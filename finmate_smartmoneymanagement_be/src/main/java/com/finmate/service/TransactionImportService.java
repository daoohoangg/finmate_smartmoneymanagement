package com.finmate.service;

import com.finmate.dto.request.TransactionImportMappingRequest;
import com.finmate.dto.response.TransactionImportPreviewResponse;
import com.finmate.dto.response.TransactionImportResultResponse;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

public interface TransactionImportService {
    TransactionImportPreviewResponse preview(UUID userId, MultipartFile file, TransactionImportMappingRequest mapping)
            throws IOException;

    TransactionImportResultResponse importTransactions(UUID userId, MultipartFile file, TransactionImportMappingRequest mapping)
            throws IOException;
}
