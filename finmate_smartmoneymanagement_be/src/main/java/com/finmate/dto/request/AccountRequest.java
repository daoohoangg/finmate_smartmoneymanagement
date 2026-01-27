package com.finmate.dto.request;

import lombok.Data;

@Data
public class AccountRequest {
    private String accountNo;
    private String accountName;
    private Double balance;
}