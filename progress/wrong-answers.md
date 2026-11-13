# Sổ lỗi — nguồn học giá trị nhất của bạn

Quy tắc: **mỗi câu sai = 1 dòng**. Không ghi "sai vì ngu" — ghi **quy tắc đúng** để lần sau áp dụng.

## Mẫu

```
| Ngày | Domain | Câu hỏi tóm tắt | Tôi chọn | Đáp án đúng | Vì sao sai (quy tắc) | Trạng thái |
```

## Bảng

| Ngày | Domain | Câu hỏi tóm tắt | Tôi chọn | Đáp án đúng | Vì sao sai (quy tắc) | Trạng thái |
|---|---|---|---|---|---|---|
| | | | | | | open |

## Nhãn domain (dùng đúng chính tả để đếm)

`identity` · `storage` · `compute` · `networking` · `monitor` · `exam-tactic`

## Cách dùng

1. **Trong lúc review mock:** điền ngay, đừng đợi "lúc khác".
2. **Phân loại sai:**
   - `knowledge` — chưa biết → đọc note + tạo flashcard.
   - `confusion` — nhầm 2 dịch vụ → viết bảng so sánh 2 dòng.
   - `careless` — đọc sai đề → ghi lại từ khoá bị bỏ qua ("EXCEPT", "least effort", "minimize cost").
   - `guess` — đoán đúng nhưng không chắc → **vẫn ghi**, vì đây là lỗ hổng.
3. **Mỗi tối:** đọc 5 dòng cũ nhất còn `open`. Nhớ rồi → đổi thành `resolved`.
4. **Ngày 14:** chỉ đọc các dòng `open`. Nếu còn > 20 dòng open → bạn chưa review đủ, không phải học thêm.

## 10 lỗi "careless" phổ biến (đọc trước khi thi)

1. Bỏ qua chữ **EXCEPT / NOT**.
2. Bỏ qua **"least administrative effort"** → chọn giải pháp thủ công.
3. Bỏ qua **"minimize cost"** → chọn GRS/Premium.
4. Chọn RBAC khi đề hỏi **"ngăn tạo resource ở region X"** → phải là Policy.
5. Chọn Policy khi đề hỏi **"ngăn xoá"** → phải là Lock.
6. Chọn service endpoint khi đề cần **private IP** → phải private endpoint.
7. Chọn GRS khi đề cần **đọc secondary** → phải RA-GRS.
8. Chọn Archive khi đề cần **đọc trong vài giờ** → Cool/Cold.
9. Chọn availability set khi đề cần **99,99%** → zone.
10. Chọn "Azure Firewall" cho câu chỉ cần lọc port/IP trong VNet → NSG.
