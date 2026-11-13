# Lab 10 — Monitor, KQL, alert, backup (90')

**Mục tiêu:** bật diagnostic settings, query KQL, tạo metric alert gửi email, backup VM và restore file. Lab này "dễ" nhưng hay bị bỏ → mất điểm oan.

## Chuẩn bị

```bash
export RG=rg-az104-lab10
az group create -n $RG -l southeastasia
az network vnet create -g $RG -n vnet-lab --address-prefixes 10.0.0.0/16 \
  --subnet-name snet-app --subnet-prefixes 10.0.1.0/24
az vm create -g $RG -n vm-mon --image Ubuntu2204 --size Standard_B1s \
  --admin-username azureuser --generate-ssh-keys \
  --vnet-name vnet-lab --subnet snet-app
```

## Bước 1 — Log Analytics workspace

```bash
az monitor log-analytics workspace create -g $RG -n law-lab -l southeastasia
LAW_ID=$(az monitor log-analytics workspace show -g $RG -n law-lab --query id -o tsv)
```

## Bước 2 — Diagnostic settings cho Activity Log (subscription level)

```bash
SUB=$(az account show --query id -o tsv)
az monitor diagnostic-settings subscription create \
  --name diag-activity \
  --location southeastasia \
  --workspace $LAW_ID \
  --logs '[{"category":"Administrative","enabled":true},{"category":"Security","enabled":true},{"category":"Policy","enabled":true}]'
```

> Với **resource log** của VM (guest OS), cần **Azure Monitor Agent + Data Collection Rule**, không dùng diagnostic settings đơn thuần. Đề hay hỏi đúng điểm này: "muốn thu log syslog từ VM → AMA + DCR".

## Bước 3 — Tạo vài hoạt động rồi query KQL

```bash
az group create -n rg-az104-temp-log -l southeastasia
az group delete -n rg-az104-temp-log --yes
sleep 60   # log có độ trễ vài phút

az monitor log-analytics query -w $LAW_ID --analytics-query "
AzureActivity
| where TimeGenerated > ago(1h)
| where OperationNameValue endswith 'DELETE'
| project TimeGenerated, Caller, ResourceGroup, OperationNameValue
| order by TimeGenerated desc
" -o table
```

Query CPU (nếu đã bật VM insights) hoặc dùng metrics:

```bash
az monitor metrics list --resource $(az vm show -g $RG -n vm-mon --query id -o tsv) \
  --metric "Percentage CPU" --interval PT5M --offset 1h -o table
```

## Bước 4 — Action group + metric alert

```bash
VM_ID=$(az vm show -g $RG -n vm-mon --query id -o tsv)
az monitor action-group create -g $RG -n ag-lab --short-name aglab \
  --action email mail1 you@example.com

AG_ID=$(az monitor action-group show -g $RG -n ag-lab --query id -o tsv)

az monitor metrics alert create -g $RG -n alert-cpu-high \
  --scopes $VM_ID --severity 2 --window-size 5m --evaluation-frequency 1m \
  --condition "avg Percentage CPU > 80" \
  --action $AG_ID \
  --description "CPU > 80% trong 5 phút"

az monitor metrics alert show -g $RG -n alert-cpu-high -o json
```

Tạo tải để thử alert (tuỳ chọn, tốn CPU):

```bash
az vm run-command invoke -g $RG -n vm-mon --command-id RunShellScript \
  --scripts "sudo apt-get install -y stress >/dev/null 2>&1; stress --cpu 2 --timeout 300 &"
```

## Bước 5 — Alert processing rule (suppression)

Portal: **Monitor → Alerts → Alert processing rules → Create**.
- Scope: subscription hoặc resource group.
- Suppress: chọn window (ví dụ cuối tuần / 2h bảo trì).
- Hoặc override action group.

CLI (nếu muốn):

```bash
az monitor alert-processing-rule create -g $RG -n suppress-maintenance \
  --scopes $VM_ID --rule-type RemoveAllActionGroups \
  --schedule-recurrence-type Weekly \
  --schedule-recurrence-days Saturday Sunday
```

## Bước 6 — Backup VM

```bash
az backup vault create -g $RG -n rsv-lab -l southeastasia
az backup protection enable-for-vm -g $RG -v rsv-lab \
  --vm $VM_ID --policy-name DefaultPolicy

az backup job list -g $RG -v rsv-lab -o table
az backup item list -g $RG -v rsv-lab -o table

# Chạy backup ngay (không chờ lịch)
az backup protection backup-now -g $RG -v rsv-lab \
  --container-name vm-mon --item-name vm-mon \
  --retain-days 7 --backup-type Full
```

Restore file (portal dễ hơn CLI):
1. Vault → Backup items → Azure Virtual Machine → vm-mon → **File Recovery**.
2. Chọn recovery point → download script → chạy trên VM để mount volume → copy file → unmount.
3. Hoặc **Restore VM** / **Restore disks**.

Kiểm tra soft delete:

```bash
az backup vault backup-properties show -g $RG -v rsv-lab \
  --query "softDeleteSettings"
```

## Bước 7 — (Đọc) Site Recovery

Không cần lab (tốn thời gian + tạo VM replica). Nắm quy trình:
`Enable replication → Replication policy → Test failover (network cô lập) → Failover → Commit → Reprotect`.
Câu hỏi: "kiểm tra DR mà không ảnh hưởng production" → **test failover**.

## Câu hỏi exam-style

1. Ai xoá resource lúc 3h sáng → tra đâu?
2. Log VM cần thu bằng gì?
3. Alert CPU > 80% gửi email → mấy resource?
4. Không muốn alert khi bảo trì → gì?
5. Backup blob → vault nào?
6. Backup VM giữ 7 năm → cấu hình gì?
7. Test DR không ảnh hưởng user → bước nào?
8. Alert tự restart VM được không?

<details><summary>Đáp án</summary>

1. Activity Log (hoặc Log Analytics nếu đã export).
2. Azure Monitor Agent + Data Collection Rule.
3. Metric alert + action group.
4. Alert processing rule (suppression).
5. Backup vault.
6. Backup policy retention dài hạn (monthly/yearly GFS).
7. ASR **test failover**.
8. Không; cần action group → Automation Runbook/Function.

</details>

## Cleanup

```bash
az group delete -n $RG --yes --no-wait
```
