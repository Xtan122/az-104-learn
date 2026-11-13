# Lab 04 — Peering, UDR, NVA, hub-spoke (90')

**Mục tiêu:** chứng minh peering **non-transitive**, rồi làm cho spoke1 → spoke2 thông qua NVA bằng UDR + IP forwarding. Đây là lab quan trọng nhất của repo (câu hỏi tình huống rất hay ra).

## Chuẩn bị — 3 VNet

```bash
export RG=rg-az104-lab04
az group create -n $RG -l southeastasia

# hub 10.0.0.0/16  (snet-nva 10.0.1.0/24)
az network vnet create -g $RG -n vnet-hub --address-prefixes 10.0.0.0/16 \
  --subnet-name snet-nva --subnet-prefixes 10.0.1.0/24
# spoke1 10.1.0.0/16 (snet-app 10.1.1.0/24)
az network vnet create -g $RG -n vnet-spoke1 --address-prefixes 10.1.0.0/16 \
  --subnet-name snet-app --subnet-prefixes 10.1.1.0/24
# spoke2 10.2.0.0/16
az network vnet create -g $RG -n vnet-spoke2 --address-prefixes 10.2.0.0/16 \
  --subnet-name snet-app --subnet-prefixes 10.2.1.0/24
```

## Bước 1 — Peering 2 chiều hub ↔ mỗi spoke (4 object)

```bash
peer() { # $1 local vnet, $2 remote vnet, $3 name
  az network vnet peering create -g $RG -n "$3" --vnet-name "$1" \
    --remote-vnet $(az network vnet show -g $RG -n "$2" --query id -o tsv) \
    --allow-vnet-access --allow-forwarded-traffic
}
peer vnet-hub    vnet-spoke1 hub-to-spoke1
peer vnet-spoke1 vnet-hub    spoke1-to-hub
peer vnet-hub    vnet-spoke2 hub-to-spoke2
peer vnet-spoke2 vnet-hub    spoke2-to-hub

az network vnet peering list -g $RG --vnet-name vnet-hub -o table
```
Cả 2 phía phải `Connected`. **Không** peer spoke1 ↔ spoke2 — cố ý.

## Bước 2 — 3 VM (spoke1, spoke2, NVA ở hub)

```bash
# NVA: cần IP forwarding, không public IP
az vm create -g $RG -n vm-nva --image Ubuntu2204 --size Standard_B1s \
  --admin-username azureuser --generate-ssh-keys \
  --vnet-name vnet-hub --subnet snet-nva --public-ip-address "" --nsg ""

for i in 1 2; do
  az vm create -g $RG -n vm-spoke$i --image Ubuntu2204 --size Standard_B1s \
    --admin-username azureuser --generate-ssh-keys \
    --vnet-name vnet-spoke$i --subnet snet-app --public-ip-address "" --nsg ""
done

NVA_IP=$(az vm list-ip-addresses -g $RG -n vm-nva --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv)
S1_IP=$(az vm list-ip-addresses -g $RG -n vm-spoke1 --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv)
S2_IP=$(az vm list-ip-addresses -g $RG -n vm-spoke2 --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv)
echo "NVA=$NVA_IP S1=$S1_IP S2=$S2_IP"
```

## Bước 3 — Chứng minh spoke1 KHÔNG tới được spoke2

```bash
az vm run-command invoke -g $RG -n vm-spoke1 --command-id RunShellScript \
  --scripts "ping -c 2 -W 2 $S2_IP || echo UNREACHABLE"
```
Kỳ vọng: `UNREACHABLE` / 100% packet loss.

Kiểm tra route của spoke1:

```bash
az network nic show-effective-route-table -g $RG -n vm-spoke1VMNic -o table
# 10.2.0.0/16 không có trong bảng → không có đường đi
```

## Bước 4 — Bật IP forwarding trên NVA (2 lớp)

```bash
# Lớp Azure: IP forwarding trên NIC
az network nic update -g $RG -n vm-nvaVMNic --ip-forwarding true

# Lớp OS: sysctl
az vm run-command invoke -g $RG -n vm-nva --command-id RunShellScript \
  --scripts "sudo sysctl -w net.ipv4.ip_forward=1 && echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward"
```

> Thiếu **bất kỳ lớp nào** → packet bị drop. Đây là bẫy số 1 của NVA.

## Bước 5 — UDR 2 chiều

```bash
# Spoke1: đi spoke2 qua NVA
az network route-table create -g $RG -n rt-spoke1
az network route-table route create -g $RG --route-table-name rt-spoke1 \
  -n to-spoke2 --address-prefix 10.2.0.0/16 \
  --next-hop-type VirtualAppliance --next-hop-ip-address $NVA_IP
az network vnet subnet update -g $RG --vnet-name vnet-spoke1 -n snet-app --route-table rt-spoke1

# Spoke2: chiều về qua NVA (nếu thiếu, reply đi thẳng và bị drop)
az network route-table create -g $RG -n rt-spoke2
az network route-table route create -g $RG --route-table-name rt-spoke2 \
  -n to-spoke1 --address-prefix 10.1.0.0/16 \
  --next-hop-type VirtualAppliance --next-hop-ip-address $NVA_IP
az network vnet subnet update -g $RG --vnet-name vnet-spoke2 -n snet-app --route-table rt-spoke2
```

## Bước 6 — Kiểm chứng

```bash
az network nic show-effective-route-table -g $RG -n vm-spoke1VMNic -o table
az network watcher show-next-hop -g $RG --vm vm-spoke1 \
  --source-ip $S1_IP --dest-ip $S2_IP
# nextHopType: VirtualAppliance, nextHopIpAddress: <NVA_IP>

az vm run-command invoke -g $RG -n vm-spoke1 --command-id RunShellScript \
  --scripts "ping -c 3 -W 2 $S2_IP && echo REACHABLE"
```
Kỳ vọng: `REACHABLE`.

## Bước 7 — Thí nghiệm phá (quan trọng hơn làm đúng)

1. Xoá route `to-spoke2` → ping fail lại. Vì sao?
2. Tắt IP forwarding trên NIC (`--ip-forwarding false`) → ping fail dù route còn. Vì sao?
3. Đặt UDR `0.0.0.0/0 → None` trên snet-app spoke1 → điều gì xảy ra với Internet? (Lưu ý: run-command vẫn chạy vì đi control plane.)
4. Đổi `--allow-forwarded-traffic` thành false trên `hub-to-spoke2` → ping fail. Vì sao?

## Câu hỏi exam-style

1. 3 VNet hub-spoke, muốn spoke-to-spoke không peer trực tiếp → mấy cách, kể tên?
2. Traffic qua NVA bị drop dù UDR đúng → kiểm tra gì đầu tiên?
3. UDR `10.2.0.0/16 → None` để làm gì?
4. Muốn mọi traffic ra Internet đi qua firewall ở hub → route nào?
5. Peering connected nhưng không ping được, 3 nguyên nhân?

<details><summary>Đáp án</summary>

1. Peer trực tiếp; UDR → NVA (IP forwarding); gateway transit qua VPN/ER ở hub.
2. IP forwarding trên NIC **và** trong OS; `allowForwardedTraffic` trên peering.
3. Chặn/blackhole traffic tới dải đó (cô lập hoặc buộc dùng đường khác).
4. `0.0.0.0/0 → Virtual appliance` (IP firewall/NVA).
5. NSG chặn, guest OS firewall, thiếu allowForwardedTraffic, address overlap, route thiếu.

</details>

## Cleanup

```bash
az group delete -n $RG --yes --no-wait
```
