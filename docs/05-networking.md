# 05 — Networking (15–20%) — phần bạn ưu tiên

> Đây là note sâu nhất repo. Đề AZ-104 hỏi networking theo kiểu **tình huống + troubleshoot**, không hỏi định nghĩa. Học theo sơ đồ, không học theo câu chữ.

## 1. Địa chỉ & subnet

- VNet address space: private CIDR, có thể nhiều prefix, **không overlap** với VNet sẽ peer / on-prem.
- Subnet: chia từ VNet, mỗi subnet thuộc **1 VNet**, không gắn AZ (trải trên các AZ trong region).
- **Azure giữ 5 IP mỗi subnet**:

| IP | Dùng |
|---|---|
| `.0` | network address |
| `.1` | default gateway |
| `.2`, `.3` | DNS mapping của Azure |
| `.255` (IP cuối) | broadcast |

→ `/24` = **251** usable; `/28` = **11**; `/29` = **3** (subnet nhỏ nhất Azure cho phép là `/29`).

- Subnet cần cho dịch vụ đặc biệt:
  - `GatewaySubnet` (VPN/ER) — **đúng tên này**, /27 hoặc lớn hơn.
  - `AzureBastionSubnet` — **đúng tên này**, /26 hoặc lớn hơn.
  - `AzureFirewallSubnet`, `AzureFirewallManagementSubnet`.
  - App Service VNet integration: subnet delegation `Microsoft.Web/serverFarms`.
- **Public IP SKU**: Basic (retired 30/9/2025) vs **Standard** (static, zone-redundant, secure by default — phải có NSG cho phép). Standard IP luôn static.
- Private IP allocation: **Dynamic** (trong subnet) hoặc **Static** (gán cố định).

## 2. NSG — Network Security Group

- **Stateful**: cho phép chiều đi thì chiều về tự động.
- Gắn được vào **subnet** và/hoặc **NIC**. Không gắn vào VNet.
- Rule: priority **100–4096**, số nhỏ **thắng**. Khi match → dừng đánh giá.
- Rule gồm: source/destination (IP, CIDR, service tag, ASG), protocol (TCP/UDP/ICMP/Any), port, direction, access (Allow/Deny).
- **Default rules** (không xoá được):

| Priority | Tên | Direction | Hành vi |
|---|---|---|---|
| 65000 | AllowVnetInBound | Inbound | Cho phép trong VNet |
| 65001 | AllowAzureLoadBalancerInBound | Inbound | Cho phép health probe của LB |
| 65500 | DenyAllInBound | Inbound | Chặn còn lại |
| 65000 | AllowVnetOutBound | Outbound | Trong VNet |
| 65001 | AllowInternetOutBound | Outbound | Ra Internet |
| 65500 | DenyAllOutBound | Outbound | Chặn còn lại |

- **Thứ tự đánh giá**: Inbound **subnet NSG → NIC NSG**; Outbound **NIC NSG → subnet NSG**.
- **ASG (Application Security Group)**: nhóm NIC theo vai trò (web, db), dùng trong NSG rule thay IP → gọn khi scale.
- **Service tag**: `VirtualNetwork`, `Internet`, `AzureLoadBalancer`, `Storage`, `Sql`, `AzureCloud`, `AzureActiveDirectory`… Thay cho IP range của dịch vụ Microsoft.
- **Effective security rules**: portal → VM/NIC → "Effective security rules" (`az network nic show-effective-nsg`).
- **NSG flow logs**: ghi traffic vào storage/Log Analytics (cần Network Watcher), dùng để audit.
- **Không có NACL** trong Azure — đừng chọn.

**Bẫy kinh điển:**
1. Deny `AzureLoadBalancer` ở priority thấp hơn 65001 → **health probe fail → backend bị loại khỏi LB** dù app vẫn sống.
2. NSG cho phép port 80 nhưng **subnet NSG deny** → vẫn chết. Phải xem cả 2.
3. NSG stateful: chỉ cần rule inbound, không cần rule outbound cho response.
4. Rule Deny ở priority 100 sẽ thắng Allow 200 — thứ tự quan trọng hơn "độ cụ thể".

## 3. Routing

### 3.1 System routes (tự có, không xoá)
| Prefix | Next hop |
|---|---|
| VNet address space | Virtual network |
| `0.0.0.0/0` | Internet |
| `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | None (drop) — trừ khi có route khác |
| Peered VNet | VNet peering (Virtual network) |

### 3.2 UDR — User Defined Route
Gắn vào **subnet** (route table). Next hop types:

| Next hop | Ý nghĩa |
|---|---|
| Virtual network | Trong VNet |
| **Internet** | Ra Internet |
| **Virtual network gateway** | VPN/ExpressRoute |
| **Virtual appliance** | IP của NVA (firewall, VM chạy routing) |
| **None** | **Drop** traffic |

- Chọn route: **longest prefix match** trước; nếu trùng prefix: **UDR > BGP > system route**.
- **NVA** (network virtual appliance): VM làm router/firewall. Phải bật **IP forwarding** trên NIC của NVA (`--ip-forwarding true`), nếu không packet bị drop.
- **Forced tunneling**: `0.0.0.0/0 → Virtual appliance` hoặc `→ Virtual network gateway` để đẩy mọi traffic ra on-prem/firewall.
- UDR không áp dụng cho traffic **trong cùng subnet**? (traffic trong subnet đi trực tiếp, không qua route table) — nhớ: route table áp cho traffic **rời subnet**.

### 3.3 Hub-spoke

```
            [on-prem]──VPN/ER──[Hub VNet]
                                 │  GatewaySubnet (VPN GW)
                                 │  AzureFirewallSubnet (NVA/Firewall)
                                 │  snet-shared
                    ┌────────────┴────────────┐
              [Spoke1 VNet]              [Spoke2 VNet]
              snet-app                   snet-app
```
- Hub: gateway, firewall/NVA, DNS, Bastion, shared services.
- Spoke: workload, **không** cần gateway riêng.
- Spoke ↔ hub: peering 2 chiều. Spoke ↔ spoke: **không tự thông** (non-transitive).
- 3 cách cho spoke-to-spoke:
  1. Peer trực tiếp spoke1 ↔ spoke2 (đơn giản, nhưng N×N peering).
  2. **UDR** ở spoke trỏ `10.2.0.0/16 → Virtual appliance (IP firewall ở hub)` + IP forwarding.
  3. Hub có **VPN/ER gateway**: bật `Allow gateway transit` ở hub peering, `Use remote gateways` ở spoke → spoke dùng gateway hub để tới on-prem **và** tới spoke khác qua gateway (traffic đi qua gateway, không phải peering).

## 4. VNet Peering

- Tạo **2 peering object** (A→B và B→A). Mỗi object có state `Initiated`/`Connected`.
- **Non-transitive**: A–B, B–C không cho A–C.
- Không overlap address space.
- Hỗ trợ **global peering** (khác region), cross-tenant, cross-subscription.
- Thuộc tính quan trọng:

| Setting | Ý nghĩa |
|---|---|
| `allowVirtualNetworkAccess` | Cho traffic giữa 2 VNet (mặc định true) |
| `allowForwardedTraffic` | Cho traffic **đã được forward** (từ NVA) đi qua peering — cần cho hub-spoke NVA |
| `allowGatewayTransit` | (Hub) cho spoke dùng gateway của hub |
| `useRemoteGateways` | (Spoke) dùng gateway của hub; **xung đột** nếu spoke có gateway riêng |

- Peering dùng **private IP**, không cần public IP, không qua Internet.
- **Bẫy:** quên `allowForwardedTraffic` → traffic qua NVA bị drop dù UDR đúng.
- **Bẫy:** "peering connected nhưng ping fail" → NSG, hoặc VM không cho ICMP (Windows Firewall), hoặc address space overlap.

## 5. DNS

### 5.1 Azure DNS
- **Public zone**: host record cho domain mua ở registrar; NS record trỏ về `ns1-xx.azure-dns.com`.
- Record types: A, AAAA, CNAME (**không** đặt ở apex), MX, TXT, SRV, **Alias** (trỏ tới Azure resource như public IP, Traffic Manager, CDN — cập nhật tự động khi IP đổi).
- **Private zone**: chỉ resolve trong VNet được **link**.
  - `virtual network link` + bật **auto-registration** → VM trong VNet tự đăng ký `vmname.zone`.
  - Mỗi VNet chỉ **1** private zone bật auto-registration.
  - Không cần DNS server riêng; Azure DNS `168.63.129.16` xử lý.
- **Hybrid DNS**: forward từ on-prem → Azure DNS private resolver (hoặc DNS server VM), hoặc conditional forwarder.

### 5.2 Private DNS cho Private Endpoint
- Tên chuẩn: `privatelink.blob.core.windows.net`, `privatelink.file.core.windows.net`, `privatelink.vaultcore.azure.net`, `privatelink.azurewebsites.net`…
- Cần: private zone + VNet link + **A record** trỏ private IP của endpoint (portal có thể tự tạo qua "DNS zone group").
- Nếu không có DNS → app vẫn resolve public IP → bị firewall chặn (hoặc đi Internet).

## 6. Truy cập PaaS: Service Endpoint vs Private Endpoint

| | Service Endpoint | Private Endpoint |
|---|---|---|
| Cơ chế | Bật trên **subnet**, thêm route tới PaaS qua backbone | **NIC + private IP** trong subnet, map tới resource |
| DNS | Không đổi | Cần private DNS zone |
| Public access | PaaS vẫn có public endpoint (firewall giới hạn) | Có thể **tắt hoàn toàn** public |
| On-prem | Không (chỉ trong VNet) | Có, qua VPN/ER |
| Chi phí | Free | Tính tiền theo giờ + data |
| Dùng khi | Nhanh, rẻ, trong Azure | Bảo mật cao, hybrid, nhiều VNet |

**Cách nhớ:** Service Endpoint = "mở cửa sau từ subnet tới PaaS". Private Endpoint = "đặt PaaS ngay trong subnet của bạn".

## 7. Load balancing — chọn đúng dịch vụ

```
Cần L4 (TCP/UDP, không cần hiểu HTTP)?
├── Regional, private/public  → Azure Load Balancer (Standard)
├── Global, DNS-based         → Traffic Manager
└── Global, anycast + WAF     → Front Door

Cần L7 (HTTP/HTTPS, path, host, WAF)?
├── Regional                  → Application Gateway (v2 + WAF_v2)
└── Global                    → Front Door (WAF)
```

### 7.1 Azure Load Balancer (L4)
- **Public** (Internet) hoặc **Internal** (private IP, cho tầng sau).
- SKU **Standard** (Basic đã retire): SLA 99,99%, zone-redundant, **secure by default** (backend không có public IP vẫn ra Internet? — cần NAT rule/outbound rule), hỗ trợ HA ports.
- Thành phần: **frontend IP** → **load balancing rule** (port + protocol) → **backend pool** (VM/VMSS/NIC/IP) + **health probe** (TCP/HTTP/HTTPS, interval, threshold).
- **Inbound NAT rule**: map port public → port VM (ví dụ 50001 → 3389).
- **Outbound rule**: SNAT cho backend ra Internet (hoặc dùng NAT Gateway — khuyến nghị).
- Probe fail → instance bị loại khỏi rotation nhưng **không** bị restart.
- **Session persistence**: None / Client IP / Client IP + protocol (5-tuple).
- **HA ports**: cho mọi port, dùng trong NVA active-active.

**Bẫy:** Standard LB **không** cho phép traffic nếu NSG không mở; và backend VM **không cần public IP** (khác Basic).

### 7.2 Application Gateway (L7)
- Chỉ **HTTP/HTTPS**; có **WAF** (OWASP CRS), SSL termination/end-to-end, cookie affinity, **path-based routing** (`/images/*` → pool A), host-based, redirect, rewrite, autoscaling (v2).
- Thành phần: **frontend IP** + **listener** (port/protocol/cert) + **rule** → **backend pool** + **HTTP settings** (port, protocol, probe, cookie).
- **WAF mode**: Detection (chỉ log) vs **Prevention** (chặn). Rule set OWASP 3.2/CRS, custom rules, exclusions.
- Subnet riêng (`snet-appgw`), khuyến nghị /24. Public hoặc private frontend.
- **Bẫy:** App Gateway **không** dùng cho TCP/UDP thuần; không phải global.

### 7.3 Traffic Manager vs Front Door
- **Traffic Manager**: DNS-based global routing (Priority, Weighted, Performance, Geographic, Multivalue, Subnet). Không phải proxy — client kết nối trực tiếp endpoint. Không WAF.
- **Front Door**: anycast proxy toàn cầu, CDN, WAF, SSL offload, path routing. Có trong đề với vai trò distractor.

### 7.4 Health probe & troubleshoot
- Probe đến từ `168.63.129.16` (service tag `AzureLoadBalancer`) → NSG phải allow.
- App Gateway probe: dùng HTTP setting riêng, có thể tùy chỉnh path `/health`.
- Test: `curl` từ VM khác, `Test-NetConnection`, Network Watcher.

## 8. Bastion, Firewall, VPN, ExpressRoute, vWAN, APIM (overview 1 dòng)

| Dịch vụ | 1 dòng | Có thi cấu hình? |
|---|---|---|
| **Azure Bastion** | SSH/RDP qua portal qua TLS 443, không cần public IP trên VM; subnet `AzureBastionSubnet` /26 | ✅ biết triển khai |
| **Azure Firewall** | Firewall managed L3–L7, FQDN filter, DNAT, threat intel, policy phân cấp | ❌ overview |
| **VPN Gateway** | Site-to-site / point-to-site / VNet-to-VNet; `GatewaySubnet`; SKU VpnGw1... | ⚠️ khái niệm |
| **ExpressRoute** | Kết nối riêng qua provider, không qua Internet; 50 Mbps–100 Gbps | ❌ overview |
| **Virtual WAN** | Hub toàn cầu managed, gộp VPN/ER/peering | ❌ overview |
| **APIM** | API gateway: publish API, policy, rate limit, subscription key, developer portal | ❌ overview (không phải LB) |

**Chi phí (ballpark, kiểm tra lại pricing calculator):**
- Bastion Basic ~0,19 USD/giờ (~140 USD/tháng) → **lab 1 giờ rồi xoá**.
- Azure Firewall ~1,25 USD/giờ + data → **đừng lab nếu không cần**.
- VPN Gateway ~0,04–0,36 USD/giờ.
- App Gateway v2 ~0,25 USD/giờ + capacity unit.
- LB Standard ~0,025 USD/giờ + rule.

## 9. Network Watcher — bộ đồ nghề troubleshoot

| Tool | Trả lời câu hỏi |
|---|---|
| **IP flow verify** | Gói tin từ IP A → IP B port P có bị NSG chặn không? (chỉ định rule nào) |
| **Next hop** | Traffic từ VM tới đích đi qua next hop nào? (phát hiện UDR sai) |
| **Connection troubleshoot** | Test end-to-end TCP/ICMP, chỉ ra điểm fail (NSG, route, DNS) |
| **Connection monitor** | Giám sát liên tục, alert khi latency/mất gói |
| **Effective security rules** | Tổng hợp NSG subnet + NIC |
| **NSG flow logs** | Log traffic, ghi ra storage/Log Analytics |
| **Packet capture** | Bắt gói trên VM (qua agent), lưu storage |
| **Topology** | Sơ đồ VNet/subnet/NIC |
| **VPN troubleshoot** | Kiểm tra tunnel |

**Câu hỏi hay ra:** "VM không kết nối được tới X, cần xác định NSG hay route chặn" → **Connection troubleshoot** (tổng hợp) hoặc **IP flow verify** (NSG) + **Next hop** (route).

## 10. 12 bẫy networking phải nhớ

1. `/24` = 251, `/28` = 11, `/29` = 3.
2. Peering phải tạo **2 chiều**, **non-transitive**.
3. `allowForwardedTraffic` bắt buộc khi đi qua NVA.
4. NVA cần **IP forwarding** trên NIC.
5. NSG inbound: **subnet → NIC**; outbound: **NIC → subnet**.
6. Default rule `AllowAzureLoadBalancerInBound` — đừng deny nó.
7. UDR thắng system route; longest prefix thắng trước.
8. `None` next hop = **drop**, không phải "route mặc định".
9. Service endpoint không tạo private IP; private endpoint thì có.
10. Private endpoint cần **DNS** đúng, nếu không vẫn đi public.
11. Standard LB yêu cầu NSG mở, backend không cần public IP.
12. App Gateway = L7; LB = L4; Traffic Manager = DNS; Front Door = global proxy.

## 11. CLI hay dùng

```bash
# VNet + subnet
az network vnet create -g rg-lab -n vnet-hub \
  --address-prefixes 10.0.0.0/16 \
  --subnet-name snet-app --subnet-prefixes 10.0.1.0/24

az network vnet subnet create -g rg-lab --vnet-name vnet-hub \
  -n snet-mgmt --address-prefixes 10.0.2.0/24

# NSG
az network nsg create -g rg-lab -n nsg-app
az network nsg rule create -g rg-lab --nsg-name nsg-app -n allow-ssh \
  --priority 100 --direction Inbound --access Allow \
  --protocol Tcp --destination-port-ranges 22 --source-address-prefixes '*'

az network vnet subnet update -g rg-lab --vnet-name vnet-hub \
  -n snet-app --network-security-group nsg-app

az network nic show-effective-nsg -g rg-lab -n vm1VMNic -o table

# Peering (phải chạy 2 lệnh)
az network vnet peering create -g rg-lab -n hub-to-spoke1 \
  --vnet-name vnet-hub \
  --remote-vnet $(az network vnet show -g rg-lab -n vnet-spoke1 --query id -o tsv) \
  --allow-vnet-access --allow-forwarded-traffic

az network vnet peering create -g rg-lab -n spoke1-to-hub \
  --vnet-name vnet-spoke1 \
  --remote-vnet $(az network vnet show -g rg-lab -n vnet-hub --query id -o tsv) \
  --allow-vnet-access --allow-forwarded-traffic

# UDR
az network route-table create -g rg-lab -n rt-spoke1
az network route-table route create -g rg-lab --route-table-name rt-spoke1 \
  -n to-spoke2 --address-prefix 10.2.0.0/16 \
  --next-hop-type VirtualAppliance --next-hop-ip-address 10.0.1.4
az network vnet subnet update -g rg-lab --vnet-name vnet-spoke1 \
  -n snet-app --route-table rt-spoke1

# Bật IP forwarding trên NVA
az network nic update -g rg-lab -n nvaVMNic --ip-forwarding true

# Private endpoint
az network private-endpoint create -g rg-lab -n pe-blob \
  --vnet-name vnet-hub --subnet snet-pe \
  --private-connection-resource-id <storage-resource-id> \
  --group-id blob --connection-name pec-blob

# Network Watcher
az network watcher test-ip-flow -g rg-lab \
  --vm vm1 --direction Outbound --protocol TCP \
  --local 10.0.1.4:12345 --remote 10.2.0.4:443
az network watcher show-next-hop -g rg-lab \
  --vm vm1 --source-ip 10.0.1.4 --dest-ip 10.2.0.4

# LB
az network lb create -g rg-lab -n lb-web --sku Standard \
  --frontend-ip-name fe --backend-pool-name be --public-ip-address pip-lb
```

## 12. Sơ đồ tư duy 1 trang (tự vẽ lại ngày 14)

```
Internet
   │ (public IP / Standard, NSG allow)
[App Gateway WAF_v2]  ← L7, path based, TLS
   │
[Standard LB] (internal) ← L4, probe 168.63.129.16
   │
snet-app 10.0.1.0/24 ── NSG (subnet)
   ├── vm1 (NIC NSG) zone 1
   ├── vm2 (NIC NSG) zone 2
   └── NVA 10.0.1.4 (IP forwarding)
          │ UDR 10.2.0.0/16 → VirtualAppliance
[snet-pe] ── Private Endpoint ── privatelink.blob.core.windows.net
[GatewaySubnet] ── VPN GW ── on-prem
[AzureBastionSubnet] ── Bastion (443, không public IP)
```

## 13. Tự kiểm tra (10 câu, không tra)

1. `/26` còn bao nhiêu IP?
2. Peering A–B đã Connected nhưng ping fail, kể 3 nguyên nhân.
3. UDR `0.0.0.0/0 → None` dùng để làm gì?
4. Tại sao cần `allowForwardedTraffic`?
5. Service endpoint có cần private DNS zone không?
6. LB health probe đi từ IP nào, rule NSG nào cho phép?
7. App Gateway vs LB: chọn cái nào cho TCP 1433?
8. Muốn spoke1 → spoke2 qua hub firewall, cần cấu hình gì ở 3 nơi?
9. Hai VNet cùng `10.0.0.0/16` có peer được không?
10. VMSS sau Standard LB, VM không có public IP, vẫn ra Internet được không? Bằng cách nào?

<details><summary>Đáp án</summary>

1. 64 − 5 = 59.
2. NSG chặn, firewall trong guest OS, address space overlap / route thiếu, `allowVirtualNetworkAccess` false.
3. Chặn toàn bộ traffic ra ngoài (ví dụ buộc đi qua NVA/gateway hoặc cô lập subnet).
4. Vì packet đến NVA rồi được forward tiếp — nếu không cho forwarded traffic, peering drop.
5. Không (nhưng phải bật service endpoint trên subnet và allow trong storage firewall).
6. `168.63.129.16`, service tag `AzureLoadBalancer`.
7. LB (L4). App Gateway chỉ HTTP/HTTPS.
8. UDR ở spoke1 → VirtualAppliance (IP firewall hub); IP forwarding trên NIC firewall; `allowForwardedTraffic` trên cả 2 peering; NSG cho phép.
9. Không, phải khác address space.
10. Được, qua outbound rule của Standard LB hoặc NAT Gateway.

</details>
