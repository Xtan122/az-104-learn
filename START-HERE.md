# START HERE — đọc repo này theo thứ tự nào

> Mục đích: hiểu **cách repo vận hành** trước khi học kiến thức. Đọc file này 1 lần (10 phút), sau đó mỗi tối chỉ cần mở `PLAN.md`.

## 1. Mental model: repo có 5 lớp

```
(1) ĐỊNH HƯỚNG   README.md · docs/00 · docs/01
        ↓  biết đề thi hỏi gì, mình đang ở đâu
(2) KIẾN THỨC    docs/02 … docs/06  (notes nén theo domain)
        ↓  đọc trước khi làm
(3) THỰC HÀNH    labs/lab-01 … lab-10
        ↓  gõ CLI, cố tình phá, sửa
(4) PHẢN HỒI     quizzes/ · progress/wrong-answers.md · tracker.md
        ↓  biết mình sai gì, sửa vào note/cheatsheet
(5) TỰ ĐỘNG HOÁ  scripts/ · iac/  (setup, dọn dẹp, ARM/Bicep)
```

Đừng đọc từ trên xuống như một cuốn sách. **Vòng lặp học là (2) → (3) → (4)**, còn (1) và (5) chỉ dùng 1 lần hoặc khi cần.

## 2. Thứ tự đọc chính xác cho 60 phút đầu (làm hôm nay)

| # | File | Thời lượng | Đọc để làm gì | Ghi chú |
|---|---|---|---|---|
| 1 | `README.md` | 5' | Biết trọng số đề, 3 cổng quyết định, nguyên tắc | Chỉ đọc phần đầu + bảng tiến độ |
| 2 | `docs/00-exam-blueprint.md` | 15' | Biết đề hỏi dạng gì, mẹo "least effort/cost", cái gì **không** thi | Bỏ qua mục 8 (nguồn) lúc này |
| 3 | `docs/01-aws-to-azure.md` | 20' | Chuyển kiến thức SAA sang Azure, biết 10 phản xạ sẽ làm bạn sai | **Quan trọng nhất hôm nay** |
| 4 | `PLAN.md` | 10' | Xem Ngày 0 → Ngày 2, biết mỗi ngày cần làm gì | Chưa cần đọc hết 14 ngày |
| 5 | `scripts/bootstrap.sh` | 5' | Chạy setup: login, bicep, RG sandbox, budget | Chạy `bash scripts/bootstrap.sh` |

Sau 60 phút này bạn phải trả lời được:
- Networking chiếm bao nhiêu %? Vì sao không học 5 ngày?
- 4 dịch vụ nào **không** có trong đề?
- Peering khác Transit Gateway ở điểm nào?
- Ngày 1 bạn phải làm gì, quiz đạt bao nhiêu %?

## 3. Bản đồ toàn bộ file

| File / thư mục | Là gì | Đọc khi nào | Có bỏ qua được không? |
|---|---|---|---|
| `README.md` | Dashboard, trọng số, cổng quyết định | Hôm nay + mỗi tuần | Không |
| `docs/00-exam-blueprint.md` | Chiến lược thi, dạng câu, 25 điều phải thuộc | Hôm nay | Không |
| `docs/01-aws-to-azure.md` | Mapping AWS → Azure + bẫy | Hôm nay | Không (bạn có SAA) |
| `docs/02-identity-governance.md` | Notes Identity & Governance | Ngày 1–2 | Không |
| `docs/05-networking.md` | Notes Networking (sâu nhất) | Ngày 3–5 | Không |
| `docs/03-storage.md` | Notes Storage | Ngày 6–7 | Không |
| `docs/04-compute.md` | Notes Compute + ARM/Bicep + App Service | Ngày 8–9 | Không |
| `docs/06-monitor-backup.md` | Notes Monitor & Backup | Ngày 10 | Không |
| `docs/07-networking-extras.md` | Firewall/vWAN/APIM/ExpressRoute | Sau khi thi, hoặc 20' overview Ngày 5 | **Có** (ngoài đề) |
| `docs/cheatsheets/01…04` | 4 tờ A4 | Viết lại Ngày 2/7, đọc Ngày 14 | Không (nhưng chỉ dùng cuối) |
| `labs/README.md` | Danh mục lab, chi phí, quy tắc cleanup | Trước lab đầu tiên | Không |
| `labs/lab-01…10` | Lab theo ngày | Theo `PLAN.md` | Lab 6, 9 có thể bỏ nếu tụt giờ |
| `quizzes/q1…q5` | 10–12 câu/domain | Cuối mỗi ngày tương ứng | Không |
| `quizzes/flashcards.csv` | 102 thẻ Anki | Từ Ngày 12 | Không (ôn trước thi) |
| `progress/tracker.md` | Ghi điểm quiz/mock | Mỗi tối | Không |
| `progress/wrong-answers.md` | Sổ lỗi | Mỗi tối | **Không — đây là tài liệu giá trị nhất** |
| `scripts/bootstrap.sh` | Setup 1 lần | Hôm nay | Không |
| `scripts/cleanup.sh` | Xoá RG lab | Sau mỗi lab | Không (tránh cháy credit) |
| `scripts/check-cost.sh` | Xem resource đang chạy | Cuối ngày | Nên dùng |
| `scripts/progress.sh` | % hoàn thành, ngày còn lại | Mỗi tối | Không |
| `iac/arm`, `iac/bicep` | Template mẫu + bài tập đọc/sửa | Ngày 8 | **Có** nếu bỏ compute lab |
| `AZ-104-14-ngay-checklist.md` | Checklist gốc của bạn | Chỉ khi muốn đối chiếu | Có |
| `info.md`, `link.md` | Input gốc | 1 lần | Có |

## 4. Số thứ tự file KHÔNG phải thứ tự học

Đây là chỗ dễ hiểu nhầm nhất:

```
Số file:    02-identity → 03-storage → 04-compute → 05-networking → 06-monitor
Thứ tự học: 02-identity → 05-networking → 03-storage → 04-compute → 06-monitor
```

Lý do: mình ưu tiên networking sớm (theo yêu cầu của bạn) và để compute sát cuối vì nó nặng nhất, cần đầu óc tỉnh. **`PLAN.md` là nguồn sự thật duy nhất** về thứ tự — cứ theo đó, đừng theo số file.

## 5. Cách đọc một note trong `docs/` (20 phút/domain)

Đừng đọc như tiểu thuyết. Đọc 3 lớp:

1. **Lớp khái niệm (5')**: đọc hết 1 lượt, không highlight, không ghi chép. Mục tiêu: biết file nói về cái gì.
2. **Lớp bảng so sánh (10')**: tìm các bảng (RBAC role, redundancy, NSG default rule, LB vs AppGW…). **Tự che cột phải và trả lời miệng**, sai thì mở ra. Đây là lúc trí nhớ hình thành.
3. **Lớp bẫy (5')**: đọc mục "Bẫy" cuối mỗi note + làm mục "Tự kiểm tra". Câu nào không trả lời được → ghi 1 dòng vào sổ lỗi, đừng đọc lại cả file.

**Không** học thuộc lòng số liệu ít gặp (giá tiền, giới hạn quota). Đề hỏi **chọn dịch vụ/feature**, không hỏi con số.

## 6. Cách dùng lab đúng (không chỉ copy-paste)

Với mỗi lab, làm theo thứ tự:

1. **Đọc mục "Mục tiêu" + "Câu hỏi exam-style" trước** khi gõ lệnh — biết mình đang đi đâu.
2. **Gõ lệnh bằng tay** (không copy cả khối) ở lần đầu. Copy chỉ khi lệnh quá dài.
3. **Làm phần "Kiểm chứng"** — đây là 60% giá trị lab.
4. **Làm phần "Thí nghiệm phá"** — cố tình tạo lỗi rồi sửa. Đề thi toàn câu "tại sao fail".
5. **Cleanup ngay**: `bash scripts/cleanup.sh`.

Nếu lệnh fail: đọc lỗi, sửa, ghi vào sổ lỗi. **Không** bỏ qua — kỹ năng troubleshoot chính là thứ đề kiểm tra.

## 7. Cách dùng quiz + sổ lỗi

- Làm **trước**, xem đáp án **sau**, bấm giờ 90 giây/câu.
- Câu sai → ghi vào `progress/wrong-answers.md` theo mẫu: *câu hỏi / tôi chọn / đáp án đúng / quy tắc đúng*.
- Phân loại lỗi: `knowledge` (chưa biết) · `confusion` (nhầm 2 dịch vụ) · `careless` (đọc sai đề) · `guess` (đoán đúng nhưng không chắc).
- Mỗi tối đọc 5 dòng cũ nhất còn `open`. Nhớ rồi → `resolved`.
- **Ngày 14 chỉ đọc các dòng `open`**, không học thêm kiến thức mới.

## 8. Đừng đọc gì lúc này

| Thứ | Vì sao |
|---|---|
| Toàn bộ `docs/` một lần | 1.200+ dòng, sẽ quên 70%; học theo ngày + lab mới nhớ |
| `docs/07-networking-extras.md` | Ngoài đề; chỉ đọc 20' overview Ngày 5 hoặc sau thi |
| `iac/` | Chỉ cần Ngày 8; đọc trước sẽ không hiểu vì chưa biết VM/disk |
| `AZ-104-14-ngay-checklist.md` | Bản gốc đã được thay bằng `PLAN.md`; giữ để đối chiếu |
| 4 cheat sheet | Để dành Ngày 2/7/14; đọc sớm chỉ tạo cảm giác "đã biết" |

## 9. Checklist 60 phút đầu

- [ ] Đọc `README.md` (phần đầu + bảng tiến độ)
- [ ] Đọc `docs/00-exam-blueprint.md` mục 1–6
- [ ] Đọc `docs/01-aws-to-azure.md` cả file, làm 8 câu tự kiểm tra
- [ ] Đọc `PLAN.md` Ngày 0 → Ngày 2
- [ ] Chạy `bash scripts/bootstrap.sh`
- [ ] Tạo Azure free account + bật spending limit
- [ ] Đặt lịch thi 28/11
- [ ] Ghi 3 domain yếu nhất dự kiến vào `progress/tracker.md`

Xong 9 bước này = bạn hiểu repo và sẵn sàng cho Ngày 1.
