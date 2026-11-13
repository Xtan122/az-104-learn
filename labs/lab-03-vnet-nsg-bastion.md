# Lab 03 — VNet, subnet, NSG, ASG (90')

**Mục tiêu:** dựng VNet 2 subnet, 2 VM **không có public IP**, dùng NSG chặn/mở, dùng ASG, đọc effective rules và IP flow verify. Đây là lab nền cho mọi câu networking.

## Chuẩn bị

```bash
export RG=rg-az104-lab03
az group create -n $RG -l southeastasia
az network vnet create -g $RG -n vnet-lab \
  --address-prefixes 10.0.0.0/16 \
  --subnet-name snet-app --subnet-prefixes 10.0.1.0/24
az network vnet subnet create -g $RG --vnet-name vnet-lab \
  -n snet-tools --address-prefixes 10.0.2.0/24
```

## Bước 1 — Tạo 2 VM không public IP

```bash
for vm in vm-app vm-tools; do
  subnet=snet-app; [ $vm = vm-tools ] && subnet=snet-tools
  az vm create -g $RG -n $vm \
    --image Ubuntu2204 --size Standard_B1s \
    --admin-username azureuser --generate-ssh-keys \
    --vnet-name vnet-lab --subnet $subnet \
    --public-ip-address "" --nsg ""
done

az vm list-ip-addresses -g $RG -o table
```
Ghi lại private IP: `vm-app` thường `.4`, `vm-tools` thường `.4` ở subnet khác.

## Bước 2 — NSG: chỉ cho SSH từ subnet tools

```bash
az network nsg create -g $RG -n nsg-app
az network nsg rule create -g $RG --nsg-name nsg-app -n allow-ssh-from-tools \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes 10.0.2.0/24 \
  --destination-port-ranges 22
az network nsg rule create -g $RG --nsg-name nsg-app -n allow-http \
  --priority 110 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --destination-port-ranges 80

az network vnet subnet update -g $RG --vnet-name vnet-lab -n snet-app --network-security-group nsg-app
```

**Quan sát:** `az network nsg rule list -g $RG --nsg-name nsg-app -o table` → thấy 2 rule + 6 default rule.

## Bước 3 — Cài nginx và test

```bash
az vm run-command invoke -g $RG -n vm-app --command-id RunShellScript \
  --scripts "sudo apt-get update -y >/dev/null 2>&1 && sudo apt-get install -y nginx >/dev/null 2>&1 && echo OK"

APP_IP=$(az vm list-ip-addresses -g $RG -n vm-app --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv)

# Từ vm-tools gọi sang vm-app
az vm run-command invoke -g $RG -n vm-tools --command-id RunShellScript \
  --scripts "curl -s -m 5 -o /dev/null -w '%{http_code}' http://$APP_IP"
```
Kỳ vọng: `200`.

## Bước 4 — Chặn bằng NSG rồi chẩn đoán

```bash
az network nsg rule create -g $RG --nsg-name nsg-app -n deny-http \
  --priority 90 --direction Inbound --access Deny --protocol Tcp \
  --source-address-prefixes 10.0.2.0/24 --destination-port-ranges 80

# Gọi lại → timeout
az vm run-command invoke -g $RG -n vm-tools --command-id RunShellScript \
  --scripts "curl -s -m 5 -o /dev/null -w '%{http_code}' http://$APP_IP || echo BLOCKED"
```
Kỳ vọng: `BLOCKED` (rule deny priority 90 thắng allow 110).

Chẩn đoán bằng Network Watcher:

```bash
TOOLS_IP=$(az vm list-ip-addresses -g $RG -n vm-tools --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv)
az network watcher test-ip-flow -g $RG --vm vm-tools --direction Outbound \
  --protocol TCP --local "$TOOLS_IP:40000" --remote "$APP_IP:80"
```
→ Kết quả chỉ ra `Deny` + tên rule `deny-http`. **Đây chính là dạng câu hỏi troubleshooting trong đề.**

## Bước 5 — ASG

```bash
az network asg create -g $RG -n asg-web
az network nic ip-config update -g $RG --nic-name vm-appVMNic -n ipconfig1 \
  --application-security-groups asg-web
# (tên NIC có thể khác: az network nic list -g $RG -o table)

az network nsg rule create -g $RG --nsg-name nsg-app -n allow-from-asg \
  --priority 80 --direction Inbound --access Allow --protocol Tcp \
  --source-asgs asg-web --destination-port-ranges 8080
```
→ Thay vì quản lý IP, bạn quản lý **nhóm NIC**. Khi scale thêm VM, chỉ cần gắn ASG.

## Kiểm chứng

```bash
az network nic show-effective-nsg -g $RG -n vm-appVMNic -o table
az network nsg rule list -g $RG --nsg-name nsg-app -o table
```

Trả lời:
1. Rule nào thắng khi 2 rule cùng port? Vì sao?
2. Tại sao VM không có public IP mà `az vm run-command` vẫn chạy được? (Azure agent qua control plane, không qua mạng của bạn — **không** chứng minh port 22 mở.)
3. Nếu gắn thêm NSG lên NIC với rule deny 22, inbound đánh giá thế nào?

## Câu hỏi exam-style

1. VM trong subnet có NSG allow 80, NIC có NSG deny 80 → kết quả?
2. Muốn cho phép LB health probe → rule/service tag nào?
3. Cần SSH vào VM không public IP, không mở 22 → dịch vụ nào?
4. NSG có stateful không? Có cần rule outbound cho response không?
5. 3 VM web cần cùng bộ rule, thay đổi linh hoạt → dùng gì?

<details><summary>Đáp án</summary>

1. Bị chặn — cả 2 NSG phải allow.
2. `AzureLoadBalancer` (default rule 65001).
3. Azure Bastion (hoặc VPN/ExpressRoute/Just-in-time).
4. Có, stateful, không cần rule return.
5. ASG (Application Security Group).

</details>

## Cleanup

```bash
az group delete -n $RG --yes --no-wait
```
