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

    @Column(name = "amount_limit", nullable = false, precision = 19, scale = 2)
    private BigDecimal amountLimit;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private BudgetPeriod period;
}
