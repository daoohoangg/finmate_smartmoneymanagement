package com.finmate.entities;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_settings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
public class UserSettings {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "dark_mode", nullable = false)
    private Boolean darkMode;

    @Column(nullable = false, length = 10)
    private String language;

    @Column(name = "default_currency", nullable = false, length = 10)
    private String defaultCurrency;

    @Column(name = "notification_enabled", nullable = false)
    private Boolean notificationEnabled;

    @Column(name = "budget_alert_threshold", nullable = false)
    private Integer budgetAlertThreshold;

    @Column(name = "rounding_scale", nullable = false)
    private Integer roundingScale;

    @Column(name = "rounding_mode", nullable = false, length = 20)
    private String roundingMode;

    @Column(name = "necessary_allocation_percent")
    private Integer necessaryAllocationPercent;

    @Column(name = "accumulation_allocation_percent")
    private Integer accumulationAllocationPercent;

    @Column(name = "flexibility_allocation_percent")
    private Integer flexibilityAllocationPercent;

    @PrePersist
    protected void onCreate() {
        if (darkMode == null) {
            darkMode = false;
        }
        if (language == null) {
            language = "EN";
        }
        if (defaultCurrency == null) {
            defaultCurrency = "VND";
        }
        if (notificationEnabled == null) {
            notificationEnabled = true;
        }
        if (budgetAlertThreshold == null) {
            budgetAlertThreshold = 80;
        }
        if (roundingScale == null) {
            roundingScale = 2;
        }
        if (roundingMode == null) {
            roundingMode = "HALF_UP";
        }
        if (necessaryAllocationPercent == null) {
            necessaryAllocationPercent = 60;
        }
        if (accumulationAllocationPercent == null) {
            accumulationAllocationPercent = 20;
        }
        if (flexibilityAllocationPercent == null) {
            flexibilityAllocationPercent = 20;
        }
    }
}
