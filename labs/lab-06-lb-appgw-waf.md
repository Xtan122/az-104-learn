# Lab 06 — Load Balancer + Application Gateway/WAF (60–90')

> ⚠️ **Cảnh báo chi phí:** App Gateway v2 ~0,25 USD/giờ + capacity unit, Bastion ~0,19 USD/giờ. Lab này có thể tốn **1–2 USD**. Làm 1 lần, xoá ngay trong buổi.

**Mục tiêu:** dựng Standard LB trước 2 VM nginx (không public IP trên VM), kiểm tra health probe; nếu còn thời gian, dựng App Gateway có WAF.

## Phần A — Standard Load Balancer (bắt buộc)

```bash
export RG=rg-az104-lab06
az group create -n $RG -l southeastasia

az network vnet create -g $RG -n vnet-lb --address-prefixes 10.0.0.0/16 \
  --subnet-name snet-web --subnet-prefixes 10.0.1.0/24

cat > cloud-init.yaml <<'EOF'
#cloud-config
package_update: true
packages: [nginx]
runcmd:
  - systemctl enable --now nginx
  - echo "Hello from $(hostname)" > /var/www/html/index.html
EOF

for i in 1 2; do
  az vm create -g $RG -n vm-web$i --image Ubuntu2204 --size Standard_B1s \
    --admin-username azureuser --generate-ssh-keys \
    --vnet-name vnet-lb --subnet snet-web \
    --public-ip-address "" --nsg "" \
    --custom-data cloud-init.yaml \
    --zone $i
done
```

Tạo LB:

```bash
az network public-ip create -g $RG -n pip-lb --sku Standard --allocation-method Static --zone 1 2 3
az network lb create -g $RG -n lb-web --sku Standard \
  --public-ip-address pip-lb \
  --frontend-ip-name fe --backend-pool-name be

az network lb probe create -g $RG --lb-name lb-web -n probe-http \
  --protocol Http --port 80 --path / --interval 5 --threshold 2

az network lb rule create -g $RG --lb-name lb-web -n rule-http \
  --protocol Tcp --frontend-port 80 --backend-port 80 \
  --frontend-ip-name fe --backend-pool-name be --probe-name probe-http

# Thêm 2 NIC vào backend pool
for i in 1 2; do
  az network nic ip-config address-pool add -g $RG \
    --nic-name vm-web${i}VMNic -n ipconfig1 \
    --lb-name lb-web --address-pool be
done
```

Test:

```bash
LB_IP=$(az network public-ip show -g $RG -n pip-lb --query ipAddress -o tsv)
for i in 1 2 3 4; do curl -s -m 5 http://$LB_IP; done
# Kỳ vọng: luân phiên "Hello from vm-web1" / "vm-web2"
```

## Phần B — Chứng minh health probe hoạt động

```bash
# Làm hỏng nginx trên vm-web1 (chỉ trong lab)
az vm run-command invoke -g $RG -n vm-web1 --command-id RunShellScript \
  --scripts "sudo systemctl stop nginx"

sleep 20
for i in 1 2 3 4; do curl -s -m 5 http://$LB_IP; done
# Kỳ vọng: chỉ còn vm-web2 (sau khi probe fail 2 lần × 5s)
```

→ **Bài học:** probe fail **không restart VM**, chỉ loại khỏi rotation. Nếu NSG deny `AzureLoadBalancer` → tất cả probe fail → 100% request fail dù app sống.

## Phần C — Internal LB (tuỳ chọn, 5 phút)

```bash
az network lb create -g $RG -n lb-internal --sku Standard \
  --vnet-name vnet-lb --subnet snet-web \
  --frontend-ip-name fe-int --backend-pool-name be-int --private-ip-address 10.0.1.100
```
Dùng cho tầng app gọi tầng DB. Frontend private IP tĩnh.

## Phần D — Application Gateway + WAF (tuỳ chọn, tốn tiền)

Làm trên portal nhanh hơn CLI (CLI cần ~15 tham số). Các bước:

1. Tạo subnet `snet-appgw` (`10.0.2.0/24`) — **không** gắn NSG chặn 80/443.
2. **Create resource → Application Gateway**:
   - Tier: **WAF V2**, Enable autoscaling.
   - Frontend: Public IP mới.
   - Listener: HTTP 80 (hoặc HTTPS 443 nếu có cert).
   - Backend pool: `vm-web1`, `vm-web2` (dùng private IP, không phải NIC).
   - Backend settings: HTTP, port 80, **custom probe** path `/`.
   - Routing rule: path-based, `/images/*` → pool phụ (nếu muốn demo).
3. **WAF**: mode **Detection** trước → gửi request chứa payload `?q=<script>alert(1)</script>` → xem log.
4. Đổi sang **Prevention** → request bị chặn 403.

Kiểm chứng:

```bash
curl -s -o /dev/null -w "%{http_code}\n" "http://<appgw-ip>/?q=<script>alert(1)</script>"
# Detection: 200 (nhưng có log), Prevention: 403
```

## Câu hỏi exam-style

1. Cần L7 path-based routing + WAF → dịch vụ nào?
2. 2 VM không public IP, cần nhận traffic Internet port 443 → kiến trúc nào?
3. LB probe fail vì NSG → rule/service tag nào bị thiếu?
4. Cần TLS termination + nhiều site trên 1 IP → LB hay App Gateway?
5. Muốn chỉ tầng web gọi được tầng API nội bộ → LB loại nào?
6. WAF mode nào chỉ log mà không chặn?

<details><summary>Đáp án</summary>

1. Application Gateway (WAF_v2).
2. Standard public LB + NSG allow 443; hoặc App Gateway.
3. `AzureLoadBalancer` (port probe), priority thấp hơn 65001.
4. App Gateway (SNI, multi-site listener).
5. Internal Load Balancer.
6. Detection.

</details>

## Cleanup (quan trọng)

```bash
az group delete -n $RG --yes --no-wait
# Kiểm tra không còn App Gateway/Bastion:
az resource list --resource-type Microsoft.Network/applicationGateways -o table
```
