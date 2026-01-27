package com.finmate.service.impl;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.finmate.service.FileUploadService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.Map;
import java.util.UUID;
@Service
@RequiredArgsConstructor
public class FileUploadServiceImpl implements FileUploadService {

    private final Cloudinary cloudinary;
    /**
     * Uploads file to Cloudinary and returns secure URL
     */
    @Override
    public String uploadFile(MultipartFile file) throws IOException {

        String fileName = UUID.randomUUID().toString();

        Map params = ObjectUtils.asMap(
                "public_id", fileName,
                "folder", "finmate_uploads"
        );

        Map uploadResult = cloudinary.uploader().upload(file.getBytes(), params);

        return uploadResult.get("secure_url").toString();
    }
}