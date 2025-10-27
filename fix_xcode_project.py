#!/usr/bin/env python3
import re
import uuid

# 读取项目文件
with open('MicroMasters.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# 生成新的 UUID
def new_uuid():
    return uuid.uuid4().hex[:24].upper()

# 查找是否已经有这些文件的引用
has_shortcut_settings = 'ShortcutSettings.swift' in content
has_shortcut_window = 'ShortcutSettingsWindow.swift' in content

print(f"ShortcutSettings.swift 在项目中: {has_shortcut_settings}")
print(f"ShortcutSettingsWindow.swift 在项目中: {has_shortcut_window}")

# 如果文件不在项目中，需要添加
if not has_shortcut_settings or not has_shortcut_window:
    print("\n需要添加文件到项目...")
    print("请在 Xcode 中手动添加文件。")
else:
    print("\n文件已在项目中，检查路径是否正确...")
    
    # 检查路径是否正确
    if 'MicroMasters/Domain/Models/ShortcutSettings.swift' not in content:
        print("⚠️ ShortcutSettings.swift 路径可能不正确")
    else:
        print("✅ ShortcutSettings.swift 路径正确")
        
    if 'MicroMasters/UI/Settings/ShortcutSettingsWindow.swift' not in content:
        print("⚠️ ShortcutSettingsWindow.swift 路径可能不正确")
    else:
        print("✅ ShortcutSettingsWindow.swift 路径正确")

print("\n项目文件分析完成！")
