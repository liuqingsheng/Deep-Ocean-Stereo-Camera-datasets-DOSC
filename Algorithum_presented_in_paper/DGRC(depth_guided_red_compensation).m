clc; clear; close all;

%% ================== Parameters ==================
% This script implements the depth-guided red-channel
% compensation with red-channel perceptual saturation.
epsilon = 1e-5;
maxIter = 20000;

fprintf('epsilon=%.6f, maxIter=%d\n', epsilon, maxIter);

%% ================== Select folders ==================
% For open-source release, avoid hard-coded local paths.
defaultRoot = pwd;

rawFolder = uigetdir(defaultRoot, 'Select the raw RGB image folder (*.png)');
if isequal(rawFolder, 0)
    error('Operation cancelled.');
end

depthFolder = uigetdir(defaultRoot, 'Select the depth-map folder (*.tif / *.tiff)');
if isequal(depthFolder, 0)
    error('Operation cancelled.');
end

saveFolder = uigetdir(defaultRoot, 'Select the output folder');
if isequal(saveFolder, 0)
    error('Operation cancelled.');
end

fprintf('\nInput images : %s\nDepth maps   : %s\nOutput       : %s\n\n', ...
    rawFolder, depthFolder, saveFolder);

%% ================== Create output folder ==================
outputFolder = fullfile(saveFolder, 'Red_compensation_Only');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% ================== Load file lists ==================
imgFiles = dir(fullfile(rawFolder, '*.png'));

% Support both .tif and .tiff depth maps.
depthFiles = [dir(fullfile(depthFolder, '*.tif')); ...
              dir(fullfile(depthFolder, '*.tiff'))];

% Sort by file name so that image/depth pairs are processed in the same order.
[~, idxImg] = sort({imgFiles.name});
imgFiles = imgFiles(idxImg);

[~, idxDepth] = sort({depthFiles.name});
depthFiles = depthFiles(idxDepth);

fprintf('Detected %d RGB images.\n', numel(imgFiles));
fprintf('Detected %d depth maps.\n', numel(depthFiles));

% Check file-count consistency.
if numel(imgFiles) ~= numel(depthFiles)
    error('The number of RGB images (%d) does not match the number of depth maps (%d).', ...
        numel(imgFiles), numel(depthFiles));
end

%% ================== Main loop ==================
for idx = 1:numel(imgFiles)

    imgName   = imgFiles(idx).name;
    depthName = depthFiles(idx).name;
    [~, prefix, ~] = fileparts(imgName);

    fprintf('\n=========================================\n');
    fprintf('Processing %d/%d: %s  <-->  %s\n', ...
        idx, numel(imgFiles), imgName, depthName);

    %% ---- Read RGB image ----
    I = im2double(imread(fullfile(rawFolder, imgName)));

    % Remove alpha channel if a PNG contains one.
    if size(I, 3) > 3
        I = I(:, :, 1:3);
    end

    if size(I, 3) ~= 3
        warning('The input file is not an RGB image: %s. Skipped.', imgName);
        continue;
    end

    %% ---- Read depth map ----
    depthFile = fullfile(depthFolder, depthName);
    if ~isfile(depthFile)
        warning('Depth map not found: %s. Skipped.', depthFile);
        continue;
    end

    D = read_depth_map(depthFile);
    D = single(squeeze(D));

    % If a multi-page TIFF is loaded as a 3-D array, use the first slice.
    % The algorithm assumes one scalar depth value per image pixel.
    if ndims(D) > 2
        warning('Depth map %s has multiple slices. The first slice is used.', depthName);
        D = D(:, :, 1);
    end

    % Check image/depth size consistency.
    if size(D, 1) ~= size(I, 1) || size(D, 2) ~= size(I, 2)
        warning('Image and depth-map sizes do not match: %s <--> %s. Skipped.', ...
            imgName, depthName);
        continue;
    end

    %% ---- Depth-guided red-channel compensation ----
    I_hat = depth_guided_red_compensation(I, D, epsilon, maxIter);

    saveName = fullfile(outputFolder, [prefix '_red_only.png']);
    imwrite(I_hat, saveName);

    fprintf('Saved result: %s\n', saveName);
end

fprintf('\nAll images have been processed.\n');

%% =====================================================================
%  Local functions
%% =====================================================================

function D = read_depth_map(depthFile)
%READ_DEPTH_MAP Robustly read a TIFF depth map.

try
    D = tiffreadVolume(depthFile);
catch
    try
        D = imread(depthFile);
    catch
        t = Tiff(depthFile, 'r');
        D = t.read();
        t.close();
    end
end

end

function I_hat = depth_guided_red_compensation(I, D, epsilon, maxIter)
%DEPTH_GUIDED_RED_COMPENSATION
%
% Input:
%   I       - RGB image normalized to [0, 1]
%   D       - depth map with the same height and width as I
%   epsilon - bisection stopping tolerance
%   maxIter - maximum number of bisection iterations
%
% Output:
%   I_hat   - corrected RGB image in uint8 format

% (I_R,0, I_G,0, I_B,0) <- I
I_R0 = I(:, :, 1);
I_G0 = I(:, :, 2);
I_B0 = I(:, :, 3);

% Omega_img is implicitly represented by the full image grid.
% Omega_valid <- valid depth pixels with D(u,v) > 0.
Omega_valid = isfinite(D) & (D > 0);

% l <- 0, and l(u,v) <- 2D(u,v) for all valid depth pixels.
l = zeros(size(D), 'like', I_R0);
l(Omega_valid) = 2 .* double(D(Omega_valid));

% T_G <- mean(I_G,0), m_R <- mean(I_R,0).
T_G = mean_finite(I_G0(:));
m_R = mean_finite(I_R0(:));

if isnan(T_G) || isnan(m_R)
    warning('Invalid RGB values were detected. Returning the original image.');
    I_hat = im2uint8(max(min(I, 1), 0));
    return;
end

% Avoid unnecessary red-channel amplification when red is already not weaker
% than green in the global mean sense.
if m_R >= T_G
    I_R_new = I_R0;
else
    k_min = 0;
    k_max = 1;
    I_R_new = I_R0;

    for t = 1:maxIter 
        k_r = (k_min + k_max) / 2;

        % eta <- 1 - exp(-k_r * l), element-wise.
        eta = 1 - exp(-k_r .* l);

        % I_R,new <- I_R,0 + eta .* I_G,0.
        I_R_candidate = I_R0 + eta .* I_G0;

        % m <- mean(I_R,new).
        m = mean_finite(I_R_candidate(:));

        I_R_new = I_R_candidate;

        if abs(m - T_G) < epsilon
            break;
        elseif m < T_G
            k_min = k_r;
        else
            k_max = k_r;
        end
    end
end

% (I_R, I_G, I_B) <- (I_R,new, I_G,0, I_B,0).
I_R = I_R_new;
I_G = I_G0;
I_B = I_B0;

% Apply the red-channel perceptual saturation. Green and blue channels are not modified.
I_R = red_channel_saturation_remap(I_R);

% I_hat <- (I_R, I_G, I_B).
I_hat = im2uint8(max(min(cat(3, I_R, I_G, I_B), 1), 0));

end

function I_R = red_channel_saturation_remap(I_R)
%RED_CHANNEL_SATURATION_REMAP
%
% If max(I_R) > 0.95, all red-channel pixels above 0.95 are linearly
% remapped using:
%
%   I_R = 0.95 + (I_R - 0.95) * 0.05 / (max(I_R) - 0.95)
%
% This maps the maximum red value to 1.0 and preserves relative contrast in
% the high-intensity red range.

threshold = 0.95;
I_R_max = max(I_R(:), [], 'omitnan');

if isempty(I_R_max) || isnan(I_R_max)
    I_R = zeros(size(I_R), 'like', I_R);
    return;
end

if I_R_max > threshold
    s = 0.05 / (I_R_max - threshold);
    Omega_sat = I_R > threshold;
    I_R(Omega_sat) = threshold + (I_R(Omega_sat) - threshold) .* s;
end

I_R = max(min(I_R, 1), 0);

end

function m = mean_finite(x)
%MEAN_FINITE Mean value after removing NaN and Inf values.

x = x(isfinite(x));
if isempty(x)
    m = NaN;
else
    m = mean(x);
end

end
