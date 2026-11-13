# 01 — Bản đồ AWS SAA → Azure (đọc ngay, 20 phút)

Mục đích: bạn **không học từ 0**, bạn đang **dịch** kiến thức SAA sang Azure rồi học phần Azure-only. Đọc bảng dưới, đánh dấu những dòng bạn chưa biết — đó là syllabus thật của bạn.

## 1. Mapping dịch vụ

| Nhu cầu | AWS (bạn đã biết) | Azure | Ghi chú thi |
|---|---|---|---|
| Mạng riêng | VPC | **Virtual Network (VNet)** | Subnet là resource con, không phải AZ-scoped |
| Chia subnet | Subnet (gắn AZ) | **Subnet** (không gắn AZ) | 1 subnet trải trên các AZ trong region |
| Firewall stateful | Security Group | **NSG** | Gắn được **cả subnet và NIC** |
| NACL | NACL (stateless) | *không có* | Đừng tìm, không tồn tại |
| Route table | Route Table | **Route table / UDR** | Gắn vào subnet, không gắn VNet |
| Internet gateway | IGW | *implicit* | Không có resource IGW; public IP + route mặc định là ra Internet |
| NAT | NAT Gateway | **NAT Gateway** | Gắn vào subnet, dùng public IP |
| Peering | VPC Peering / TGW | **VNet Peering** | **Non-transitive**, phải tạo 2 chiều |
| Private link | PrivateLink / VPCE | **Private Endpoint** | Cần Private DNS zone `privatelink.*` |
| DNS | Route 53 | **Azure DNS** (public + private zone) | Private zone + VNet link + auto-registration |
| LB L4 | NLB | **Azure Load Balancer** | Basic đã retire → Standard |
| LB L7 | ALB | **Application Gateway** | Có WAF, path-based routing |
| CDN + global LB | CloudFront + Global Accelerator | **Azure Front Door** | Không có trong objectives |
| WAF | AWS WAF | **WAF trên App Gateway / Front Door** | Detection vs Prevention |
| VPN | Site-to-Site VPN | **VPN Gateway** | SKU + GatewaySubnet |
| Dedicated link | Direct Connect | **ExpressRoute** | Overview only |
| Hub toàn cầu | Transit Gateway | **Virtual WAN** | Overview only |
| Object storage | S3 | **Blob Storage** (trong Storage Account) | Container, tier, lifecycle, SAS |
| Block storage | EBS | **Managed Disk** | Standard/Premium SSD v2/Ultra |
| File storage | EFS / FSx | **Azure Files** (SMB/NFS) | Identity-based access |
| Archive | S3 Glacier | **Archive tier** | Rehydrate mất giờ |
| Chia sẻ file | S3 presigned URL | **SAS** (3 loại) | user delegation SAS = Entra |
| IAM | IAM user/role/policy | **Entra ID + Azure RBAC** | Role definition khác IAM policy |
| SCP | SCP | **Azure Policy** (Deny) | Policy mạnh hơn SCP |
| Permission boundary | — | **Deny assignment** (hiếm) | Biết khái niệm |
| CloudTrail | CloudTrail | **Activity Log** | 90 ngày, per-subscription |
| CloudWatch | CloudWatch | **Azure Monitor** (Metrics + Logs) | Log Analytics + KQL |
| CloudWatch Alarms | Alarm | **Alert rule + Action group** | Metric/log/activity log alert |
| Config | AWS Config | **Azure Policy compliance** + Resource Graph | |
| Backup | AWS Backup | **Azure Backup** (RSV / Backup vault) | |
| DR | DRS | **Azure Site Recovery** | Test failover, recovery plan |
| IaC | CloudFormation | **ARM template / Bicep** | Bicep là DSL compile ra ARM JSON |
| Auto scaling | ASG | **VMSS** (autoscale) | Uniform vs Flexible |
| PaaS web | Elastic Beanstalk / App Runner | **App Service** | Plan + slot |
| Container | ECS Fargate | **ACI** | 1 container group, không orchestrator |
| Serverless container | App Runner | **Container Apps** | Scale to zero, revisions |
| Registry | ECR | **ACR** | Basic/Standard/Premium |
| Kubernetes | EKS | **AKS** | Overview only |
| Secret | Secrets Manager / KMS | **Key Vault** | Không có trong objectives (nhưng xuất hiện trong câu) |
| Org | Organizations | **Management groups** | Kế thừa policy + RBAC |
| Cost | Budgets / Cost Explorer | **Cost Management + Budgets** | Budget chỉ alert, không chặn |

## 2. Khác biệt "chết người" — học kỹ 8 điểm này

### 2.1 Peering không transitive
AWS: VPC A ↔ TGW ↔ VPC B là thông.
Azure: A ↔ B, B ↔ C **không** làm A ↔ C thông.
Giải: (a) peer trực tiếp A–C, (b) UDR trỏ spoke→NVA ở hub + bật IP forwarding, (c) hub có VPN/ER + `allow gateway transit` + spoke `use remote gateways`.

### 2.2 Subnet giữ 5 IP
`10.0.1.0/24` → 251 IP dùng được. Đề rất hay hỏi "còn bao nhiêu IP" hoặc "subnet /28 chứa được mấy VM" (/28 = 16 − 5 = 11).

### 2.3 NSG gắn được vào subnet VÀ NIC
Inbound: **subnet NSG trước → NIC NSG sau**. Outbound: **NIC trước → subnet sau**.
Cả 2 phải cho phép. NSG **stateful** (không cần rule return). Priority 100–4096, số nhỏ thắng. Default rules không xoá được.

### 2.4 Policy ≠ RBAC ≠ Lock
- **RBAC**: *ai* được làm gì (identity → action).
- **Policy**: resource được *trông như thế nào* (location, tag, SKU), có thể chặn tạo mới (Deny) hoặc tự sửa (Modify/DeployIfNotExists).
- **Lock**: chặn xoá/sửa **resource đã tồn tại**, áp dụng cho mọi người kể cả Owner.
Câu hỏi hay hỏi: "ngăn user tạo VM ở region khác" → **Policy Deny**, không phải RBAC.

### 2.5 Storage Account là namespace, không phải bucket
1 account chứa 4 dịch vụ: **Blob, Files, Queue, Table**. Tên 3–24 ký tự, lowercase + số, globally unique, không đổi tên được.
S3 bucket ≈ Blob container, không phải storage account.

### 2.6 SAS có 3 loại + cách thu hồi
| Loại | Ký bằng | Phạm vi | Thu hồi |
|---|---|---|---|
| Account SAS | Account key | Toàn account, nhiều service | Rotate key (ảnh hưởng tất cả) |
| Service SAS | Account key | 1 service (blob/file/queue/table) | Stored access policy (tốt nhất) |
| **User delegation SAS** | **Entra ID** | Blob, **tối đa 7 ngày** | Revoke delegation key / policy |

Stored access policy: tối đa **5** policy/container, gắn vào service SAS/user delegation SAS, xoá policy = chết SAS ngay.

### 2.7 Availability set vs zone
| | Availability set | Availability zone |
|---|---|---|
| SLA | 99,95% | 99,99% |
| Cơ chế | Fault domain (tối đa 3) + Update domain (tối đa 20) | 3 datacenter vật lý riêng trong 1 region |
| Dùng khi | Không cần zone, muốn rẻ | Cần SLA cao, latency thấp giữa các instance |
| Gắn sau khi tạo VM | Không (phải tạo cùng lúc) | Không (phải chọn lúc tạo) |

### 2.8 Metrics vs Logs
- **Metrics**: số, time series, retention 93 ngày, dùng cho alert real-time (CPU, IOPS).
- **Logs**: text/structured, cần **diagnostic settings** đẩy vào Log Analytics, query bằng **KQL**, retention 30 ngày mặc định (tăng được).
Câu "cần biết ai đã xoá VM" → **Activity Log**. Câu "cần query log của app" → **Log Analytics**.

## 3. 10 phản xạ AWS sẽ làm bạn sai trong đề

1. Tìm "Internet Gateway" → không có; public IP + route hệ thống là đủ.
2. Tìm NACL → không có; chỉ NSG.
3. Nghĩ peering cần 1 lần → phải tạo **2 peering object**.
4. Nghĩ subnet gắn với 1 AZ → không; subnet phủ mọi AZ trong region.
5. Nghĩ `/24` = 256 IP → 251.
6. Nghĩ SCP là công cụ chặn region duy nhất → **Policy Deny** ở subscription/MG.
7. Nghĩ "presigned URL" thu hồi bằng cách xoá key → dùng **stored access policy**.
8. Nghĩ snapshot nằm trong bucket → **snapshot là resource riêng** (disk snapshot).
9. Nghĩ "SG chỉ gắn NIC" → NSG gắn **subnet** là pattern phổ biến trong đề.
10. Nghĩ "AZ = region" → zone trong region; **region pair** mới là DR.

## 4. Tự kiểm tra (2 phút)

Trả lời miệng, không tra:
1. VNet A peer B, B peer C. A gọi được C không? Vì sao?
2. Subnet `/28` còn bao nhiêu IP usable?
3. NSG gắn subnet và NIC, inbound đánh giá theo thứ tự nào?
4. Muốn chặn tạo storage account ở region `eastus` → dùng gì?
5. SAS nào ký bằng Entra ID và sống tối đa bao lâu?
6. Cần SLA 99,99% cho 2 VM → dùng gì?
7. Câu "ai đã xoá resource" tra ở đâu?
8. LB L7 có path-based routing là dịch vụ nào?

<details><summary>Đáp án</summary>

1. Không. Peering non-transitive.
2. 16 − 5 = 11.
3. Subnet trước, NIC sau.
4. Azure Policy với effect Deny.
5. User delegation SAS, tối đa 7 ngày.
6. Availability zones (2 VM ở 2 zone khác nhau sau Standard LB).
7. Activity Log.
8. Application Gateway.

</details>
