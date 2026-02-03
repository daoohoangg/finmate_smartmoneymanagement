package com.finmate.util;

import com.finmate.security.UserPrincipal;

import java.util.UUID;

public final class UserIdResolver {
    private UserIdResolver() {
    }

    public static UUID resolve(UUID headerUserId, UserPrincipal principal) {
        if (headerUserId != null && principal != null && !headerUserId.equals(principal.getUserId())) {
            throw new RuntimeException("User ID does not match token");
        }
        if (headerUserId != null) {
            return headerUserId;
        }
        if (principal != null) {
            return principal.getUserId();
        }
        throw new RuntimeException("User ID is required");
    }
}
