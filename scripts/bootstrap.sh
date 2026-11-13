#!/usr/bin/env bash
# bootstrap.sh — chuẩn bị môi trường học AZ-104
# Dùng: bash scripts/bootstrap.sh [--register]
set -uo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
say()  { printf "${BLUE}==>${NC} %s\n" "$*"; }
ok()   { printf "${GREEN} OK ${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}WARN${NC} %s\n" "$*"; }
fail() { printf "${RED}FAIL${NC} %s\n" "$*"; }

REGISTER=0
[[ "${1:-}" == "--register" ]] && REGISTER=1

# 1. az CLI
say "Kiểm tra Azure CLI"
if ! command -v az >/dev/null 2>&1; then
  fail "Chưa có az CLI. Cài:"
  echo "  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
  exit 1
fi
ok "az $(az version --query '\"azure-cli\"' -o tsv 2>/dev/null)"

# 2. Bicep
say "Kiểm tra Bicep"
if az bicep version >/dev/null 2>&1; then
  ok "$(az bicep version)"
else
  warn "Chưa có Bicep, đang cài..."
  az bicep install && ok "Đã cài Bicep"
fi

# 3. Login
say "Kiểm tra đăng nhập"
if az account show >/dev/null 2>&1; then
  ok "Đã đăng nhập: $(az account show --query user.name -o tsv)"
else
  warn "Chưa đăng nhập, mở browser..."
  az login >/dev/null
fi

SUB_ID=$(az account show --query id -o tsv)
TENANT=$(az account show --query tenantId -o tsv)
echo "  Subscription : $(az account show --query name -o tsv)"
echo "  Sub ID       : $SUB_ID"
echo "  Tenant       : $TENANT"

# 4. Register providers (tuỳ chọn, mất 1-3 phút)
if [[ $REGISTER -eq 1 ]]; then
  say "Đăng ký resource providers (chỉ cần 1 lần/subscription)"
  for p in Microsoft.Storage Microsoft.Network Microsoft.Compute \
           Microsoft.Web Microsoft.Insights Microsoft.OperationalInsights \
           Microsoft.Authorization Microsoft.PolicyInsights Microsoft.ContainerInstance \
           Microsoft.ContainerRegistry Microsoft.RecoveryServices; do
    state=$(az provider show -n "$p" --query registrationState -o tsv 2>/dev/null)
    if [[ "$state" != "Registered" ]]; then
      echo "  -> $p ($state)"
      az provider register -n "$p" --wait >/dev/null 2>&1 &
    fi
  done
  wait
  ok "Providers registered"
else
  warn "Bỏ qua đăng ký providers (chạy lại với --register nếu cần)"
fi

# 5. Resource group sandbox
say "Tạo resource group sandbox"
if az group show -n rg-az104-sandbox >/dev/null 2>&1; then
  ok "rg-az104-sandbox đã tồn tại"
else
  az group create -n rg-az104-sandbox -l southeastasia --tags purpose=az104-lab owner=student >/dev/null
  ok "Đã tạo rg-az104-sandbox (southeastasia)"
fi

# 6. Budget alert (best effort — cần quyền Cost Management)
say "Tạo budget alert 20 USD (best effort)"
START=$(date +%Y-%m-01)
END=$(date -d "+1 year" +%Y-%m-%d 2>/dev/null || date -v+1y +%Y-%m-%d)
if az consumption budget create \
     --budget-name budget-az104 \
     --amount 20 --category Cost \
     --time-grain Monthly \
     --start-date "$START" --end-date "$END" \
     --resource-group rg-az104-sandbox >/dev/null 2>&1; then
  ok "Budget 20 USD đã tạo (chỉ alert, không chặn)"
else
  warn "Không tạo được budget bằng CLI (thiếu quyền hoặc API đổi)."
  echo "     Làm trên portal: Cost Management + Billing → Budgets → Add"
fi

# 7. Kiểm tra công cụ phụ
for tool in jq curl git; do
  command -v $tool >/dev/null 2>&1 && ok "$tool có sẵn" || warn "Thiếu $tool (không bắt buộc)"
done

echo
ok "Xong. Bước tiếp theo:"
cat <<'EOF'
  1. Đọc docs/00-exam-blueprint.md và docs/01-aws-to-azure.md (20 phút)
  2. Mở PLAN.md, làm Ngày 0
  3. Đặt lịch thi 28/11 trên Pearson VUE
  4. Chạy: bash scripts/progress.sh
EOF
