# Cheat sheet 3 — Storage

## Account
- Tên: 3–24, lowercase + số, globally unique, không đổi tên.
- 4 service: blob / file / queue / table.
- Kind: StorageV2 (mặc định), BlockBlobStorage (premium), FileStorage (premium).

## Redundancy
| SKU | Copy | Phạm vi | Đọc secondary |
|---|---|---|---|
| LRS | 3 | 1 DC | — |
| ZRS | 3 | 3 AZ / 1 region | — |
| GRS | 6 | 2 region | ❌ |
| GZRS | 6 | 3 AZ + region | ❌ |
| RA-GRS | 6 | 2 region | ✅ |
| RA-GZRS | 6 | 3 AZ + region | ✅ |

Premium = LRS/ZRS only. Failover = thủ công.

## Tier
Hot · Cool (≥30d) · Cold (≥90d) · Archive (≥180d, **offline**, rehydrate giờ)
Lifecycle chạy **1 lần/ngày**. Điều kiện: `daysAfterModification`, `daysAfterLastAccess`, `prefixMatch`.

## Quyền
| Cách | Ghi chú |
|---|---|
| Entra RBAC | cần role **data plane**: Storage Blob Data Reader/Contributor/Owner |
| Access key | 2 key, full quyền, rotate được |
| SAS | account / service / **user delegation** |
| Public | nên tắt |

## SAS
| Loại | Ký bằng | Max | Thu hồi |
|---|---|---|---|
| Account | key | — | rotate key |
| Service | key | — | **stored access policy** |
| User delegation | Entra | **7 ngày** (blob) | revoke delegation key |

Stored access policy: max **5**/container, thu hồi bằng sửa/xoá policy.

## Network
- Firewall: All networks / Selected (VNet+subnet cần **service endpoint**, hoặc IP) / Private endpoint / Disabled.
- Private endpoint: NIC + private IP + DNS `privatelink.blob.core.windows.net`.
- "Allow trusted Microsoft services" ≠ mở cho mọi service.

## Files
- Standard (HDD, SMB) vs Premium (SSD, SMB + **NFS 4.1**).
- Identity: AD DS / Entra DS / Entra Kerberos (hybrid).
- Snapshot (read-only), soft delete 1–365 ngày.
- File Sync: sync group, cloud tiering, server endpoint.

## Blob features
versioning · soft delete · snapshot · object replication (cần versioning + change feed) · immutable (WORM) · lease · index tags · static website (`$web`)

## Câu chốt
| Yêu cầu | Đáp án |
|---|---|
| Chịu mất 1 AZ, rẻ | ZRS |
| Đọc được region 2 | RA-GRS / RA-GZRS |
| Blob 200 ngày, đọc trong 1h | Cool (Archive phải rehydrate) |
| Upload không lưu key | managed identity + Storage Blob Data Contributor |
| SAS 6 tháng, thu hồi sau 1 tuần | stored access policy |
| Không lộ Internet, có private IP | private endpoint + private DNS |
| Mount SMB on-prem | Azure Files + File Sync + AD DS |
| Hàng PB, mạng yếu | Data Box |
