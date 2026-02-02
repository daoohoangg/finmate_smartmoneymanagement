package com.finmate.dto.request;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class WalletRequest {
    private String name;
    private BigDecimal balance;
    private String currency;
    private String icon;
}
