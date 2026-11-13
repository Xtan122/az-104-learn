#!/usr/bin/env bash
# cleanup.sh — xoá resource group lab, tránh cháy credit
# Dùng: bash scripts/cleanup.sh [--yes] [--prefix rg-az104-]
set -uo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
say()  { printf "${BLUE}==>${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}WARN${NC} %s\n" "$*"; }
ok()   { printf "${GREEN} OK ${NC} %s\n" "$*"; }

PREFIX="rg-az104-"
AUTO=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y) AUTO=1; shift ;;
    --prefix) PREFIX="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

az account show >/dev/null 2>&1 || { echo "Chưa login: az login"; exit 1; }

say "Tìm resource group bắt đầu bằng '$PREFIX'"
mapfile -t RGS < <(az group list --query "[?starts_with(name, '$PREFIX')].name" -o tsv)

if [[ ${#RGS[@]} -eq 0 ]]; then
  ok "Không có RG nào cần xoá."
else
  printf '  %s\n' "${RGS[@]}"
fi

say "Resource đắt tiền đang chạy (kiểm tra thủ công)"
az resource list --query "[?type=='Microsoft.Network/azureFirewalls' || type=='Microsoft.Network/bastionHosts' || type=='Microsoft.Network/applicationGateways' || type=='Microsoft.Network/virtualNetworkGateways' || type=='Microsoft.ContainerService/managedClusters'].{name:name,type:type,rg:resourceGroup}" -o table 2>/dev/null || true

if [[ ${#RGS[@]} -gt 0 ]]; then
  if [[ $AUTO -eq 0 ]]; then
    echo
    read -r -p "Xoá ${#RGS[@]} resource group ở trên? (gõ 'yes'): " ans
    [[ "$ans" == "yes" ]] || { warn "Huỷ."; exit 0; }
  fi
  for rg in "${RGS[@]}"; do
    say "Đang xoá $rg ..."
    az group delete -n "$rg" --yes --no-wait
  done
  ok "Đã gửi lệnh xoá (chạy nền). Kiểm tra lại sau 5 phút: az group list -o table"
fi

say "VM còn allocated (nên deallocate nếu chưa xoá)"
az vm list -d --query "[?powerState=='VM running'].{name:name,rg:resourceGroup,size:hardwareProfile.vmSize}" -o table 2>/dev/null || true
