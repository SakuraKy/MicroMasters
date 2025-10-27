#!/usr/bin/env python3

# 读取项目文件
with open('MicroMasters.xcodeproj/project.pbxproj', 'r') as f:
    lines = f.readlines()

# 找到 Settings 组 (6AA1C2172EAF73F80008F5DE) 并移除其 path
new_lines = []
in_settings_group = False
for i, line in enumerate(lines):
    if '6AA1C2172EAF73F80008F5DE /* Settings */' in line:
        in_settings_group = True
        new_lines.append(line)
    elif in_settings_group and 'path = Settings;' in line:
        # 跳过这一行,不添加 path
        in_settings_group = False
        continue
    elif in_settings_group and '};' in line:
        in_settings_group = False
        new_lines.append(line)
    else:
        new_lines.append(line)

# 写回文件
with open('MicroMasters.xcodeproj/project.pbxproj', 'w') as f:
    f.writelines(new_lines)

print('✅ 已移除 Settings 组的 path 属性')
