package com.finmate.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class TransactionAttachmentResponse {
    private Long id;
    private Long transactionId;
    private String fileName;
    private String contentType;
    private Long fileSize;
}
