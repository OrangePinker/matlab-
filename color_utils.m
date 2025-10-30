function varargout = color_utils(action, varargin)
% 颜色工具函数集合
% 提供各种颜色分析和处理功能
%
% 用法：
%   result = color_utils('action', parameters...)
%
% 支持的操作：
%   'analyze' - 分析颜色特征
%   'harmony' - 生成和谐配色
%   'convert' - 颜色空间转换
%   'similarity' - 计算颜色相似度
%   'palette' - 生成调色板
%   'temperature' - 分析色温

switch lower(action)
    case 'analyze'
        varargout{1} = analyze_colors(varargin{:});
    case 'harmony'
        varargout{1} = generate_harmony(varargin{:});
    case 'convert'
        varargout{1} = convert_colorspace(varargin{:});
    case 'similarity'
        varargout{1} = calculate_similarity(varargin{:});
    case 'palette'
        varargout{1} = generate_palette(varargin{:});
    case 'temperature'
        varargout{1} = analyze_temperature(varargin{:});
    otherwise
        error('不支持的操作: %s', action);
end
end

function result = analyze_colors(colors)
% 分析颜色特征
% 输入: colors - RGB颜色矩阵 (N x 3)
% 输出: result - 包含各种颜色特征的结构体

if size(colors, 2) ~= 3
    error('颜色矩阵必须是 N x 3 格式');
end

result = struct();

% 转换到不同颜色空间
hsv_colors = rgb2hsv(colors);
lab_colors = rgb2lab(colors);

% 基本统计
result.num_colors = size(colors, 1);
result.rgb_mean = mean(colors, 1);
result.rgb_std = std(colors, 0, 1);

% HSV分析
result.hue_mean = mean(hsv_colors(:, 1));
result.hue_std = std(hsv_colors(:, 1));
result.saturation_mean = mean(hsv_colors(:, 2));
result.saturation_std = std(hsv_colors(:, 2));
result.brightness_mean = mean(hsv_colors(:, 3));
result.brightness_std = std(hsv_colors(:, 3));

% 色彩分布分析
result.dominant_hue = mode(round(hsv_colors(:, 1) * 12)) / 12; % 12色相分区
result.color_diversity = calculate_diversity(colors);
result.warmth_score = calculate_warmth(colors);

% 颜色和谐度
result.harmony_score = calculate_harmony_score(hsv_colors);

% 对比度分析
result.contrast_score = calculate_contrast(colors);

% 色彩情感分析
result.emotion = analyze_emotion(hsv_colors);

fprintf('\n=== 颜色特征分析 ===\n');
fprintf('颜色数量: %d\n', result.num_colors);
fprintf('平均RGB: [%.3f, %.3f, %.3f]\n', result.rgb_mean);
fprintf('平均色相: %.3f\n', result.hue_mean);
fprintf('平均饱和度: %.3f\n', result.saturation_mean);
fprintf('平均亮度: %.3f\n', result.brightness_mean);
fprintf('色彩多样性: %.3f\n', result.color_diversity);
fprintf('暖色调评分: %.3f\n', result.warmth_score);
fprintf('和谐度评分: %.3f\n', result.harmony_score);
fprintf('对比度评分: %.3f\n', result.contrast_score);
fprintf('色彩情感: %s\n', result.emotion);
end

function diversity = calculate_diversity(colors)
% 计算色彩多样性
distances = pdist(colors, 'euclidean');
diversity = mean(distances);
end

function warmth = calculate_warmth(colors)
% 计算暖色调评分 (0-1, 1为最暖)
% 基于红色和黄色成分
red_weight = colors(:, 1);
yellow_weight = min(colors(:, 1), colors(:, 2));
blue_weight = colors(:, 3);

warmth = mean((red_weight + yellow_weight - blue_weight) / 2);
warmth = max(0, min(1, warmth));
end

function harmony = calculate_harmony_score(hsv_colors)
% 计算颜色和谐度评分
hues = hsv_colors(:, 1) * 360; % 转换为度数

% 检查常见的和谐关系
harmony_types = [
    60,   % 类似色
    120,  % 三角色
    180   % 互补色
];

harmony_scores = zeros(size(harmony_types));
for i = 1:length(harmony_types)
    angle = harmony_types(i);
    for j = 1:length(hues)
        for k = j+1:length(hues)
            diff = abs(hues(j) - hues(k));
            diff = min(diff, 360 - diff); % 处理环形距离
            if abs(diff - angle) < 30 % 30度容差
                harmony_scores(i) = harmony_scores(i) + 1;
            end
        end
    end
end

harmony = max(harmony_scores) / (length(hues) * (length(hues) - 1) / 2);
end

function contrast = calculate_contrast(colors)
% 计算对比度评分
if size(colors, 1) < 2
    contrast = 0;
    return;
end

% 计算所有颜色对之间的对比度
contrasts = [];
for i = 1:size(colors, 1)
    for j = i+1:size(colors, 1)
        % 使用相对亮度计算对比度
        L1 = 0.2126*colors(i,1) + 0.7152*colors(i,2) + 0.0722*colors(i,3);
        L2 = 0.2126*colors(j,1) + 0.7152*colors(j,2) + 0.0722*colors(j,3);
        contrast_ratio = (max(L1, L2) + 0.05) / (min(L1, L2) + 0.05);
        contrasts(end+1) = contrast_ratio;
    end
end

contrast = mean(contrasts);
end

function emotion = analyze_emotion(hsv_colors)
% 分析色彩情感倾向
hue_mean = mean(hsv_colors(:, 1));
sat_mean = mean(hsv_colors(:, 2));
val_mean = mean(hsv_colors(:, 3));

% 基于HSV值判断情感倾向
if val_mean > 0.7 && sat_mean > 0.6
    if hue_mean < 0.1 || hue_mean > 0.9 % 红色系
        emotion = '热情/活力';
    elseif hue_mean < 0.2 % 橙色系
        emotion = '温暖/友好';
    elseif hue_mean < 0.35 % 黄色系
        emotion = '快乐/明亮';
    elseif hue_mean < 0.65 % 绿色系
        emotion = '自然/平静';
    elseif hue_mean < 0.75 % 蓝色系
        emotion = '冷静/专业';
    else % 紫色系
        emotion = '神秘/优雅';
    end
elseif val_mean < 0.3
    emotion = '深沉/严肃';
elseif sat_mean < 0.3
    emotion = '中性/简约';
else
    emotion = '平衡/和谐';
end
end

function harmony_colors = generate_harmony(base_color, harmony_type, num_colors)
% 生成和谐配色
% 输入:
%   base_color - 基础颜色 RGB (1x3)
%   harmony_type - 和谐类型: 'monochromatic', 'analogous', 'complementary', 'triadic', 'tetradic'
%   num_colors - 生成颜色数量
% 输出:
%   harmony_colors - 和谐配色 RGB矩阵

if nargin < 3
    num_colors = 5;
end

base_hsv = rgb2hsv(base_color);
harmony_colors = zeros(num_colors, 3);

switch lower(harmony_type)
    case 'monochromatic' % 单色调和
        for i = 1:num_colors
            new_hsv = base_hsv;
            % 调整饱和度和明度
            new_hsv(2) = max(0.1, min(1, base_hsv(2) + (i-3)*0.2));
            new_hsv(3) = max(0.1, min(1, base_hsv(3) + (i-3)*0.15));
            harmony_colors(i, :) = hsv2rgb(new_hsv);
        end
        
    case 'analogous' % 类似色
        hue_step = 0.08; % 约30度
        for i = 1:num_colors
            new_hsv = base_hsv;
            new_hsv(1) = mod(base_hsv(1) + (i-3)*hue_step, 1);
            harmony_colors(i, :) = hsv2rgb(new_hsv);
        end
        
    case 'complementary' % 互补色
        harmony_colors(1, :) = base_color;
        if num_colors > 1
            comp_hsv = base_hsv;
            comp_hsv(1) = mod(comp_hsv(1) + 0.5, 1);
            harmony_colors(2, :) = hsv2rgb(comp_hsv);
        end
        % 填充其余颜色为单色调变化
        for i = 3:num_colors
            new_hsv = base_hsv;
            new_hsv(3) = max(0.2, min(1, base_hsv(3) + (i-2)*0.2));
            harmony_colors(i, :) = hsv2rgb(new_hsv);
        end
        
    case 'triadic' % 三角色
        hue_offsets = [0, 0.333, 0.667]; % 0°, 120°, 240°
        for i = 1:min(3, num_colors)
            new_hsv = base_hsv;
            new_hsv(1) = mod(base_hsv(1) + hue_offsets(i), 1);
            harmony_colors(i, :) = hsv2rgb(new_hsv);
        end
        % 填充其余颜色
        for i = 4:num_colors
            idx = mod(i-1, 3) + 1;
            new_hsv = rgb2hsv(harmony_colors(idx, :));
            new_hsv(3) = max(0.2, min(1, new_hsv(3) - 0.3));
            harmony_colors(i, :) = hsv2rgb(new_hsv);
        end
        
    case 'tetradic' % 四角色
        hue_offsets = [0, 0.25, 0.5, 0.75]; % 0°, 90°, 180°, 270°
        for i = 1:min(4, num_colors)
            new_hsv = base_hsv;
            new_hsv(1) = mod(base_hsv(1) + hue_offsets(i), 1);
            harmony_colors(i, :) = hsv2rgb(new_hsv);
        end
        % 填充其余颜色
        for i = 5:num_colors
            idx = mod(i-1, 4) + 1;
            new_hsv = rgb2hsv(harmony_colors(idx, :));
            new_hsv(2) = max(0.2, min(1, new_hsv(2) - 0.3));
            harmony_colors(i, :) = hsv2rgb(new_hsv);
        end
        
    otherwise
        error('不支持的和谐类型: %s', harmony_type);
end

% 确保颜色值在有效范围内
harmony_colors = max(0, min(1, harmony_colors));
end

function converted = convert_colorspace(colors, from_space, to_space)
% 颜色空间转换
% 支持: 'rgb', 'hsv', 'lab', 'xyz'

switch lower(from_space)
    case 'rgb'
        switch lower(to_space)
            case 'hsv'
                converted = rgb2hsv(colors);
            case 'lab'
                converted = rgb2lab(colors);
            case 'xyz'
                converted = rgb2xyz(colors);
            case 'rgb'
                converted = colors;
            otherwise
                error('不支持的目标颜色空间: %s', to_space);
        end
    case 'hsv'
        rgb_colors = hsv2rgb(colors);
        converted = convert_colorspace(rgb_colors, 'rgb', to_space);
    case 'lab'
        rgb_colors = lab2rgb(colors);
        converted = convert_colorspace(rgb_colors, 'rgb', to_space);
    case 'xyz'
        rgb_colors = xyz2rgb(colors);
        converted = convert_colorspace(rgb_colors, 'rgb', to_space);
    otherwise
        error('不支持的源颜色空间: %s', from_space);
end
end

function similarity = calculate_similarity(color1, color2, method)
% 计算颜色相似度
% method: 'euclidean', 'delta_e', 'cosine'

if nargin < 3
    method = 'euclidean';
end

switch lower(method)
    case 'euclidean'
        similarity = 1 / (1 + norm(color1 - color2));
        
    case 'delta_e'
        % 使用CIE Delta E 2000公式（简化版）
        lab1 = rgb2lab(color1);
        lab2 = rgb2lab(color2);
        delta_e = sqrt(sum((lab1 - lab2).^2));
        similarity = 1 / (1 + delta_e / 100);
        
    case 'cosine'
        similarity = dot(color1, color2) / (norm(color1) * norm(color2));
        
    otherwise
        error('不支持的相似度计算方法: %s', method);
end
end

function palette = generate_palette(base_colors, palette_type, size_limit)
% 生成调色板
% palette_type: 'gradient', 'discrete', 'mixed'

if nargin < 3
    size_limit = 256;
end

switch lower(palette_type)
    case 'gradient'
        palette = generate_gradient_palette(base_colors, size_limit);
    case 'discrete'
        palette = generate_discrete_palette(base_colors, size_limit);
    case 'mixed'
        palette = generate_mixed_palette(base_colors, size_limit);
    otherwise
        error('不支持的调色板类型: %s', palette_type);
end
end

function palette = generate_gradient_palette(colors, size_limit)
% 生成渐变调色板
num_colors = size(colors, 1);
if num_colors < 2
    palette = repmat(colors, size_limit, 1);
    return;
end

% 在颜色之间创建平滑渐变
palette = zeros(size_limit, 3);
segment_size = size_limit / (num_colors - 1);

for i = 1:num_colors-1
    start_idx = round((i-1) * segment_size) + 1;
    end_idx = round(i * segment_size);
    
    if end_idx > size_limit
        end_idx = size_limit;
    end
    
    segment_length = end_idx - start_idx + 1;
    for j = 1:segment_length
        t = (j-1) / (segment_length-1);
        palette(start_idx + j - 1, :) = (1-t) * colors(i, :) + t * colors(i+1, :);
    end
end
end

function palette = generate_discrete_palette(colors, size_limit)
% 生成离散调色板
num_colors = size(colors, 1);
palette = zeros(size_limit, 3);

for i = 1:size_limit
    color_idx = mod(i-1, num_colors) + 1;
    palette(i, :) = colors(color_idx, :);
end
end

function palette = generate_mixed_palette(colors, size_limit)
% 生成混合调色板（原色+渐变）
num_original = size(colors, 1);
num_gradients = size_limit - num_original;

if num_gradients <= 0
    palette = colors(1:size_limit, :);
    return;
end

palette = [colors; generate_gradient_palette(colors, num_gradients)];
end

function temp_info = analyze_temperature(colors)
% 分析色温信息
temp_info = struct();

% 计算每个颜色的色温
temperatures = zeros(size(colors, 1), 1);
for i = 1:size(colors, 1)
    temperatures(i) = estimate_color_temperature(colors(i, :));
end

temp_info.individual_temps = temperatures;
temp_info.mean_temp = mean(temperatures);
temp_info.temp_range = [min(temperatures), max(temperatures)];
temp_info.temp_category = categorize_temperature(temp_info.mean_temp);

fprintf('\n=== 色温分析 ===\n');
fprintf('平均色温: %.0f K (%s)\n', temp_info.mean_temp, temp_info.temp_category);
fprintf('色温范围: %.0f - %.0f K\n', temp_info.temp_range(1), temp_info.temp_range(2));
end

function temp = estimate_color_temperature(rgb_color)
% 估算RGB颜色的色温（简化算法）
% 基于RGB比值估算

r = rgb_color(1);
g = rgb_color(2);
b = rgb_color(3);

% 避免除零
if r == 0
    r = 0.001;
end

% 使用经验公式估算色温
if b/r >= 1.0
    temp = 3000 + 2000 * (b/r - 1);
else
    temp = 3000 - 1000 * (1 - b/r);
end

% 限制在合理范围内
temp = max(1000, min(10000, temp));
end

function category = categorize_temperature(temp)
% 色温分类
if temp < 3000
    category = '暖光';
elseif temp < 4000
    category = '中性偏暖';
elseif temp < 5000
    category = '中性';
elseif temp < 6500
    category = '中性偏冷';
else
    category = '冷光';
end
end