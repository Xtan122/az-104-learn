# Q4 — Compute (10 câu / 15 phút)

1. Cần SLA 99,99% cho 2 web server. Cách bố trí?
   A. 2 VM trong availability set
   B. 2 VM ở 2 availability zone
   C. 1 VM size lớn
   D. 2 VM cùng host

2. Bạn deallocate VM rồi resize. Dữ liệu nào mất?
   A. OS disk
   B. Data disk
   C. Temp disk
   D. Snapshot

3. Template ARM đang dùng `mode: Complete`. Rủi ro chính?
   A. Không deploy được
   B. Xoá resource trong RG không có trong template
   C. Không tạo được tag
   D. Không hỗ trợ Bicep

4. Cần staging URL trước khi đưa app lên production. Tier tối thiểu của App Service plan?
   A. Free
   B. Basic
   C. Standard
   D. Shared

5. App setting nào **không** bị swap giữa 2 slot?
   A. Setting thường
   B. Deployment slot setting (sticky)
   C. Connection string thường
   D. Biến môi trường trong code

6. Cần chạy container 15 phút rồi exit, không cần orchestration, chi phí thấp. Chọn gì?
   A. AKS
   B. ACI với restart policy Never/OnFailure
   C. App Service
   D. VMSS

7. Autoscale rule: CPU > 70% **trung bình trong 10 phút** thì thêm 1 instance. Tham số nào thể hiện "10 phút"?
   A. Cooldown
   B. Time window / duration
   C. Evaluation frequency
   D. Instance count

8. Cần deploy template vào subscription (tạo resource group + policy), không phải vào RG. Lệnh nào?
   A. `az deployment group create`
   B. `az deployment sub create`
   C. `az group create`
   D. `az deployment mg create`

9. VMSS cần tự tăng instance 8h sáng mỗi ngày. Dùng gì?
   A. Metric rule
   B. Schedule profile (recurrence)
   C. Manual scale
   D. Availability set

10. Câu nào **không** đúng về availability set?
    A. Tối đa 3 fault domain
    B. Tối đa 20 update domain
    C. Có thể thêm VM vào set sau khi VM đã tạo
    D. SLA 99,95%

---

<details><summary>Đáp án & giải thích</summary>

1. **B.** Zone cho 99,99% (set là 99,95%).
2. **C.** Temp disk là ephemeral.
3. **B.** Complete xoá resource không khai báo — nguy hiểm.
4. **C.** Deployment slot chỉ có từ Standard.
5. **B.** Sticky/deployment slot setting.
6. **B.** ACI, restart policy Never/OnFailure.
7. **B.** Time window (duration) của điều kiện.
8. **B.** `az deployment sub create` (cần `-l`).
9. **B.** Schedule-based autoscale profile.
10. **C.** Phải gán availability set **lúc tạo** VM, không thêm sau được.

</details>
