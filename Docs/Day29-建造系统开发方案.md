# Day 29：建造系统 - 完整 UI 层与地图集成

> 第29天开发内容：建筑浏览、建造确认、地图选点、领地建筑列表、主地图建筑显示
> **最后更新：已完成实现，包含踩坑记录**

---

## 一、功能概览

通过对原项目 `/Users/tuzi/Desktop/项目/tuzi-earthlord` 的详细分析，建造系统需要实现以下完整功能：

### 1.1 核心功能清单

| 模块          | 功能                         | 状态    |
| ----------- | -------------------------- | ----- |
| **建筑浏览**    | 分类筛选、建筑卡片网格                | ✅ 已完成 |
| **建筑详情**    | 完整信息展示、开始建造入口              | ✅ 已完成 |
| **建造确认**    | 地图选点、资源确认、执行建造             | ✅ 已完成 |
| **地图选点**    | 显示领地**多边形**边界、点击选位置、显示已有建筑 | ✅ 已完成 |
| **领地建筑列表**  | 在领地详情页显示建筑、状态、倒计时          | ✅ 已完成 |
| **建筑升级/拆除** | 操作菜单、确认弹窗                  | ✅ 已完成 |
| **领地重命名**   | 齿轮按钮、对话框、通知刷新              | ✅ 已完成 |
| **主地图建筑显示** | 在主地图上渲染建筑标注                | ✅ 已完成 |
| **开发者测试工具** | 添加/清空测试资源                  | ✅ 已完成 |

### 1.2 与之前方案的关键差异

| 问题         | 之前方案             | 正确方案                  |
| ---------- | ---------------- | --------------------- |
| **领地形状**   | 使用圆形 `MapCircle` | 使用**多边形** `MKPolygon` |
| **位置验证**   | 距离中心点判断          | **点在多边形内**算法          |
| **领地建筑列表** | 无                | 在领地详情页显示建筑列表          |
| **建筑状态显示** | 无                | 显示状态徽章、进度条、倒计时        |
| **主地图建筑**  | 无                | 在主地图渲染建筑标注            |
| **实时更新**   | 无                | Timer 定时检查建造完成        |

---

## 二、已创建的文件清单

### 2.1 新建文件

| 文件                                 | 路径                 | 说明                       |
| ---------------------------------- | ------------------ | ------------------------ |
| `BuildingBrowserView.swift`        | `Views/Building/`  | 建筑浏览器（分类Tab + 网格）        |
| `BuildingDetailView.swift`         | `Views/Building/`  | 建筑详情页                    |
| `BuildingPlacementView.swift`      | `Views/Building/`  | 建造确认页（资源检查+位置选择）         |
| `BuildingLocationPickerView.swift` | `Views/Building/`  | 地图位置选择器（UIKit MKMapView） |
| `BuildingCard.swift`               | `Views/Building/`  | 建筑卡片组件                   |
| `CategoryButton.swift`             | `Views/Building/`  | 分类按钮组件                   |
| `ResourceRow.swift`                | `Views/Building/`  | 资源行组件                    |
| `TerritoryBuildingRow.swift`       | `Views/Building/`  | 领地建筑行（含操作菜单）             |
| `TerritoryMapView.swift`           | `Views/Territory/` | 领地地图组件（UIKit）            |
| `TerritoryToolbarView.swift`       | `Views/Territory/` | 悬浮工具栏组件                  |

### 2.2 修改的文件

| 文件                           | 修改内容                                              |
| ---------------------------- | ------------------------------------------------- |
| `TerritoryDetailView.swift`  | **完全重写**：全屏地图布局 + 建筑列表 + 操作菜单                     |
| `TerritoryTabView.swift`     | 添加 NotificationCenter 监听刷新                        |
| `TerritoryManager.swift`     | 添加 `updateTerritoryName` + 通知定义                   |
| `BuildingManager.swift`      | 添加 `demolishBuilding` 方法                          |
| `BuildingModels.swift`       | 添加 `buildProgress`、`formattedRemainingTime` 等计算属性 |
| `MapViewRepresentable.swift` | 添加建筑标注渲染（修复坐标转换）                                  |

---

## 三、重要踩坑记录

### 3.1 坐标转换问题（最重要！）

#### 问题现象

建筑在地图上显示位置偏移约 500 米，不在领地多边形内。

#### 根本原因

**数据库中存储的坐标已经是 GCJ-02 坐标**，但代码中又进行了一次转换，导致双重转换。

#### 错误代码

```swift
// ❌ 错误：数据库坐标已经是 GCJ-02，不应该再转换
let gcj02Coord = CoordinateConverter.wgs84ToGcj02(
    latitude: building.locationLat,
    longitude: building.locationLon
)
annotation.coordinate = gcj02Coord
```

#### 正确代码

```swift
// ✅ 正确：直接使用数据库中的坐标
guard let coord = building.coordinate else { continue }
// 注意：数据库中保存的已经是 GCJ-02 坐标，直接使用无需转换
annotation.coordinate = coord
```

#### 涉及文件

1. **TerritoryMapView.swift** - 领地详情页的建筑标记
2. **MapViewRepresentable.swift** - 主地图的建筑标记
3. **BuildingLocationPickerView.swift** - 位置选择器中的已有建筑

#### 调试方法

```swift
// 打印坐标对比
print("🏗️ 建筑坐标: \(building.locationLat), \(building.locationLon)")
print("🗺️ 领地中心: \(territory.center)")
// 如果相差很大（如0.005度 ≈ 500米），说明有转换问题
```

#### 最终方案

**保存时用 GCJ-02，显示时直接用**，不做任何转换。

---

### 3.2 位置选择器不显示已有建筑

#### 问题

选择新建筑位置时，看不到已经建好的建筑，容易重叠放置。

#### 解决方案

在 `BuildingLocationPickerView` 中添加已有建筑显示：

```swift
struct BuildingLocationPickerView: View {
    let territoryCoordinates: [CLLocationCoordinate2D]
    let existingBuildings: [PlayerBuilding]        // 新增
    let buildingTemplates: [String: BuildingTemplate]  // 新增
    // ...
}

// 在 Coordinator 中添加已有建筑标记
func addExistingBuildings(to mapView: MKMapView) {
    for building in parent.existingBuildings {
        guard let coord = building.coordinate else { continue }

        // 数据库中的坐标已经是 GCJ-02，直接使用
        let annotation = ExistingBuildingAnnotation(
            building: building,
            template: parent.buildingTemplates[building.templateId]
        )
        annotation.coordinate = coord
        mapView.addAnnotation(annotation)
    }
}
```

#### 调用方式

```swift
// BuildingPlacementView.swift
.sheet(isPresented: $showLocationPicker) {
    BuildingLocationPickerView(
        territoryCoordinates: territoryCoordinates,
        existingBuildings: buildingManager.playerBuildings.filter { $0.territoryId == territoryId },
        buildingTemplates: buildingManager.buildingTemplates,
        onSelectLocation: { coord in ... },
        onCancel: { ... }
    )
}
```

---

### 3.3 领地重命名后列表不刷新

#### 问题

在领地详情页重命名后，返回列表页仍显示旧名称，需要手动下拉刷新。

#### 原因分析

```
TerritoryTabView (myTerritories 数组)
       ↓ 传递 territory 给 sheet
TerritoryDetailView (修改成功，但只更新了自己的 @State territory)
       ✗ 没有通知父页面
```

#### 解决方案：NotificationCenter 通知机制

**1. 定义通知（TerritoryManager.swift 末尾）**

```swift
extension Notification.Name {
    static let territoryUpdated = Notification.Name("territoryUpdated")
    static let territoryDeleted = Notification.Name("territoryDeleted")
}
```

**2. 发送通知（TerritoryDetailView.swift）**

```swift
private func renameTerritory() async {
    // ... 更新数据库

    if success {
        await MainActor.run {
            // 更新本地对象
            territory = Territory(...)

            // 发送通知刷新领地列表
            NotificationCenter.default.post(name: .territoryUpdated, object: nil)
        }
    }
}
```

**3. 监听通知（TerritoryTabView.swift）**

```swift
var body: some View {
    // ...
    .onReceive(NotificationCenter.default.publisher(for: .territoryUpdated)) { _ in
        Task {
            await loadMyTerritories()
        }
    }
    .onReceive(NotificationCenter.default.publisher(for: .territoryDeleted)) { _ in
        Task {
            await loadMyTerritories()
        }
    }
}
```

---

### 3.4 Sheet 管理：使用 item 而非 isPresented

#### 问题

使用 `isPresented` 传递数据时，闭包内无法获取最新的选中数据。

#### 解决方案：使用 `sheet(item:)`

```swift
// 选中的建筑模板
@State private var selectedTemplateForConstruction: BuildingTemplate?

// 使用 item: 绑定，自动传递数据
.sheet(item: $selectedTemplateForConstruction) { template in
    BuildingPlacementView(
        template: template,  // 直接使用传入的 template
        territoryId: territory.id,
        // ...
    )
}

// 打开 sheet
selectedTemplateForConstruction = template

// 关闭 sheet
selectedTemplateForConstruction = nil
```

#### 关键点

- `BuildingTemplate` 需要遵循 `Identifiable` 协议
- 赋值 `selectedTemplateForConstruction = template` 自动打开 sheet
- 赋值 `nil` 自动关闭 sheet

---

### 3.5 从 Browser 到 Placement 的跳转时机

#### 问题

从建筑浏览器选择建筑后直接打开建造确认页，动画冲突。

#### 解决方案：延迟打开

```swift
// BuildingBrowserView 的回调
onStartConstruction: { template in
    showBuildingBrowser = false  // 先关闭浏览器

    // 延迟 0.3 秒等待关闭动画完成
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        selectedTemplateForConstruction = template  // 再打开建造确认
    }
}
```

---

## 四、视图层级与 Sheet 架构

### 4.1 完整视图流程

```
领地详情页 (TerritoryDetailView) - 全屏地图布局
    │
    ├─ TerritoryMapView（底层地图 + 多边形 + 建筑标记）
    │
    ├─ TerritoryToolbarView（顶部悬浮工具栏）
    │   ├─ 关闭按钮
    │   ├─ 建造按钮 → showBuildingBrowser = true
    │   └─ 信息面板切换
    │
    └─ 底部信息面板（可折叠）
        ├─ 领地名称 + 齿轮按钮（重命名）
        ├─ 领地信息卡片（面积/点数/时间）
        ├─ 建筑列表区域
        │   └─ TerritoryBuildingRow（带操作菜单）
        └─ 删除领地按钮

    │ 点击"建造"按钮
    ▼
┌──────────────────────────────────────────────────────┐
│  BuildingBrowserView (Sheet 1)                       │
│  ├─ 分类筛选栏（全部/生存/储存/生产/能源）           │
│  ├─ 建筑卡片网格                                     │
│  │                                                   │
│  │ 点击建筑卡片 → onStartConstruction(template)      │
│  └───────────────────────────────────────────────────┘
    │
    ▼ (延迟 0.3s)
┌──────────────────────────────────────────────────────┐
│ BuildingPlacementView (Sheet 2 - 由 item: 管理)      │
│ ├─ 建筑预览（图标+名称+分类）                        │
│ ├─ 建造位置选择                                      │
│ │   └─ 点击"在地图上选择位置"                        │
│ │       ▼                                            │
│ │   ┌────────────────────────────────────────────┐   │
│ │   │ BuildingLocationPickerView (Sheet 3)       │   │
│ │   │ ├─ 地图显示领地**多边形**边界               │   │
│ │   │ ├─ 显示已有建筑（避免重叠）                 │   │
│ │   │ ├─ 点击地图选择位置                         │   │
│ │   │ └─ 验证位置在多边形内                       │   │
│ │   └────────────────────────────────────────────┘   │
│ ├─ 资源消耗确认（足够绿色/不足红色）                 │
│ ├─ 建造时间显示                                      │
│ │                                                    │
│ │ 点击"确认建造"                                     │
│ ▼                                                    │
│ 扣除资源 → 创建数据库记录 → 刷新建筑列表 → 关闭      │
└──────────────────────────────────────────────────────┘
```

### 4.2 Sheet 管理代码

```swift
// TerritoryDetailView.swift

// 状态变量
@State private var showBuildingBrowser = false
@State private var selectedTemplateForConstruction: BuildingTemplate?

// Sheet 绑定
.sheet(isPresented: $showBuildingBrowser) {
    BuildingBrowserView(
        onDismiss: { showBuildingBrowser = false },
        onStartConstruction: { template in
            showBuildingBrowser = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                selectedTemplateForConstruction = template
            }
        }
    )
}
.sheet(item: $selectedTemplateForConstruction) { template in
    BuildingPlacementView(
        template: template,
        territoryId: territory.id,
        territoryCoordinates: territoryCoordinates,
        onDismiss: { selectedTemplateForConstruction = nil },
        onConstructionStarted: { building in
            selectedTemplateForConstruction = nil
            Task {
                await buildingManager.fetchPlayerBuildings(territoryId: territory.id)
            }
        }
    )
}
```

---

## 五、关键功能实现细节

### 5.1 地图选点 - 多边形边界渲染

#### LocationPickerMapView (UIKit)

```swift
struct LocationPickerMapView: UIViewRepresentable {
    let territoryCoordinates: [CLLocationCoordinate2D]
    let existingBuildings: [PlayerBuilding]
    let buildingTemplates: [String: BuildingTemplate]
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .hybrid  // 卫星混合模式

        // 添加领地多边形
        if territoryCoordinates.count >= 3 {
            let polygon = MKPolygon(coordinates: territoryCoordinates, count: territoryCoordinates.count)
            mapView.addOverlay(polygon)

            // 设置地图区域为领地范围
            let region = regionForPolygon(territoryCoordinates)
            mapView.setRegion(region, animated: false)
        }

        // 添加已有建筑标记
        context.coordinator.addExistingBuildings(to: mapView)

        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }
}
```

#### 点在多边形内算法（射线法）

```swift
private func isPointInPolygon(_ point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
    guard polygon.count >= 3 else { return false }

    var isInside = false
    var j = polygon.count - 1

    for i in 0..<polygon.count {
        let xi = polygon[i].longitude
        let yi = polygon[i].latitude
        let xj = polygon[j].longitude
        let yj = polygon[j].latitude

        if ((yi > point.latitude) != (yj > point.latitude)) &&
           (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi) {
            isInside = !isInside
        }
        j = i
    }

    return isInside
}
```

---

### 5.2 领地详情页 - 全屏地图布局

#### TerritoryDetailView 结构

```swift
var body: some View {
    ZStack {
        // 1. 全屏地图（底层）
        TerritoryMapView(
            territoryCoordinates: territoryCoordinates,
            buildings: territoryBuildings,
            templates: templateDict
        )
        .ignoresSafeArea()

        // 2. 悬浮工具栏（顶部）
        VStack {
            TerritoryToolbarView(
                onDismiss: { dismiss() },
                onBuildingBrowser: { showBuildingBrowser = true },
                showInfoPanel: $showInfoPanel
            )
            Spacer()
        }

        // 3. 可折叠信息面板（底部）
        VStack {
            Spacer()
            if showInfoPanel {
                infoPanelView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}
```

---

### 5.3 建筑行操作菜单

#### TerritoryBuildingRow 设计

```swift
struct TerritoryBuildingRow: View {
    let building: PlayerBuilding
    let template: BuildingTemplate
    var onUpgrade: (() -> Void)?
    var onDemolish: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // 左侧：分类图标
            // 中间：名称 + 状态

            Spacer()

            // 右侧：操作菜单或进度环
            if building.status == .active {
                Menu {
                    // 升级按钮
                    if building.level >= template.maxLevel {
                        Button {} label: {
                            Label("已达最高等级", systemImage: "checkmark.circle.fill")
                        }
                        .disabled(true)
                    } else {
                        Button {
                            onUpgrade?()
                        } label: {
                            Label("升级", systemImage: "arrow.up.circle")
                        }
                    }

                    // 拆除按钮
                    Button(role: .destructive) {
                        onDemolish?()
                    } label: {
                        Label("拆除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(ApocalypseTheme.primary)
                }
            } else if building.status == .constructing || building.status == .upgrading {
                CircularProgressView(progress: building.buildProgress)
                    .frame(width: 36, height: 36)
            }
        }
    }
}
```

---

### 5.4 主地图建筑显示

#### MapViewRepresentable 修改

```swift
// 在 updateUIView 中调用
private func updateBuildingAnnotations(_ mapView: MKMapView) {
    // 移除旧的建筑标注
    let buildingAnnotations = mapView.annotations.compactMap { $0 as? BuildingAnnotation }
    mapView.removeAnnotations(buildingAnnotations)

    // 添加新的建筑标记
    for building in buildings {
        guard let coord = building.coordinate else { continue }

        // ⚠️ 重要：数据库中保存的已经是 GCJ-02 坐标，直接使用无需转换

        let template = templates.first { $0.templateId == building.templateId }
        let annotation = BuildingAnnotation(
            building: building,
            coordinate: coord,
            template: template
        )
        mapView.addAnnotation(annotation)
    }
}
```

---

## 六、数据模型补充

### 6.1 PlayerBuilding 进度计算

```swift
extension PlayerBuilding {
    /// 建造进度（0.0 ~ 1.0）
    var buildProgress: Double {
        guard status == .constructing || status == .upgrading,
              let startedAt = buildStartedAt,
              let completedAt = buildCompletedAt else { return 0 }

        let total = completedAt.timeIntervalSince(startedAt)
        let elapsed = Date().timeIntervalSince(startedAt)
        return min(1.0, max(0, elapsed / total))
    }

    /// 格式化剩余时间
    var formattedRemainingTime: String {
        guard status == .constructing || status == .upgrading,
              let completedAt = buildCompletedAt else { return "" }

        let remaining = completedAt.timeIntervalSince(Date())
        guard remaining > 0 else { return "即将完成" }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}
```

### 6.2 BuildingStatus 显示属性

```swift
extension BuildingStatus {
    var displayName: String {
        switch self {
        case .constructing: return "建造中"
        case .upgrading: return "升级中"
        case .active: return "运行中"
        case .inactive: return "已停用"
        case .damaged: return "已损坏"
        }
    }

    var color: Color {
        switch self {
        case .constructing: return .orange
        case .upgrading: return .blue
        case .active: return .green
        case .inactive: return .gray
        case .damaged: return .red
        }
    }
}
```

---

## 七、开发者测试工具

### 7.1 InventoryManager 测试方法

```swift
// MARK: - 开发者测试方法

#if DEBUG
/// 添加测试资源
func addTestResources() async -> Bool {
    let testResources: [(id: String, name: String, quantity: Int)] = [
        ("79d5cc71-d98a-46ef-9a4b-4a7d7c1c0495", "木材", 200),
        ("419e6e21-dc02-4bd4-94bb-1fcb9c08f738", "石头", 150),
        ("dd722a71-ba35-4cf8-92d3-356bc10f0b35", "废金属", 100),
        ("de93eab2-daa0-43dc-b33a-1f21496ebc31", "玻璃", 50)
    ]

    for resource in testResources {
        guard let uuid = UUID(uuidString: resource.id) else { continue }
        _ = await addItem(itemId: uuid, quantity: resource.quantity, quality: nil)
    }
    return true
}

/// 清空所有背包物品
func clearAllItems() async -> Bool {
    guard let userId = try? await client.auth.session.user.id else { return false }

    do {
        try await client
            .from("inventory_items")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        self.inventoryItems = []
        return true
    } catch {
        return false
    }
}
#endif
```

---

## 八、验收标准

### 建造流程

- [x] 领地详情页有"建造"按钮
- [x] 点击进入建筑浏览页，显示所有建筑
- [x] 分类筛选正常工作
- [x] 点击建筑卡片显示详情
- [x] 点击"开始建造"进入建造确认页

### 地图选点（核心！）

- [x] 地图显示领地**多边形**边界（不是圆形！）
- [x] 显示已有建筑（避免重叠放置）
- [x] 点击地图可选择位置
- [x] 只有在领地范围内的点击才有效
- [x] 选中位置显示标记

### 建造确认

- [x] 显示建筑预览
- [x] 显示已选位置或提示选择
- [x] 资源检查正确（足够绿色，不足红色）
- [x] 未选位置时确认按钮禁用
- [x] 资源不足时确认按钮禁用
- [x] 点击确认，资源正确扣除

### 领地建筑列表

- [x] 领地详情页显示建筑列表
- [x] 每个建筑显示状态徽章
- [x] 建造中的建筑显示进度条
- [x] 建造中的建筑显示倒计时
- [x] 活跃建筑有操作菜单（升级/拆除）

### 领地管理

- [x] 领地可重命名（齿轮按钮）
- [x] 重命名后列表立即刷新（NotificationCenter）

### 主地图建筑显示

- [x] 主地图上能看到建筑标注
- [x] 建筑位置正确（无偏移）

---

## 九、踩坑总结清单

| 问题            | 原因                    | 解决方案                     |
| ------------- | --------------------- | ------------------------ |
| 建筑位置偏移 500m   | 数据库已是 GCJ-02，又做了一次转换  | 直接使用数据库坐标，不转换            |
| 位置选择器无法避开已有建筑 | 没有传入已有建筑列表            | 添加 existingBuildings 参数  |
| 重命名后列表不刷新     | 只更新了详情页的 @State       | 使用 NotificationCenter 通知 |
| Sheet 数据传递失败  | 使用 isPresented 无法传递数据 | 改用 sheet(item:) 绑定       |
| Sheet 跳转动画冲突  | 关闭和打开动画重叠             | 延迟 0.3s 再打开新 Sheet       |

---

*Day 29 建造系统完整开发方案 v4.0*
*已完成实现，包含所有踩坑记录和解决方案*
