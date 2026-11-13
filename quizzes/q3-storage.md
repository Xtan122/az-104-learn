# Q3 — Storage (10 câu / 15 phút)

1. Cần 3 bản copy trải trên 3 availability zone trong cùng region. Chọn SKU?
   A. LRS
   B. ZRS
   C. GRS
   D. RA-GRS

2. Ứng dụng phải **đọc được** dữ liệu ở region thứ cấp khi region chính gặp sự cố. Chọn gì?
   A. GRS
   B. RA-GRS
   C. LRS
   D. ZRS

3. Blob không được truy cập 200 ngày, cần chi phí lưu thấp nhất nhưng vẫn phải đọc được trong vòng vài giờ. Chọn tier?
   A. Hot
   B. Cool
   C. Cold
   D. Archive

4. Đối tác cần quyền đọc 1 blob trong 30 ngày và bạn phải **thu hồi ngay** nếu cần. Cách nào?
   A. Account SAS
   B. Service SAS gắn stored access policy
   C. Public blob
   D. Chia sẻ access key

5. App chạy trên VM Azure cần ghi blob, không được lưu credential. Chọn gì?
   A. Access key trong appsettings
   B. Managed identity + Storage Blob Data Contributor
   C. SAS 1 năm
   D. Contributor role trên storage account

6. User có role **Contributor** trên storage account nhưng không đọc được blob. Vì sao?
   A. Cần bật public access
   B. RBAC control plane không cấp quyền data plane
   C. Cần access key
   D. Phải dùng SAS

7. Bạn bật storage firewall `Selected networks` và thêm subnet `snet-app`. Cần gì trên subnet để VM truy cập được?
   A. Private endpoint
   B. Service endpoint `Microsoft.Storage`
   C. NAT Gateway
   D. Public IP

8. Lifecycle rule `tierToArchive` sau 90 ngày. Blob ở ngày 91. Điều gì xảy ra?
   A. Blob bị xoá
   B. Blob chuyển Archive trong tối đa 1 ngày (rule chạy hằng ngày)
   C. Blob chuyển ngay lập tức
   D. Rule không chạy

9. Cần mount file share SMB cho server on-prem, xác thực bằng AD DS. Cần gì?
   A. Chỉ storage key
   B. Azure Files + identity-based access (AD DS/Entra DS) + kết nối mạng 445
   C. Blob container
   D. Data Box

10. Object replication giữa 2 storage account yêu cầu gì?
    A. Cùng region
    B. Blob versioning + change feed ở cả 2 account
    C. RA-GRS
    D. Public access

---

<details><summary>Đáp án & giải thích</summary>

1. **B.** ZRS = 3 copy trong 3 AZ của 1 region.
2. **B.** RA-GRS (hoặc RA-GZRS) cho đọc secondary.
3. **C.** Cold (≥90 ngày) rẻ hơn Cool; Archive phải rehydrate mất giờ và có early deletion 180 ngày.
4. **B.** Service SAS + stored access policy → xoá/sửa policy là thu hồi ngay.
5. **B.** Managed identity + data-plane role.
6. **B.** Control plane ≠ data plane.
7. **B.** Service endpoint trên subnet (hoặc private endpoint, nhưng câu hỏi nói "thêm subnet vào firewall").
8. **B.** Rule chạy 1 lần/ngày, không real-time.
9. **B.** Identity-based access + SMB 445 (qua VPN/ER nếu ISP chặn).
10. **B.** Versioning + change feed ở cả source và destination.

</details>
