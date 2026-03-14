package com.finmate.entities;

import com.finmate.enums.BudgetPeriod;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "budgets")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
public class Budget {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    @Column(name = "name", length = 150)
    private String name;

    @Column(name = "amount_limit", nullable = false, precision = 19, scale = 2)
    private BigDecimal amountLimit;

    @Column(
            name = "saved_amount",
            nullable = false,
            precision = 19,
            scale = 2,
            columnDefinition = "DECIMAL(19,2) NOT NULL DEFAULT 0"
    )
    private BigDecimal savedAmount = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private BudgetPeriod period;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private com.finmate.enums.BudgetStatus status = com.finmate.enums.BudgetStatus.PROCESSING;
}
