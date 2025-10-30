function color_extractor_gui()
% 颜色提取器图形用户界面
% 提供友好的界面来使用颜色提取功能

% 创建主窗口
fig = figure('Name', '颜色提取器', 'NumberTitle', 'off', ...
    'Position', [100, 100, 800, 600], 'Resize', 'off', ...
    'MenuBar', 'none', 'ToolBar', 'none');

% 全局变量
global img_data img_path extracted_colors;
img_data = [];
img_path = '';
extracted_colors = [];

% 创建UI控件
create_ui_controls(fig);

% 设置窗口关闭回调
set(fig, 'CloseRequestFcn', @close_callback);

end

function create_ui_controls(fig)
% 创建所有UI控件

% 标题
title_text = uicontrol('Style', 'text', 'String', '图片颜色提取器', ...
    'Position', [300, 550, 200, 30], 'FontSize', 16, 'FontWeight', 'bold');

% 图片选择区域
img_panel = uipanel('Title', '图片选择', 'Position', [0.02, 0.7, 0.96, 0.25]);

% 选择图片按钮
select_btn = uicontrol('Parent', img_panel, 'Style', 'pushbutton', ...
    'String', '选择图片', 'Position', [20, 100, 100, 30], ...
    'Callback', @select_image_callback);

% 图片路径显示
global path_text;
path_text = uicontrol('Parent', img_panel, 'Style', 'text', ...
    'String', '未选择图片', 'Position', [130, 100, 400, 30], ...
    'HorizontalAlignment', 'left');

% 图片预览
global img_axes;
img_axes = axes('Parent', img_panel, 'Position', [0.65, 0.1, 0.3, 0.8]);
axis(img_axes, 'off');
text(0.5, 0.5, '图片预览', 'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', 'Parent', img_axes);

% 参数设置区域
param_panel = uipanel('Title', '参数设置', 'Position', [0.02, 0.45, 0.96, 0.2]);

% 颜色数量设置
uicontrol('Parent', param_panel, 'Style', 'text', 'String', '颜色数量:', ...
    'Position', [20, 80, 80, 20], 'HorizontalAlignment', 'left');
global color_count_edit;
color_count_edit = uicontrol('Parent', param_panel, 'Style', 'edit', ...
    'String', '8', 'Position', [110, 80, 50, 25]);

% 提取方法选择
uicontrol('Parent', param_panel, 'Style', 'text', 'String', '提取方法:', ...
    'Position', [200, 80, 80, 20], 'HorizontalAlignment', 'left');
global method_popup;
method_popup = uicontrol('Parent', param_panel, 'Style', 'popupmenu', ...
    'String', {'九宫格法(Grid)', 'K均值法(K-means)', '中位切分法(Median Cut)', '直方图法(Histogram)'}, ...
    'Position', [290, 80, 150, 25], 'Value', 1);

% 显示结果选项
global show_result_check;
show_result_check = uicontrol('Parent', param_panel, 'Style', 'checkbox', ...
    'String', '显示可视化结果', 'Position', [480, 80, 120, 25], 'Value', 1);

% 提取按钮
extract_btn = uicontrol('Parent', param_panel, 'Style', 'pushbutton', ...
    'String', '提取颜色', 'Position', [650, 75, 100, 35], ...
    'FontSize', 12, 'FontWeight', 'bold', 'Callback', @extract_colors_callback);

% 结果显示区域
result_panel = uipanel('Title', '提取结果', 'Position', [0.02, 0.02, 0.96, 0.4]);

% 颜色显示区域
global color_axes;
color_axes = axes('Parent', result_panel, 'Position', [0.05, 0.6, 0.9, 0.35]);
axis(color_axes, 'off');

% 结果文本显示
global result_text;
result_text = uicontrol('Parent', result_panel, 'Style', 'listbox', ...
    'Position', [20, 20, 500, 120], 'FontName', 'Courier New', 'FontSize', 9);

% 导出按钮
export_btn = uicontrol('Parent', result_panel, 'Style', 'pushbutton', ...
    'String', '导出颜色', 'Position', [540, 80, 80, 30], ...
    'Callback', @export_colors_callback);

% 生成配色按钮
palette_btn = uicontrol('Parent', result_panel, 'Style', 'pushbutton', ...
    'String', '生成配色', 'Position', [540, 40, 80, 30], ...
    'Callback', @generate_palette_callback);

% 帮助按钮
help_btn = uicontrol('Parent', result_panel, 'Style', 'pushbutton', ...
    'String', '帮助', 'Position', [650, 80, 60, 30], ...
    'Callback', @help_callback);

% 关于按钮
about_btn = uicontrol('Parent', result_panel, 'Style', 'pushbutton', ...
    'String', '关于', 'Position', [650, 40, 60, 30], ...
    'Callback', @about_callback);

end

function select_image_callback(~, ~)
% 选择图片回调函数
global img_data img_path path_text img_axes;

[file, path] = uigetfile({'*.jpg;*.png;*.jpeg;*.bmp;*.tiff;*.gif', ...
    '图片文件 (*.jpg;*.png;*.jpeg;*.bmp;*.tiff;*.gif)'}, '选择图片');

if isequal(file, 0)
    return;
end

img_path = fullfile(path, file);
set(path_text, 'String', img_path);

try
    img_data = imread(img_path);
    % 在预览区域显示图片
    axes(img_axes);
    imshow(imresize(img_data, [100, 100]));
    title('图片预览', 'FontSize', 10);
catch ME
    errordlg(['无法读取图片: ' ME.message], '错误');
    img_data = [];
    img_path = '';
    set(path_text, 'String', '未选择图片');
end
end

function extract_colors_callback(~, ~)
% 提取颜色回调函数
global img_data img_path extracted_colors color_count_edit method_popup show_result_check;
global color_axes result_text;

if isempty(img_data)
    errordlg('请先选择图片！', '错误');
    return;
end

% 获取参数
color_count = str2double(get(color_count_edit, 'String'));
if isnan(color_count) || color_count < 1 || color_count > 20
    errordlg('颜色数量必须是1-20之间的整数！', '错误');
    return;
end

method_names = {'grid', 'kmeans', 'median_cut', 'histogram'};
method_idx = get(method_popup, 'Value');
method = method_names{method_idx};

show_result = get(show_result_check, 'Value');

try
    % 调用颜色提取函数
    extracted_colors = extract_dominant_color(color_count, method, show_result, img_path);
    
    % 在GUI中显示颜色条
    display_colors_in_gui(extracted_colors);
    
    % 显示结果文本
    display_results_text(extracted_colors, method);
    
catch ME
    errordlg(['颜色提取失败: ' ME.message], '错误');
end
end

function display_colors_in_gui(colors)
% 在GUI中显示颜色条
global color_axes;

if isempty(colors)
    return;
end

axes(color_axes);
cla(color_axes);
hold on;

% 绘制颜色条
num_colors = size(colors, 1);
for i = 1:num_colors
    x_start = (i-1) / num_colors;
    x_width = 1 / num_colors;
    
    rectangle('Position', [x_start, 0, x_width, 1], ...
        'FaceColor', colors(i, :), 'EdgeColor', 'black', 'LineWidth', 1);
    
    % 添加RGB标签
    rgb_255 = round(colors(i, :) * 255);
    text(x_start + x_width/2, 0.5, ...
        sprintf('%d,%d,%d', rgb_255(1), rgb_255(2), rgb_255(3)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', 8, 'FontWeight', 'bold', ...
        'Color', [1-colors(i,1), 1-colors(i,2), 1-colors(i,3)]);
end

xlim([0, 1]);
ylim([0, 1]);
set(color_axes, 'XTick', [], 'YTick', []);
title('提取的主题色', 'FontSize', 12);
hold off;
end

function display_results_text(colors, method)
% 显示结果文本
global result_text;

if isempty(colors)
    return;
end

result_strings = {};
result_strings{end+1} = sprintf('=== 颜色提取结果 ===');
result_strings{end+1} = sprintf('提取方法: %s', upper(method));
result_strings{end+1} = sprintf('颜色数量: %d', size(colors, 1));
result_strings{end+1} = '';

colors_255 = round(colors * 255);

for i = 1:size(colors, 1)
    result_strings{end+1} = sprintf('颜色%d: RGB[%3d,%3d,%3d] HEX[#%02X%02X%02X]', ...
        i, colors_255(i,1), colors_255(i,2), colors_255(i,3), ...
        colors_255(i,1), colors_255(i,2), colors_255(i,3));
end

set(result_text, 'String', result_strings);
end

function export_colors_callback(~, ~)
% 导出颜色回调函数
global extracted_colors;

if isempty(extracted_colors)
    errordlg('请先提取颜色！', '错误');
    return;
end

[file, path] = uiputfile({'*.txt', '文本文件 (*.txt)'; '*.csv', 'CSV文件 (*.csv)'}, ...
    '保存颜色数据');

if isequal(file, 0)
    return;
end

filepath = fullfile(path, file);
[~, ~, ext] = fileparts(filepath);

try
    colors_255 = round(extracted_colors * 255);
    
    if strcmpi(ext, '.csv')
        % CSV格式
        fid = fopen(filepath, 'w');
        fprintf(fid, 'Index,R,G,B,Hex\n');
        for i = 1:size(colors_255, 1)
            fprintf(fid, '%d,%d,%d,%d,#%02X%02X%02X\n', i, ...
                colors_255(i,1), colors_255(i,2), colors_255(i,3), ...
                colors_255(i,1), colors_255(i,2), colors_255(i,3));
        end
        fclose(fid);
    else
        % TXT格式
        fid = fopen(filepath, 'w');
        fprintf(fid, '颜色提取结果\n');
        fprintf(fid, '=================\n\n');
        for i = 1:size(colors_255, 1)
            fprintf(fid, '颜色%d: RGB(%d,%d,%d) HEX(#%02X%02X%02X)\n', i, ...
                colors_255(i,1), colors_255(i,2), colors_255(i,3), ...
                colors_255(i,1), colors_255(i,2), colors_255(i,3));
        end
        fclose(fid);
    end
    
    msgbox(['颜色数据已保存到: ' filepath], '导出成功');
    
catch ME
    errordlg(['导出失败: ' ME.message], '错误');
end
end

function generate_palette_callback(~, ~)
% 生成配色方案回调函数
global extracted_colors;

if isempty(extracted_colors)
    errordlg('请先提取颜色！', '错误');
    return;
end

% 创建配色方案窗口
palette_fig = figure('Name', '配色方案生成器', 'NumberTitle', 'off', ...
    'Position', [200, 200, 600, 400], 'Resize', 'off');

% 生成不同类型的配色方案
generate_color_schemes(palette_fig, extracted_colors);
end

function generate_color_schemes(fig, base_colors)
% 生成多种配色方案
schemes = {};

% 1. 单色配色（基于主色调）
main_color = base_colors(1, :);
hsv_main = rgb2hsv(main_color);
monochromatic = [];
for i = 1:5
    new_hsv = hsv_main;
    new_hsv(3) = max(0.2, min(1, hsv_main(3) + (i-3)*0.2)); % 调整明度
    monochromatic(i, :) = hsv2rgb(new_hsv);
end
schemes{end+1} = struct('name', '单色配色', 'colors', monochromatic);

% 2. 互补配色
complementary = [main_color];
hsv_comp = hsv_main;
hsv_comp(1) = mod(hsv_comp(1) + 0.5, 1); % 色相相差180度
complementary(2, :) = hsv2rgb(hsv_comp);
schemes{end+1} = struct('name', '互补配色', 'colors', complementary);

% 3. 三角配色
triadic = [main_color];
for i = 1:2
    hsv_tri = hsv_main;
    hsv_tri(1) = mod(hsv_tri(1) + i*0.333, 1); % 色相相差120度
    triadic(i+1, :) = hsv2rgb(hsv_tri);
end
schemes{end+1} = struct('name', '三角配色', 'colors', triadic);

% 4. 原始提取色
schemes{end+1} = struct('name', '原始提取色', 'colors', base_colors);

% 显示配色方案
display_schemes(fig, schemes);
end

function display_schemes(fig, schemes)
% 显示配色方案
num_schemes = length(schemes);
for i = 1:num_schemes
    % 创建子图
    subplot(num_schemes, 1, i, 'Parent', fig);
    
    colors = schemes{i}.colors;
    num_colors = size(colors, 1);
    
    hold on;
    for j = 1:num_colors
        x_start = (j-1) / num_colors;
        x_width = 1 / num_colors;
        
        rectangle('Position', [x_start, 0, x_width, 1], ...
            'FaceColor', colors(j, :), 'EdgeColor', 'black');
        
        % 添加颜色值标签
        rgb_255 = round(colors(j, :) * 255);
        brightness = 0.2126*colors(j,1) + 0.7152*colors(j,2) + 0.0722*colors(j,3);
        text_color = [1 1 1];
        if brightness > 0.5
            text_color = [0 0 0];
        end
        
        text(x_start + x_width/2, 0.5, ...
            sprintf('#%02X%02X%02X', rgb_255(1), rgb_255(2), rgb_255(3)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'Color', text_color, 'FontSize', 8, 'FontWeight', 'bold');
    end
    
    xlim([0, 1]);
    ylim([0, 1]);
    set(gca, 'XTick', [], 'YTick', []);
    title(schemes{i}.name, 'FontSize', 10);
    hold off;
end
end

function help_callback(~, ~)
% 帮助回调函数
help_text = {
    '颜色提取器使用帮助',
    '==================',
    '',
    '1. 选择图片：点击"选择图片"按钮选择要分析的图片',
    '2. 设置参数：',
    '   - 颜色数量：要提取的主题色数量（1-20）',
    '   - 提取方法：选择颜色提取算法',
    '     * 九宫格法：快速，适合大多数图片',
    '     * K均值法：精确，适合复杂图片',
    '     * 中位切分法：平衡，适合色彩丰富的图片',
    '     * 直方图法：简单，适合色彩单一的图片',
    '3. 提取颜色：点击"提取颜色"开始分析',
    '4. 查看结果：在结果区域查看提取的颜色',
    '5. 导出颜色：将结果保存为文本或CSV文件',
    '6. 生成配色：基于提取的颜色生成配色方案',
    '',
    '提示：',
    '- 建议图片分辨率不要过大（<2000x2000）',
    '- 不同算法适用于不同类型的图片',
    '- 可以尝试不同的颜色数量来获得最佳效果'
};

msgbox(help_text, '帮助', 'help');
end

function about_callback(~, ~)
% 关于回调函数
about_text = {
    '颜色提取器 v2.0',
    '================',
    '',
    '功能特点：',
    '• 支持多种图片格式',
    '• 四种颜色提取算法',
    '• 直观的图形界面',
    '• 颜色数据导出',
    '• 配色方案生成',
    '',
    '支持的图片格式：',
    'JPG, PNG, BMP, TIFF, GIF',
    '',
    '开发环境：MATLAB',
    '版本：2.0',
    '更新日期：2024'
};

msgbox(about_text, '关于', 'help');
end

function close_callback(~, ~)
% 窗口关闭回调函数
selection = questdlg('确定要退出颜色提取器吗？', '确认退出', '是', '否', '否');
if strcmp(selection, '是')
    delete(gcf);
end
end