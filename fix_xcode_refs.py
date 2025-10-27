#!/usr/bin/env python3
import sys

# 读取项目文件
with open('MicroMasters.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# 找到 ShortcutSettings.swift 的引用并更新路径
# 需要找到这个文件的 UUID: 6AA1C2152EAF73CA0008F5DE
# 当前: path = ShortcutSettings.swift;
# 应该: path = Domain/Models/ShortcutSettings.swift;

# 找到 ShortcutSettingsWindow.swift 的引用并更新路径  
# UUID: 6AA1C2182EAF74380008F5DE
# 当前: path = ShortcutSettingsWindow.swift;
# 应该: path = UI/Settings/ShortcutSettingsWindow.swift;

# 替换 ShortcutSettings.swift 的引用
lines = content.split('\n')
new_lines = []
for line in lines:
    if '6AA1C2152EAF73CA0008F5DE' in line and 'path = ShortcutSettings.swift;' in line:
        # 找到这一行,替换路径
        line = line.replace('path = ShortcutSettings.swift;', 'path = Domain/Models/ShortcutSettings.swift;')
    elif '6AA1C2182EAF74380008F5DE' in line and 'path = ShortcutSettingsWindow.swift;' in line:
        # 找到这一行,替换路径
        line = line.replace('path = ShortcutSettingsWindow.swift;', 'path = UI/Settings/ShortcutSettingsWindow.swift;')
    new_lines.append(line)

# 写回文件
with open('MicroMasters.xcodeproj/project.pbxproj', 'w') as f:
    f.write('\n'.join(new_lines))

print('✅ 项目文件已更新!')
print('ShortcutSettings.swift 路径: Domain/Models/ShortcutSettings.swift')
print('ShortcutSettingsWindow.swift 路径: UI/Settings/ShortcutSettingsWindow.swift')
