package com.finmate.service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;


//service của cloudary
public interface FileUploadService {
    String uploadFile(MultipartFile file) throws IOException;
}