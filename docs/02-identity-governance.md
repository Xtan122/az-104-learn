# 02 — Identity & Governance (20–25%)

> Đây là domain "học thuộc là có điểm". Đừng lab quá sâu, hãy nhớ **bảng so sánh**.

## 1. Microsoft Entra ID (Azure AD cũ)

**Là gì:** identity provider (IdP) cho cloud, không phải AD DS. Không có OU, GPO, LDAP (trừ Entra Domain Services).
**Tenant:** 1 instance Entra ID gắn với 1 organization; mỗi Azure subscription trust **1 tenant**.

| Loại user | Tạo thế nào | Đăng nhập bằng | Ghi chú |
|---|---|---|---|
| Member (internal) | Tạo trong tenant / sync từ AD | UPN trong tenant | Có thể là cloud-only hoặc synced |
| Guest (external) | Invite (B2B) | Email của họ (MSA, Google, …) | Mặc định quyền rất hạn chế; vẫn gán được RBAC |
| Service principal | App registration | Client secret / certificate | Danh tính của app |
| Managed identity | Bật trên resource | Không cần credential | **System-assigned** (chết cùng resource) vs **User-assigned** (độc lập, gán nhiều resource) |

**Group:**
- **Security group** (dùng cho RBAC, license) vs **Microsoft 365 group** (có mailbox, Teams).
- Membership: **Assigned** (thêm tay) vs **Dynamic** (rule dựa trên attribute, cần Entra ID P1).
- Group lồng group: có (trừ dynamic group không lồng được? — dynamic group **không** chứa group khác).
- Không dùng group để gán **Entra directory role**? — Có, role-assignable group (cần P1).

**License:** gán trực tiếp hoặc **group-based licensing** (cần P1). Bỏ khỏi group = mất license.

**SSPR (self-service password reset):** bật cho All/Selected/None; cần **2 phương thức** (số điện thoại, email, authenticator, câu hỏi bảo mật); admin có SSPR 2 lần/ngày? Không cần nhớ con số — nhớ: **admin luôn phải dùng 2 phương thức mạnh, không dùng security questions**.

**External collaboration:** guest invite settings (anyone / member can invite / only admins), cross-tenant access settings, entitlement management (P2).

## 2. Azure RBAC

```
Management group
   └── Subscription
         └── Resource group
               └── Resource
```
- Assignment ở scope cao → **kế thừa xuống dưới**. Không có "deny" thường; **Deny assignment** chỉ do managed app/Lighthouse tạo.
- 1 identity có nhiều role → **hợp (union)** các quyền.
- Role definition: `Actions`, `NotActions`, `DataActions`, `NotDataActions`, `AssignableScopes`.
  - `NotActions` **không phải deny** — nó chỉ trừ khỏi tập Actions được phép.
- Role assignment = (security principal, role definition, scope). Có thể có **condition** (ABAC, ví dụ theo tag) — biết khái niệm.

### Built-in roles phải thuộc

| Role | Làm được | Không làm được |
|---|---|---|
| **Owner** | Mọi thứ + **gán quyền** | — |
| **Contributor** | Tạo/sửa/xoá mọi resource | **Không gán quyền**, không tạo role |
| **Reader** | Xem | Không sửa |
| **User Access Administrator** | Quản lý role assignment | Không quản lý resource |
| **Virtual Machine Contributor** | Quản lý VM | Không quản lý VNet/NIC gắn vào? (được quản lý NIC nhưng không sửa VNet) |
| **Network Contributor** | VNet, NSG, LB, IP | Không sửa VM |
| **Storage Account Contributor** | Quản lý account | **Không đọc data** (cần Storage Blob Data Reader) |
| **Storage Blob Data Reader/Contributor/Owner** | Đọc/ghi data plane | Không quản lý account |
| **Backup Contributor / Operator** | Tạo vault / chạy backup | Operator không xoá policy |
| **Monitoring Contributor** | Alert, diagnostic | — |
| **Reader and Data Access** | Đọc resource + data | — |

**Câu bẫy kinh điển:** user cần upload file vào blob nhưng **không** được xoá container → **Storage Blob Data Contributor** (data plane), không phải Contributor.

### Custom role (JSON)

```json
{
  "Name": "VM Operator Custom",
  "Description": "Start/restart VMs, khong xoa",
  "Actions": [
    "Microsoft.Compute/virtualMachines/read",
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachines/restart/action"
  ],
  "NotActions": [],
  "AssignableScopes": ["/subscriptions/<sub-id>"],
  "DataActions": []
}
```
- `AssignableScopes` **bắt buộc**; chỉ gán được trong scope đó.
- `Actions` dạng `Provider/resource/action`. Wildcard được.
- Custom role cần quyền `Microsoft.Authorization/roleDefinitions/write` (Owner/UAA).

### Managed identity — khi nào dùng
Câu "app cần truy cập Key Vault/Storage mà **không lưu credential**" → **managed identity** + RBAC role, không dùng access key/SAS.
System-assigned: 1 resource ↔ 1 identity, xoá resource là mất. User-assigned: tạo riêng, gán cho nhiều resource, sống độc lập.

## 3. Policy, Lock, Tag — bộ ba dễ lẫn

| | Azure Policy | Resource Lock | RBAC |
|---|---|---|---|
| Trả lời câu | "Resource được phép **trông thế nào**" | "Có được xoá/sửa **cái đã có** không" | "**Ai** được làm gì" |
| Đối tượng | Resource (kể cả tương lai) | Resource/RG/Subscription đã tồn tại | Identity |
| Chặn Owner? | Có (Deny) | **Có** | Không (Owner vẫn bị lock chặn) |
| Ví dụ | Chỉ cho region SEA, bắt buộc tag | Cấm xoá RG production | Cho team A Contributor ở RG A |

**Lock type:**
- `CanNotDelete` = đọc + sửa được, **không xoá**.
- `ReadOnly` = chỉ đọc, **không sửa, không xoá**.
- Lock áp ở scope cao → kế thừa xuống (xoá RG có lock thì phải xoá lock trước).
- Lock **không** chặn thay đổi data plane (vẫn ghi được blob trong account bị ReadOnly? — lock quản lý control plane; data plane thường vẫn hoạt động).

### Policy anatomy
- **Definition** (rule JSON: `if` + `then.effect`) → **Initiative** (bundle nhiều definition) → **Assignment** (scope + parameters + exclusions + enforcement mode).
- Scope: MG / Subscription / RG. Exclusion: bỏ 1 resource/RG khỏi assignment.
- **Enforcement mode: Disabled** = chỉ đánh giá compliance, không chặn (dùng để test).
- **Remediation task**: bắt buộc với `DeployIfNotExists` / `Modify` trên resource cũ (cần managed identity của assignment).

| Effect | Hành vi | Dùng khi |
|---|---|---|
| **Deny** | Chặn create/update | Bắt buộc region/tag/SKU |
| **Audit** | Cho qua, ghi non-compliant | Rollout chính sách mới |
| **Append** | Thêm field vào request (ví dụ tag) | Bổ sung property thiếu |
| **Modify** | Thêm/sửa field, có remediation | Chuẩn hoá tag, thêm setting |
| **DeployIfNotExists** | Deploy resource liên quan nếu thiếu | Tự bật diagnostic settings, NSG |
| **AuditIfNotExists** | Chỉ báo thiếu | Giám sát |
| **Disabled** | Tắt | Test |

**Bẫy:** "đảm bảo tag `costCenter` có giá trị X trên resource hiện có" → **Modify + remediation**, không phải Append (Append chỉ thêm khi chưa có, không sửa được resource cũ nếu không remediation).
"Gắn diagnostic setting cho mọi VM mới" → **DeployIfNotExists**.

## 4. Management group & Subscription

- MG: tối đa **6 cấp** (không tính root), 1 MG chỉ có **1 parent**, 1 tenant tối đa 10.000 MG.
- Mọi subscription mới nằm dưới **Tenant Root Group**.
- Policy/RBAC gán ở MG → kế thừa toàn bộ subscription con.
- **Subscription** là boundary của billing + quota + rate limit. Có thể move subscription giữa MG, chuyển billing ownership.
- **Resource group**: 1 resource chỉ thuộc **1 RG**; RG thuộc 1 subscription; RG có location (nơi lưu metadata), resource có thể ở region khác. Xoá RG = xoá tất cả.
- **Move resource**: hỗ trợ move giữa RG/subscription (cùng tenant), **không move giữa region** (phải dùng Resource Mover/recreate). Move cần **lock nguồn + đích**, và một số resource không move được (ví dụ VM có managed disk? — move được nhưng phải move kèm dependency).

## 5. Cost Management

| Công cụ | Chức năng | Bẫy |
|---|---|---|
| **Cost analysis** | Xem/group by tag, resource, service | Dữ liệu có độ trễ ~8–24h |
| **Budget** | Ngưỡng + alert email/action group | **Không chặn** resource, không tự xoá |
| **Cost alert** | Alert khi vượt ngưỡng | Khác budget (budget theo kỳ) |
| **Azure Advisor** | Recommendation: cost, security, reliability, performance, operational excellence | Cost recommendation: right-size, shutdown, reserved |
| **Tag** | Phân bổ chi phí | Tag **không kế thừa** từ RG xuống resource; phải dùng Policy để enforce |
| **Reserved instance / Savings plan** | Giảm giá cam kết | Không phải câu hỏi nặng |

**Bẫy tag:** "tag gán cho RG có tự động áp cho resource không?" → **Không**. Dùng Policy `Append`/`Modify` hoặc `az tag update --operation Merge`.

## 6. Câu hỏi tự kiểm tra (miệng, 5 phút)

1. Contributor khác Owner ở đúng 1 điểm nào?
2. User cần đọc blob nhưng không được xoá → role nào?
3. Policy effect nào để "cảnh báo nhưng không chặn"?
4. Lock nào chặn cả sửa? Ai bị chặn?
5. Tag có kế thừa từ RG không? Cách enforce?
6. Managed identity giải quyết vấn đề gì?
7. Gán Reader ở subscription, gán Contributor ở 1 RG → quyền cuối cùng ở RG đó?
8. Budget vượt ngưỡng thì chuyện gì xảy ra?

<details><summary>Đáp án</summary>

1. Owner gán được quyền (role assignment), Contributor không.
2. Storage Blob Data Contributor (hoặc custom role read+write, không delete).
3. Audit.
4. ReadOnly; chặn tất cả, kể cả Owner.
5. Không. Dùng Azure Policy (Modify/Append) hoặc script merge.
6. Truy cập resource không cần lưu credential/secret.
7. Contributor (union quyền, scope cụ thể hơn cộng thêm).
8. Chỉ gửi alert; không chặn, không xoá gì.

</details>
