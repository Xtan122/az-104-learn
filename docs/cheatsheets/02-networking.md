# Cheat sheet 2 — Networking

## Số IP
`/24`=251 · `/25`=123 · `/26`=59 · `/27`=27 · `/28`=11 · `/29`=3 · `/30` không dùng được
Giữ 5: `.0` network, `.1` gateway, `.2-.3` DNS, IP cuối broadcast.

## NSG
- Stateful. Gắn **subnet + NIC**. Priority 100–4096, nhỏ thắng.
- Inbound: **subnet → NIC**. Outbound: **NIC → subnet**.
- Defaults: 65000 AllowVnetIn, 65001 AllowAzureLBIn, 65500 DenyAllIn; out: 65000/65001/65500.
- ASG = nhóm NIC. Service tag = `VirtualNetwork`, `Internet`, `AzureLoadBalancer`, `Storage`…
- Probe LB đến từ `168.63.129.16` → đừng deny `AzureLoadBalancer`.

## Routing
- Longest prefix → nếu trùng: **UDR > BGP > system**.
- Next hop: Virtual network · Internet · Virtual network gateway · **Virtual appliance** · **None = drop**.
- NVA phải bật **IP forwarding**.
- Peering cần `allowForwardedTraffic` khi đi qua NVA.

## Peering
- **2 object**, **non-transitive**, không overlap, global được.
- `allowGatewayTransit` (hub) + `useRemoteGateways` (spoke).
- Spoke↔spoke: peer trực tiếp / UDR→NVA / gateway transit.

## DNS
- Public zone: A, CNAME (không ở apex), **Alias**.
- Private zone: VNet link + auto-registration (1 zone/VNet).
- Private endpoint cần `privatelink.<service>.core.windows.net`.

## Service endpoint vs Private endpoint
| | SE | PE |
|---|---|---|
| Private IP | ❌ | ✅ NIC |
| DNS đổi | ❌ | ✅ |
| On-prem | ❌ | ✅ |
| Tắt public | ❌ | ✅ |
| Phí | free | theo giờ |

## LB chọn đúng
```
L4 TCP/UDP, regional        → Load Balancer (Standard)
L7 HTTP, path, WAF, regional→ Application Gateway (WAF_v2)
DNS global, không proxy     → Traffic Manager
Global proxy + CDN + WAF    → Front Door
Reverse proxy API           → APIM
```

## Troubleshoot
| Câu hỏi | Tool |
|---|---|
| NSG nào chặn? | IP flow verify |
| Route nào? | Next hop |
| Fail ở đâu? | Connection troubleshoot |
| Liên tục? | Connection Monitor |
| Traffic log? | NSG flow logs |
| Bắt gói? | Packet capture |

## Port hay gặp
22 SSH · 3389 RDP · 80/443 HTTP(S) · 445 SMB (Files) · 1433 SQL · 5432 PG · 3306 MySQL · 53 DNS · 123 NTP

## Giá (ballpark)
Bastion ~0,19 $/h · Firewall ~1,25 $/h · VPN GW ~0,04–0,36 $/h · AppGW v2 ~0,25 $/h · LB Std ~0,025 $/h

## Câu chốt
| Yêu cầu | Đáp án |
|---|---|
| Spoke1 → spoke2 | peer trực tiếp / UDR→NVA / gateway transit |
| Chặn Internet, chỉ cho qua firewall | UDR `0.0.0.0/0` → Virtual appliance |
| 2 VM không public IP vẫn chạy web | Standard LB + NSG allow |
| HTTPS + path-based + WAF | Application Gateway WAF_v2 |
| Storage chỉ truy cập từ VNet, có private IP | Private endpoint + private DNS |
| SSH không mở port 22 ra Internet | Azure Bastion |
