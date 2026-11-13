# Lab 02 — Policy, Lock, Tag, Budget (60')

**Mục tiêu:** tạo policy chặn region + policy bắt tag, remediation, lock, tag bằng CLI, budget alert. Đây là lab "nhớ đời" cho bộ ba RBAC/Policy/Lock.

## Chuẩn bị

```bash
export RG=rg-az104-lab02
az group create -n $RG -l southeastasia
SUB=$(az account show --query id -o tsv)
RG_ID=$(az group show -n $RG --query id -o tsv)
```

## Bước 1 — Policy chặn region

```bash
# Dùng built-in definition "Allowed locations"
DEF=$(az policy definition list \
  --query "[?displayName=='Allowed locations'].id" -o tsv)

az policy assignment create \
  --name deny-non-sea \
  --display-name "Only Southeast Asia" \
  --policy "$DEF" \
  --scope $RG_ID \
  --params '{"listOfAllowedLocations":{"value":["southeastasia"]}}'
```

**Kiểm chứng:** thử tạo storage account ở `eastus`:

```bash
az storage account create -g $RG -n staz104deny001 --location eastus --sku Standard_LRS
# Kỳ vọng: RequestDisallowedByPolicy
```

→ Đây là điểm khác biệt cốt lõi so với **lock**: policy chặn **tạo mới**, lock chặn **xoá cái đã có**.

## Bước 2 — Policy bắt buộc tag (Modify + remediation)

```bash
# Built-in: "Add a tag to resources" (Append) hoặc "Inherit a tag from the resource group"
DEF_TAG=$(az policy definition list \
  --query "[?displayName=='Add a tag to resources'].id" -o tsv)

az policy assignment create \
  --name require-env-tag \
  --policy "$DEF_TAG" \
  --scope $RG_ID \
  --params '{"tagName":{"value":"env"},"tagValue":{"value":"lab"}}' \
  --mi-system-assigned \
  --location southeastasia
```

Kiểm tra: tạo 1 storage account hợp lệ rồi xem tag `env=lab` có tự xuất hiện không. Nếu policy là **Modify**, chạy remediation:

```bash
az policy remediation create --name fix-tags --policy-assignment require-env-tag
az policy state list --filter "policyAssignmentName eq 'require-env-tag'" -o table
```

## Bước 3 — Lock

```bash
az lock create -n no-delete --lock-type CanNotDelete --resource-group $RG

# Thử xoá RG → phải fail
az group delete -n $RG --yes
# Kỳ vọng: ScopeLocked

# Đổi sang ReadOnly → thử sửa tag
az lock delete -n no-delete --resource-group $RG
az lock create -n readonly --lock-type ReadOnly --resource-group $RG
az group update -n $RG --set tags.x=1
# Kỳ vọng: fail vì ReadOnly
az lock delete -n readonly --resource-group $RG
```

## Bước 4 — Tag + budget

```bash
az group update -n $RG --set tags.owner=an tags.costCenter=training
az tag list --resource-id $RG_ID -o table

az consumption budget create \
  --budget-name budget-az104 \
  --amount 20 \
  --category Cost \
  --time-grain Monthly \
  --start-date 2026-11-01 \
  --end-date 2027-11-01 \
  --resource-group $RG
```

Portal: **Cost Management + Billing → Budgets → Add** (xem cảnh báo 50/80/100%). Nhớ: budget **không chặn** gì.

## Bước 5 — Management group (đọc, không cần tạo)

```bash
az account management-group list -o table
az account management-group show --name <id> --expand --recurse
```
Nếu tenant cho phép, tạo 1 MG con và gán policy Audit lên đó, rồi quan sát resource bên dưới bị đánh giá non-compliant.

## Câu hỏi exam-style

1. Chặn user tạo VM ở region `eastus` nhưng vẫn cho phép resource cũ ở đó tồn tại → gì?
2. Ngăn xoá storage account production → gì?
3. Tự động thêm tag `owner` cho mọi resource mới → effect nào?
4. Resource đã tồn tại thiếu tag, cần sửa hàng loạt → effect nào + bước gì?
5. Budget 20 USD, vượt 20 USD thì Azure làm gì?
6. Policy gán ở management group có áp cho subscription con không?

<details><summary>Đáp án</summary>

1. Policy **Deny** với allowed locations (không phải lock, không phải RBAC).
2. Lock **CanNotDelete**.
3. **Append** (hoặc Modify).
4. **Modify** + **remediation task** (cần managed identity).
5. Chỉ gửi alert. Không chặn, không xoá.
6. Có, kế thừa xuống toàn bộ.

</details>

## Cleanup

```bash
az lock delete -n readonly --resource-group $RG 2>/dev/null
az lock delete -n no-delete --resource-group $RG 2>/dev/null
az group delete -n $RG --yes --no-wait
# Xoá policy assignment nếu giữ RG
az policy assignment delete --name deny-non-sea --scope $RG_ID
```
