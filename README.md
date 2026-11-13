# AZ-104 Learning

> Mục tiêu: **pass AZ-104 (≥ 700/1000)** ngày 28/11/2026.
> Xuất phát điểm: **có AWS SAA, chưa từng học Azure**. Quỹ thời gian: **~59 giờ** (10 buổi tối × 3,5h + 4 ngày cuối tuần × 6h).

## Đọc cái này trước (3 phút)

**Sự thật về trọng số đề** (nguồn: study guide chính thức, cập nhật 05/11/2026):

| Domain | Trọng số | Kết luận cho bạn |
|---|---|---|
| Manage identities and governance | **20–25%** | Đầu tư lớn, dễ ăn điểm, lab nhanh |
| Deploy and manage compute | **20–25%** | Đầu tư lớn, nhiều câu ARM/Bicep + VM |
| Implement and manage storage | 15–20% | Trung bình, nhiều câu "chọn redundancy/SAS" |
| Implement and manage virtual networking | 15–20% | **Bạn thích → học kỹ, nhưng đừng chiếm 5 ngày** |
| Monitor and maintain resources | 10–15% | Học thuộc lòng, ít lab, dễ mất điểm |

**Cảnh báo:** checklist gốc (`AZ-104-14-ngay-checklist.md`) dành 5/14 ngày cho networking (35% thời gian) — lệch với trọng số thật. Plan trong repo này giữ networking ở mức **3 ngày + lab**, đúng ưu tiên của bạn nhưng không đánh đổi điểm Compute/Storage.

**Những thứ KHÔNG có trong skills measured** (chỉ đọc overview, đừng lab, đừng mua khoá):
`APIM`, `Virtual WAN`, `ExpressRoute`, `Azure Firewall`, `Front Door`, `AKS`, `Entra Connect`.
Chúng xuất hiện trong đề với vai trò **distractor** — bạn chỉ cần biết "khi nào dùng" để loại trừ, không cần cấu hình. Xem `docs/07-networking-extras.md`.

## Cách dùng repo này

```
README.md                  ← dashboard (bạn đang ở đây)
PLAN.md                    ← lịch 14 ngày, tick checkbox mỗi ngày
docs/                      ← lý thuyết nén, đọc trước khi lab
  00-exam-blueprint.md     ← chiến lược thi, dạng câu hỏi, bẫy
  01-aws-to-azure.md       ← bản đồ AWS SAA → Azure (đọc ngay hôm nay)
  02..06-*.md              ← notes 5 domain
  07-networking-extras.md  ← Firewall/vWAN/APIM/ER (ngoài đề, cho công việc)
  cheatsheets/             ← 4 tờ A4 để ôn ngày cuối
labs/                      ← 10 lab, có CLI copy-paste được + cleanup
quizzes/                   ← 5 bộ 10 câu + 102 flashcard (import Anki)
iac/                       ← ARM + Bicep mẫu để tập đọc/sửa
progress/                  ← tracker điểm + sổ lỗi
scripts/                   ← bootstrap, cleanup, check-cost, progress
```

File tham khảo gốc: `info.md` (yêu cầu), `AZ-104-14-ngay-checklist.md` (checklist Claude), `link.md` (study guide).

### Vòng lặp mỗi ngày (đừng phá vòng lặp)

1. **Đọc** note domain trong `docs/` (45–60 phút) — không đọc hết doc Microsoft, chỉ tra khi note ghi "tra cứu".
2. **Lab** theo `labs/` (60–90 phút) — tay phải gõ CLI, không chỉ click portal.
3. **Quiz** trong `quizzes/` (20 phút) — làm trước, xem đáp án sau, **mỗi câu sai ghi 1 dòng vào `progress/wrong-answers.md`**.
4. **Recap 5 phút**: đọc lại sổ lỗi của hôm trước.

### 3 lệnh mở màn

```bash
bash scripts/bootstrap.sh     # kiểm tra az CLI, login, set default region, tạo budget alert
cat PLAN.md                   # xem hôm nay làm gì
bash scripts/progress.sh      # xem % hoàn thành
```

## Bảng tiến độ

| Ngày | Nội dung | Giờ | Trạng thái |
|---|---|---|---|
| 0 · 13/11 | Setup tài khoản + đặt lịch thi | 1,5h | [ ] |
| 1 · 14/11 | Baseline test + Entra ID | 6h | [ ] |
| 2 · 15/11 | RBAC + Policy + Lock + Cost | 6h | [ ] |
| 3 · 16/11 | Networking 1: VNet, NSG, Bastion | 3,5h | [ ] |
| 4 · 17/11 | Networking 2: Peering, UDR, hub-spoke | 3,5h | [ ] |
| 5 · 18/11 | Networking 3: DNS, Private Endpoint, LB/WAF | 3,5h | [ ] |
| 6 · 19/11 | Storage 1: account, redundancy, tier, SAS | 3,5h | [ ] |
| 7 · 20/11 | Storage 2: Files, firewall, lifecycle | 3,5h | [ ] |
| 8 · 21/11 | Compute 1: VM, disk, VMSS, ARM/Bicep | 6h | [ ] |
| 9 · 22/11 | Compute 2: App Service, container + Monitor intro | 6h | [ ] |
| 10 · 23/11 | Monitor + Backup + Site Recovery | 3,5h | [ ] |
| 11 · 24/11 | **Mock exam 1** + review | 3,5h | [ ] |
| 12 · 25/11 | Vá lỗ hổng + section test | 3,5h | [ ] |
| 13 · 26/11 | **Mock exam 2** + review | 3,5h | [ ] |
| 14 · 27/11 | Ôn nhẹ, flashcard, logistics | 3h | [ ] |

Chi tiết từng khối giờ: [`PLAN.md`](PLAN.md).

## 3 cổng quyết định (ghi vào lịch, đừng tự lừa mình)

- **Cổng A — hết ngày 7 (20/11):** quiz Storage ≥ 80% **và** làm lại lab 3–4 không nhìn hướng dẫn.
- **Cổng B — hết ngày 11 (24/11):** mock 1 ≥ 75%. Nếu 65–74%: giữ lịch thi, tăng giờ mock. Nếu < 65%: **dời thi sang 3–5/12** ngay hôm đó (đổi lịch trước 24h là được, kiểm tra lại chính sách Pearson VUE khi đặt).
- **Cổng C — hết ngày 13 (26/11):** mock 2 ≥ 80% và không có domain nào < 70%.

## Nguyên tắc sinh tồn

- **Không học công cụ không thi.** APIM/Virtual WAN/ExpressRoute/AKS: 20 phút đọc overview, hết.
- **Không lab dịch vụ tính tiền theo giờ** (Firewall, Bastion, VPN Gateway, App Gateway): nếu lab, tạo xong chụp ảnh → xoá trong cùng buổi.
- **Mỗi lab xong: `bash scripts/cleanup.sh`** — đừng để quên 1 VM chạy 2 tuần.
- **Không dùng đề dumps** (ExamTopics...): đáp án cũ, sai kiến thức, dạy bạn thói quen học vẹt. Dùng Microsoft Practice Assessment (free) + 1 bộ trả phí có giải thích.
- **AWS SAA là lợi thế, không phải bảo hiểm:** 40% khái niệm map 1-1, nhưng các bẫy Azure (peering non-transitive, 5 IP reserved, Policy vs RBAC, SAS) sẽ giết bạn nếu học theo phản xạ AWS. Đọc `docs/01-aws-to-azure.md` **hôm nay**.

## Nguồn đã kiểm chứng (05/11/2026)

- Study guide: https://learn.microsoft.com/credentials/certifications/resources/study-guides/az-104
- Exam details (100 phút, 700 pass, retake sau 24h): https://learn.microsoft.com/credentials/certifications/exams/az-104/
- Practice Assessment mới: https://aka.ms/AZ104-PA
- Exam sandbox: https://aka.ms/examdemo
- Lab chính thức: https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/
- Learning paths: `az-104-manage-identities-governance`, `az-104-manage-storage`, `az-104-manage-compute-resources`, `az-104-manage-virtual-networks`, `az-104-monitor-backup-resources`
