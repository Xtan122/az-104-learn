# Cheat sheet 1 — RBAC vs Policy vs Lock (+ cost)

## RBAC
```
MG → Subscription → RG → Resource     (kế thừa xuống, quyền cộng dồn)
```
| Role | Cho phép | Không |
|---|---|---|
| Owner | tất cả + gán role | — |
| Contributor | CRUD resource | gán role |
| Reader | xem | sửa |
| User Access Admin | gán role | CRUD resource |
| VM Contributor | quản lý VM | sửa VNet |
| Network Contributor | VNet/NSG/LB | sửa VM |
| Storage Account Contributor | quản lý account | đọc blob |
| Storage Blob Data Reader | đọc blob | quản lý account |
| Backup Operator | chạy backup/restore | xoá policy |

Custom role JSON: `Actions`, `NotActions` (không phải deny), `DataActions`, **`AssignableScopes` (bắt buộc)**.

Managed identity: system-assigned (chết cùng resource) vs user-assigned (độc lập).

## Policy
`Definition (if/then) → Initiative → Assignment (scope, params, exclusions, enforcement)`

| Effect | Việc | Dùng |
|---|---|---|
| Deny | chặn create/update | bắt region/tag/SKU |
| Audit | cho qua, báo non-compliant | rollout |
| Append | thêm field nếu thiếu | tag |
| Modify | thêm/sửa + remediation | chuẩn hoá tag |
| DeployIfNotExists | deploy resource thiếu | diagnostic settings |
| AuditIfNotExists | báo thiếu | giám sát |
| Disabled | tắt | test |

Deny > mọi thứ. Remediation task cần managed identity.

## Lock
| | CanNotDelete | ReadOnly |
|---|---|---|
| Đọc | ✅ | ✅ |
| Sửa | ✅ | ❌ |
| Xoá | ❌ | ❌ |

Lock chặn **cả Owner**. Lock ở RG → xoá RG phải xoá lock trước.

## Cost
- **Budget** = ngưỡng + alert. **Không chặn** chi tiêu.
- **Advisor** = recommendation (cost/security/reliability/performance/ops).
- **Tag không kế thừa** RG → resource. Enforce bằng Policy Modify/Append.
- Cost data trễ 8–24h.

## Câu chốt
| Yêu cầu | Đáp án |
|---|---|
| Chặn tạo resource ở region khác | Policy **Deny** |
| Cấm xoá RG production | Lock **CanNotDelete** |
| User chỉ được start/restart VM | custom role / VM Contributor |
| App đọc Key Vault không lưu secret | managed identity + RBAC |
| Cảnh báo khi vượt 500 USD | Budget |
| Tag tự động cho resource mới | Policy **Modify** |
