# Q5 — Monitor & Backup (10 câu / 15 phút)

1. Cần biết **ai** đã xoá một NSG lúc 2h sáng. Xem ở đâu?
   A. Metrics
   B. Activity Log
   C. VM Insights
   D. NSG flow logs

2. Cần lưu log của VM để query bằng KQL trong 1 năm. Cần gì?
   A. Chỉ bật boot diagnostics
   B. Azure Monitor Agent + Data Collection Rule → Log Analytics, tăng retention
   C. Metric alert
   D. Activity Log

3. Alert khi CPU > 80% trong 10 phút, gửi email. Cần những resource nào?
   A. Log Analytics + workbook
   B. Metric alert + action group
   C. Activity log alert
   D. Automation account

4. Không muốn nhận alert trong cửa sổ bảo trì Chủ nhật. Dùng gì?
   A. Tắt alert rule
   B. Alert processing rule (suppression)
   C. Xoá action group
   D. Đổi severity

5. Cần backup **blob storage**. Chọn vault nào?
   A. Recovery Services vault
   B. Backup vault
   C. Key Vault
   D. Storage account

6. Cần giữ backup VM hàng tháng trong 7 năm. Cấu hình gì?
   A. Chỉ daily retention
   B. Backup policy với monthly/yearly retention (GFS)
   C. Soft delete 7 năm
   D. Snapshot

7. Cần kiểm tra DR sang region khác mà **không** ảnh hưởng người dùng. Làm gì?
   A. Failover
   B. Test failover
   C. Commit
   D. Reprotect

8. Alert rule có tự restart VM khi CPU cao không?
   A. Có, mặc định
   B. Không, cần action group → Automation Runbook/Function
   C. Có, nếu severity 0
   D. Chỉ khi bật autoscale

9. KQL: muốn đếm số event theo từng giờ. Toán tử nào?
   A. `project`
   B. `summarize count() by bin(TimeGenerated, 1h)`
   C. `where TimeGenerated > ago(1h)`
   D. `take 10`

10. Xoá backup accidentally, muốn vẫn khôi phục được. Bật gì?
    A. Immutable vault
    B. Soft delete
    C. Geo-redundant storage
    D. Retention 1 ngày

---

<details><summary>Đáp án & giải thích</summary>

1. **B.** Activity Log (control plane).
2. **B.** AMA + DCR → Log Analytics; tăng retention/archive.
3. **B.** Metric alert + action group.
4. **B.** Alert processing rule suppression.
5. **B.** Backup vault (blob/disk/AKS).
6. **B.** Backup policy GFS (monthly/yearly).
7. **B.** Test failover.
8. **B.** Alert chỉ thông báo; muốn hành động phải qua action group.
9. **B.** `summarize ... by bin(...)`.
10. **B.** Soft delete (immutable vault chống sửa/xoá nhưng không thay soft delete).

</details>
