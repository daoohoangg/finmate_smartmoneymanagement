package com.finmate;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
public class SystemE2ETest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void contextLoads() {
        // System Test: Context successfully boots with all DB definitions and Security Chains.
    }

    @Test
    void securitySystem_UnauthenticatedRequests_ShouldBeDenied() throws Exception {
        // System Test: Verifies that the global security filter chain protects business endpoints
        mockMvc.perform(get("/api/transactions")
                .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized()); // Expect 401 Unauthorized
    }
    
    @Test
    void authSystem_InvalidGoogleToken_ShouldBeRejected() throws Exception {
        // System Test: Verifies that the OAuth loopback handles invalid tokens securely
        String invalidPayload = "{\"idToken\":\"invalid_token\"}";
        
        mockMvc.perform(post("/api/auth/google")
                .contentType(MediaType.APPLICATION_JSON)
                .content(invalidPayload))
                .andExpect(status().is4xxClientError()); 
    }
}
