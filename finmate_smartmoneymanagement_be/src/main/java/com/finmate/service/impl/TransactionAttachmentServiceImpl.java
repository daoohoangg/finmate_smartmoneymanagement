package com.finmate.service.impl;

import com.finmate.dto.response.TransactionAttachmentResponse;
import com.finmate.entities.Transaction;
import com.finmate.entities.TransactionAttachment;
import com.finmate.repository.TransactionAttachmentRepository;
import com.finmate.repository.TransactionRepository;
import com.finmate.service.TransactionAttachmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TransactionAttachmentServiceImpl implements TransactionAttachmentService {

    private final TransactionAttachmentRepository transactionAttachmentRepository;
    private final TransactionRepository transactionRepository;

    @Override
    public TransactionAttachmentResponse addAttachment(Long transactionId, MultipartFile file) throws IOException {
        Transaction transaction = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new RuntimeException("Transaction not found"));

        TransactionAttachment attachment = new TransactionAttachment();
        attachment.setTransaction(transaction);
        attachment.setFileName(file.getOriginalFilename());
        attachment.setContentType(file.getContentType() != null ? file.getContentType() : "application/octet-stream");
        attachment.setFileSize(file.getSize());
        attachment.setData(file.getBytes());

        TransactionAttachment saved = transactionAttachmentRepository.save(attachment);
        return mapToResponse(saved);
    }

    @Override
    public List<TransactionAttachmentResponse> getAttachments(Long transactionId) {
        return transactionAttachmentRepository.findByTransactionId(transactionId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public TransactionAttachment getAttachment(Long attachmentId) {
        return transactionAttachmentRepository.findById(attachmentId)
                .orElseThrow(() -> new RuntimeException("Attachment not found"));
    }

    @Override
    public void deleteAttachment(Long attachmentId) {
        if (!transactionAttachmentRepository.existsById(attachmentId)) {
            throw new RuntimeException("Attachment not found");
        }
        transactionAttachmentRepository.deleteById(attachmentId);
    }

    private TransactionAttachmentResponse mapToResponse(TransactionAttachment attachment) {
        return new TransactionAttachmentResponse(
                attachment.getId(),
                attachment.getTransaction().getId(),
                attachment.getFileName(),
                attachment.getContentType(),
                attachment.getFileSize());
    }
}
