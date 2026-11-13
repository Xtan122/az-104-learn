# 04 — Compute (20–25%)

> Domain nặng nhất về lượng: VM + disk + availability + VMSS + ARM/Bicep + App Service + container.

## 1. Virtual Machine

### 1.1 Chọn size
- Series: **B** (burstable, rẻ, credit CPU — lab dùng cái này), **D** (general), **E** (memory), **F** (compute), **N** (GPU), **L** (storage), **M** (large memory).
- Trong tên: `Standard_D2s_v5` = family D, **2 vCPU**, `s` = premium SSD support, `v5` generation.
- **Resize**: đổi size được khi VM stopped/deallocated (một số size yêu cầu deallocate). Resize làm **mất dữ liệu temp disk**.
- **Redeploy** = di chuyển VM sang host khác (fix lỗi host), không mất disk.
- **Move**: giữa RG/subscription được; giữa **region** phải dùng Azure Resource Mover hoặc recreate.

### 1.2 Disk

| Loại | Dùng | Đặc điểm |
|---|---|---|
| **OS disk** | Boot | Luôn có, tối đa 4 TiB (gen2), gắn cùng VM |
| **Temp disk** | Pagefile/swap | **Không bền**, mất khi deallocate/resize; không phải managed disk |
| **Data disk** | Dữ liệu | Gắn thêm, tối đa tùy size; có thể detach/attach |

| SKU | IOPS | Dùng |
|---|---|---|
| Standard HDD | thấp | backup, test, rẻ |
| Standard SSD | trung bình | web server nhỏ |
| **Premium SSD** | cao | production, SLA 99,9% cho single VM |
| **Premium SSD v2** | rất cao, cấu hình IOPS/throughput độc lập | production hiện đại; **không dùng làm OS disk** |
| **Ultra Disk** | cực cao | DB lớn, cần zone |

- **Managed disk** (mặc định) vs unmanaged (storage account VHD — legacy).
- **Snapshot**: read-only copy tại thời điểm; **incremental** (mặc định) hoặc full.
- **Disk encryption**:
  - SSE mặc định (platform-managed key).
  - **ADE (Azure Disk Encryption)** = BitLocker/DM-Crypt trong guest OS, cần Key Vault.
  - **Encryption at host** = mã hoá ở host, bật lúc tạo/trên VM.
  - **CMK** qua Disk Encryption Set.
  - Câu hỏi: "mã hoá cả OS và data disk bằng key của công ty" → CMK + Disk Encryption Set, hoặc ADE + Key Vault.

### 1.3 Availability

| | Availability set | Availability zone |
|---|---|---|
| SLA | **99,95%** | **99,99%** |
| Chống | rack failure + maintenance | datacenter failure |
| Cơ chế | **Fault domain** ≤3, **Update domain** ≤20 | 3 zone vật lý/region |
| Phạm vi | trong 1 datacenter cluster | trong 1 region |
| Tạo sau | Không | Không |

- Single VM dùng **Premium SSD** → SLA 99,9%. Standard disk → 99,5%.
- 2+ VM trong availability set hoặc 2+ zone → SLA cao hơn.
- **Zone-redundant** service (LB, App Gateway, storage ZRS) tự chịu zone.

### 1.4 VMSS (Virtual Machine Scale Sets)

| | Uniform | Flexible |
|---|---|---|
| Model | 1 VM model, tất cả giống nhau | Nhiều model/VM mix, gần như availability set + autoscale |
| Dùng | stateless web tier | workload hỗn hợp, migration dần |
| Upgrade policy | Manual / Automatic / Rolling | Manual / Automatic / Rolling |

- **Autoscale**: min/max/default instance count + rules.
  Rule = metric + operator + threshold + **duration** (thời gian trung bình) + **action** (scale out/in N) + **cooldown** (mặc định 5 phút).
- Scale **out** thêm instance, **up** đổi size (scale up/down chỉ thủ công với VMSS? — VMSS có thể đổi SKU nhưng không phải autoscale).
- Câu hỏi: "CPU > 70% trong 10 phút thì thêm 1 instance" → autoscale rule với duration 10m.
- **Overprovisioning**: mặc định bật, tạo nhiều VM hơn cần rồi xoá bớt để tăng tốc (tốn thêm chút tiền).

## 2. ARM template & Bicep

### 2.1 Cấu trúc ARM (JSON)

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "vmName": { "type": "string", "defaultValue": "vm-demo" },
    "location": { "type": "string", "defaultValue": "[resourceGroup().location]" }
  },
  "variables": { "nicName": "[concat(parameters('vmName'), '-nic')]" },
  "resources": [
    {
      "type": "Microsoft.Network/networkInterfaces",
      "apiVersion": "2023-09-01",
      "name": "[variables('nicName')]",
      "location": "[parameters('location')]",
      "properties": { }
    }
  ],
  "outputs": {
    "nicId": { "type": "string", "value": "[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]" }
  }
}
```

Phải nhận diện được:
- `parameters()` / `variables()` / `resourceGroup()` / `subscription()` / `concat()` / `resourceId()` / `reference()`.
- `dependsOn` = thứ tự phụ thuộc (không bắt buộc nếu dùng `resourceId` reference, nhưng đề hay hỏi).
- `mode`: `Incremental` (mặc định) vs `Complete` (xoá resource không có trong template — **nguy hiểm**).
- **Nested template** / linked template.
- `apiVersion` bắt buộc cho mỗi resource.

### 2.2 Bicep

```bicep
param location string = resourceGroup().location
param vnetName string = 'vnet-hub'
var subnetName = 'snet-app'

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    subnets: [
      { name: subnetName, properties: { addressPrefix: '10.0.1.0/24' } }
    ]
  }
}

output vnetId string = vnet.id
```
- `param` (có default/`@secure()`), `var`, `resource`, `module`, `output`, `targetScope` (`resourceGroup` mặc định, `subscription`, `managementGroup`, `tenant`).
- So với ARM: ngắn hơn, không cần `[ ]`, không cần `dependsOn` (tự suy ra từ tham chiếu symbolic name).
- **Decompile**: `az bicep decompile --file template.json` (có thể lỗi, cần sửa).
- **Build**: `az bicep build --file main.bicep` → JSON.

### 2.3 Lệnh deploy

```bash
az deployment group create -g rg-lab -f main.bicep -p location=southeastasia
az deployment group what-if -g rg-lab -f main.bicep        # xem trước thay đổi
az deployment group validate -g rg-lab -f main.bicep
az deployment sub create -l southeastasia -f main.bicep     # scope subscription
az group export -n rg-lab > exported.json                   # export resource hiện có
az deployment group list -g rg-lab -o table
```

**Bẫy:** `what-if` không đảm bảo deploy thành công; `validate` kiểm tra schema/quota nhưng không kiểm tra runtime.

## 3. App Service

### 3.1 Plan

| Tier | Scale | Slot | Custom domain/TLS | Autoscale | VNet integration |
|---|---|---|---|---|---|
| Free/Shared | 1 | ❌ | hạn chế | ❌ | ❌ |
| Basic | 3 | ❌ | ✅ | ❌ | ✅ (limited) |
| **Standard** | 10 | ✅ | ✅ | ✅ | ✅ |
| Premium v2/v3 | 30/100 | ✅ | ✅ | ✅ | ✅ |
| Isolated | dedicated ASE | ✅ | ✅ | ✅ | ✅ |

- **Scale up** = đổi tier/size (nhiều CPU/RAM). **Scale out** = thêm instance (autoscale).
- Autoscale theo schedule hoặc metric (CPU, memory, queue length, HTTP queue).
- **Deployment slot**: chỉ Standard+; slot là app riêng có hostname `app-staging.azurewebsites.net`; swap = tráo nội dung giữa 2 slot (warm-up rồi swap).
- **Slot-sticky setting**: app setting/connection string đánh dấu "deployment slot setting" **không** theo swap (ví dụ `DB=staging`).

### 3.2 Networking & TLS
- **Inbound**: access restrictions (IP allowlist), private endpoint, App Service Environment (isolated).
- **Outbound**: **VNet integration** (subnet dedicated, delegation `Microsoft.Web/serverFarms`), NAT gateway cho outbound IP tĩnh.
- **Custom domain**: verify (CNAME/TXT), bind TLS. **Managed certificate** free (chỉ Standard+, không wildcard), hoặc upload PFX.
- **TLS**: SNI SSL (nhiều cert/1 IP), IP-based SSL (cần App Service Environment? — IP-based yêu cầu Standard+ và 1 IP).
- **Backup**: cần storage account; backup cả file + DB (nếu cấu hình connection string); restore tạo app mới hoặc overwrite.
- **Deployment**: zip deploy, GitHub Actions, FTP (nên tắt), `az webapp deploy`.
- **App Service plan** chứa nhiều app → mọi app chia sẻ resource của plan.

## 4. Containers

| | ACR | ACI | Container Apps | AKS |
|---|---|---|---|---|
| Là gì | Registry image | Chạy 1 container group | Serverless container platform | Kubernetes managed |
| Orchestration | — | Không | Có (revisions, scale) | Có (full K8s) |
| Scale to zero | — | Không | **Có** | Có (KEDA/node autoscale) |
| Dùng khi | Lưu image | Job ngắn, burst, test | Microservices, event-driven | Workload K8s phức tạp |
| Trong objectives | ✅ | ✅ | ✅ | ❌ overview |

**ACR**: SKU Basic/Standard/Premium (Premium có geo-replication, private link, content trust). `admin account` = dùng username/password (nên dùng managed identity thay thế).
**ACI**: container group (1+ container chia sẻ network/volume), `restartPolicy` (Always/OnFailure/Never), public IP + DNS name label, không autoscale.
**ACA**: environment + revision + ingress; scale rule theo HTTP/KEDA; Dapr optional; không quản lý node.

## 5. Câu hỏi tự kiểm tra

1. Cần SLA 99,99% cho web tier 2 VM → cách bố trí?
2. VM bị chậm, cần thêm RAM tạm thời → scale up hay out?
3. Data trên temp disk có mất khi stop (deallocate) không?
4. Template ARM muốn xoá resource không khai báo → `mode` nào?
5. App cần staging URL trước khi swap → tier tối thiểu?
6. Setting nào không bị swap?
7. Container chạy job 10 phút rồi exit, rẻ nhất → dịch vụ nào?
8. Đổi size VM có làm mất data disk không?

<details><summary>Đáp án</summary>

1. 2 VM ở 2 availability zone + Standard LB.
2. Scale up (đổi size), vì cần RAM chứ không cần thêm instance.
3. Có, temp disk mất.
4. `Complete`.
5. Standard.
6. Deployment slot setting (sticky).
7. ACI (restart policy OnFailure/Never).
8. Không, chỉ temp disk mất.

</details>
