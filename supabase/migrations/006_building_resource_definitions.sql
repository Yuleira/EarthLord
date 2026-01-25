-- 《地球新主》建筑资源物品定义
-- Migration: 006_building_resource_definitions
--
-- 与 building_templates.json 的 required_resources 键完全一致，
-- 使 inventory_items.item_definition_id 能通过 FK 校验。

INSERT INTO item_definitions (id, name, description, category, icon, rarity) VALUES
-- 建筑资源（ID 必须与 building_templates.json 的 wood/stone/fabric/metal/glass/circuit 一致）
-- scrap_metal 已在 003 中存在，此处不重复插入
('wood',   'item_wood',   'item_scrap_metal_desc', 'material', 'tree.fill',                   'common'),
('stone',  'item_stone',  'item_scrap_metal_desc', 'material', 'square.stack.3d.up.fill',     'common'),
('metal',  'item_metal',  'item_scrap_metal_desc', 'material', 'gearshape.fill',              'common'),
('fabric', 'item_fabric', 'item_scrap_metal_desc', 'material', 'scissors',                    'common'),
('glass',  'item_glass',  'item_scrap_metal_desc', 'material', 'circle.grid.cross.fill',      'common'),
('circuit','item_circuit','item_scrap_metal_desc', 'material', 'cpu.fill',                    'common')
ON CONFLICT (id) DO NOTHING;
