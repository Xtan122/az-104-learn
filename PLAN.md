# Kế hoạch 14 ngày — AZ-104 (14/11 → 27/11/2026)

Ký hiệu: `[L]` lý thuyết · `[P]` lab thực hành · `[Q]` quiz · `[R]` recap/sổ lỗi
Nguyên tắc: **mỗi ngày phải có ít nhất 1 artifact** (cheat sheet, CLI script, sơ đồ, hoặc 5 dòng sổ lỗi). Học mà không tạo ra gì = sẽ quên.

---

## Ngày 0 — Thứ Sáu 13/11 (1,5h): Setup

- [ ] Tạo Azure free account (Microsoft account **cá nhân**, không dùng account trường/công ty). Kiểm tra offer credit hiện hành; **bật spending limit**.
- [ ] Cài `az` CLI + `bicep`, chạy `bash scripts/bootstrap.sh`
- [ ] Tạo budget alert 20 USD/tháng (Cost Management → Budgets → email ở 50/80/100%)
- [ ] Tạo `progress/wrong-answers.md` (đã có template trong repo)
- [ ] Đặt lịch thi **28/11**, chọn online proctored hoặc test center. Ghi chú: đổi/huỷ được trước 24h.
- [ ] Chọn 1 nguồn đề trả phí có giải thích (Tutorials Dojo hoặc MeasureUp). **Chỉ 1**, không mua 3 bộ.
- [ ] Đọc `docs/00-exam-blueprint.md` + `docs/01-aws-to-azure.md`

## Ngày 1 — Thứ Bảy 14/11 (6h): Baseline + Entra ID

| Giờ | Việc | Output |
|---|---|---|
| 08:30–09:00 | `[L]` Verify setup, làm quen portal, Resource Group, region `southeastasia` | 1 RG `rg-az104-sandbox` |
| 09:00–10:30 | `[Q]` **Practice Assessment #1, không tra cứu, không Google.** Ghi điểm từng domain | 3 domain yếu nhất |
| 10:45–12:00 | `[L]` Entra ID: user/group/guest, license, SSPR, Entra role vs Azure RBAC | `docs/02` mục 1–3 |
| 14:30–16:30 | `[P]` **Lab 1** — user, group, guest, role assignment, effective access | `labs/lab-01-identity-rbac.md` |
| 16:30–17:00 | `[Q]` `quizzes/q1-identity-governance.md` (10 câu) + `[R]` sổ lỗi | ≥ 8/10 |

**Chốt ngày:** bạn phải trả lời được không cần nhìn: *Contributor khác Owner ở đâu? Guest khác Member ở đâu? Gán role ở subscription thì resource group có quyền gì?*

- [ ] Hoàn thành Ngày 1 (quiz ≥ 80%, đã ghi 3 domain yếu)

## Ngày 2 — Chủ Nhật 15/11 (6h): RBAC + Governance

| Giờ | Việc | Output |
|---|---|---|
| 08:30–10:00 | `[L]` RBAC scope/kế thừa, built-in roles, custom role JSON, deny assignment | `docs/02` mục 2 |
| 10:15–12:00 | `[L]` Policy (effects, initiative, remediation), Lock, management group, tag, budget | `docs/02` mục 4–6 |
| 14:30–15:30 | `[P]` **Lab 2** — policy chặn region, policy bắt tag, lock RG, budget | `labs/lab-02-policy-locks-cost.md` |
| 15:30–16:15 | Viết `docs/cheatsheets/01-rbac-policy-lock.md` **bằng tay, không copy** | 1 trang A4 |
| 16:15–17:00 | `[Q]` 20 câu Identity & Governance (q1 + câu tự tạo từ sổ lỗi) | ≥ 16/20 |

**Chốt ngày:** phân biệt được 4 câu: *ai được làm (RBAC) · được tạo gì (Policy) · có được xoá không (Lock) · tốn bao nhiêu (Budget)*.

- [ ] Hoàn thành Ngày 2 (quiz 20 câu ≥ 80%, cheat sheet viết tay)

## Ngày 3 — Thứ Hai 16/11 (3,5h): Networking 1 — VNet, NSG, Bastion

- [ ] `[L]` 19:00–20:00: VNet/subnet/**5 IP bị giữ**, IP planning, public IP SKU, NSG rule + default rules + priority, ASG, service tag, effective rules
- [ ] `[P]` 20:00–21:30: **Lab 3** — 1 VNet 3 subnet, 2 VM không public IP, NSG allow/deny, ASG, `show-effective-nsg`
- [ ] `[Q]` 21:30–22:15: `quizzes/q2-networking.md` phần VNet/NSG + sổ lỗi
- [ ] `[R]` 22:15–22:30: tự vẽ sơ đồ subnet ra giấy

**Must-know:** subnet /24 → **251 IP dùng được**. NSG inbound: **subnet trước, NIC sau**. Default rules priority 65000/65001/65500.

## Ngày 4 — Thứ Ba 17/11 (3,5h): Networking 2 — Peering, UDR, hub-spoke

- [ ] `[L]` 19:00–20:00: peering (2 chiều, non-transitive, gateway transit, không overlap), system route, UDR, longest prefix, NVA + IP forwarding
- [ ] `[P]` 20:00–21:30: **Lab 4** — hub + 2 spoke, chứng minh spoke1 **không** tới được spoke2, thêm UDR qua NVA rồi thông
- [ ] `[Q]` 21:30–22:15: q2 phần routing + sổ lỗi
- [ ] `[R]` 22:15–22:30: vẽ lại hub-spoke khi **không** nhìn

**Must-know:** peering KHÔNG transitive (khác Transit Gateway). Muốn spoke-to-spoke: peer trực tiếp, hoặc UDR → NVA, hoặc dùng gateway transit của hub.

## Ngày 5 — Thứ Tư 18/11 (3,5h): Networking 3 — DNS, Private Endpoint, LB/WAF

- [ ] `[L]` 19:00–20:00: Azure DNS public/private zone, VNet link, auto-registration; service endpoint vs private endpoint; LB (L4, probe, rule, SKU) vs App Gateway (L7, path-based, WAF); Network Watcher
- [ ] `[P]` 20:00–21:30: **Lab 5** (DNS + private endpoint cho storage) — phần LB chuyển sang đọc + làm nhanh nếu còn giờ
- [ ] `[L]` 21:30–21:50: overview **Azure Firewall / Virtual WAN / APIM** (20 phút, chỉ để loại trừ đáp án)
- [ ] `[Q]` 21:50–22:30: q2 phần DNS/LB + sổ lỗi

**Must-know:** Private Endpoint = NIC + private IP + cần `privatelink.*` DNS zone. Service Endpoint = bật trên subnet, không có private IP, vẫn đi qua public IP của PaaS.

## Ngày 6 — Thứ Năm 19/11 (3,5h): Storage 1

- [ ] `[L]` 19:00–20:00: account kind/SKU, **LRS/ZRS/GRS/GZRS/RA-***, tier Hot/Cool/Cold/Archive (+ early deletion), lifecycle rule
- [ ] `[P]` 20:00–21:30: **Lab 7a** — tạo account, upload bằng AzCopy, bật versioning + soft delete, lifecycle rule, đổi tier
- [ ] `[Q]` 21:30–22:15: `quizzes/q3-storage.md` (10 câu) + sổ lỗi
- [ ] `[R]` 22:15–22:30: vẽ bảng redundancy ra giấy

## Ngày 7 — Thứ Sáu 20/11 (3,5h): Storage 2 + Cổng A

- [ ] `[L]` 19:00–20:00: access key vs Entra vs **SAS 3 loại** vs stored access policy; storage firewall; Azure Files (SMB/NFS, identity-based, snapshot, soft delete); File Sync overview
- [ ] `[P]` 20:00–21:30: **Lab 7b** — SAS có stored access policy rồi thu hồi; mount file share; firewall + service endpoint
- [ ] `[Q]` 21:30–22:15: 15 câu Storage (q3 + tự tạo) — **mục tiêu ≥ 80%**
- [ ] `[R]` 22:15–22:30: **Cổng A** — làm lại lab 3–4 không nhìn hướng dẫn. Nếu không làm được → dời mock, xem lại networking.

## Ngày 8 — Thứ Bảy 21/11 (6h): Compute 1 + IaC

| Giờ | Việc | Output |
|---|---|---|
| 08:30–10:00 | `[L]` VM size/series, disk (OS/temp/data, SKU, snapshot), **availability set vs zone**, VMSS + autoscale, disk encryption | `docs/04` mục 1–4 |
| 10:15–12:15 | `[P]` **Lab 8** — VM + data disk, resize, zone, VMSS autoscale, deploy ARM template | `labs/lab-08-vm-vmss-arm.md` |
| 14:30–15:30 | `[L+P]` Đọc `iac/` — sửa 2 chỗ trong template rồi deploy lại, `what-if`, export, decompile Bicep | `iac/README.md` |
| 15:30–17:00 | `[Q]` `quizzes/q4-compute.md` + sổ lỗi | ≥ 8/10 |

**Must-know:** availability set (99,95%, FD/UD) vs zone (99,99%). Temp disk mất dữ liệu khi deallocate/resize. `az deployment group create`.

- [ ] Hoàn thành Ngày 8 (quiz Compute ≥ 80%, template deploy thành công)

## Ngày 9 — Chủ Nhật 22/11 (6h): Compute 2 + Monitor intro

| Giờ | Việc | Output |
|---|---|---|
| 08:30–10:00 | `[L]` App Service plan tier, scale up/out, **deployment slot + swap + sticky**, TLS/custom domain, backup, VNet integration; ACR/ACI/ACA | `docs/04` mục 5–6 |
| 10:15–12:15 | `[P]` **Lab 9** — web app + staging slot + swap; ACI từ image public | `labs/lab-09-appservice-containers.md` |
| 14:30–15:30 | `[L]` Metrics vs logs, diagnostic settings, Log Analytics cơ bản | `docs/06` mục 1–3 |
| 15:30–17:00 | `[Q]` 15 câu Compute + 5 câu Monitor + sổ lỗi | ≥ 80% |

- [ ] Hoàn thành Ngày 9 (slot swap chạy được, quiz ≥ 80%)

## Ngày 10 — Thứ Hai 23/11 (3,5h): Monitor + Backup/DR

- [ ] `[L]` 19:00–20:00: alert (metric/log/activity) + action group + **alert processing rule**; KQL (`where/summarize/project/bin/ago`); Activity Log; Insights; Network Watcher
- [ ] `[P]` 20:00–21:45: **Lab 10** — Log Analytics + diagnostic settings + CPU alert gửi mail + backup VM + restore file
- [ ] `[Q]` 21:45–22:15: `quizzes/q5-monitor-backup.md` + sổ lỗi
- [ ] `[R]` 22:15–22:30: phân biệt **Recovery Services vault vs Backup vault**, **backup vs ASR**

## Ngày 11 — Thứ Ba 24/11 (3,5h): MOCK EXAM 1

- [ ] 19:00–20:40: **Mock 1 full, 100 phút, không tra cứu, không pause.** Đánh dấu câu không chắc.
- [ ] 20:50–22:30: review **từng câu sai + từng câu đánh dấu**, ghi sổ lỗi kèm nhãn domain
- [ ] Ghi điểm: Domain 1 ___% · Domain 2 ___% · Domain 3 ___% · Domain 4 ___% · Domain 5 ___%
- [ ] **Cổng B:** ≥ 75% → giữ lịch. 65–74% → giữ lịch + tăng mock. **< 65% → dời thi ngay tối nay.**

## Ngày 12 — Thứ Tư 25/11 (3,5h): Vá lỗ hổng

- [ ] 19:00–20:00: 2 domain yếu nhất — đọc lại `docs/` + làm 10 câu mỗi domain
- [ ] 20:00–21:40: **section test**: 2 domain yếu, 30–40 câu, timed 1,5 phút/câu
- [ ] 21:40–22:30: review + cập nhật `progress/wrong-answers.md`; xoá các mục đã nhớ (đánh dấu `resolved`)

## Ngày 13 — Thứ Năm 26/11 (3,5h): MOCK EXAM 2 + Cổng C

- [ ] 19:00–20:40: **Mock 2 full, 100 phút**
- [ ] 20:50–22:30: review; so sánh với mock 1 theo domain
- [ ] **Cổng C:** ≥ 80% và không domain nào < 70% → tự tin đi thi. Nếu không → huỷ/dời (trước 24h).

## Ngày 14 — Thứ Sáu 27/11 (3h): Không học mới

- [ ] 19:00–19:40: đọc 4 cheat sheet trong `docs/cheatsheets/`
- [ ] 19:40–20:20: flashcard `quizzes/flashcards.csv` (chỉ các thẻ còn sai)
- [ ] 20:20–21:00: làm lại 20 câu trong sổ lỗi
- [ ] 21:00–21:30: logistics — giấy tờ, webcam/micro, mạng, phòng yên tĩnh, Pearson VUE system test, giờ thi
- [ ] Ngủ trước 23:00. **Không học thêm dịch vụ mới.**

---

## Nếu tụt tiến độ (chọn 1, đừng cố làm hết)

| Tình huống | Cắt gì | Giữ gì |
|---|---|---|
| Mất 1 buổi tối | Bỏ phần "overview APIM/vWAN", gộp 2 ngày storage làm 1 | Quiz + sổ lỗi |
| Mất 1 ngày | Bỏ Lab 9 (App Service) — đọc note + xem portal | Mock exam |
| Mất 2 ngày | Bỏ toàn bộ lab compute, chỉ đọc `docs/04` + `iac/` | 2 mock exam |
| Chỉ còn 3 ngày | Bỏ hết lab | Cheatsheet + 2 mock + sổ lỗi |

## Ngân sách thời gian theo domain (để tự kiểm tra)

| Domain | Giờ học | Giờ lab | Giờ quiz | Tổng |
|---|---|---|---|---|
| Identity & Governance | 5 | 3 | 1,5 | **9,5** |
| Networking | 6 | 5 | 2 | **13** |
| Storage | 3,5 | 3,5 | 1,5 | **8,5** |
| Compute | 5 | 5 | 2 | **12** |
| Monitor & Backup | 4 | 2 | 1,5 | **7,5** |
| Mock + review | — | — | 7 | **7** |
| Buffer | | | | **1,5** |
