
function C = extract_dominant_color(N, method, seka_flag, img_path)
% 图片主题色自动提取函数（优化版）
% 输入参数：
%   N - 提取的主题色数量（默认8）
%   method - 提取方法：'grid'（九宫格）或'kmeans'（K均值）（默认'grid'）
%   seka_flag - 是否显示可视化结果（默认1）
%   img_path - 图片路径（可选，如果不提供则弹出文件选择对话框）
% 输出：
%   C - 主题色RGB矩阵（0-1范围）
%
% 使用示例：
%   C = extract_dominant_color();  % 使用默认参数
%   C = extract_dominant_color(8, 'grid', 1);
%   C = extract_dominant_color(5, 'kmeans', 0, 'image.jpg');

% 参数验证和默认值设置
if nargin < 1 || isempty(N)
    N = 8;
end
if nargin < 2 || isempty(method)
    method = 'grid';
end
if nargin < 3 || isempty(seka_flag)
    seka_flag = 1;
end

% 验证参数有效性
if ~isnumeric(N) || N < 1 || N > 20
    error('颜色数量N必须是1-20之间的整数');
end
N = round(N);

if ~ischar(method) && ~isstring(method)
    error('方法参数必须是字符串');
end

% 图片加载
if nargin < 4 || isempty(img_path)
    % 选择图片文件
    [file, path] = uigetfile({'*.jpg;*.png;*.jpeg;*.bmp;*.tiff;*.gif', '图片文件 (*.jpg;*.png;*.jpeg;*.bmp;*.tiff;*.gif)'});
    if isequal(file, 0)
        error('未选择图片');
    end
    img_path = fullfile(path, file);
end

% 检查文件是否存在
if ~exist(img_path, 'file')
    error('图片文件不存在: %s', img_path);
end

try
    img = imread(img_path);
    % 处理灰度图像
    if size(img, 3) == 1
        img = repmat(img, [1, 1, 3]);
    end
    img = im2double(img);
catch ME
    error('无法读取图片文件: %s\n错误信息: %s', img_path, ME.message);
end

% 将图像转换为像素颜色矩阵
[h, w, ~] = size(img);
pixels = reshape(img, h*w, 3);

valid_counts = []; % 初始化颜色计数变量

switch lower(method)
    case 'grid' % 九宫格算法（优化版）
        % 动态调整bins数量
        total_pixels = h * w;
        if total_pixels > 1000000  % 大图片
            bins = 12;
        elseif total_pixels > 500000  % 中等图片
            bins = 10;
        else  % 小图片
            bins = 8;
        end
        
        bin_size = 1 / bins;
        
        % 优化索引计算
        indices = min(floor(pixels / bin_size), bins-1) + 1;
        
        % 使用更高效的线性索引计算
        linear_idx = indices(:,1) + (indices(:,2)-1)*bins + (indices(:,3)-1)*bins^2;
        
        % 统计颜色频次
        counts = accumarray(linear_idx, 1, [bins^3 1]);
        
        % 获取前N个最频繁的颜色
        [sorted_counts, idx] = sort(counts, 'descend');
        valid_idx = find(sorted_counts > 0);
        num_colors = min(N, length(valid_idx));
        
        if num_colors == 0
            error('无法提取到有效颜色');
        end
        
        valid_counts = sorted_counts(1:num_colors);
        
        C = zeros(num_colors, 3);
        for i = 1:num_colors
            [r, g, b] = ind2sub([bins, bins, bins], idx(i));
            C(i,:) = ([r, g, b] - 0.5) * bin_size;
        end
        
    case 'kmeans' % K均值算法（优化版）
        % 动态采样策略
        total_pixels = h * w;
        if total_pixels > 50000
            max_samples = min(20000, total_pixels);
            sample_idx = randperm(total_pixels, max_samples);
            pixels = pixels(sample_idx, :);
        end
        
        % 确保N不超过实际像素数
        N = min(N, size(pixels, 1));
        
        try
            % 使用更稳定的K-means参数
            if exist('kmeans', 'file') == 2
                % 检查是否有Statistics Toolbox
                [idx, centers] = kmeans(pixels, N, 'Replicates', 5, 'MaxIter', 300, 'Display', 'off');
                C = centers;
                % 计算每个簇的样本数量
                valid_counts = accumarray(idx, 1, [N 1]);
            else
                warning('Statistics Toolbox不可用，使用九宫格法替代');
                [C, valid_counts] = grid_method_fallback(pixels, N, h, w);
            end
        catch ME
            warning('K-means失败: %s，使用九宫格法替代', ME.message);
            [C, valid_counts] = grid_method_fallback(pixels, N, h, w);
        end
        
    case 'median_cut' % 中位切分算法（新增）
        [C, valid_counts] = median_cut_algorithm(pixels, N);
        
    case 'histogram' % 直方图算法（新增）
        [C, valid_counts] = histogram_algorithm(pixels, N);
        
    otherwise
        error('无效的提取方法。支持的方法：grid, kmeans, median_cut, histogram');
end

% 按亮度排序颜色（HSV空间）
if size(C, 1) > 1
    hsv_colors = rgb2hsv(C);
    [~, sort_idx] = sort(hsv_colors(:,3), 'descend');
    C = C(sort_idx, :);
    if ~isempty(valid_counts)  % 保持颜色计数与排序后的颜色对应
        valid_counts = valid_counts(sort_idx);
    end
end

% 确保颜色值在有效范围内
C = max(0, min(1, C));

% 显示完整颜色矩阵
if nargout == 0 || seka_flag
    fprintf('\n=== 颜色提取结果 ===\n');
    fprintf('提取方法: %s\n', upper(method));
    fprintf('颜色数量: %d\n', size(C, 1));
    fprintf('\nRGB颜色矩阵（0-1范围）:\n');
    disp(C)
    
    % 显示0-255整数格式
    C_255 = round(C * 255);
    fprintf('\nRGB颜色矩阵（0-255范围）:\n');
    disp(C_255)
    
    % 显示十六进制颜色值
    fprintf('\n十六进制颜色值:\n');
    for i = 1:size(C_255, 1)
        fprintf('#%02X%02X%02X\n', C_255(i,1), C_255(i,2), C_255(i,3));
    end
end

% 可视化展示（优化版）
if seka_flag
    C_255 = round(C * 255);  % 确保C_255已定义
    
    figure('Name','主题色提取结果','NumberTitle','off', 'Position', [100 100 1200 700])
    
    % 原图显示
    subplot('Position', [0.05 0.4 0.9 0.55])
    imshow(img)
    title(sprintf('原始图片 - %s', img_path), 'FontSize', 12, 'Interpreter', 'none')
    
    % 颜色条显示
    subplot('Position', [0.05 0.05 0.9 0.3])
    hold on
    
    % 计算颜色比例
    if isempty(valid_counts) || length(valid_counts) ~= size(C,1)
        valid_counts = ones(size(C,1), 1); % 默认等宽显示
    end
    proportions = valid_counts / sum(valid_counts);
    percentages = round(proportions * 100, 1);
    
    current_x = 0;
    for i = 1:size(C,1)
        % 绘制颜色块
        rectangle('Position', [current_x, 0, proportions(i), 1],...
                 'FaceColor', C(i,:), 'EdgeColor', 'black', 'LineWidth', 0.5)
        
        % 计算文本颜色对比度
        brightness = 0.2126*C(i,1) + 0.7152*C(i,2) + 0.0722*C(i,3);
        text_color = [1 1 1]; % 白色
        if brightness > 0.5
            text_color = [0 0 0]; % 黑色
        end
        
        % 添加标注
        if proportions(i) > 0.12 % 宽色块显示详细信息
            % RGB值
            text(current_x + proportions(i)/2, 0.75,...
                sprintf('RGB: %d,%d,%d', C_255(i,1), C_255(i,2), C_255(i,3)),...
                'Color', text_color, 'HorizontalAlignment', 'center',...
                'VerticalAlignment', 'middle', 'FontSize', 9, 'FontWeight', 'bold');
            
            % 十六进制值
            text(current_x + proportions(i)/2, 0.5,...
                sprintf('#%02X%02X%02X', C_255(i,1), C_255(i,2), C_255(i,3)),...
                'Color', text_color, 'HorizontalAlignment', 'center',...
                'VerticalAlignment', 'middle', 'FontSize', 8, 'FontWeight', 'bold');
            
            % 百分比
            text(current_x + proportions(i)/2, 0.25,...
                sprintf('%.1f%%', percentages(i)),...
                'Color', text_color, 'HorizontalAlignment', 'center',...
                'VerticalAlignment', 'middle', 'FontSize', 10, 'FontWeight', 'bold');
        else % 窄色块显示简化信息
            text(current_x + proportions(i)/2, 0.5,...
                sprintf('%d,%d,%d\n%.1f%%', C_255(i,1), C_255(i,2), C_255(i,3), percentages(i)),...
                'Color', text_color, 'HorizontalAlignment', 'center',...
                'VerticalAlignment', 'middle', 'FontSize', 7, 'FontWeight', 'bold');
        end
        
        current_x = current_x + proportions(i);
    end
    
    axis([0 1 0 1])
    set(gca, 'XTick', [], 'YTick', [])
    title(sprintf('提取的主题色 (%s方法)', upper(method)), 'FontSize', 12)
    hold off
    
    % 显示颜色占比分析
    if exist('valid_counts', 'var') && ~isempty(valid_counts) && length(valid_counts) == size(C,1)
        total = sum(valid_counts);
        fprintf('\n=== 颜色占比分析 ===\n')
        for i = 1:length(valid_counts)
            fprintf('颜色%d: %5.2f%% \t RGB: [%3d, %3d, %3d] \t HEX: #%02X%02X%02X\n',...
                i, valid_counts(i)/total*100, C_255(i,1), C_255(i,2), C_255(i,3),...
                C_255(i,1), C_255(i,2), C_255(i,3));
        end
    end
end

% 辅助函数：九宫格法回退
function [C, valid_counts] = grid_method_fallback(pixels, N, h, w)
    bins = 8;
    bin_size = 1 / bins;
    indices = min(floor(pixels / bin_size), bins-1) + 1;
    linear_idx = indices(:,1) + (indices(:,2)-1)*bins + (indices(:,3)-1)*bins^2;
    counts = accumarray(linear_idx, 1, [bins^3 1]);
    [sorted_counts, idx] = sort(counts, 'descend');
    valid_idx = find(sorted_counts > 0);
    num_colors = min(N, length(valid_idx));
    valid_counts = sorted_counts(1:num_colors);
    C = zeros(num_colors, 3);
    for i = 1:num_colors
        [r, g, b] = ind2sub([bins, bins, bins], idx(i));
        C(i,:) = ([r, g, b] - 0.5) * bin_size;
    end
end

% 辅助函数：中位切分算法
function [C, valid_counts] = median_cut_algorithm(pixels, N)
    if N <= 1
        C = mean(pixels, 1);
        valid_counts = size(pixels, 1);
        return;
    end
    
    % 初始化颜色盒子
    boxes = {pixels};
    
    % 递归切分直到达到N个盒子
    while length(boxes) < N
        % 找到最大的盒子
        box_sizes = cellfun(@(x) size(x, 1), boxes);
        [~, max_idx] = max(box_sizes);
        
        if box_sizes(max_idx) <= 1
            break; % 无法继续切分
        end
        
        % 切分最大的盒子
        current_box = boxes{max_idx};
        ranges = max(current_box) - min(current_box);
        [~, split_dim] = max(ranges);
        
        sorted_pixels = sortrows(current_box, split_dim);
        mid_point = ceil(size(sorted_pixels, 1) / 2);
        
        % 替换原盒子为两个新盒子
        boxes{max_idx} = sorted_pixels(1:mid_point, :);
        boxes{end+1} = sorted_pixels(mid_point+1:end, :);
    end
    
    % 计算每个盒子的代表颜色
    C = zeros(length(boxes), 3);
    valid_counts = zeros(length(boxes), 1);
    for i = 1:length(boxes)
        C(i, :) = mean(boxes{i}, 1);
        valid_counts(i) = size(boxes{i}, 1);
    end
end

% 辅助函数：直方图算法
function [C, valid_counts] = histogram_algorithm(pixels, N)
    % 将RGB空间量化为更粗的网格
    bins = 16;
    bin_size = 1 / bins;
    
    % 量化像素值
    quantized = floor(pixels / bin_size);
    quantized = min(quantized, bins-1);
    
    % 计算直方图
    unique_colors = unique(quantized, 'rows');
    valid_counts = zeros(size(unique_colors, 1), 1);
    
    for i = 1:size(unique_colors, 1)
        matches = all(quantized == unique_colors(i, :), 2);
        valid_counts(i) = sum(matches);
    end
    
    % 选择前N个最频繁的颜色
    [sorted_counts, idx] = sort(valid_counts, 'descend');
    num_colors = min(N, length(idx));
    
    C = (unique_colors(idx(1:num_colors), :) + 0.5) * bin_size;
    valid_counts = sorted_counts(1:num_colors);
end

end