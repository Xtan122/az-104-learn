# Lab 05 — DNS + Service Endpoint + Private Endpoint (90')

**Mục tiêu:** tự tay làm 3 thứ hay bị nhầm nhất: private DNS zone, service endpoint, private endpoint. Kết thúc lab bạn phải giải thích được **khi nào DNS phải sửa**.

## Chuẩn bị

```bash
export RG=rg-az104-lab05
export ST=staz104lab05$RANDOM
az group create -n $RG -l southeastasia
az network vnet create -g $RG -n vnet-lab --address-prefixes 10.0.0.0/16 \
  --subnet-name snet-app --subnet-prefixes 10.0.1.0/24
az network vnet subnet create -g $RG --vnet-name vnet-lab -n snet-se  --address-prefixes 10.0.2.0/24
az network vnet subnet create -g $RG --vnet-name vnet-lab -n snet-pe  --address-prefixes 10.0.3.0/24
az network vnet subnet create -g $RG --vnet-name vnet-lab -n snet-out --address-prefixes 10.0.4.0/24

# 3 VM test (không public IP)
for pair in "vm-se snet-se" "vm-pe snet-pe" "vm-out snet-out"; do
  set -- $pair
  az vm create -g $RG -n $1 --image Ubuntu2204 --size Standard_B1s \
    --admin-username azureuser --generate-ssh-keys \
    --vnet-name vnet-lab --subnet $2 --public-ip-address "" --nsg ""
done
az vm list-ip-addresses -g $RG -o table
```

## Phần A — Private DNS zone + auto-registration

```bash
az network private-dns zone create -g $RG -n corp.az104.local
az network private-dns link vnet create -g $RG -n link-vnet-lab \
  -z corp.az104.local -v vnet-lab -e true      # -e true = auto-registration

az network private-dns record-set list -g $RG -z corp.az104.local -o table
```
Auto-registration cần vài phút. Kiểm tra từ `vm-out`:

```bash
az vm run-command invoke -g $RG -n vm-out --command-id RunShellScript \
  --scripts "nslookup vm-se.corp.az104.local || true"
```
Kỳ vọng: trả về private IP `10.0.1.4`.

**Ghi nhớ:** auto-registration chỉ cho VM trong VNet **đã link**; mỗi VNet chỉ 1 zone auto-registration.

## Phần B — Service Endpoint (không có private IP)

```bash
# 1. Bật service endpoint trên subnet
az network vnet subnet update -g $RG --vnet-name vnet-lab -n snet-se \
  --service-endpoints Microsoft.Storage

# 2. Storage account, chặn public
az storage account create -g $RG -n $ST --sku Standard_LRS --kind StorageV2 \
  --min-tls-version TLS1_2 --allow-blob-public-access false \
  --default-action Deny --bypass AzureServices
az storage container create --account-name $ST -n data --auth-mode login
echo "hello az104" > hello.txt
az storage blob upload --account-name $ST -c data -f hello.txt -n hello.txt --auth-mode login

# 3. Cho subnet snet-se đi qua firewall
SUBNET_SE=$(az network vnet subnet show -g $RG --vnet-name vnet-lab -n snet-se --query id -o tsv)
az storage account network-rule add -g $RG --account-name $ST --subnet $SUBNET_SE

# 4. Test: vm-se OK, vm-out bị chặn
az vm run-command invoke -g $RG -n vm-se --command-id RunShellScript \
  --scripts "curl -s -m 8 -o /dev/null -w 'SE:%{http_code}\n' https://$ST.blob.core.windows.net/data/hello.txt"

az vm run-command invoke -g $RG -n vm-out --command-id RunShellScript \
  --scripts "curl -s -m 8 -o /dev/null -w 'OUT:%{http_code}\n' https://$ST.blob.core.windows.net/data/hello.txt || echo OUT:BLOCKED"
```

**Quan sát DNS:** từ `vm-se`, `nslookup $ST.blob.core.windows.net` vẫn trả **public IP** — service endpoint **không** tạo private IP, chỉ đổi đường đi (backbone) và nguồn IP mà storage nhìn thấy.

## Phần C — Private Endpoint (có private IP)

```bash
ST_ID=$(az storage account show -g $RG -n $ST --query id -o tsv)

az network private-endpoint create -g $RG -n pe-blob \
  --vnet-name vnet-lab --subnet snet-pe \
  --private-connection-resource-id $ST_ID \
  --group-id blob --connection-name pec-blob

# DNS zone chuẩn cho blob
az network private-dns zone create -g $RG -n privatelink.blob.core.windows.net
az network private-dns link vnet create -g $RG -n link-pe \
  -z privatelink.blob.core.windows.net -v vnet-lab -e false

az network private-endpoint dns-zone-group create -g $RG \
  --endpoint-name pe-blob -n default \
  --private-dns-zone privatelink.blob.core.windows.net --zone-name blob

az network private-endpoint show -g $RG -n pe-blob \
  --query "customDnsConfigs" -o table
```

Kiểm chứng từ `vm-pe`:

```bash
az vm run-command invoke -g $RG -n vm-pe --command-id RunShellScript \
  --scripts "nslookup $ST.blob.core.windows.net; curl -s -m 8 -o /dev/null -w 'PE:%{http_code}\n' https://$ST.blob.core.windows.net/data/hello.txt"
```
Kỳ vọng: DNS trả `10.0.3.x` (private IP của PE), HTTP 200.

Từ `vm-out` (không có SE/PE): DNS trả public IP, curl **bị chặn** (vì storage firewall Deny).

## Thí nghiệm phá

1. Xoá `dns-zone-group` (hoặc A record) → `vm-pe` vẫn curl được nhưng DNS trả public IP → vì sao? (Gợi ý: có thể vẫn đi qua PE nếu DNS cache? Thực tế sẽ fail sau khi cache hết.)
2. Bật `--public-network-access Enabled` trên storage → `vm-out` curl được. Tại sao đây là điều nguy hiểm?
3. Dùng `--group-id file` thay vì `blob` → điều gì xảy ra? (Sai sub-resource → connection không dùng được.)

## Câu hỏi exam-style

1. On-prem cần truy cập storage qua private IP → service endpoint hay private endpoint?
2. App trong VNet gọi `stxxx.blob.core.windows.net` nhưng vẫn ra Internet dù đã có PE → thiếu gì?
3. Service endpoint có cần đổi DNS không?
4. Private endpoint có cần bật service endpoint trên subnet không?
5. Muốn 2 VNet cùng dùng 1 private endpoint → làm gì?

<details><summary>Đáp án</summary>

1. Private endpoint (qua VPN/ExpressRoute).
2. Thiếu private DNS zone/record trỏ về private IP của PE.
3. Không.
4. Không (hai cơ chế độc lập).
5. PE nằm ở 1 VNet/subnet; VNet còn lại phải peer hoặc dùng DNS/route phù hợp (hoặc tạo PE riêng cho từng VNet).

</details>

## Cleanup

```bash
az group delete -n $RG --yes --no-wait
```
