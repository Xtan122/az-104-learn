# IaC — đọc và sửa, không viết từ đầu

Đề AZ-104 **không** yêu cầu viết template từ số 0. Đề cho 1 đoạn ARM/Bicep và hỏi:
- tham số nào bắt buộc, giá trị mặc định là gì
- resource nào được tạo, theo thứ tự nào
- sửa dòng nào để thêm disk/tag/size
- lệnh deploy đúng
- sự khác nhau `validate` / `what-if` / `create`

## Bài tập với 2 file trong thư mục này

### `arm/vm-simple.json`
1. Template tạo ra bao nhiêu resource? Kể tên.
2. `adminPassword` thuộc loại parameter gì? Tại sao?
3. Nếu không truyền `vmSize`, VM dùng size nào?
4. `dependsOn` của VM trỏ tới resource nào? Nếu bỏ đi thì sao?
5. Thêm một data disk 32 GB Premium_LRS vào VM: cần thêm resource gì, sửa mảng nào?
6. Đổi sang deploy ở `eastasia` mà không sửa file: dùng tham số nào?
7. `mode: Complete` có nguy hiểm gì nếu deploy vào RG đang có resource khác?

### `bicep/vnet-peering.bicep`
1. Resource nào được tạo? Có mấy peering object?
2. `allowForwardedTraffic` dùng để làm gì?
3. Tại sao không cần `dependsOn`?
4. Thêm subnet thứ 2 vào `vnetA` — sửa ở đâu?
5. Compile sang JSON bằng lệnh nào?

## Đáp án ngắn

<details><summary>Xem sau khi tự trả lời</summary>

**ARM**
1. 4: VNet, public IP, NIC, VM (subnet là resource con của VNet).
2. `secureString` — không hiện trong log/portal.
3. `Standard_B1s` (defaultValue).
4. NIC; nếu bỏ, ARM có thể tạo VM trước NIC → fail (ARM tự suy ra dependency qua `resourceId`/`reference` trong nhiều trường hợp, nhưng không nên bỏ).
5. Thêm resource `Microsoft.Compute/disks` (hoặc inline `dataDisks` trong VM) + `properties.storageProfile.dataDisks`.
6. `-p location=eastasia` (parameter `location`).
7. Xoá mọi resource trong RG không có trong template — mất dữ liệu.

**Bicep**
1. 2 VNet + 2 peering (A→B, B→A).
2. Cho phép traffic đã được NVA forward đi qua peering (bắt buộc trong hub-spoke có NVA).
3. Bicep suy ra dependency từ symbolic name (`vnetA`, `vnetB`).
4. Trong `properties.subnets` của `vnetA`.
5. `az bicep build --file iac/bicep/vnet-peering.bicep`.

</details>
