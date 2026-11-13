# Labs — nguyên tắc và danh mục

## Trước khi lab (mỗi lần)

```bash
az login
az account show -o table
bash scripts/check-cost.sh          # xem resource đang chạy
```

## Sau khi lab (mỗi lần — không thoả hiệp)

```bash
bash scripts/cleanup.sh             # xoá toàn bộ RG có prefix az104-
```

Quy ước đặt tên: **mọi resource group bắt đầu bằng `rg-az104-`** để script cleanup xoá đúng, không xoá nhầm resource khác.

## Danh mục

| Lab | Nội dung | Thời lượng | Chi phí ước tính | Ngày |
|---|---|---|---|---|
| [01](lab-01-identity-rbac.md) | Entra user/group/guest + RBAC scope | 90' | ~0 | 1 |
| [02](lab-02-policy-locks-cost.md) | Policy, lock, tag, management group, budget | 60' | ~0 | 2 |
| [03](lab-03-vnet-nsg-bastion.md) | VNet, subnet, NSG, ASG, effective rules | 90' | ~0,05 USD | 3 |
| [04](lab-04-peering-udr-nva.md) | Hub-spoke, peering, UDR, NVA, IP forwarding | 90' | ~0,15 USD | 4 |
| [05](lab-05-dns-private-endpoint.md) | Private DNS, service endpoint, private endpoint | 90' | ~0,10 USD | 5 |
| [06](lab-06-lb-appgw-waf.md) | Standard LB, health probe, App Gateway + WAF | 60–90' | **~1–2 USD** | 5 (optional) |
| [07](lab-07-storage-security.md) | Account, tier, lifecycle, SAS, Files, firewall | 150' | ~0,10 USD | 6–7 |
| [08](lab-08-vm-vmss-arm.md) | VM, disk, zone, VMSS, ARM deploy | 120' | ~0,20 USD | 8 |
| [09](lab-09-appservice-containers.md) | App Service slot swap, ACI, ACR | 90' | ~0,15 USD | 9 |
| [10](lab-10-monitor-backup.md) | Log Analytics, KQL, alert, backup/restore | 90' | ~0,20 USD | 10 |

> Giá là ballpark cho region `southeastasia`, dùng B-series và xoá trong ngày. Luôn kiểm tra [pricing calculator](https://azure.microsoft.com/pricing/calculator/).

## Quy tắc an toàn chi phí

1. **Deallocate VM** ngay khi không dùng: `az vm deallocate -g <rg> -n <vm>` (stop trong portal vẫn tính tiền compute nếu chưa deallocate).
2. **Xoá Bastion/Firewall/VPN Gateway/App Gateway trong cùng buổi** — chúng tính tiền theo giờ, không theo request.
3. **Storage account**: xoá luôn, đừng để lại data.
4. **Public IP Standard** tính tiền cả khi không gắn.
5. Kiểm tra cuối ngày: `az resource list -o table` + `az consumption usage list --top 10`.

## Cách dùng lab

Mỗi lab có 4 phần: **Mục tiêu → Bước làm → Kiểm chứng → Câu hỏi**. Đừng bỏ phần kiểm chứng: đó là lúc bạn học được nhiều nhất. Nếu lệnh fail, đọc lỗi rồi sửa — kỹ năng troubleshoot chính là thứ đề thi kiểm tra.
