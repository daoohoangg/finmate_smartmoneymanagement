package com.finmate.repository;

import com.finmate.entities.Wallet;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface WalletRepository extends JpaRepository<Wallet, Long> {
    List<Wallet> findByUserId(UUID userId);

    List<Wallet> findByUserIdAndIsDeletedFalse(UUID userId);

    Optional<Wallet> findByIdAndIsDeletedFalse(Long id);
}
