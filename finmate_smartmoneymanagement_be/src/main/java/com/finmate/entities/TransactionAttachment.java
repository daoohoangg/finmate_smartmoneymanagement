package com.finmate.entities;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "transaction_attachments")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
public class TransactionAttachment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transaction_id", nullable = false)
    private Transaction transaction;

    @Column(nullable = false)
    private String fileName;

    @Column(nullable = false)
    private String contentType;

    @Column(nullable = false)
    private Long fileSize;

    @Lob
    @Column(nullable = false)
    private byte[] data;
}
