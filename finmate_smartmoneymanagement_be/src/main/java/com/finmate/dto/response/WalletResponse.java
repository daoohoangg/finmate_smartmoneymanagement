package com.finmate.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;

@Data
@AllArgsConstructor
public class WalletResponse {
    private Long id;
    private String name;
    private BigDecimal balance;
    private String currency;
    private String icon;
}
