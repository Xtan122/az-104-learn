# Cheat sheet 4 — CLI · ARM/Bicep · KQL

## az login & context
```bash
az login
az account list -o table
az account set -s "<subscription-id>"
az group create -n rg-lab -l southeastasia
az configure --defaults group=rg-lab location=southeastasia
```

## Identity / RBAC
```bash
az ad user create --display-name "An" --user-principal-name an@tenant.onmicrosoft.com --password 'P@ss...'
az ad group create --display-name grp-admins --mail-nickname grp-admins
az ad group member add -g grp-admins --member-id <objectId>
az role assignment create --assignee <upn|objectId> --role Reader --scope /subscriptions/<sub>
az role assignment list --assignee <upn> --all -o table
az role definition create --role-definition custom-role.json
```

## Policy / lock / tag / budget
```bash
az policy assignment create --name deny-region \
  --policy <definition-id> --scope <rg-id> \
  --params '{"listOfAllowedLocations":{"value":["southeastasia"]}}'

az lock create -n no-delete --lock-type CanNotDelete --resource-group rg-lab
az tag update --resource-id <id> --operation Merge --tags env=lab owner=an
az consumption budget create --amount 20 --category Cost \
  --time-grain Monthly --start-date 2026-11-01 --end-date 2027-11-01 \
  --resource-group rg-lab
```

## Networking
```bash
az network vnet create -g rg-lab -n vnet-hub --address-prefixes 10.0.0.0/16 \
  --subnet-name snet-app --subnet-prefixes 10.0.1.0/24
az network nsg create -g rg-lab -n nsg-app
az network nsg rule create -g rg-lab --nsg-name nsg-app -n allow-https \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --destination-port-ranges 443 --source-address-prefixes Internet
az network vnet subnet update -g rg-lab --vnet-name vnet-hub -n snet-app --network-security-group nsg-app
az network nic show-effective-nsg -g rg-lab -n <nic> -o table
az network watcher show-next-hop -g rg-lab --vm <vm> --source-ip 10.0.1.4 --dest-ip 8.8.8.8
az network watcher test-ip-flow -g rg-lab --vm <vm> --direction Outbound --protocol TCP \
  --local 10.0.1.4:1234 --remote 10.2.0.4:443
```

## Storage
```bash
az storage account create -g rg-lab -n staz104lab001 --sku Standard_LRS \
  --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false
az storage container create --account-name staz104lab001 -n data --auth-mode login
az storage blob upload --account-name staz104lab001 -c data -f ./file.txt -n file.txt --auth-mode login
az storage blob generate-sas --account-name staz104lab001 -c data -n file.txt \
  --permissions r --expiry 2026-12-01 --auth-mode login --as-user
az storage container policy create --account-name staz104lab001 -n data \
  --name readonly --permissions r --expiry 2026-12-01
azcopy copy './data/*' 'https://staz104lab001.blob.core.windows.net/data/?<SAS>' --recursive
az storage share create --account-name staz104lab001 -n share1 --quota 5
```

## VM / VMSS
```bash
az vm create -g rg-lab -n vm1 --image Ubuntu2204 --size Standard_B1s \
  --admin-username azureuser --generate-ssh-keys \
  --vnet-name vnet-hub --subnet snet-app --public-ip-address "" --nsg ""
az vm deallocate -g rg-lab -n vm1
az vm resize -g rg-lab -n vm1 --size Standard_B2s
az vm disk attach -g rg-lab --vm-name vm1 --name disk1 --new --size-gb 32 --sku Premium_LRS
az vmss create -g rg-lab -n vmss1 --image Ubuntu2204 --instance-count 2 \
  --admin-username azureuser --generate-ssh-keys --upgrade-policy-mode automatic
az monitor autoscale create -g rg-lab --resource vmss1 \
  --resource-type Microsoft.Compute/virtualMachineScaleSets --min-count 2 --max-count 4 --count 2
az monitor autoscale rule create -g rg-lab --autoscale-name vmss1 \
  --condition "Percentage CPU > 70 avg 5m" --scale out 1
```

## ARM / Bicep
```bash
az bicep install
az bicep build --file main.bicep
az bicep decompile --file template.json
az deployment group validate -g rg-lab -f main.bicep
az deployment group what-if -g rg-lab -f main.bicep
az deployment group create -g rg-lab -f main.bicep -p location=southeastasia
az group export -n rg-lab > exported.json
```

## App Service / container
```bash
az appservice plan create -g rg-lab -n plan1 --sku S1 --is-linux
az webapp create -g rg-lab -p plan1 -n appaz104lab001 --runtime "PYTHON:3.12"
az webapp deployment slot create -g rg-lab -n appaz104lab001 --slot staging
az webapp deployment slot swap -g rg-lab -n appaz104lab001 --slot staging --target-slot production
az webapp config appsettings set -g rg-lab -n appaz104lab001 --slot-settings ENV=staging
az acr create -g rg-lab -n acraz104lab001 --sku Basic --admin-enabled true
az container create -g rg-lab -n aci1 --image mcr.microsoft.com/azuredocs/aci-helloworld \
  --dns-name-label aci-az104-lab001 --ports 80
```

## Monitor / backup
```bash
az monitor log-analytics workspace create -g rg-lab -n law1
az monitor diagnostic-settings create --name diag --resource <resource-id> \
  --workspace <workspace-id> --metrics AllMetrics
az monitor action-group create -g rg-lab -n ag1 --short-name ag1 \
  --action email me you@example.com
az monitor metrics alert create -g rg-lab -n cpu-high --scopes <vm-id> \
  --condition "avg Percentage CPU > 80" --window-size 5m --evaluation-frequency 1m --action ag1
az backup vault create -g rg-lab -n rsv1 -l southeastasia
az backup protection enable-for-vm -g rg-lab -v rsv1 --vm <vm-id> --policy-name DefaultPolicy
```

## KQL
```kql
AzureActivity
| where TimeGenerated > ago(24h)
| where OperationNameValue contains "DELETE"
| project TimeGenerated, Caller, ResourceId, ActivityStatusValue

Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize avg(CPU=CounterValue) by Computer, bin(TimeGenerated, 5m)
| render timechart

Heartbeat
| summarize LastSeen=max(TimeGenerated) by Computer
| where LastSeen < ago(15m)

// top 10 lỗi
AppExceptions
| summarize Count=count() by ProblemId, OuterMessage
| top 10 by Count desc
```

## ARM nhớ nhanh
`$schema` · `contentVersion` · `parameters` · `variables` · `resources` · `outputs`
Hàm: `parameters()` `variables()` `concat()` `resourceId()` `reference()` `resourceGroup().location`
`mode`: Incremental (default) vs **Complete (xoá resource không khai báo)**

## Bicep nhớ nhanh
`param` · `var` · `resource` · `module` · `output` · `targetScope`
Không cần `dependsOn` nếu dùng symbolic reference.
