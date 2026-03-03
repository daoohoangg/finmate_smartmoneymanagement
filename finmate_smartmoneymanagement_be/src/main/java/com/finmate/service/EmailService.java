package com.finmate.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public void sendOtpEmail(String toEmail, String otp) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("FinMate — Mã xác thực đặt lại mật khẩu");

            String html = """
                    <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #f9fafb; border-radius: 12px;">
                      <h2 style="color: #1e3a5f; margin-bottom: 8px;">FinMate</h2>
                      <p style="color: #374151; font-size: 15px;">Bạn đã yêu cầu đặt lại mật khẩu. Nhập mã OTP bên dưới để tiếp tục:</p>
                      <div style="text-align: center; margin: 32px 0;">
                        <span style="font-size: 40px; font-weight: bold; letter-spacing: 10px; color: #2563eb; background: #eff6ff; padding: 16px 32px; border-radius: 10px; display: inline-block;">
                          %s
                        </span>
                      </div>
                      <p style="color: #6b7280; font-size: 13px;">Mã có hiệu lực trong <strong>10 phút</strong>. Nếu bạn không yêu cầu, hãy bỏ qua email này.</p>
                    </div>
                    """
                    .formatted(otp);

            helper.setText(html, true);
            mailSender.send(message);

        } catch (MessagingException e) {
            throw new RuntimeException("Failed to send OTP email: " + e.getMessage());
        }
    }
}
