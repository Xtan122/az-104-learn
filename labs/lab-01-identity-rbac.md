# Lab 01 — Entra ID & RBAC (90')

**Mục tiêu:** tạo user/group/guest, gán role ở 2 scope, đọc "effective access", hiểu vì sao Contributor khác Owner.

## Chuẩn bị

```bash
az login
az account show --query "{sub:id, tenant:tenantId, user:user.name}" -o table
export RG=rg-az104-lab01
az group create -n $RG -l southeastasia
```

> Nếu tenant của bạn không cho tạo user (account cá nhân), dùng tenant mặc định của free account — vẫn tạo được. Nếu bị chặn, ghi lại lỗi và chuyển sang phần RBAC với user hiện có.
> **Thay `<TENANT>`** bằng tên tenant của bạn: `az account show --query tenantDefaultDomain -o tsv` (thường dạng `tencongty.onmicrosoft.com`).

## Bước 1 — Tạo group và 3 user

```bash
az ad group create --display-name grp-az104-ops --mail-nickname grp-az104-ops
az ad group show --group grp-az104-ops --query id -o tsv

for u in alice bob carol; do
  az ad user create \
    --display-name "$u az104" \
    --user-principal-name "$u-az104@<TENANT>.onmicrosoft.com" \
    --password 'Az104!LabPassw0rd' \
    --force-change-password-next-login true
done

az ad group member add -g grp-az104-ops --member-id $(az ad user show --id alice-az104@<TENANT>.onmicrosoft.com --query id -o tsv)
```

## Bước 2 — Mời guest (B2B)

```bash
az rest --method POST \
  --url "https://graph.microsoft.com/v1.0/invitations" \
  --headers "Content-Type=application/json" \
  --body '{"invitedUserEmailAddress":"your.personal@example.com","inviteRedirectUrl":"https://portal.azure.com","sendInvitationMessage":true}'
```
Portal: **Entra ID → Users → New guest user** (dễ hơn, dùng nếu CLI lỗi quyền).

## Bước 3 — Gán role ở 2 scope

```bash
SUB=$(az account show --query id -o tsv)
RG_ID=$(az group show -n $RG --query id -o tsv)
ALICE=$(az ad user show --id alice-az104@<TENANT>.onmicrosoft.com --query id -o tsv)

# Reader ở subscription
az role assignment create --assignee $ALICE --role Reader --scope /subscriptions/$SUB

# Contributor ở RG
az role assignment create --assignee $ALICE --role Contributor --scope $RG_ID

# Group nhận role Virtual Machine Contributor ở RG
az role assignment create --assignee $(az ad group show --group grp-az104-ops --query id -o tsv) \
  --role "Virtual Machine Contributor" --scope $RG_ID
```

## Bước 4 — Đọc quyền hiệu lực

```bash
az role assignment list --assignee $ALICE --all -o table
az role assignment list --scope $RG_ID -o table

# Kiểm tra bằng token (chỉ ra action được phép)
az rest --method GET \
  --url "https://management.azure.com/subscriptions/$SUB/providers/Microsoft.Authorization/permissions?api-version=2022-04-01" \
  --query "value[].actions" -o json
```

Portal: **RG → Access control (IAM) → Check access → chọn user → xem "Effective access"**.

## Kiểm chứng (ghi vào sổ lỗi)

1. Alice có Contributor ở RG và Reader ở subscription → tại RG Alice có quyền gì? Tại RG khác thì sao?
2. Alice có tạo được **role assignment** không? Thử `az role assignment create --assignee $ALICE --role Reader --scope $RG_ID` → lỗi gì?
3. Group `grp-az104-ops` có quyền gì? Thêm Bob vào group rồi kiểm tra lại.
4. Guest có thấy subscription trong portal không? (Mặc định: không, cho tới khi được gán role.)

## Câu hỏi exam-style

1. User cần tạo và quản lý VM nhưng **không** được sửa VNet → role nào?
2. Cần cấp quyền cho 200 user, dễ thu hồi nhất → cách nào?
3. Một user có Reader ở subscription và Contributor ở 1 RG. Họ xoá được resource trong RG đó không?
4. Owner ở RG có thể gán role ở subscription không?

<details><summary>Đáp án</summary>

1. Virtual Machine Contributor (không bao gồm quyền sửa VNet).
2. Gán role cho **group**, quản lý membership.
3. Có — Contributor ở RG cho phép xoá resource trong RG.
4. Không — scope assignment không vượt quá scope nơi họ có quyền gán (Owner ở RG chỉ gán trong RG).

</details>

## Cleanup

```bash
az group delete -n $RG --yes --no-wait
# Xoá user/group lab nếu muốn sạch tenant
# az ad user delete --id alice-az104@<TENANT>.onmicrosoft.com
```
