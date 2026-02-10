package com.finmate.dto.request;

import lombok.Data;

@Data
public class GoogleLoginRequest {
    private String idToken;
    private String accessToken;
}
