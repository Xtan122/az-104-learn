# 00 — Exam blueprint & chiến lược thi

Cập nhật theo study guide chính thức (MS Learn, `updated_at 2026-11-05`). Objectives vẫn là bản **26/10/2023** — nhiều blog nói "đề mới 2025/2026" là sai; hãy tin trang study guide.

## 1. Thông số đề

| Hạng mục | Giá trị |
|---|---|
| Thời gian | **100 phút** (có thể xin thêm 30' nếu thi bằng ngôn ngữ không phải tiếng Anh) |
| Số câu | ~40–50 (Microsoft không công bố chính thức; gồm case study + câu lẻ) |
| Điểm đạt | **700/1000** (scaled score, không phải % câu đúng) |
| Hình thức | Proctored tại nhà hoặc test center; Pearson VUE |
| Thi lại | Sau **24h** cho lần đầu fail; các lần sau lâu hơn |
| Giá | Theo quốc gia (~165 USD) |
| Labs tay | **Không có** (AZ-104 không còn hands-on lab) |
| Ngôn ngữ | Có tiếng Anh; không có tiếng Việt |

**Suy ra chiến thuật:** 100 phút / 45 câu ≈ **2,2 phút/câu**, nhưng case study ăn 4–6 phút. Đặt mục tiêu **1,5 phút/câu** cho câu lẻ để bù.

## 2. Trọng số & hàm ý

| Domain | Weight | Hàm ý |
|---|---|---|
| Identity & governance | 20–25% | Câu hỏi RBAC/Policy/lock rất "thuộc bài" → **điểm chắc**, không được mất |
| Compute | 20–25% | Nhiều câu ARM/Bicep + VM/VMSS + App Service → **nặng nhất về lượng kiến thức** |
| Storage | 15–20% | Câu ngắn, so sánh redundancy/SAS/tier → dễ ăn điểm nếu thuộc bảng |
| Networking | 15–20% | Câu tình huống + troubleshoot → tốn thời gian, dễ sai bẫy |
| Monitor & backup | 10–15% | Ít câu nhưng dễ mất điểm vì học sơ sài |

**Điểm mấu chốt:** không domain nào được phép bỏ. 15–20% = khoảng 7–10 câu; mất trắng 1 domain là mất ~150 điểm scaled → trượt.

## 3. Dạng câu hỏi & cách xử lý

| Dạng | Đặc điểm | Cách làm |
|---|---|---|
| Multiple choice 1 đáp án | Phổ biến nhất | Loại 2 đáp án sai rõ, còn 2 thì chọn cái **ít công quản trị hơn** |
| Multiple choice nhiều đáp án | "Chọn 2/3" | Đọc kỹ "Select two" — chọn thiếu = 0 điểm |
| **Yes/No series** | 3–5 phát biểu, mỗi cái Yes/No, **không quay lại được** | Làm chắc ngay, đừng đánh dấu |
| **Case study** | 1 tình huống + 5–7 câu, **rời section là không quay lại** | Đọc yêu cầu trước, đọc case sau; ghi note giấy |
| Drag & drop / hotspot | Sắp xếp thứ tự, chọn vùng trên hình | Thường hỏi **thứ tự đánh giá** (NSG/routing) |
| Build a solution | Kéo nhiều bước thành giải pháp | Đọc xem có yêu cầu "least effort / least cost" không |

### 4 từ khoá quyết định đáp án
1. **"Least administrative effort"** → chọn dịch vụ managed / built-in policy / template, không chọn "tạo script tự viết".
2. **"Minimize cost"** → tier thấp nhất đáp ứng yêu cầu, LRS thay GRS nếu không cần DR, deallocate thay vì để chạy.
3. **"Minimize latency"** → cùng region, zone-redundant, private endpoint, Premium.
4. **"Most secure"** → Entra ID/managed identity > SAS > access key; private endpoint > service endpoint > public; WAF Prevention > Detection.

## 4. Những thứ KHÔNG nằm trong skills measured

Đừng dành thời gian cấu hình: **APIM, Virtual WAN, ExpressRoute, Azure Firewall, Front Door, AKS, Entra Connect, Azure File Sync, Defender for Cloud, Azure Functions, Logic Apps, Azure SQL**.
Bạn vẫn cần **biết 1 dòng** về chúng để loại trừ:

- **APIM**: API gateway, publish/manage API, policy, rate limit, subscription key. Không phải LB.
- **Virtual WAN**: hub mạng toàn cầu do Microsoft quản lý, gộp VPN/ER/peering. Không phải hub-spoke tự dựng.
- **ExpressRoute**: kết nối riêng on-prem ↔ Azure, không qua Internet. Không phải VPN.
- **Azure Firewall**: firewall L3–L7 stateful, FQDN filter, DNAT, threat intel; đắt, tính theo giờ. Không thay NSG.
- **Front Door**: CDN + global L7 LB + WAF. Không phải App Gateway (regional).
- **AKS**: Kubernetes managed. Không phải ACI/ACA.

## 5. Bản đồ 80/20 — 25 thứ phải thuộc lòng

**Identity/Governance**
1. RBAC kế thừa: MG → Subscription → RG → Resource. Quyền **cộng dồn**, Deny thắng Allow.
2. Owner / Contributor / Reader / User Access Administrator / Virtual Machine Contributor.
3. Policy effect: Deny, Audit, Append, Modify, DeployIfNotExists, AuditIfNotExists, Disabled.
4. Lock: CanNotDelete vs ReadOnly (ReadOnly chặn cả update).
5. Budget **chỉ cảnh báo**, không chặn chi tiêu.

**Networking**
6. Mỗi subnet giữ **5 IP**: network, gateway, 2 DNS, broadcast.
7. NSG stateful; inbound subnet→NIC, outbound NIC→subnet; priority nhỏ thắng.
8. Peering **không transitive**; phải tạo ở **cả 2 phía**.
9. UDR thắng system route khi cùng prefix; longest prefix match trước.
10. `0.0.0.0/0 → Virtual appliance` = forced tunneling; cần **IP forwarding** trên NIC của NVA.
11. Service endpoint vs private endpoint.
12. LB = L4 (TCP/UDP), App Gateway = L7 (HTTP/S, path, WAF).
13. Azure LB health probe đến từ `168.63.129.16` / service tag `AzureLoadBalancer` → NSG phải cho phép.

**Storage**
14. LRS / ZRS / GRS / GZRS / RA-GRS / RA-GZRS.
15. Hot / Cool / Cold / Archive + early deletion.
16. SAS: account, service, **user delegation** (Entra, max 7 ngày).
17. Stored access policy = cách **thu hồi SAS** không cần rotate key.
18. Storage firewall cần service endpoint (hoặc private endpoint), không chỉ "allow subnet" là xong.

**Compute**
19. Availability set = 99,95% (FD/UD); Availability zone = 99,99%.
20. Temp disk mất dữ liệu khi **deallocate/resize**.
21. VMSS: autoscale rule = metric + threshold + duration + cooldown.
22. ARM: `$schema`, `parameters`, `variables`, `resources`, `outputs`; Bicep: `param`, `var`, `resource`, `module`, `output`.
23. Deployment slot chỉ có từ tier **Standard**; swap có **sticky settings**.

**Monitor/Backup**
24. Metrics = số, time series, gần real-time; Logs = text, cần Log Analytics + KQL.
25. Recovery Services vault (VM/SQL/Files) vs Backup vault (Blob/Disk/AKS); ASR = replication + failover.

## 6. Quản lý thời gian trong phòng thi

```
0–5'    : đọc lướt toàn bộ câu lẻ, đánh dấu câu dài (>4 dòng) để làm sau
5–75'   : làm câu lẻ, 1,5'/câu; câu nào >2' thì đánh dấu, đoán, đi tiếp
75–95'  : case study (không quay lại được → làm cẩn thận)
95–100' : rà câu đánh dấu (nếu section còn cho quay lại)
```
Quy tắc: **không bao giờ để trống**. Đáp án sai không bị trừ điểm.

## 7. Sai lầm phổ biến của người có AWS SAA

| Phản xạ AWS | Sự thật Azure |
|---|---|
| "Peering là transitive qua Transit Gateway" | VNet peering **không** transitive, không có TGW tương đương (phải dùng NVA/gateway transit/vWAN) |
| "NACL + SG, NACL stateless" | Azure chỉ có NSG **stateful**; không có NACL riêng |
| "Subnet /24 có 256 IP" | Azure giữ 5 → còn 251 |
| "SCP chỉ deny" | Azure Policy có Deny, Audit, Append, Modify, DeployIfNotExists |
| "IAM policy JSON" | Azure RBAC role JSON (`Actions`, `NotActions`, `assignableScopes`) + Policy JSON riêng |
| "S3 bucket" | Storage account (namespace) + container; tên 3–24 ký tự, globally unique |
| "Presigned URL" | SAS, nhưng có 3 loại và nhiều cách thu hồi |
| "Mỗi AZ là 1 region riêng" | Zone nằm trong region; region pair mới là khái niệm DR |

## 8. Checklist nguồn ôn (đã lọc)

**Bắt buộc**
- [ ] Microsoft Practice Assessment mới: https://aka.ms/AZ104-PA (free, sát đề)
- [ ] Exam sandbox: https://aka.ms/examdemo (làm 1 lần cho quen UI Yes/No + case study)
- [ ] 5 learning path AZ-104 trên MS Learn (dùng làm index, không đọc hết)
- [ ] Lab chính thức: https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/

**Nên có**
- [ ] 1 bộ đề trả phí có giải thích (Tutorials Dojo hoặc MeasureUp)
- [ ] John Savill "AZ-104 Study Cram" (YouTube) — xem 1 lần ở tốc độ 1,25× trước ngày 11
- [ ] Azure CLI docs (`az network`, `az storage`, `az vm`, `az policy`) để tra cú pháp

**Tránh**
- ExamTopics / dumps / "đề thật 2026": sai và lỗi thời, dạy học vẹt.
- Video 10 tiếng "full course": bạn không có thời gian; note trong repo đã nén theo đề.
- Lab dịch vụ đắt (Firewall, Bastion, VPN GW) trước ngày 10.
