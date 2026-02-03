package com.finmate.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@AllArgsConstructor
public class UserProfileResponse {
    private UUID userId;
    private String email;
    private String fullName;
    private Boolean hasAvatar;
    private LocalDateTime updatedAt;
}
