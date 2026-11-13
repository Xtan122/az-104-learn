# Q2 — Networking (12 câu / 18 phút)

1. Subnet `10.0.5.0/26` còn bao nhiêu địa chỉ IP usable?
   A. 64
   B. 62
   C. 59
   D. 58

2. VNet A peer VNet B, VNet B peer VNet C. VM ở A ping VM ở C. Kết quả?
   A. Thông, vì peering bắc cầu
   B. Không thông, peering non-transitive
   C. Thông nếu cùng region
   D. Thông nếu bật allowGatewayTransit

3. Traffic từ spoke1 → spoke2 đi qua NVA ở hub nhưng bị drop. Đã có UDR đúng. Thiếu gì?
   A. NAT Gateway
   B. IP forwarding trên NIC NVA (và trong OS)
   C. Public IP cho NVA
   D. Service endpoint

4. NSG có rule Deny `AzureLoadBalancer` ở priority 100. Hậu quả?
   A. Không ảnh hưởng
   B. Load balancer probe fail, backend bị loại
   C. VM bị restart
   D. Chỉ chặn SSH

5. Cần storage account chỉ truy cập từ VNet, có private IP, không lộ public endpoint. Chọn gì?
   A. Service endpoint
   B. Private endpoint + private DNS
   C. NSG trên storage
   D. Azure Firewall

6. UDR `10.9.0.0/16 → None`. Tác dụng?
   A. Route mặc định ra Internet
   B. Drop traffic tới 10.9.0.0/16
   C. Chuyển sang VNet peering
   D. Gửi tới NVA

7. Cần HTTPS, path-based routing (`/api` → pool khác), WAF. Chọn gì?
   A. Azure Load Balancer Standard
   B. Application Gateway WAF_v2
   C. Traffic Manager
   D. NAT Gateway

8. App gọi `st123.blob.core.windows.net` từ VM đã có private endpoint nhưng vẫn đi public. Nguyên nhân khả dĩ nhất?
   A. Thiếu NSG rule
   B. Thiếu private DNS zone/record
   C. Thiếu public IP
   D. Storage dùng GRS

9. Cần SSH vào VM không có public IP, không mở port 22 ra Internet. Chọn gì?
   A. VPN point-to-site
   B. Azure Bastion
   C. Jump box có public IP
   D. NSG allow 22 từ `*`

10. Hub có VPN Gateway, spoke cần dùng gateway này để tới on-prem. Cấu hình gì?
    A. `useRemoteGateways` ở hub, `allowGatewayTransit` ở spoke
    B. `allowGatewayTransit` ở hub, `useRemoteGateways` ở spoke
    C. Chỉ cần peering
    D. Cần gateway riêng ở spoke

11. Hai VM không có public IP nằm sau **Standard** Load Balancer, cần nhận traffic Internet port 443. Điều kiện?
    A. Không cần gì thêm
    B. NSG phải cho phép 443 và probe; backend không cần public IP
    C. Phải gán public IP cho từng VM
    D. Phải dùng Basic LB

12. VM không kết nối được tới `10.2.0.4:443`. Muốn biết **route** nào đang được chọn, dùng gì?
    A. IP flow verify
    B. Next hop
    C. Packet capture
    D. NSG flow logs

---

<details><summary>Đáp án & giải thích</summary>

1. **C.** /26 = 64 − 5 = 59.
2. **B.** Peering không transitive.
3. **B.** Cả 2 lớp: `--ip-forwarding true` trên NIC + `net.ipv4.ip_forward=1` trong OS (và `allowForwardedTraffic` trên peering).
4. **B.** Probe đến từ `168.63.129.16` / service tag `AzureLoadBalancer`; deny → unhealthy.
5. **B.** Private endpoint + DNS `privatelink.blob.core.windows.net`.
6. **B.** Next hop None = drop.
7. **B.** App Gateway WAF_v2.
8. **B.** Không có DNS record → resolve public IP → firewall chặn/hoặc đi Internet.
9. **B.** Bastion (TLS 443, subnet `AzureBastionSubnet`).
10. **B.** Hub cho transit, spoke dùng remote gateway.
11. **B.** Standard LB secure by default; NSG phải mở, backend không cần public IP.
12. **B.** Next hop (IP flow verify dùng cho NSG).

</details>
