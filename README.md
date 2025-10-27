# HMD2FBX - Heaps Model Data to FBX Converter

将 Heaps 引擎的 HMD/HWD 模型文件转换回 FBX 格式的工具。

## 环境要求

- **Heaps 源码**: 2.1.0
- **Haxe**: 4.3.2
- **HashLink**: 1.15.0
- **format library**: 通过 haxelib 安装

## 快速开始

### 1. 获取 Heaps 源码

本工具需要在 Heaps 源码目录下编译和运行。

```bash
# 下载 Heaps 源码
git clone https://github.com/HeapsIO/heaps.git
cd heaps

# 或者下载特定版本
git clone -b 2.1.0 https://github.com/HeapsIO/heaps.git
cd heaps
```

### 2. 放置工具文件

将 `hmd2fbx` 目录放在 Heaps 源码根目录下：

```
heaps/
├── h2d/
├── h3d/
├── hxd/
├── hxsl/
├── hmd2fbx/          # 本工具目录
│   ├── HMD2FBX.hx
│   ├── HMD2FBX.hxml
│   └── README.md
└── ...
```

### 3. 安装依赖

```bash
haxelib install format
```

### 4. 编译

```bash
cd hmd2fbx
haxe HMD2FBX.hxml
```

### 5. 使用

```bash
hl HMD2FBX.hl <input.hmd|hwd> <output.fbx>
```

**示例：**

```bash
hl HMD2FBX.hl model.hmd model.fbx
hl HMD2FBX.hl game_model.hwd exported.fbx
```

## 输出格式

工具输出 **ASCII 格式** 的 FBX 文件，包含：

- 顶点位置、法线、UV 坐标
- 模型层级结构
- 材质名称和纹理引用

## 转换为二进制 FBX

ASCII FBX 文件较大，可使用 Autodesk FBX Converter 转换为二进制格式：

### 下载

https://www.autodesk.com/developer-network/platform-technologies/fbx-converter-archives

### 转换命令

**Windows:**
```bash
"C:\Program Files\Autodesk\FBX\FBX Converter\2013.3\bin\FbxConverter.exe" ^
    input.fbx output_binary.fbx /sffFBX /dffFBX /binary
```

**Linux/Mac:**
```bash
FbxConverter input.fbx output_binary.fbx /sffFBX /dffFBX /binary
```

## 批量转换

可根据需要编写批量脚本。以下是一些示例：

### Windows PowerShell

```powershell
Get-ChildItem -Filter *.hwd | ForEach-Object {
    $input = $_.FullName
    $output = $_.BaseName + ".fbx"
    Write-Host "Converting: $($_.Name)"
    hl HMD2FBX.hl $input $output
}
```

### Linux/Mac Bash

```bash
for file in *.hwd; do
    output="${file%.hwd}.fbx"
    echo "Converting: $file"
    hl HMD2FBX.hl "$file" "$output"
done
```

### Python

```python
import subprocess
from pathlib import Path

input_dir = "path/to/hwd/files"
output_dir = "path/to/output"

for hwd_file in Path(input_dir).rglob("*.hwd"):
    output_file = Path(output_dir) / hwd_file.relative_to(input_dir).with_suffix(".fbx")
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    print(f"Converting: {hwd_file.name}")
    subprocess.run(["hl", "HMD2FBX.hl", str(hwd_file), str(output_file)])
```

## 功能特性

- ✅ 支持 HMD v2 和 v4 格式
- ✅ 完整导出几何数据（顶点、法线、UV）
- ✅ 保留模型层级结构
- ✅ 导出材质和纹理引用
- ✅ 支持多材质模型

## 注意事项

### 纹理文件

转换后的 FBX 文件包含纹理路径引用，但不包含实际纹理文件。需要：

- 手动提取纹理文件
- 将纹理放置在 FBX 引用的路径下
- 或在 3D 软件中重新指定纹理路径

### 材质

导出的材质仅包含名称和基本属性，可能需要在 3D 软件中调整材质参数。

## 常见问题

### 编译错误

如果遇到 "Type not found" 错误：

```bash
# 确保已安装 format 库
haxelib install format

# 确保在正确的目录下编译
cd hmd2fbx
haxe HMD2FBX.hxml
```

### 运行时错误

如果遇到 "Invalid signature" 错误，确保 HashLink 版本匹配（推荐 1.15.0）。

### UV 坐标

如果贴图显示不正确：
- 检查纹理文件是否存在
- 确认纹理路径是否正确
- 在 3D 软件中检查 UV 映射

## 相关链接

- [Heaps 官网](http://heaps.io)
- [Haxe 官网](https://haxe.org)
- [HashLink 官网](https://hashlink.haxe.org)
- [Autodesk FBX Converter](https://www.autodesk.com/developer-network/platform-technologies/fbx-converter-archives)

## 许可证

本工具基于 Heaps 引擎开发，遵循 BSD 许可证。

---

**版本**: 1.0  
**日期**: 2025-10-25
