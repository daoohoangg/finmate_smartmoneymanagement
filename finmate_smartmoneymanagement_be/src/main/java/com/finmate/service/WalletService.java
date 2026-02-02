package com.finmate.service;

import com.finmate.dto.request.WalletRequest;
import com.finmate.dto.response.WalletResponse;

import java.util.List;
import java.util.UUID;

public interface WalletService {
    WalletResponse createWallet(UUID userId, WalletRequest request);

    WalletResponse getWalletById(Long id);

    List<WalletResponse> getAllWalletsByUser(UUID userId);

    WalletResponse updateWallet(Long id, WalletRequest request);

    void deleteWallet(Long id);
}
