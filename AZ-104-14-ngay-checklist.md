# Checklist 14 ngày thi AZ-104 (ưu tiên Networking, nguyên tắc 80/20)

14/11/2026 → 27/11/2026 · Dự kiến thi 28/11 · Nền tảng: AWS SAA

Cách dùng: đổi `[ ]` thành `[x]` khi xong. Giờ chỉ là gợi ý, có thể dời cả khối theo giờ rảnh nhưng giữ thứ tự.

---

## A. Việc cần làm một lần

- [ ] Tạo Azure free account
- [ ] Đặt budget alert
- [ ] Tạo sổ lỗi (cột: câu hỏi / vì sao sai / quy tắc đúng)
- [ ] Tải study guide chính thức trên Microsoft Learn và đối chiếu lại tỷ trọng các domain
- [ ] Đặt lịch thi 28/11 (kiểm tra chính sách đổi lịch)
- [ ] Chọn nguồn học: Microsoft Learn + repo lab AZ-104 trên GitHub + 1 video cram + 1 bộ đề thi thử có giải thích

## B. 20% nội dung mang lại ~80% điểm (phải nắm chắc)

**Identity & Governance**
- [ ] RBAC: scope, kế thừa, custom role
- [ ] Azure Policy (Deny/Audit/Append/Modify/DeployIfNotExists) vs RBAC vs Resource Lock
- [ ] Management group, subscription, tag, budget
- [ ] Entra user / group / guest

**Networking**
- [ ] NSG: thứ tự ưu tiên, rule mặc định, gắn subnet vs NIC, ASG, service tag
- [ ] VNet peering (non-transitive), UDR, next hop, hub-spoke
- [ ] Private DNS zone, service endpoint vs private endpoint
- [ ] Load Balancer vs Application Gateway (kèm WAF)
- [ ] Network Watcher (IP flow verify, next hop, connection troubleshoot)

**Storage**
- [ ] Redundancy: LRS / ZRS / GRS / GZRS
- [ ] Access tier + lifecycle
- [ ] SAS vs access key vs Entra, stored access policy
- [ ] Storage firewall, Azure Files

**Compute**
- [ ] Availability set vs availability zone
- [ ] VMSS + autoscale
- [ ] Đọc và triển khai ARM/Bicep
- [ ] App Service plan + deployment slot, ACI

**Monitor & Backup**
- [ ] Metrics vs logs, alert + action group
- [ ] Log Analytics + KQL cơ bản
- [ ] Recovery Services vault, backup policy, Site Recovery

**Chỉ đọc overview (tối đa 30 phút/mục), không lab sâu**
- [ ] APIM
- [ ] Virtual WAN
- [ ] ExpressRoute
- [ ] Entra Connect / hybrid identity
- [ ] AKS

## C. Quy tắc vận hành

- Mỗi buổi tối: đọc lại sổ lỗi hôm trước 10 phút.
- Quiz domain đạt từ 80% mới sang phần tiếp theo.
- Sau mỗi lab: xóa Resource Group, stop/deallocate VM.
- Azure Firewall, Bastion, VPN Gateway tính tiền theo giờ: chỉ lab ngắn rồi xóa ngay.

Khung ngày thường (~3,5 giờ): 19:00–20:00 lý thuyết · 20:00–21:30 lab · 21:30–22:15 quiz + sổ lỗi · 22:15–22:30 recap.
Khung cuối tuần (~6 giờ): 08:30–10:00 lý thuyết · 10:15–12:15 lab · 14:30–15:30 củng cố · 15:30–17:00 quiz + sổ lỗi.

---

## D. Lịch chi tiết

### Ngày 1 — Thứ Bảy 14/11: Setup, baseline, Identity (1)
- [ ] 08:30–09:15 Setup (mục A)
- [ ] 09:15–10:15 Làm free practice assessment của Microsoft, không tra cứu; ghi 3 domain yếu nhất
- [ ] 10:30–12:00 Lý thuyết: Entra user/group/guest (B2B), license, SSPR (khái niệm), Entra role vs Azure RBAC
- [ ] 14:30–16:30 Lab: 3 user, 2 group, mời guest, gán Reader/Contributor ở scope Resource Group và Subscription, kiểm tra quyền hiệu lực
- [ ] 16:30–17:30 Quiz 20 câu Identity + ghi sổ lỗi

### Ngày 2 — Chủ Nhật 15/11: Identity (2) và Governance
- [ ] 08:30–10:00 Lý thuyết: kế thừa RBAC, custom role (JSON), Policy (effects, initiative), Lock (CanNotDelete/ReadOnly), management group, tag, Cost Management
- [ ] 10:15–12:15 Lab: policy chặn region, policy bắt buộc tag, lock Resource Group, management group, budget alert, move resource
- [ ] 14:30–15:30 Viết cheat sheet 1 trang: Policy vs RBAC vs Lock
- [ ] 15:30–17:00 Quiz 30 câu Identity & Governance (mục tiêu ≥ 80%)

### Ngày 3 — Thứ Hai 16/11: Networking (1) — VNet và NSG
- [ ] 19:00–20:00 Lý thuyết: VNet/subnet (5 IP bị giữ mỗi subnet), public IP SKU, NSG, ASG, service tag
- [ ] 20:00–21:30 Lab: VNet 2 subnet, 2 VM, NSG chặn/mở SSH-RDP-ICMP, ASG, xem effective security rules
- [ ] 21:30–22:15 Quiz 15 câu VNet và NSG + sổ lỗi
- [ ] 22:15–22:30 Recap

### Ngày 4 — Thứ Ba 17/11: Networking (2) — Peering, UDR, hub-spoke
- [ ] 19:00–20:00 Lý thuyết: peering (non-transitive, không chồng address space, gateway transit), system route, UDR, next hop VirtualAppliance, IP forwarding
- [ ] 20:00–21:30 Lab hub-spoke: 1 hub + 2 spoke, peering; kiểm chứng spoke1 không tới spoke2 mặc định; thêm UDR qua VM làm NVA để cho phép transit
- [ ] 21:30–22:15 Quiz 15 câu peering và routing + sổ lỗi
- [ ] 22:15–22:30 Recap

### Ngày 5 — Thứ Tư 18/11: Networking (3) — DNS và kết nối riêng tư
- [ ] 19:00–20:00 Lý thuyết: Azure DNS public zone, Private DNS zone, virtual network link, auto-registration, service endpoint vs private endpoint
- [ ] 20:00–21:30 Lab: Private DNS zone nối 2 VNet; storage account với private endpoint; storage firewall với service endpoint
- [ ] 21:30–22:15 Quiz 15 câu DNS và private connectivity + sổ lỗi
- [ ] 22:15–22:30 Recap

### Ngày 6 — Thứ Năm 19/11: Networking (4) — Load balancing, WAF, Firewall, VPN
- [ ] 19:00–20:00 Lý thuyết: Load Balancer (L4, probe, rule), Application Gateway (L7, path-based, WAF Detection vs Prevention), Front Door/Traffic Manager (toàn cầu), Bastion, Azure Firewall vs NSG, VPN Gateway (khái niệm)
- [ ] 20:00–21:30 Lab: Standard LB trước 2 VM với health probe; Bastion hoặc Firewall chỉ lab ngắn rồi xóa ngay
- [ ] 21:30–22:15 Quiz 15 câu LB, App Gateway, Firewall + sổ lỗi
- [ ] 22:15–22:30 Recap

### Ngày 7 — Thứ Sáu 20/11: Networking (5) — Troubleshooting và tổng kết
- [ ] 19:00–20:00 Lý thuyết: Network Watcher (IP flow verify, next hop, connection troubleshoot, effective routes, NSG flow logs)
- [ ] 20:00–21:00 Lab: cố tình tạo lỗi (NSG deny, UDR sai) rồi chẩn đoán bằng Network Watcher
- [ ] 21:00–21:30 Đọc overview APIM
- [ ] 21:30–22:00 Đọc overview Virtual WAN
- [ ] 22:00–22:45 Quiz tổng Networking 30 câu (≥ 80%) + cheat sheet Networking 1 trang

### Ngày 8 — Thứ Bảy 21/11: Storage
- [ ] 08:30–10:00 Lý thuyết: loại account, redundancy, access tier, lifecycle, soft delete/versioning, SAS (account/service/user delegation, stored access policy), access key vs Entra, storage firewall, Azure Files + File Sync, AzCopy
- [ ] 10:15–12:15 Lab: storage account, upload bằng AzCopy, lifecycle rule, SAS rồi thu hồi bằng stored access policy, mount file share, storage firewall
- [ ] 14:30–15:30 Củng cố: failover GRS, Blob vs Files, bảng so sánh SAS
- [ ] 15:30–17:00 Quiz 30 câu Storage + sổ lỗi

### Ngày 9 — Chủ Nhật 22/11: Compute (1) — VM và ARM/Bicep
- [ ] 08:30–10:00 Lý thuyết: size VM, managed disk/snapshot, availability set vs zone, VMSS + autoscale, Azure Disk Encryption, resize/redeploy, ARM/Bicep (đọc cấu trúc, deploy bằng CLI/PowerShell, export template)
- [ ] 10:15–12:15 Lab: VM + data disk, resize, VMSS với autoscale rule, deploy ARM template bằng CLI
- [ ] 14:30–15:30 Củng cố: đọc và sửa một ARM template ngắn
- [ ] 15:30–17:00 Quiz 30 câu VM và template + sổ lỗi

### Ngày 10 — Thứ Hai 23/11: Compute (2) — App Service và container
- [ ] 19:00–20:00 Lý thuyết: App Service plan (tier, scale up/out), deployment slot, TLS/custom domain, backup; ACI, Container Apps (khái niệm), ACR
- [ ] 20:00–21:30 Lab: web app với staging slot và swap, autoscale, chạy container bằng ACI
- [ ] 21:30–22:15 Quiz 25 câu Compute + sổ lỗi
- [ ] 22:15–22:30 Recap

### Ngày 11 — Thứ Ba 24/11: Monitoring, Backup và DR
- [ ] 19:00–20:00 Lý thuyết: Azure Monitor (metrics vs logs), Log Analytics + KQL (where, summarize, project), alert + action group, diagnostic settings, Activity Log, Recovery Services vault, backup policy, Site Recovery
- [ ] 20:00–21:30 Lab: Log Analytics workspace, diagnostic settings, alert CPU gửi email, backup VM rồi restore file
- [ ] 21:30–22:15 Quiz 25 câu Monitor và Backup + sổ lỗi
- [ ] 22:15–22:30 Recap

### Ngày 12 — Thứ Tư 25/11: Đề thi thử 1
- [ ] 19:00–21:00 Làm đề thi thử đầy đủ trong 100–120 phút, không tra cứu
- [ ] 21:00–22:30 Xem lại từng câu sai, ghi sổ lỗi, gắn nhãn domain
- [ ] Chọn 2 chủ đề yếu nhất: ______________ và ______________
- Điểm: ____ %

### Ngày 13 — Thứ Năm 26/11: Vá lỗ hổng và đề thi thử 2
- [ ] 19:00–20:15 Lab hoặc đọc docs cho 2 chủ đề yếu nhất
- [ ] 20:15–22:15 Đề thi thử 2 (hoặc làm lại câu sai của đề 1 cộng đề mới)
- [ ] 22:15–22:45 Xem lại câu sai
- Điểm: ____ %

### Ngày 14 — Thứ Sáu 27/11: Ôn nhẹ, không học mới
- [ ] 19:00–20:00 Đọc sổ lỗi và 3 cheat sheet (Policy/RBAC/Lock, Networking, Storage)
- [ ] 20:00–20:45 Làm lại 20–30 câu từng sai
- [ ] 20:45–21:15 Kiểm tra logistics: giấy tờ tùy thân, giờ thi, địa điểm hoặc môi trường thi online
- [ ] Ngủ trước 23:00

---

## E. Cổng quyết định

- [ ] Điểm đề thi thử ổn định từ 80–85% ở ít nhất 2 đề liên tiếp
- [ ] Tự làm lại được lab hub-spoke từ đầu mà không nhìn hướng dẫn
- [ ] Đọc hiểu được lệnh Azure CLI/PowerShell và một ARM template ngắn

Nếu đạt cả ba: giữ lịch thi 28/11. Nếu điểm dưới 75%: dời thêm 3–5 ngày, dùng thời gian đó cho các domain yếu nhất, không học lại từ đầu.

## F. Mẹo ngày thi

- [ ] Vào hệ thống (hoặc đến điểm thi) sớm để làm thủ tục
- [ ] Câu khó thì đánh dấu và làm sau, mục tiêu khoảng 1,5 phút mỗi câu
- [ ] Câu hỏi "ít công quản trị nhất / ít thay đổi nhất": ưu tiên dịch vụ managed và cấu hình sẵn có
- [ ] Case study và loạt câu yes/no: đọc kỹ ngay lần đầu vì có phần không cho quay lại
