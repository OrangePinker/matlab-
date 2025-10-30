# matlab-
MATLAB颜色提取程序
## 🎯 完成的优化和扩展
### 1. MATLAB运行时兼容性修复 ✅
- 添加了完整的参数验证和默认值设置
- 增强了错误处理机制，包括文件存在性检查
- 支持灰度图像自动转换为RGB
- 优化了工具箱依赖检查（Statistics Toolbox）
### 2. 算法性能优化 ✅
- 九宫格法 ：动态调整bins数量，根据图片分辨率自适应
- K均值法 ：改进采样策略，增加稳定性参数
- 添加回退机制，当主算法失败时自动切换
- 优化内存使用，支持大图片处理
### 3. 功能扩展 ✅
- 新增 中位切分算法 （Median Cut）
- 新增 直方图算法 （Histogram）
- 添加十六进制颜色值显示
- 增强颜色分析功能（色温、情感、和谐度等）
### 4. 图形用户界面 ✅
创建了完整的GUI界面 `color_extractor_gui.m` ：

- 直观的图片选择和预览
- 参数设置面板（颜色数量、提取方法）
- 实时结果显示和颜色条展示
- 颜色数据导出功能（TXT/CSV格式）
- 配色方案生成器
- 帮助和关于信息
### 5. 颜色工具函数集 ✅
创建了 `color_utils.m` 提供：

- 颜色特征分析（多样性、暖度、对比度等）
- 和谐配色生成（单色、互补、三角、四角配色）
- 颜色空间转换（RGB/HSV/LAB/XYZ）
- 颜色相似度计算
- 调色板生成
- 色温分析
## 📁 项目结构
```
COLOR/
├── extract_dominant_color.m    # 核心
颜色提取函数（已优化）
├── color_extractor_gui.m       # 图形
用户界面（新增）
├── color_utils.m               # 颜色
工具函数集（新增）
└── README.md                   # 项目
说明文档（新增）
```
## 🚀 使用方法
### 启动GUI界面（推荐）：
```
color_extractor_gui
```
### 命令行使用：
```
% 使用默认参数
colors = extract_dominant_color();

% 指定参数
colors = extract_dominant_color(8, 
'grid', 1);

% 指定图片路径
colors = extract_dominant_color(5, 
'kmeans', 1, 'image.jpg');
```
