package com.finmate.service;

import com.finmate.dto.response.TransactionAttachmentResponse;
import com.finmate.entities.TransactionAttachment;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

public interface TransactionAttachmentService {
    TransactionAttachmentResponse addAttachment(Long transactionId, MultipartFile file) throws IOException;

    List<TransactionAttachmentResponse> getAttachments(Long transactionId);

    TransactionAttachment getAttachment(Long attachmentId);

    void deleteAttachment(Long attachmentId);
}
