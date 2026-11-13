# Lab 08 — VM, disk, VMSS, ARM/Bicep (120')

**Mục tiêu:** tạo VM có zone, gắn data disk, resize, tạo VMSS autoscale, deploy ARM template và sửa template.

## Chuẩn bị

```bash
export RG=rg-az104-lab08
az group create -n $RG -l southeastasia
az network vnet create -g $RG -n vnet-lab --address-prefixes 10.0.0.0/16 \
  --subnet-name snet-app --subnet-prefixes 10.0.1.0/24
```

## Bước 1 — VM + zone + data disk

```bash
az vm create -g $RG -n vm-lab --image Ubuntu2204 --size Standard_B1s \
  --admin-username azureuser --generate-ssh-keys \
  --vnet-name vnet-lab --subnet snet-app --zone 1

az vm disk attach -g $RG --vm-name vm-lab --name disk-data --new --size-gb 32 --sku Premium_LRS
az vm show -g $RG -n vm-lab --query "storageProfile.dataDisks" -o table

# Resize (deallocate trước)
az vm deallocate -g $RG -n vm-lab
az vm resize -g $RG -n vm-lab --size Standard_B2s
az vm start -g $RG -n vm-lab
az vm show -g $RG -n vm-lab --query "hardwareProfile.vmSize" -o tsv
```
**Quan sát:** temp disk mất dữ liệu sau deallocate. Data disk còn.

## Bước 2 — Snapshot disk

```bash
DISK_ID=$(az disk show -g $RG -n disk-data --query id -o tsv)
az snapshot create -g $RG -n snap-data --source $DISK_ID --sku Standard_LRS
az snapshot show -g $RG -n snap-data --query "{size:diskSizeGb,time:timeCreated}" -o json
```

## Bước 3 — VMSS + autoscale

```bash
az vmss create -g $RG -n vmss-web \
  --image Ubuntu2204 --instance-count 2 --vm-sku Standard_B1s \
  --admin-username azureuser --generate-ssh-keys \
  --vnet-name vnet-lab --subnet snet-app \
  --upgrade-policy-mode automatic \
  --load-balancer "" --public-ip-address ""

az vmss list-instances -g $RG -n vmss-web -o table

az monitor autoscale create -g $RG \
  --resource vmss-web --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --min-count 2 --max-count 4 --count 2

az monitor autoscale rule create -g $RG --autoscale-name vmss-web \
  --condition "Percentage CPU > 70 avg 5m" --scale out 1

az monitor autoscale rule create -g $RG --autoscale-name vmss-web \
  --condition "Percentage CPU < 30 avg 10m" --scale in 1
```

Scale thủ công để thấy instance mới:

```bash
az vmss scale -g $RG -n vmss-web --new-capacity 4
az vmss list-instances -g $RG -n vmss-web -o table
```

## Bước 4 — Deploy ARM template

```bash
cat iac/arm/vm-simple.json   # đọc trước: parameters, resources, outputs

az deployment group validate -g $RG -f iac/arm/vm-simple.json \
  -p adminPassword='Az104!LabPassw0rd'

az deployment group what-if -g $RG -f iac/arm/vm-simple.json \
  -p adminPassword='Az104!LabPassw0rd'

az deployment group create -g $RG -f iac/arm/vm-simple.json \
  -p adminPassword='Az104!LabPassw0rd' \
  -p vmName=vm-from-arm

az deployment group show -g $RG -n vm-simple -o json
```

## Bước 5 — Sửa template (bắt buộc)

Mở `iac/arm/vm-simple.json`, đổi:
- `vmSize` thành `Standard_B2s`
- thêm tag `env: lab`

Deploy lại (cùng tên deployment sẽ tạo deployment mới):

```bash
az deployment group create -g $RG -n vm-simple-v2 -f iac/arm/vm-simple.json \
  -p adminPassword='Az104!LabPassw0rd' -p vmName=vm-from-arm
```

## Bước 6 — Export & Bicep

```bash
az group export -n $RG > exported.json
az bicep decompile --file exported.json
# File exported.bicep sinh ra — đọc và tìm 3 lỗi/thứ cần sửa (thường là API version, dependsOn, property lạ)

az bicep build --file iac/bicep/vnet-peering.bicep
```

## Câu hỏi exam-style

1. Cần SLA 99,99% cho VM → làm gì?
2. Đổi size VM mất gì?
3. Template muốn xoá mọi resource không khai báo → `mode` nào?
4. `dependsOn` dùng để làm gì? Bicep có cần không?
5. Muốn thêm 1 data disk vào template có sẵn → sửa phần nào?
6. `what-if` khác `validate` thế nào?
7. VMSS cần scale theo lịch 8h sáng → dùng gì?

<details><summary>Đáp án</summary>

1. Đặt VM ở availability zone (2+ zone lý tưởng).
2. Temp disk (và phải deallocate trước).
3. `Complete`.
4. Thứ tự tạo resource; Bicep tự suy ra từ symbolic reference.
5. `resources` → `Microsoft.Compute/virtualMachines` → `properties.storageProfile.dataDisks` + disk resource.
6. `validate` kiểm schema/quota; `what-if` mô phỏng thay đổi so với hiện trạng.
7. Autoscale **schedule profile** (recurrence).

</details>

## Cleanup

```bash
az group delete -n $RG --yes --no-wait
```
