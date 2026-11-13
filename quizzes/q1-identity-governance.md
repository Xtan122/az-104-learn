# Q1 — Identity & Governance (10 câu / 15 phút)

1. Một nhóm 5 kỹ sư cần tạo và quản lý VM trong `rg-app`, nhưng **không** được thay đổi VNet hay NSG. Cách ít công nhất?
   A. Gán Contributor ở `rg-app`
   B. Gán Virtual Machine Contributor ở `rg-app`
   C. Tạo custom role chỉ có `Microsoft.Compute/*`
   D. Gán Owner ở subscription

2. Bạn gán role **Reader** cho user A ở scope subscription. Sau đó gán **Contributor** cho A ở `rg-prod`. Kết quả tại `rg-prod`?
   A. Chỉ Reader
   B. Chỉ Contributor
   C. Contributor (cộng dồn quyền)
   D. Không có quyền vì xung đột

3. Cần ngăn **mọi người**, kể cả Owner, xoá resource group `rg-prod` nhưng vẫn cho phép sửa resource bên trong. Chọn gì?
   A. RBAC role Reader
   B. Policy Deny
   C. Lock `CanNotDelete`
   D. Lock `ReadOnly`

4. 200 resource đã tồn tại đang thiếu tag `costCenter`. Cần tự động thêm tag mà không xoá/tạo lại. Chọn effect + hành động?
   A. Append, không cần remediation
   B. Modify + remediation task
   C. Deny + remediation
   D. AuditIfNotExists

5. Budget 50 USD/tháng đã đặt, chi phí thực tế lên 62 USD. Chuyển gì xảy ra?
   A. Resource bị dừng
   B. Subscription bị disable
   C. Chỉ có alert theo ngưỡng đã cấu hình
   D. Resource group bị xoá

6. Mời một đối tác bên ngoài vào tenant để gán role Reader cho 1 RG. Cách đúng?
   A. Tạo user mới trong tenant với domain của họ
   B. Mời guest qua B2B rồi gán role
   C. Chia sẻ access key
   D. Tạo service principal

7. Custom role JSON thiếu `AssignableScopes`. Chuyện gì xảy ra?
   A. Role dùng được cho toàn tenant
   B. Role tạo thất bại
   C. Role mặc định gán cho subscription hiện tại
   D. Role chỉ đọc

8. Công ty muốn gán license Microsoft 365 theo group, tự động khi thêm/bớt thành viên. Cần gì?
   A. Entra ID Free
   B. Entra ID P1 (group-based licensing)
   C. Entra Domain Services
   D. Azure Policy

9. Role nào cho phép gán quyền cho người khác nhưng **không** tạo/xoá resource?
   A. Owner
   B. Contributor
   C. User Access Administrator
   D. Reader

10. Policy gán ở management group `MG-Prod` với effect Deny cho phép vị trí `southeastasia`. Một subscription con tạo storage ở `eastasia`. Kết quả?
    A. Thành công
    B. Bị chặn (Deny kế thừa)
    C. Chỉ bị audit
    D. Cần remediation mới chặn

---

<details><summary>Đáp án & giải thích</summary>

1. **B.** Virtual Machine Contributor đủ quyền VM, không bao gồm sửa VNet. C là quá nhiều công, D thừa quyền.
2. **C.** Quyền cộng dồn; scope cụ thể hơn không "ghi đè" mà bổ sung.
3. **C.** CanNotDelete cho sửa nhưng chặn xoá; ReadOnly chặn cả sửa.
4. **B.** Modify thay đổi resource hiện có, cần remediation + managed identity.
5. **C.** Budget chỉ cảnh báo. Không có cơ chế tự dừng.
6. **B.** B2B guest; guest vẫn gán được RBAC.
7. **B.** `AssignableScopes` là bắt buộc.
8. **B.** Group-based licensing yêu cầu P1.
9. **C.** UAA chỉ quản lý role assignment.
10. **B.** Policy kế thừa từ MG → subscription.

</details>
