# 06 — Monitor & Backup (10–15%)

> Ít câu nhưng **rất dễ mất điểm** vì ai cũng bỏ qua. Học 1 buổi tối là đủ nếu thuộc bảng.

## 1. Azure Monitor — 2 loại dữ liệu

| | **Metrics** | **Logs** |
|---|---|---|
| Dạng | Số, time series | Text/structured record |
| Nguồn | Platform metrics (tự có) | Resource logs, guest OS, app, activity |
| Lưu | 93 ngày (platform metrics) | Log Analytics workspace (mặc định 30 ngày) |
| Truy vấn | Metrics Explorer | **KQL** |
| Alert | Metric alert (gần real-time) | Log search alert (chạy query theo lịch) |
| Dùng cho | CPU, IOPS, latency, connections | "Ai làm gì", lỗi app, audit |

- **Activity Log**: log control-plane (create/update/delete), **90 ngày**, theo subscription. Không cần bật. Export được ra storage/Event Hub/Log Analytics.
- **Diagnostic settings**: bật để đẩy **resource logs + metrics** tới 1 trong: Log Analytics workspace, Storage account, Event Hub, partner solution. Không bật = không có log.
- **Insights**: VM Insights (agent + workbook), Container Insights, Storage Insights, Network Insights, App Insights (APM). Câu hỏi hay hỏi "xem performance tổng hợp của nhiều VM" → VM Insights.
- **Data collection rule (DCR)**: định nghĩa dữ liệu nào thu từ VM (AMA — Azure Monitor Agent). Biết tên là đủ.

## 2. Log Analytics + KQL

Workspace là nơi lưu log; truy vấn bằng KQL.

| Toán tử | Ý nghĩa |
|---|---|
| `where` | lọc |
| `project` | chọn cột |
| `summarize` | gộp nhóm (`count()`, `avg()`, `max()`, `sum()`) |
| `bin(TimeGenerated, 5m)` | chia bucket thời gian |
| `order by ... desc` | sắp xếp |
| `take 10` / `limit` | lấy N dòng |
| `ago(1h)`, `now()` | thời gian tương đối |
| `extend` | tạo cột tính toán |
| `join` | ghép bảng |
| `render` | vẽ chart |

```kql
// CPU trung bình theo VM trong 1 giờ
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where TimeGenerated > ago(1h)
| summarize avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| render timechart

// Các thao tác xoá resource trong 24h
AzureActivity
| where TimeGenerated > ago(24h)
| where OperationNameValue endswith "DELETE"
| project TimeGenerated, Caller, ResourceGroup, OperationNameValue, ActivityStatusValue
| order by TimeGenerated desc
```

**Bẫy:** log search alert **không real-time** — chạy theo frequency (tối thiểu 5 phút), có `evaluation period` và `threshold`.

## 3. Alert

Thành phần: **scope** (resource) + **condition** (signal + logic) + **action group** + **severity** (0 Critical → 4 Verbose) + **alert rule**.

| Loại alert | Signal | Dùng |
|---|---|---|
| **Metric alert** | metric | CPU > 80% |
| **Log search alert** | KQL query | "có lỗi 500 trong 5 phút" |
| **Activity log alert** | control-plane event | "có người xoá NSG" |
| **Smart detection** | App Insights anomaly | tự động |

- **Action group**: email, SMS, voice, push, webhook, Logic App, Function, Automation Runbook, ITSM. 1 action group gán cho nhiều alert.
- **Alert processing rule**: **suppression** (tắt alert trong maintenance window) hoặc **action group override**. Câu hỏi: "không gửi alert vào cuối tuần" → alert processing rule.
- **Action rule** là tên cũ của alert processing rule — đừng nhầm.

**Bẫy:** alert **không** tự restart VM, không tự scale. Muốn tự động xử lý → **action group → Automation Runbook / Function**.

## 4. Network Watcher (nhắc lại phần networking)

`IP flow verify` (NSG) · `Next hop` (route) · `Connection troubleshoot` (end-to-end) · `Connection monitor` (liên tục + alert) · `NSG flow logs` · `Packet capture` · `Topology` · `VPN troubleshoot`.

Network Watcher **tự bật** theo region khi tạo VNet lần đầu (hoặc bật tay). Không tính phí cho các tính năng cơ bản, flow logs tính theo GB.

## 5. Azure Backup

### 5.1 Vault

| | **Recovery Services vault (RSV)** | **Backup vault** |
|---|---|---|
| Dùng cho | Azure VM, SQL trong VM, SAP HANA, Azure Files, on-prem (MARS/MABS) | **Blob, Managed Disk, AKS, PostgreSQL, Elastic SAN** (các datasource mới) |
| Tính năng | Backup policy, soft delete, immutable, reports, ASR? (ASR dùng RSV) | Backup policy, vaulted backup |
| Chọn khi | 90% câu hỏi "backup VM" | câu hỏi "backup blob/disk" |

- **Backup policy**: schedule (daily/weekly, có thể nhiều lần/ngày với VM premium) + **retention** (daily/weekly/monthly/yearly) + instant restore snapshot retention (1–5 ngày) + **GFS**.
- **Azure Backup agent**:
  - **MARS** (Microsoft Azure Recovery Services agent): file/folder + system state từ Windows Server/on-prem, lên RSV.
  - **MABS/DPM**: enterprise on-prem.
  - **VM extension**: cho Azure VM (không cần agent thủ công).
- **Soft delete**: giữ backup đã xoá thêm 14 ngày (mặc định), chống ransomware; có thể tắt (không khuyến nghị).
- **Immutable vault**: khoá để không ai xoá backup (WORM).
- **Restore options**: Restore VM (tạo mới), Restore disk, **File recovery** (mount snapshot, copy file), Replace existing, Cross-region restore (nếu bật CRR).
- **Backup reports** + **alerts** (built-in, qua RSV → diagnostic settings).
- **Backup Center**: 1 chỗ quản lý nhiều vault/jobs/policies.

### 5.2 Azure Site Recovery (ASR)
- **Replication** VM từ primary region → secondary region (hoặc on-prem → Azure), **liên tục**, RPO thấp (vài phút).
- Thành phần: **Recovery Services vault**, **replication policy**, **fabric**, **protection container**, **replication item**.
- Quy trình: Enable replication → (option) **Test failover** (vào network cô lập, không ảnh hưởng production) → **Failover** → **Commit** → **Reprotect** (để failback).
- **Recovery plan**: nhóm VM + thứ tự khởi động + script/Azure Automation runbook + manual action.
- Khác Backup: Backup = bản copy định kỳ để restore dữ liệu; ASR = replica liên tục để **chuyển region** với RTO thấp.
- **Bẫy:** "test DR mà không ảnh hưởng production" → **Test failover**, không phải failover.

## 6. Bảng "chọn dịch vụ" cho câu hỏi monitor/backup

| Yêu cầu | Chọn |
|---|---|
| "Ai đã xoá VM?" | Activity Log |
| "CPU của VM 7 ngày trước" | Metrics (93 ngày) |
| "Query log app theo requestId" | Log Analytics + KQL |
| "Cảnh báo khi CPU > 80% trong 10 phút" | Metric alert |
| "Không gửi alert khi bảo trì" | Alert processing rule (suppression) |
| "Alert gửi Teams/Slack" | Action group → webhook |
| "Tự động chạy script khi alert" | Action group → Automation Runbook |
| "Backup VM mỗi ngày, giữ 5 năm" | RSV + backup policy GFS |
| "Backup blob" | Backup vault |
| "Chống xoá backup" | Immutable vault + soft delete |
| "DR sang region khác, RTO thấp" | Azure Site Recovery |
| "Kiểm tra DR mà không ảnh hưởng prod" | ASR **test failover** |
| "Xem sức khoẻ nhiều VM" | VM Insights |
| "Theo dõi kết nối mạng liên tục" | Connection Monitor |

## 7. Bẫy tổng hợp

1. Diagnostic settings **phải bật** mới có resource log — không tự có.
2. Activity Log 90 ngày, không phải 30.
3. Metric alert dùng metrics; log alert dùng KQL và **không real-time**.
4. Alert không tự động sửa lỗi.
5. Backup vault ≠ Recovery Services vault.
6. ASR test failover ≠ failover.
7. Soft delete bảo vệ backup khỏi bị xoá, không bảo vệ dữ liệu nguồn.
8. Network Watcher flow logs cần storage account/LA workspace để lưu.

## 8. Tự kiểm tra

1. Cần biết ai đổi NSG lúc 2h sáng → xem đâu?
2. Muốn lưu log VM 1 năm để query → làm gì?
3. Alert CPU gửi email cho team → 2 resource nào?
4. Tắt alert trong maintenance window → tính năng nào?
5. Backup blob storage → vault nào?
6. RTO 15 phút khi region chết → Backup hay ASR?
7. Test DR không ảnh hưởng user → bước nào?
8. KQL: đếm số event theo giờ → toán tử nào?

<details><summary>Đáp án</summary>

1. Activity Log.
2. Diagnostic settings → Log Analytics workspace, tăng retention (hoặc archive).
3. Metric alert + action group.
4. Alert processing rule (suppression).
5. Backup vault.
6. ASR.
7. Test failover.
8. `summarize count() by bin(TimeGenerated, 1h)`.

</details>
