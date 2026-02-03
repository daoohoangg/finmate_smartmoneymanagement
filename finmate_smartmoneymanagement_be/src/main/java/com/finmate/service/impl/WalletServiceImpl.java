package com.finmate.service.impl;

import com.finmate.dto.request.WalletRequest;
import com.finmate.dto.response.WalletResponse;
import com.finmate.entities.User;
import com.finmate.entities.Wallet;
import com.finmate.repository.UserRepository;
import com.finmate.repository.WalletRepository;
import com.finmate.service.WalletService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class WalletServiceImpl implements WalletService {

    private final WalletRepository walletRepository;
    private final UserRepository userRepository;

    @Override
    public WalletResponse createWallet(UUID userId, WalletRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Wallet wallet = new Wallet();
        wallet.setUser(user);
        wallet.setName(request.getName());
        wallet.setBalance(request.getBalance() != null ? request.getBalance() : BigDecimal.ZERO);
        wallet.setCurrency(request.getCurrency());
        wallet.setIcon(request.getIcon());
        wallet.setIsDeleted(false);

        Wallet savedWallet = walletRepository.save(wallet);
        return mapToResponse(savedWallet);
    }

    @Override
    public WalletResponse getWalletById(Long id) {
        Wallet wallet = walletRepository.findByIdAndIsDeletedFalse(id)
                .orElseThrow(() -> new RuntimeException("Wallet not found"));
        return mapToResponse(wallet);
    }

    @Override
    public List<WalletResponse> getAllWalletsByUser(UUID userId) {
        return walletRepository.findByUserIdAndIsDeletedFalse(userId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    public WalletResponse updateWallet(Long id, WalletRequest request) {
        Wallet wallet = walletRepository.findByIdAndIsDeletedFalse(id)
                .orElseThrow(() -> new RuntimeException("Wallet not found"));

        wallet.setName(request.getName());
        wallet.setBalance(request.getBalance());
        wallet.setCurrency(request.getCurrency());
        wallet.setIcon(request.getIcon());

        Wallet updatedWallet = walletRepository.save(wallet);
        return mapToResponse(updatedWallet);
    }

    @Override
    public void deleteWallet(Long id) {
        Wallet wallet = walletRepository.findByIdAndIsDeletedFalse(id)
                .orElseThrow(() -> new RuntimeException("Wallet not found"));
        wallet.setIsDeleted(true);
        wallet.setDeletedAt(java.time.LocalDateTime.now());
        walletRepository.save(wallet);
    }

    private WalletResponse mapToResponse(Wallet wallet) {
        return new WalletResponse(
                wallet.getId(),
                wallet.getName(),
                wallet.getBalance(),
                wallet.getCurrency(),
                wallet.getIcon());
    }
}
