package com.finmate.service.impl;

import com.finmate.dto.request.TransactionImportMappingRequest;
import com.finmate.dto.request.TransactionRequest;
import com.finmate.dto.response.TransactionImportPreviewResponse;
import com.finmate.dto.response.TransactionImportPreviewRow;
import com.finmate.dto.response.TransactionImportResultResponse;
import com.finmate.entities.Category;
import com.finmate.enums.CategoryType;
import com.finmate.enums.TransactionType;
import com.finmate.repository.CategoryRepository;
import com.finmate.repository.WalletRepository;
import com.finmate.service.CategoryRuleService;
import com.finmate.service.TransactionImportService;
import com.finmate.service.TransactionService;
import lombok.RequiredArgsConstructor;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;
import org.apache.poi.ss.usermodel.*;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStreamReader;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TransactionImportServiceImpl implements TransactionImportService {

    private static final int PREVIEW_LIMIT = 20;

    private final TransactionService transactionService;
    private final CategoryRepository categoryRepository;
    private final WalletRepository walletRepository;
    private final CategoryRuleService categoryRuleService;

    @Override
    public TransactionImportPreviewResponse preview(UUID userId, MultipartFile file,
            TransactionImportMappingRequest mapping) throws IOException {
        List<Map<String, String>> rows = parseFile(file);
        List<TransactionImportPreviewRow> previewRows = rows.stream()
                .limit(PREVIEW_LIMIT)
                .map(row -> mapRow(userId, row, mapping))
                .collect(Collectors.toList());
        return new TransactionImportPreviewResponse(rows.size(), previewRows);
    }

    @Override
    public TransactionImportResultResponse importTransactions(UUID userId, MultipartFile file,
            TransactionImportMappingRequest mapping) throws IOException {
        List<Map<String, String>> rows = parseFile(file);
        List<String> errors = new ArrayList<>();
        int imported = 0;

        if (mapping.getWalletId() == null) {
            throw new RuntimeException("Wallet is required for import");
        }
        walletRepository.findByIdAndIsDeletedFalse(mapping.getWalletId())
                .filter(wallet -> wallet.getUser().getId().equals(userId))
                .orElseThrow(() -> new RuntimeException("Wallet not found"));

        for (int i = 0; i < rows.size(); i++) {
            Map<String, String> row = rows.get(i);
            try {
                TransactionImportPreviewRow preview = mapRow(userId, row, mapping);
                if (preview.getAmount() == null || preview.getTransactionDate() == null || preview.getType() == null) {
                    errors.add("Row " + (i + 1) + ": missing required fields");
                    continue;
                }

                TransactionRequest request = new TransactionRequest();
                request.setWalletId(mapping.getWalletId());
                request.setCategoryId(preview.getCategoryId());
                request.setType(preview.getType());
                request.setAmount(preview.getAmount());
                request.setNote(preview.getNote());
                request.setTransactionDate(preview.getTransactionDate());

                transactionService.createTransaction(userId, request);
                imported++;
            } catch (Exception ex) {
                errors.add("Row " + (i + 1) + ": " + ex.getMessage());
            }
        }

        return new TransactionImportResultResponse(rows.size(), imported, rows.size() - imported, errors);
    }

    private TransactionImportPreviewRow mapRow(UUID userId, Map<String, String> row,
            TransactionImportMappingRequest mapping) {
        String dateRaw = getValue(row, mapping.getDateColumn());
        String amountRaw = getValue(row, mapping.getAmountColumn());
        String noteRaw = getValue(row, mapping.getNoteColumn());
        String merchantRaw = getValue(row, mapping.getMerchantColumn());
        String categoryRaw = getValue(row, mapping.getCategoryColumn());
        String typeRaw = getValue(row, mapping.getTypeColumn());

        LocalDateTime date = parseDate(dateRaw, mapping.getDateFormat());
        BigDecimal amount = parseAmount(amountRaw);
        TransactionType type = resolveType(mapping, typeRaw, amount);

        if (amount != null && amount.signum() < 0 && Boolean.TRUE.equals(mapping.getAmountNegativeIsExpense())) {
            amount = amount.abs();
        }

        String note = buildNote(merchantRaw, noteRaw);

        Category category = resolveCategory(userId, type, categoryRaw, note);

        return new TransactionImportPreviewRow(
                date,
                amount != null ? amount.abs() : null,
                type,
                note,
                category != null ? category.getId() : null,
                category != null ? category.getName() : null,
                categoryRaw,
                typeRaw);
    }

    private String buildNote(String merchant, String note) {
        if (merchant == null || merchant.isBlank()) {
            return note;
        }
        if (note == null || note.isBlank()) {
            return merchant;
        }
        return merchant + " - " + note;
    }

    private Category resolveCategory(UUID userId, TransactionType type, String categoryRaw, String note) {
        if (categoryRaw != null && !categoryRaw.isBlank()) {
            List<Category> userCategories = categoryRepository.findByUserIdAndNameIgnoreCase(userId, categoryRaw.trim());
            Category matchedUserCategory = pickPreferredCategory(userCategories, type);
            if (matchedUserCategory != null) {
                return matchedUserCategory;
            }
            List<Category> systemCategories = categoryRepository.findByUserIdIsNullAndNameIgnoreCase(categoryRaw.trim());
            Category matchedSystemCategory = pickPreferredCategory(systemCategories, type);
            if (matchedSystemCategory != null) {
                return matchedSystemCategory;
            }
        }
        Category suggested = categoryRuleService.suggestCategory(userId, note);
        return pickPreferredCategory(suggested != null ? List.of(suggested) : Collections.emptyList(), type);
    }

    private Category pickPreferredCategory(List<Category> categories, TransactionType type) {
        if (categories == null || categories.isEmpty()) {
            return null;
        }
        if (type == TransactionType.EXPENSE) {
            for (Category category : categories) {
                if (category == null) {
                    continue;
                }
                if (category.getType() == CategoryType.EXPENSE
                        && category.getParent() != null
                        && !categoryRepository.existsByParentId(category.getId())) {
                    return category;
                }
            }
            for (Category category : categories) {
                if (category != null && category.getType() == CategoryType.EXPENSE) {
                    return category;
                }
            }
            return null;
        }
        if (type == TransactionType.INCOME) {
            for (Category category : categories) {
                if (category != null && category.getType() == CategoryType.INCOME) {
                    return category;
                }
            }
            return null;
        }
        return categories.stream().filter(c -> c != null).findFirst().orElse(null);
    }

    private TransactionType resolveType(TransactionImportMappingRequest mapping, String typeRaw, BigDecimal amount) {
        if (typeRaw != null && !typeRaw.isBlank()) {
            String normalized = typeRaw.trim().toLowerCase();
            if (normalized.contains("income") || normalized.contains("credit") || normalized.contains("thu")) {
                return TransactionType.INCOME;
            }
            if (normalized.contains("expense") || normalized.contains("debit") || normalized.contains("chi")) {
                return TransactionType.EXPENSE;
            }
            if (normalized.contains("transfer")) {
                return TransactionType.TRANSFER;
            }
        }
        if (mapping.getDefaultType() != null) {
            return mapping.getDefaultType();
        }
        if (amount != null && amount.signum() < 0 && Boolean.TRUE.equals(mapping.getAmountNegativeIsExpense())) {
            return TransactionType.EXPENSE;
        }
        return TransactionType.INCOME;
    }

    private LocalDateTime parseDate(String raw, String format) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String trimmed = raw.trim();
        List<DateTimeFormatter> formatters = new ArrayList<>();
        if (format != null && !format.isBlank()) {
            formatters.add(DateTimeFormatter.ofPattern(format));
        }
        formatters.add(DateTimeFormatter.ISO_DATE_TIME);
        formatters.add(DateTimeFormatter.ISO_DATE);
        formatters.add(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
        formatters.add(DateTimeFormatter.ofPattern("MM/dd/yyyy"));
        formatters.add(DateTimeFormatter.ofPattern("dd-MM-yyyy"));
        formatters.add(DateTimeFormatter.ofPattern("yyyy-MM-dd"));

        for (DateTimeFormatter formatter : formatters) {
            try {
                return LocalDateTime.parse(trimmed, formatter);
            } catch (Exception ignored) {
                try {
                    LocalDate date = LocalDate.parse(trimmed, formatter);
                    return date.atStartOfDay();
                } catch (Exception ignoredAgain) {
                    // try next
                }
            }
        }
        return null;
    }

    private BigDecimal parseAmount(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String cleaned = raw.trim()
                .replaceAll("[,\\s]", "")
                .replaceAll("[^0-9.\\-()]", "");
        if (cleaned.startsWith("(") && cleaned.endsWith(")")) {
            cleaned = "-" + cleaned.substring(1, cleaned.length() - 1);
        }
        try {
            return new BigDecimal(cleaned);
        } catch (Exception ex) {
            return null;
        }
    }

    private String getValue(Map<String, String> row, String key) {
        if (key == null) {
            return null;
        }
        return row.getOrDefault(key, null);
    }

    private List<Map<String, String>> parseFile(MultipartFile file) throws IOException {
        String fileName = file.getOriginalFilename() != null ? file.getOriginalFilename().toLowerCase() : "";
        if (fileName.endsWith(".csv")) {
            return parseCsv(file);
        }
        if (fileName.endsWith(".xlsx") || fileName.endsWith(".xls")) {
            return parseExcel(file);
        }
        throw new RuntimeException("Unsupported file type. Please upload CSV or Excel.");
    }

    private List<Map<String, String>> parseCsv(MultipartFile file) throws IOException {
        try (CSVParser parser = CSVParser.parse(
                new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8),
                CSVFormat.DEFAULT.builder().setHeader().setSkipHeaderRecord(true).build())) {
            List<Map<String, String>> rows = new ArrayList<>();
            for (CSVRecord record : parser) {
                Map<String, String> row = new LinkedHashMap<>();
                for (String header : parser.getHeaderNames()) {
                    row.put(header, record.get(header));
                }
                rows.add(row);
            }
            return rows;
        }
    }

    private List<Map<String, String>> parseExcel(MultipartFile file) throws IOException {
        try (Workbook workbook = WorkbookFactory.create(file.getInputStream())) {
            Sheet sheet = workbook.getSheetAt(0);
            Iterator<Row> iterator = sheet.iterator();
            if (!iterator.hasNext()) {
                return Collections.emptyList();
            }
            Row headerRow = iterator.next();
            List<String> headers = new ArrayList<>();
            for (Cell cell : headerRow) {
                headers.add(getCellValue(cell));
            }
            List<Map<String, String>> rows = new ArrayList<>();
            while (iterator.hasNext()) {
                Row row = iterator.next();
                Map<String, String> map = new LinkedHashMap<>();
                for (int i = 0; i < headers.size(); i++) {
                    Cell cell = row.getCell(i, Row.MissingCellPolicy.CREATE_NULL_AS_BLANK);
                    map.put(headers.get(i), getCellValue(cell));
                }
                rows.add(map);
            }
            return rows;
        }
    }

    private String getCellValue(Cell cell) {
        if (cell == null) {
            return null;
        }
        return switch (cell.getCellType()) {
            case STRING -> cell.getStringCellValue();
            case NUMERIC -> DateUtil.isCellDateFormatted(cell)
                    ? cell.getLocalDateTimeCellValue().toString()
                    : new BigDecimal(cell.getNumericCellValue()).toPlainString();
            case BOOLEAN -> Boolean.toString(cell.getBooleanCellValue());
            case FORMULA -> cell.getCellFormula();
            case BLANK -> null;
            default -> null;
        };
    }
}
