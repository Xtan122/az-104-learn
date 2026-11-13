# Lab 07 — Storage toàn tập (150' = 2 buổi)

**Mục tiêu:** account + blob + lifecycle + SAS/stored access policy + Azure Files. Làm phần A buổi 6, phần B buổi 7.

## Chuẩn bị

```bash
export RG=rg-az104-lab07
export ST=staz104lab07$RANDOM
az group create -n $RG -l southeastasia
az storage account create -g $RG -n $ST --sku Standard_LRS --kind StorageV2 \
  --min-tls-version TLS1_2 --allow-blob-public-access false
az storage container create --account-name $ST -n data --auth-mode login
az storage container create --account-name $ST -n logs --auth-mode login
```

---

# Phần A — Blob, tier, versioning, lifecycle

## A1. Upload + AzCopy

```bash
mkdir -p sample && for i in $(seq 1 20); do echo "file $i" > sample/file$i.txt; done
azcopy login --identity 2>/dev/null || azcopy login   # hoặc dùng SAS bên dưới
# Cách chắc chắn nhất trong lab: dùng SAS
SAS=$(az storage container generate-sas --account-name $ST -n data \
  --permissions acdlrw --expiry 2026-12-01 --auth-mode login --as-user -o tsv)
azcopy copy './sample/*' "https://$ST.blob.core.windows.net/data/?$SAS" --recursive
azcopy list "https://$ST.blob.core.windows.net/data/?$SAS"
```

## A2. Versioning + soft delete

```bash
az storage account blob-service-properties update -g $RG --account-name $ST \
  --enable-versioning true \
  --enable-delete-retention true --delete-retention-days 7

echo "v2" > sample/file1.txt
az storage blob upload --account-name $ST -c data -f sample/file1.txt -n file1.txt --auth-mode login --overwrite

az storage blob list --account-name $ST -c data --include v --auth-mode login -o table
```
Portal: container → file1.txt → **Show versions** → restore version cũ.

## A3. Lifecycle rule

```bash
cat > lifecycle.json <<'EOF'
{
  "rules": [
    {
      "enabled": true,
      "name": "tier-and-delete",
      "type": "Lifecycle",
      "definition": {
        "filters": { "blobTypes": ["blockBlob"], "prefixMatch": ["logs/"] },
        "actions": {
          "baseBlob": {
            "tierToCool": { "daysAfterModificationGreaterThan": 30 },
            "tierToArchive": { "daysAfterModificationGreaterThan": 90 },
            "delete": { "daysAfterModificationGreaterThan": 365 }
          }
        }
      }
    }
  ]
}
EOF
az storage account management-policy create -g $RG --account-name $ST --policy @lifecycle.json
az storage account management-policy show -g $RG --account-name $ST
```
**Lưu ý:** rule chỉ chạy 1 lần/ngày, và **không** áp dụng hồi tố ngay — đừng chờ trong lab. Kiểm tra bằng "Run now" trên portal nếu có.

## A4. Đổi tier + so sánh

```bash
az storage blob update --account-name $ST -c data -n file2.txt --tier Cool --auth-mode login
az storage blob show --account-name $ST -c data -n file2.txt --query "properties.accessTier" -o tsv
# Archive rồi thử đọc → phải rehydrate
az storage blob update --account-name $ST -c data -n file3.txt --tier Archive --auth-mode login
az storage blob download --account-name $ST -c data -n file3.txt -f /tmp/x --auth-mode login
# Kỳ vọng: lỗi/không đọc được → phải set-tier Hot/Cool để rehydrate
az storage blob set-tier --account-name $ST -c data -n file3.txt --tier Hot --auth-mode login --rehydrate-priority Standard
```

---

# Phần B — SAS, stored access policy, Azure Files

## B1. User delegation SAS (Entra, max 7 ngày)

```bash
az storage blob generate-sas --account-name $ST -c data -n file1.txt \
  --permissions r --expiry 2026-11-20 --auth-mode login --as-user -o tsv
```
Copy URL và test:

```bash
curl -s -o /dev/null -w "%{http_code}\n" "https://$ST.blob.core.windows.net/data/file1.txt?<SAS>"
# 200
```

Thử tạo SAS 30 ngày → **lỗi** (quá 7 ngày).

## B2. Stored access policy (cách thu hồi SAS)

```bash
KEY=$(az storage account keys list -g $RG -n $ST --query "[0].value" -o tsv)

az storage container policy create --account-name $ST -n data \
  --name readonly --permissions r \
  --start 2026-11-13T00:00:00Z --expiry 2027-01-01T00:00:00Z \
  --auth-mode key --account-key "$KEY"

SAS2=$(az storage blob generate-sas --account-name $ST -c data -n file1.txt \
  --policy-name readonly --account-key "$KEY" -o tsv)

curl -s -o /dev/null -w "before revoke: %{http_code}\n" \
  "https://$ST.blob.core.windows.net/data/file1.txt?$SAS2"

# Thu hồi: xoá policy
az storage container policy delete --account-name $ST -n data --name readonly \
  --account-key "$KEY"

curl -s -o /dev/null -w "after revoke: %{http_code}\n" \
  "https://$ST.blob.core.windows.net/data/file1.txt?$SAS2"
# Kỳ vọng: 403
```
→ Đây là câu trả lời cho "làm sao thu hồi SAS mà không rotate key".

## B3. Access key vs Entra

```bash
# Chứng minh Contributor không đọc được data (nếu bạn có user Contributor)
az storage blob list --account-name $ST -c data --auth-mode key --account-key "$KEY" -o table   # OK
# --auth-mode login với role Contributor (không có data role) → 403
```
Nhớ: **control plane ≠ data plane**.

## B4. Azure Files

```bash
az storage share create --account-name $ST -n share1 --quota 5 --auth-mode key --account-key "$KEY"
echo "hello files" > share.txt
az storage file upload --account-name $ST -n share1 -s share.txt --auth-mode key --account-key "$KEY"
az storage file list --account-name $ST -n share1 --auth-mode key --account-key "$KEY" -o table

# Snapshot share
az storage share snapshot --account-name $ST -n share1 --account-key "$KEY"
az storage share list --account-name $ST --include-snapshot --account-key "$KEY" -o table
```

Mount SMB (làm trên Windows/VM, không phải máy Linux của bạn nếu ISP chặn 445):

```powershell
net use Z: \\<st>.file.core.windows.net\share1 /user:Azure\<st> <KEY>
```

Portal → share1 → **Connect** để lấy script mount cho Windows/Linux/macOS.

## B5. Storage firewall (ôn lại lab 5)

```bash
az storage account update -g $RG -n $ST --default-action Deny --bypass AzureServices
az storage account show -g $RG -n $ST --query networkRuleSet -o json
# Từ máy bạn: az storage blob list ... --auth-mode login → bị chặn
# Sửa: thêm IP của bạn
az storage account network-rule add -g $RG --account-name $ST --ip-address $(curl -s ifconfig.me)
```

## Câu hỏi exam-style

1. Blob không truy cập 100 ngày, cần rẻ nhất nhưng vẫn đọc được trong vài giờ → tier?
2. Đối tác cần đọc 1 blob trong 30 ngày, có thể thu hồi → loại SAS nào + cơ chế?
3. App trên VM cần ghi blob, không lưu key → cách nào?
4. User có Contributor storage account nhưng không đọc blob → vì sao?
5. Cần mount share SMB cho 50 user on-prem, dùng AD → giải pháp?
6. Object replication cần bật gì ở 2 account?
7. Vì sao lifecycle không xoá file ngay sau khi bật?

<details><summary>Đáp án</summary>

1. Cool (hoặc Cold nếu ≥90 ngày; không Archive vì phải rehydrate lâu).
2. Service SAS + **stored access policy** (hoặc user delegation SAS + revoke delegation key).
3. Managed identity + `Storage Blob Data Contributor`.
4. RBAC control plane và data plane tách biệt.
5. Azure Files + Azure File Sync + identity-based access (AD DS/Entra DS).
6. Blob versioning + change feed ở cả source và destination.
7. Rule chạy theo lịch 1 lần/ngày và đánh giá theo ngày.

</details>

## Cleanup

```bash
az group delete -n $RG --yes --no-wait
```
