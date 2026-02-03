package com.finmate.entities;

import com.finmate.enums.InvestmentFrequency;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Entity
@Table(name = "investment_plans")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
public class InvestmentPlan {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "periodic_amount", nullable = false, precision = 19, scale = 2)
    private BigDecimal periodicAmount;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private InvestmentFrequency frequency;

    @Column(name = "next_execution_date")
    private LocalDate nextExecutionDate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "source_savings_goal_id")
    private SavingsGoal sourceSavingsGoal;

    @Column(name = "total_invested", nullable = false, precision = 19, scale = 2)
    private BigDecimal totalInvested;

    @Column(name = "current_value", precision = 19, scale = 2)
    private BigDecimal currentValue;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDate createdAt;

    @OneToMany(mappedBy = "investmentPlan", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Transaction> transactions;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDate.now();
        if (totalInvested == null) {
            totalInvested = BigDecimal.ZERO;
        }
        if (isActive == null) {
            isActive = true;
        }
    }
}
