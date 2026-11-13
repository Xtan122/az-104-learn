# Lab 09 — App Service slot swap + container (90')

**Mục tiêu:** tạo web app, thêm staging slot, cấu hình **sticky setting**, swap; chạy container bằng ACI. Đây là lab dễ và rất sát đề.

## Chuẩn bị

```bash
export RG=rg-az104-lab09
export APP=app-az104-$RANDOM
az group create -n $RG -l southeastasia
```

## Bước 1 — Plan + Web App (PHP cho nhanh)

```bash
az appservice plan create -g $RG -n plan-lab --sku S1 --is-linux
az webapp create -g $RG -p plan-lab -n $APP --runtime "PHP:8.2"
# Nếu runtime không còn hỗ trợ: az webapp list-runtimes --os linux | grep -i php
az webapp show -g $RG -n $APP --query "{host:defaultHostName,state:state}" -o json
```

Tạo nội dung:

```bash
mkdir -p app && cat > app/index.php <<'EOF'
<?php
$slot = getenv('SLOT_NAME') ?: 'unknown';
$version = getenv('APP_VERSION') ?: 'v1';
echo "<h1>AZ-104 lab</h1><p>slot=$slot version=$version</p>";
EOF
cd app && zip -r ../app.zip . && cd ..
az webapp deploy -g $RG -n $APP --src-path app.zip --type zip
curl -s https://$APP.azurewebsites.net
```

## Bước 2 — Staging slot

```bash
az webapp deployment slot create -g $RG -n $APP --slot staging --configuration-source $APP

# Setting sticky (không theo swap) — đánh dấu "deployment slot setting"
az webapp config appsettings set -g $RG -n $APP --slot staging \
  --slot-settings SLOT_NAME=staging APP_VERSION=v2

az webapp config appsettings set -g $RG -n $APP \
  --settings APP_VERSION=v1
```

Deploy bản v2 lên staging:

```bash
cat > app/index.php <<'EOF'
<?php
$slot = getenv('SLOT_NAME') ?: 'production';
$version = getenv('APP_VERSION') ?: 'v1';
echo "<h1>AZ-104 lab</h1><p>slot=$slot version=$version</p>";
EOF
(cd app && zip -r ../app.zip .)
az webapp deploy -g $RG -n $APP --slot staging --src-path app.zip --type zip
```

Kiểm tra:

```bash
curl -s https://$APP.azurewebsites.net              # v1
curl -s https://$APP-staging.azurewebsites.net      # v2, slot=staging
```

## Bước 3 — Swap

```bash
az webapp deployment slot swap -g $RG -n $APP --slot staging --target-slot production

curl -s https://$APP.azurewebsites.net          # v2
curl -s https://$APP-staging.azurewebsites.net  # v1
```
**Quan sát:** `APP_VERSION` (sticky) đã đi theo slot, `SLOT_NAME` cũng vậy nếu là sticky. Nếu setting **không** sticky thì nó swap theo code.

## Bước 4 — Autoscale (chỉ Standard+)

```bash
az monitor autoscale create -g $RG \
  --resource plan-lab --resource-type Microsoft.Web/serverfarms \
  --min-count 1 --max-count 3 --count 1
# Lưu ý: autoscale gắn vào App Service PLAN, không phải web app
az monitor autoscale show -g $RG -n <autoscale-name> -o json
```
Portal: App Service plan → Scale out → rules.

## Bước 5 — ACI

```bash
az container create -g $RG -n aci-hello \
  --image mcr.microsoft.com/azuredocs/aci-helloworld \
  --dns-name-label aci-az104-$RANDOM --ports 80

az container show -g $RG -n aci-hello \
  --query "{fqdn:ipAddress.fqdn,state:instanceView.state}" -o json
curl -s http://<fqdn>
```

**Quan sát:** ACI không có autoscale, không có slot, không có LB. Restart policy mặc định `Always`.

## Bước 6 — ACR (tuỳ chọn, 5')

```bash
az acr create -g $RG -n acraz104$RANDOM --sku Basic --admin-enabled true
az acr list -g $RG -o table
# Build image từ Dockerfile nếu có; hoặc import image public:
az acr import -n <acr> --source mcr.microsoft.com/azuredocs/aci-helloworld:latest -t hello:v1
```

## Câu hỏi exam-style

1. Cần URL staging trước khi đưa lên production → gì?
2. Setting nào không bị swap?
3. App Service autoscale gắn vào resource nào?
4. Cần chạy container 1 lần rồi exit, không cần orchestration → dịch vụ nào?
5. Cần scale container về 0 khi không có request → dịch vụ nào?
6. Tier tối thiểu để có deployment slot?
7. Custom domain + TLS miễn phí → cần gì?

<details><summary>Đáp án</summary>

1. Deployment slot (Standard+) + swap.
2. Deployment slot setting (sticky).
3. App Service **plan**.
4. Azure Container Instances (restart policy Never/OnFailure).
5. Azure Container Apps.
6. Standard.
7. Custom domain đã verify + managed certificate (Standard+), hoặc upload PFX.

</details>

## Cleanup

```bash
az group delete -n $RG --yes --no-wait
```
