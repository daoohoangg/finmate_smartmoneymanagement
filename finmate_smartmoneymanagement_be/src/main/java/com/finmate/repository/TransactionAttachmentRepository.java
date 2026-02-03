package com.finmate.repository;

import com.finmate.entities.TransactionAttachment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TransactionAttachmentRepository extends JpaRepository<TransactionAttachment, Long> {
    List<TransactionAttachment> findByTransactionId(Long transactionId);
}
