# 07 — Networking extras (ngoài đề, cho công việc)

> 4 dịch vụ dưới đây **không nằm trong skills measured** của AZ-104. Đọc 10 phút mỗi cái để (a) loại trừ đáp án trong đề, (b) không bị "mù" khi vào dự án thật. **Không lab** trừ khi có yêu cầu công việc.

## 1. Azure Firewall

- Firewall **managed, stateful**, L3–L7, triển khai trong subnet riêng `AzureFirewallSubnet`.
- Có **private IP** (egress) + **public IP** (ingress/DNAT).
- 3 loại rule (theo thứ tự đánh giá: DNAT → Network → Application):
  - **DNAT**: public IP:port → private IP:port (publish service).
  - **Network**: IP/port/protocol (L3/L4).
  - **Application**: FQDN (HTTP/S, MSSQL) — ví dụ chỉ cho `*.microsoft.com`.
- **Threat intelligence**: alert/deny traffic tới IP/domain độc hại.
- **Policy** (Firewall Policy) phân cấp: base policy ở hub → child policy ở spoke (kế thừa rule).
- **SKU**: Basic (nhỏ, rẻ), Standard (mặc định), Premium (TLS inspection, IDPS, URL filtering).
- **Forced tunneling**: đẩy traffic ra on-prem qua `AzureFirewallManagementSubnet`.
- **Khác NSG**: NSG lọc port/IP, miễn phí, gắn subnet/NIC. Firewall lọc FQDN, DNAT, threat intel, tính tiền theo giờ. **Đề AZ-104 gần như không hỏi cấu hình Firewall.**

**Câu chốt:** "chặn outbound theo FQDN cho toàn bộ spoke" → Azure Firewall (NSG không biết FQDN).
"Chặn port 22 giữa 2 subnet" → NSG.

## 2. Virtual WAN

- **Hub toàn cầu do Microsoft quản lý**, gộp VPN site-to-site, point-to-site, ExpressRoute, VNet connection.
- Thay cho việc tự dựng hub VNet + NVA + gateway.
- **Standard** (đầy đủ tính năng, có routing intent, securable hub) vs **Basic** (chỉ site-to-site).
- **Securable hub**: tích hợp Azure Firewall để inspect traffic giữa các spoke/on-prem.
- **Routing intent**: policy định tuyến tập trung cho Internet + private traffic.
- Không phải "hub-spoke tự dựng" — nếu đề nói "tự quản lý VNet, peering, UDR" thì không phải vWAN.

**Khi nào dùng:** hàng chục/hàng trăm chi nhánh, nhiều region, cần kết nối on-prem quy mô lớn, không muốn tự quản gateway.

## 3. API Management (APIM)

- **API gateway**: publish API cho developer, không phải load balancer.
- Thành phần: **API** → **Operation** → **Policy** (XML) → **Product** → **Subscription**.
- **Policy** hay dùng: `rate-limit`, `quota`, `validate-jwt`, `set-backend-service`, `rewrite-uri`, `cache-store`, `ip-filter`.
- **Subscription key** để client gọi API; có thể gắn với product.
- **Developer portal** cho nội bộ/đối tác.
- Tier: Consumption, Developer (không SLA), Basic, Standard, Premium (multi-region, VNet).
- **VNet**: External (client ngoài vào được), Internal (chỉ trong VNet, dùng private endpoint/App Gateway phía trước).
- **Khác App Gateway**: App Gateway là reverse proxy hạ tầng (L7 LB, WAF). APIM là lớp quản trị API (auth, quota, versioning, developer portal). Có thể dùng **cả hai**: App Gateway (WAF) → APIM → backend.

**Câu chốt:** "giới hạn 100 request/phút cho mỗi subscription key" → APIM policy `rate-limit`.
"Path-based routing + WAF" → App Gateway, không phải APIM.

## 4. ExpressRoute

- Kết nối **riêng** từ on-prem → Azure qua provider (không qua Internet), bandwidth 50 Mbps–100 Gbps.
- **Circuit** gắn với provider + peering location; cần **ExpressRoute Gateway** trong `GatewaySubnet`.
- 3 loại peering:
  - **Private peering**: vào VNet (private IP).
  - **Microsoft peering**: tới Microsoft 365/Azure public services (public IP).
  - **Public peering**: deprecated.
- **Global Reach**: nối 2 ExpressRoute circuit với nhau qua backbone Microsoft.
- **FastPath**: bypass gateway để tăng throughput (private peering).
- **Redundancy**: 2 circuit ở 2 peering location khác nhau.
- Không mã hoá mặc định (khác VPN IPsec) → cần VPN over ExpressRoute nếu cần encryption.

**Câu chốt:** "kết nối riêng, không qua Internet, SLA cao" → ExpressRoute. "Nhanh, rẻ, qua Internet" → VPN Gateway.

## 5. Bảng chọn nhanh

| Yêu cầu | Dịch vụ |
|---|---|
| Lọc port/IP trong VNet | NSG |
| Lọc FQDN outbound toàn hub | Azure Firewall |
| Kết nối on-prem qua Internet | VPN Gateway |
| Kết nối on-prem riêng, SLA cao | ExpressRoute |
| Hub managed cho 100 chi nhánh | Virtual WAN |
| Publish API + quota + subscription key | APIM |
| HTTPS path routing + WAF | Application Gateway |
| Global HTTP proxy + CDN + WAF | Front Door |
