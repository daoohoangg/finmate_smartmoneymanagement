package com.finmate.service;

import com.finmate.dto.request.AccountRequest;
import com.finmate.dto.response.AccountResponse;

import java.util.List;

public interface AccountService {
    AccountResponse createAccount(AccountRequest request);
    AccountResponse getAccountById(Long id);
    List<AccountResponse> getAllAccounts();
    AccountResponse updateAccount(Long id, AccountRequest request);
    void deleteAccount(Long id);
}