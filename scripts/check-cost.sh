#!/usr/bin/env bash
# check-cost.sh — nhìn nhanh thứ đang ngốn tiền
set -uo pipefail
az account show >/dev/null 2>&1 || { echo "Chưa login: az login"; exit 1; }

echo "=== Resource đang có (theo loại) ==="
az resource list --query "sort_by([].{name:name,type:type,rg:resourceGroup,location:location}, &type)" -o table

echo
echo "=== Resource tính tiền theo giờ (nhớ xoá!) ==="
az resource list --query "[?type=='Microsoft.Network/azureFirewalls' || type=='Microsoft.Network/bastionHosts' || type=='Microsoft.Network/applicationGateways' || type=='Microsoft.Network/virtualNetworkGateways' || type=='Microsoft.Network/publicIPAddresses' || type=='Microsoft.ContainerService/managedClusters'].{name:name,type:type,rg:resourceGroup}" -o table

echo
echo "=== VM đang chạy (allocated) ==="
az vm list -d --query "[?powerState=='VM running'].{name:name,rg:resourceGroup,size:hardwareProfile.vmSize,location:location}" -o table

echo
echo "=== 20 dòng usage gần nhất (cần quyền billing) ==="
az consumption usage list --top 20 \
  --query "[].{date:usageStart, cost:pretaxCost, service:consumedService, rg:resourceGroup}" \
  -o table 2>/dev/null || echo "(Không có quyền hoặc API không trả dữ liệu — xem portal Cost Management)"
