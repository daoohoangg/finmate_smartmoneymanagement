package com.finmate.repository;

import com.finmate.entities.InvestmentPlan;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface InvestmentPlanRepository extends JpaRepository<InvestmentPlan, Long> {
    List<InvestmentPlan> findByUserId(UUID userId);

    List<InvestmentPlan> findByUserIdAndIsActive(UUID userId, Boolean isActive);

    List<InvestmentPlan> findByIsActiveAndNextExecutionDateLessThanEqual(Boolean isActive, java.time.LocalDate date);
}
