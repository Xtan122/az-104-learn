# 03 — Storage (15–20%)

> Domain dễ ăn điểm nhất nếu thuộc **4 bảng**: redundancy, tier, SAS, quyền truy cập.

## 1. Storage Account

| Thuộc tính | Giá trị |
|---|---|
| Tên | 3–24 ký tự, **lowercase + số**, globally unique, không đổi tên |
| Kind | `StorageV2` (general-purpose v2, mặc định), `BlockBlobStorage` (premium block), `FileStorage` (premium file), `BlobStorage` (legacy) |
| Performance | Standard (HDD/SSD mix) vs Premium (SSD, chỉ LRS/ZRS) |
| Endpoint | `https://<name>.blob.core.windows.net`, `.file.`, `.queue.`, `.table.` |
| 4 dịch vụ | Blob, Files, Queue, Table |
| Network | Public (all networks) / Selected networks / **Private endpoint** / Disabled |
| Min TLS | 1.2 (khuyến nghị) |
| Allow blob public access | Nên tắt; có thể tắt ở account level, container level |

**Blob types:** Block blob (file, phổ biến), Append blob (log), Page blob (VHD/disk).
**Container:** giống folder cấp 1; tên lowercase, 3–63 ký tự. Blob có thể có "folder ảo" qua `/`.

## 2. Redundancy — bảng phải thuộc

| SKU | Copy | Phạm vi | Chịu được | Ghi chú |
|---|---|---|---|---|
| **LRS** | 3 | 1 datacenter trong 1 region | mất ổ đĩa/rack | rẻ nhất |
| **ZRS** | 3 | 3 AZ trong 1 region | mất 1 AZ | cần region hỗ trợ |
| **GRS** | 6 (3 LRS + 3 LRS ở region pair) | 2 region | mất cả region | secondary **không đọc được** |
| **GZRS** | 6 (3 ZRS + 3 LRS) | 3 AZ + region pair | mất 1 AZ hoặc 1 region | mạnh nhất |
| **RA-GRS** | 6 | như GRS | + đọc secondary | đọc secondary bất cứ lúc nào (read-only) |
| **RA-GZRS** | 6 | như GZRS | + đọc secondary | |

- Replication **bất đồng bộ** (async), RPO ~15 phút (không cần nhớ chính xác).
- Region pair do Azure định nghĩa (ví dụ Southeast Asia ↔ East Asia).
- **Failover** (account failover) là thao tác thủ công, có thể mất dữ liệu gần nhất chưa replicate; sau failover account chuyển sang LRS ở region mới.
- Premium performance chỉ hỗ trợ **LRS/ZRS** (không GRS).

**Bẫy:** "ứng dụng cần đọc dữ liệu ở region thứ 2 khi region chính chết" → **RA-GRS/RA-GZRS**, không phải GRS.
"Chịu mất 1 zone, rẻ nhất" → **ZRS**.

## 3. Access tier (Blob)

| Tier | Dùng khi | Min storage | Ghi chú |
|---|---|---|---|
| **Hot** | truy cập thường xuyên | — | chi phí lưu cao, truy cập thấp |
| **Cool** | ít truy cập, ≥30 ngày | 30 ngày | early deletion fee nếu xoá sớm |
| **Cold** | rất ít, ≥90 ngày | 90 ngày | rẻ hơn Cool, latency cao hơn |
| **Archive** | lưu trữ, ≥180 ngày | 180 ngày | **offline**, rehydrate mất **giờ** (standard) hoặc <15 phút (high priority, đắt) |

- Tier đặt ở **account level** (default) hoặc **blob level** (override).
- **Lifecycle management**: rule chạy **1 lần/ngày**, có thể tier hoặc delete.
- Rule điều kiện: `daysAfterModificationGreaterThan`, `daysAfterCreationGreaterThan`, `daysAfterLastAccessTimeGreaterThan` (cần bật access tracking), `prefixMatch`.
- Actions: `tierToCool`, `tierToCold`, `tierToArchive`, `delete`, `enableAutoTierToHotFromCool`.

```json
{
  "rules": [{
    "name": "archive-old",
    "enabled": true,
    "type": "Lifecycle",
    "definition": {
      "filters": { "blobTypes": ["blockBlob"], "prefixMatch": ["logs/"] },
      "actions": {
        "baseBlob": {
          "tierToCool": { "daysAfterModificationGreaterThan": 30 },
          "tierToArchive": { "daysAfterModificationGreaterThan": 180 },
          "delete": { "daysAfterModificationGreaterThan": 365 }
        }
      }
    }
  }]
}
```

**Bẫy:** Archive **không đọc trực tiếp được** — phải rehydrate (copy sang Hot/Cool) trước.

## 4. Bảo mật truy cập — phần hay ra thi nhất

### 4.1 Authorization options

| Cách | Ai dùng | Ghi chú |
|---|---|---|
| **Entra ID (RBAC)** | User/app trong tenant | Tốt nhất; cần role **data plane** như `Storage Blob Data Reader` |
| **Shared Key (access key)** | App legacy, script | 2 key/account, rotate được; key = full quyền |
| **SAS** | Chia sẻ giới hạn thời gian/quyền | Xem bảng dưới |
| **Anonymous/public** | Blob public | Nên tắt |

**Bẫy:** `Contributor` trên storage account **không** đọc được blob. Cần `Storage Blob Data Reader/Contributor`. Đây là câu hỏi rất phổ biến.

### 4.2 SAS

| Loại | Ký bằng | Phạm vi | Max thời gian | Thu hồi |
|---|---|---|---|---|
| Account SAS | Account key | Nhiều service trong account | tùy | rotate key |
| Service SAS | Account key | 1 service (blob/file/queue/table) | tùy | **stored access policy** |
| **User delegation** | **Entra ID** (delegation key) | Blob (container/blob) | **7 ngày** | revoke delegation key / policy |

**Stored access policy** (`storedAccessPolicy`): đặt trên container/file share/queue/table, tối đa **5** policy, định nghĩa `permissions` + `start` + `expiry`. SAS tham chiếu policy qua `policyId`.
→ Muốn **thu hồi ngay** SAS đã phát: sửa/xoá stored access policy. Rotate key ảnh hưởng **mọi** SAS + app đang dùng key.

**Least privilege:** user delegation SAS + read-only + expiry ngắn.

### 4.3 Storage firewall & private access

| | Service endpoint | Private endpoint |
|---|---|---|
| Cơ chế | Bật trên **subnet**, traffic đến PaaS qua Azure backbone | Tạo **NIC + private IP** trong subnet, map tới resource |
| DNS | Không cần đổi | Cần **Private DNS zone** `privatelink.blob.core.windows.net` (hoặc DNS tùy chỉnh) |
| Chặn public | Vẫn có thể bật "Selected networks" | Có thể **disable public access** hoàn toàn |
| Nguồn IP thấy bởi storage | IP private của VM (qua VNet) | IP private của PE |
| Dùng khi | Nhanh, rẻ, giới hạn subnet | Cần private IP thật, on-prem qua VPN/ER, chặt nhất |

- Firewall: `Selected networks` → thêm VNet/subnet (cần service endpoint) hoặc IP range. Có "Allow trusted Microsoft services" (hữu ích cho backup, nhưng **không** cho mọi service).
- Khi bật private endpoint: vẫn phải cấu hình **DNS** để `st<name>.blob.core.windows.net` resolve về private IP; nếu không, app vẫn đi public và bị chặn.

### 4.4 Encryption
- **SSE** mặc định cho mọi storage account (AES-256), platform-managed key.
- **CMK**: dùng Key Vault, gán managed identity cho account.
- **Infrastructure encryption**: double encryption, bật lúc tạo account.
- **Scope**: account level (mọi service) hoặc container level (blob).
- Client-side encryption (app tự mã hoá trước khi upload) — biết khái niệm.

## 5. Azure Files

| | Standard file share | Premium file share |
|---|---|---|
| Media | HDD | SSD |
| Protocol | SMB 3.x, REST | SMB 3.x, **NFS 4.1** |
| Redundancy | LRS/ZRS/GRS/GZRS | LRS/ZRS |
| Dùng | share chung, lift-and-shift | workload IOPS cao, Linux NFS |

- **SMB** port 445 — nhiều ISP chặn → dùng VPN/ExpressRoute/private endpoint.
- **Identity-based access**:
  - On-prem AD DS (join domain) → gán NTFS permission.
  - **Entra Domain Services** (managed domain).
  - **Entra Kerberos** cho hybrid user (cần Entra Connect + device/AD).
  - Không dùng được "Entra ID thuần" cho SMB ACL theo kiểu AD.
- **Snapshot** (share-level, read-only), **soft delete** (retention 1–365 ngày), **previous versions**.
- **Azure File Sync**: agent trên Windows Server, **sync group** (cloud endpoint + server endpoints), **cloud tiering** (file cũ để lại cloud, giữ stub), cần 1 server làm "primary"? Không — mọi server ngang hàng nhưng cần 1 server endpoint là primary cho new namespace? (không cần nhớ).
- Giới hạn: 100 TB/share (standard), 5 TiB file? Không cần nhớ con số — nhớ "share lớn hơn blob container".

## 6. Blob features khác (nhớ 1 dòng mỗi cái)

| Feature | Ý nghĩa |
|---|---|
| **Blob versioning** | Mỗi lần ghi tạo version; khôi phục version cũ |
| **Soft delete** | Giữ blob đã xoá trong N ngày (1–365), restore được |
| **Snapshots** | Bản read-only tại thời điểm, khác versioning (không auto) |
| **Object replication** | Copy async blob giữa account (khác region), cần **versioning + change feed** ở cả 2 |
| **Change feed** | Log thay đổi blob, dùng cho replication/ETL |
| **Immutability (WORM)** | Time-based retention / legal hold, không sửa/xoá |
| **Static website** | Bật `$web` container |
| **Blob index tags** | Tag để query blob (khác metadata) |
| **Lease** | Lock blob/container để tránh ghi đồng thời |

## 7. Tools

| Tool | Dùng khi |
|---|---|
| **AzCopy** | CLI copy nhanh, hỗ trợ SAS, sync, --recursive; `azcopy copy`, `azcopy sync` |
| **Storage Explorer** | GUI, xem/upload, SAS, kết nối bằng Entra |
| **Azure Data Box** | Hàng chục TB–PB, gửi ổ vật lý; dùng khi mạng không đủ |
| **Import/Export job** | Gửi ổ cứng cho Azure |
| **AzCopy sync** | Incremental copy 1 chiều |

---

## 8. Bẫy tổng hợp

1. GRS: **không đọc** secondary. RA-GRS mới đọc được.
2. Archive: phải **rehydrate**, không đọc ngay.
3. Contributer account ≠ đọc blob → cần data-plane role.
4. SAS revoke = stored access policy, không phải xoá blob.
5. User delegation SAS max **7 ngày**, chỉ blob.
6. Storage firewall "Selected networks" cần **service endpoint** trên subnet, trừ khi dùng private endpoint.
7. Private endpoint không tự có DNS → phải link private DNS zone.
8. Lifecycle rule chạy 1 lần/ngày, không real-time.
9. Tên account: 3–24, lowercase, không gạch ngang.
10. Soft delete ≠ snapshot ≠ versioning (3 thứ khác nhau).

## 9. Tự kiểm tra

1. Cần 3 bản copy ở 3 AZ trong cùng region → SKU nào?
2. Blob 200 ngày không đụng, cần rẻ nhất mà vẫn đọc được trong 1 giờ → tier nào + tại sao không Archive?
3. App cần upload blob, không lưu key, chạy trên Azure VM → cách nào?
4. SAS 6 tháng phát cho đối tác, muốn thu hồi sau 1 tuần → làm gì?
5. VM trong subnet A cần truy cập storage không qua Internet, không cần private IP → dùng gì?
6. Muốn mount share SMB trên Windows Server on-prem, xác thực bằng AD → cần gì?
7. Vì sao `Storage Account Contributor` không đọc được blob?

<details><summary>Đáp án</summary>

1. ZRS.
2. Cool (hoặc Cold nếu ≥90 ngày); Archive phải rehydrate mất giờ.
3. Managed identity + `Storage Blob Data Contributor`.
4. Dùng service SAS gắn **stored access policy**, sửa/xoá policy.
5. Service endpoint (hoặc private endpoint nếu cần IP private).
6. Azure File Sync + identity-based access với AD DS (hoặc Entra DS), mount SMB 445.
7. RBAC control plane và data plane tách nhau.

</details>
