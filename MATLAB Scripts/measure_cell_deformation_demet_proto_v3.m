function measure_cell_deformation()
% Interactive measurement of cell shape at two frames and deformation metrics.
% Run: measure_cell_deformation()

[fn, path] = uigetfile({'*.mp4;*.avi;*.mov;*.m4v','Video files'}, 'Select video');
if isequal(fn,0), return; end
vidPath = fullfile(path, fn);

%Optional: remove duplicate frames using ffmpeg (mpdecimate)
doRemove = questdlg('Remove duplicate frames before analysis?','Preprocess','Yes','No','Yes');
if strcmp(doRemove,'Yes')
    % Use base filename safely
    [~, baseName, ~] = fileparts(fn);
    stampedName = sprintf('%s_nodup_30fps.mp4', baseName);
    stampedPath = fullfile(path, stampedName);
    % mpdecimate command to drop near-duplicate frames and re-timestamp.
    % Use '-fflags +genpts' and '-vsync vfr' so output duration matches kept frames.
    cmd = sprintf('ffmpeg -y -fflags +genpts -i "%s" -vf "mpdecimate,setpts=N/FRAME_RATE/TB" -vsync vfr -c:v libx264 -crf 18 -preset veryfast -an "%s"', vidPath, stampedPath);
    fprintf('Running ffmpeg to remove duplicate frames (this may take a while)...\n');
    [st, out] = system(cmd);
    if st == 0
        fprintf('Duplicate-removed copy created: %s\n', stampedPath);
        vidPath = stampedPath;
    else
        warning('ffmpeg (mpdecimate) failed (status=%d). Proceeding with original file. Output:\n%s', st, out);
    end
end

v = VideoReader(vidPath);

% Determine actual frame count
numFrames = get_frame_count(v, vidPath);

% Let user pick frames visually using a simple browser
% default range calculation
defaultStart = 1;
defaultEnd = min(numFrames-1, max(2, round(numFrames/10)));
[f1, f2] = frameBrowser(v, defaultStart, defaultEnd);
if isempty(f1) || isempty(f2)
    disp('No frames selected — aborting.');
    return;
end

fprintf('Measuring frames %d and %d (video: %s)\n', f1, f2, fn);

% Helper to read and show frame and let user draw ROI (region of interest)
function props = measure_frame(frameIdx)
    frame = read(v, frameIdx);
    I = im2gray(frame);
    hF = figure('Name', sprintf('Frame %d - draw ROI and double-click to finish', frameIdx), 'NumberTitle','off');
    imshow(I, []); title(sprintf('Frame %d — draw ROI (double-click to finish) — t=%.3fs', frameIdx, (frameIdx-1)/v.FrameRate));

    % Loop so user can redraw or cancel if the ROI is unsatisfactory
    accepted = false;
    props = struct();
    while ~accepted
        h = drawfreehand('Color','r'); wait(h);
        mask = createMask(h);
        % Analyze selected mask
        stats = regionprops(mask, I, 'Area','Centroid','MajorAxisLength','MinorAxisLength','Orientation','PixelIdxList','Perimeter','EquivDiameter','BoundingBox');
        if isempty(stats)
            choice = questdlg('No object found in ROI. Redraw or Cancel?', 'No object', 'Redraw','Cancel','Redraw');
            if strcmp(choice,'Cancel')
                close(hF); props = struct(); return;
            else
                continue;
            end
        end

        % If multiple components, take the largest area
        [~, idxMax] = max([stats.Area]);
        s = stats(idxMax);

        % Show a small preview and ask user to Accept/Redraw/Cancel
        hPreview = figure('Name','ROI Preview','NumberTitle','off'); imshow(I, []); hold on;
        B = bwboundaries(false(size(mask)), 'noholes'); 
        objMask = false(size(mask)); objMask(s.PixelIdxList) = true;
        B = bwboundaries(objMask, 'noholes'); boundary = B{1};
        plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 1.5);
        plot(s.Centroid(1), s.Centroid(2), 'go', 'MarkerFaceColor','g');
        title(sprintf('Area=%.1f  Major=%.2f  Minor=%.2f', s.Area, s.MajorAxisLength, s.MinorAxisLength));

        choice = questdlg('Accept this ROI?', 'Confirm ROI', 'Accept','Redraw','Cancel','Accept');
        close(hPreview);
        if strcmp(choice,'Accept')
            accepted = true;
            minPixArea = 20;           
            objMask = false(size(mask)); objMask(s.PixelIdxList) = true;
            B = bwboundaries(objMask, 'noholes'); boundary = B{1};
            props = struct();
            props.frame = frameIdx;
            props.centroid = s.Centroid;
            props.area = s.Area;
            props.major = s.MajorAxisLength;
            props.minor = s.MinorAxisLength;
            props.orientation = s.Orientation;
            props.perimeter = s.Perimeter;
            props.equivDiameter = s.EquivDiameter;
            props.mask = objMask;
            props.boundary = boundary;
            props.rawFrame = frame;
            close(hF);
            return;
        elseif strcmp(choice,'Cancel')
            close(hF); props = struct(); return;
        else
            % Redraw: loop again
            try delete(h); catch; end
            continue;
        end
    end
    % If multiple components, take the largest area
    [~, idxMax] = max([stats.Area]);
    s = stats(idxMax);
    minPixArea = 20;           
    objMask = false(size(mask)); objMask(s.PixelIdxList) = true;
    B = bwboundaries(objMask, 'noholes'); boundary = B{1};
    props = struct();
    props.frame = frameIdx;
    props.centroid = s.Centroid;
    props.area = s.Area;
    props.major = s.MajorAxisLength;
    props.minor = s.MinorAxisLength;
    props.orientation = s.Orientation;
    props.perimeter = s.Perimeter;
    props.equivDiameter = s.EquivDiameter;
    props.mask = objMask;
    props.boundary = boundary;
    props.rawFrame = frame;
    close(hF);
end

p1 = measure_frame(f1);
if isempty(fieldnames(p1)), disp('No measurement at frame 1 — aborting'); return; end
p2 = measure_frame(f2);
if isempty(fieldnames(p2)), disp('No measurement at frame 2 — aborting'); return; end

% Calibration: draw a line to set pixel -> micrometer scale (optional)
% The user draws a line of known real-world length on frame f2, then
% inputs that length in micrometers. The code computes micrometers-per-pixel
% and uses it to convert distances and areas.
um_per_pixel = NaN;
scaleAccepted = false;
calChoice = questdlg('Would you like to add a calibration scale (draw a line and enter length in micrometers)?', 'Calibration', 'Yes', 'No', 'Yes');
if strcmp(calChoice, 'Yes')
    % Show the second frame for calibration
    calFrame = p2.rawFrame;
    hCal = figure('Name','Calibration - draw line (double-click to finish)','NumberTitle','off');
    imshow(calFrame); title('Draw a line of known length (double-click to finish)');
    hLine = drawline('Color','y'); wait(hLine);
    pos = hLine.Position; % 2x2: [x1 y1; x2 y2]
    pA = pos(1,:); 
    pB = pos(end,:);
    pixelLen = hypot(pB(1)-pA(1), pB(2)-pA(2));
    prompt = {'Enter real length of the drawn line (in micrometers):'};
    dlgtitle = 'Calibration length (µm)';
    definput = {'10'};
    answer = inputdlg(prompt, dlgtitle, 1, definput);
    if ~isempty(answer)
        real_um = str2double(answer{1});
        if ~isnan(real_um) && real_um > 0 && pixelLen > 0
            um_per_pixel = real_um / pixelLen;
            scaleAccepted = true;
            fprintf('Calibration: %.6f µm / pixel  (drawn: %.2f px -> %.2f µm)\n', um_per_pixel, pixelLen, real_um);
        else
            warning('Invalid calibration length or drawn line. Skipping calibration.');
        end
    else
        disp('Calibration cancelled by user.');
    end
end

% Ask for true acquisition frame rate after calibration
frame_rate = NaN;
if scaleAccepted
    prompt = {'Enter true acquisition frame rate (frames per second):'};
    dlgtitle = 'Frame Rate';
    definput = {'30'};
    answer = inputdlg(prompt, dlgtitle, 1, definput);
    if ~isempty(answer)
        frame_rate = str2double(answer{1});
        if isnan(frame_rate) || frame_rate <= 0
            warning('Invalid frame rate. Skipping velocity calculation.\n');
            frame_rate = NaN;
        end
    else
        disp('Frame rate input cancelled. Skipping velocity calculation.\n');
    end
end
if strcmp(calChoice, 'Yes')
    try close(hCal); catch; end
end

% Compute deformation metrics
dx = p2.centroid(1) - p1.centroid(1); % x (col) difference
dy = p2.centroid(2) - p1.centroid(2); % y (row) difference
centroid_disp = hypot(dx, dy);

area_change = (p2.area - p1.area) / p1.area;
major_strain = (p2.major - p1.major) / p1.major;
minor_strain = (p2.minor - p1.minor) / p1.minor;
aspect_ratio_change = (p2.major/p2.minor) - (p1.major/p1.minor);

% Pixelwise overlap (IoU/Jaccard) after aligning centroids roughly
mask1 = p1.mask; mask2 = p2.mask;
[cH, cW, ~] = size(p1.rawFrame);
canvas = false(cH*2, cW*2);
center = round([cW, cH]); % [x,y] center

% place mask1 at center
canvas1 = paste_mask_safe(canvas, mask1, center, p1.centroid);

% place mask2 aligned by centroid
canvas2 = paste_mask_safe(canvas, mask2, center, p2.centroid);

intersection = nnz(canvas1 & canvas2);
unionArea = nnz(canvas1 | canvas2);
if unionArea > 0
    iou = intersection / unionArea;
else
    iou = 0;
end

% Display results
    fprintf('Frame %d -> Frame %d\n\n', f1, f2);
    fprintf('Centroid displacement: dx = %.2f px, dy = %.2f px, distance = %.2f px\n', dx, dy, centroid_disp);
    fprintf('Area: %.1f -> %.1f px (change = %.2f%%)\n', p1.area, p2.area, area_change*100);
    fprintf('Major axis: %.2f -> %.2f px (strain = %.3f)\n', p1.major, p2.major, major_strain);
    fprintf('Minor axis: %.2f -> %.2f px (strain = %.3f)\n', p1.minor, p2.minor, minor_strain);
    fprintf('Aspect ratio change: %.3f\n', aspect_ratio_change);
    fprintf('IoU (mask overlap after centroid align): %.3f\n', iou);

% If calibration provided, convert pixels to micrometers and print
if exist('um_per_pixel','var') && ~isnan(um_per_pixel)
    centroid_disp_um = centroid_disp * um_per_pixel;
    dx_um = dx * um_per_pixel; dy_um = dy * um_per_pixel;
    area1_um2 = p1.area * (um_per_pixel^2);
    area2_um2 = p2.area * (um_per_pixel^2);
    major1_um = p1.major * um_per_pixel; major2_um = p2.major * um_per_pixel;
    minor1_um = p1.minor * um_per_pixel; minor2_um = p2.minor * um_per_pixel;

    fprintf('\nConverted using scale: %.6f µm / pixel\n', um_per_pixel);
    fprintf('Centroid displacement: dx = %.2f µm, dy = %.2f µm, distance = %.2f µm\n', dx_um, dy_um, centroid_disp_um);
    fprintf('Area: %.2f µm^2 -> %.2f µm^2 (change = %.2f%%)\n', area1_um2, area2_um2, area_change*100);
    fprintf('Major axis: %.2f µm -> %.2f µm (strain = %.3f)\n', major1_um, major2_um, major_strain);
    fprintf('Minor axis: %.2f µm -> %.2f µm (strain = %.3f)\n', minor1_um, minor2_um, minor_strain);
end

% Compute and display velocities if calibration and frame rate are available
if ~isnan(frame_rate) && ~isnan(um_per_pixel)
    time_delta = abs(f2 - f1) / frame_rate;  % seconds between first and last selected frames
    vx = dx_um / time_delta;  % µm/s
    vy = dy_um / time_delta;
    v_mag = centroid_disp_um / time_delta;
    fprintf('\nVelocities (using true frame rate %.2f FPS):\n', frame_rate);
    fprintf('Average x-velocity: %.2f µm/s\n', vx);
    fprintf('Average y-velocity: %.2f µm/s\n', vy);
    fprintf('Average 2D velocity magnitude: %.2f µm/s\n', v_mag);
    fprintf('A to B real-time duration: %.2fms\n', time_delta*1000);
    fprintf('Full video real-time duration: %.2fms\n', v.Duration * 1000); 
elseif isnan(um_per_pixel)
    disp('Calibration not performed — skipping velocity calculation.');
elseif isnan(frame_rate)
    disp('Frame rate not provided — skipping velocity calculation.');
end

% Show overlays: plot both boundaries together by translating boundary A to frame B
figure('Name','Overlaid boundaries'); imshow(p2.rawFrame); hold on;
% boundary for frame B (plotted in red)
b2 = p2.boundary; plot(b2(:,2), b2(:,1), 'r', 'LineWidth', 1.5);
% translate boundary A so its centroid aligns with centroid B, then plot (green)
% Note: boundary rows are [row col], while centroid is [x y] (col,row)
t_xy = p2.centroid - p1.centroid;          % [dx, dy] in x,y
t_rowcol = [t_xy(2), t_xy(1)];            % [dy, dx] to apply to [row col]
bA_trans = p1.boundary + repmat(t_rowcol, size(p1.boundary,1), 1);
plot(bA_trans(:,2), bA_trans(:,1), 'g', 'LineWidth', 1.5);
% Mark centroids: translated A (green) and B (red)
plot(p1.centroid(1)+t_xy(1), p1.centroid(2)+t_xy(2), 'go', 'MarkerFaceColor','g');
plot(p2.centroid(1), p2.centroid(2), 'rs', 'MarkerFaceColor','r');
legend({'Boundary B (frame B)','Boundary A (translated)','Centroid A (translated)','Centroid B'}, 'Location','best');
title(sprintf('Overlaid boundaries: frame %d (red) and frame %d (green, translated)', f2, f1));
hold off;

end

% frameBrowser helper
function [startF, endF] = frameBrowser(v, defaultStart, defaultEnd)
% Simple interactive browser to visually pick two frames. Returns start and end.
startF = []; endF = [];
numFrames = max(1, round(v.NumFrames));
cur = max(1, min(numFrames, defaultStart));
selStart = defaultStart; selEnd = defaultEnd;

hFig = figure('Name','Frame Browser','NumberTitle','off','MenuBar','none','ToolBar','none');
ax = axes('Parent',hFig);
frameIm = imshow(read(v,cur),'Parent',ax);
title(ax, sprintf('Frame %d / %d  —  t=%.3fs   [Start=%d End=%d]', cur, numFrames, (cur-1) * v.Duration / numFrames, selStart, selEnd));

uicontrol('Style','pushbutton','String','<<','Position',[10 10 40 24],'Callback',@btnFirst);
uicontrol('Style','pushbutton','String','<','Position',[60 10 40 24],'Callback',@btnPrev);
uicontrol('Style','pushbutton','String','>','Position',[110 10 40 24],'Callback',@btnNext);
uicontrol('Style','pushbutton','String','>>','Position',[160 10 40 24],'Callback',@btnLast);
uicontrol('Style','text','Position',[220 10 80 24],'String','Jump to frame:');
jumpBox = uicontrol('Style','edit','Position',[300 10 80 24],'String',num2str(cur),'Callback',@btnJump);
uicontrol('Style','pushbutton','String','Set Frame A','Position',[400 10 80 24],'Callback',@btnSetStart);
uicontrol('Style','pushbutton','String','Set Frame B','Position',[490 10 80 24],'Callback',@btnSetEnd);
uicontrol('Style','pushbutton','String','OK','Position',[580 10 50 24],'Callback',@btnOK);
uicontrol('Style','pushbutton','String','Cancel','Position',[640 10 60 24],'Callback',@btnCancel);

    function updateFrame()
        try
            frame = read(v,cur);
            set(frameIm,'CData',frame);
            title(ax, sprintf('Frame %d / %d  —  t=%.3fs   [Start=%d End=%d]', cur, numFrames, (cur-1) * v.Duration / numFrames, selStart, selEnd));
            set(jumpBox,'String',num2str(cur));
            drawnow limitrate;
        catch
        end
    end

    function btnFirst(~,~)
        cur = 1; updateFrame();
    end
    function btnPrev(~,~)
        cur = max(1, cur-1); updateFrame();
    end
    function btnNext(~,~)
        cur = min(numFrames, cur+1); updateFrame();
    end
    function btnLast(~,~)
        cur = numFrames; updateFrame();
    end
    function btnJump(src,~)
        vstr = get(src,'String'); val = round(str2double(vstr));
        if ~isnan(val) && val>=1 && val<=numFrames, cur = val; updateFrame(); end
    end
    function btnSetStart(~,~)
        selStart = cur; updateFrame(); end
    function btnSetEnd(~,~)
        selEnd = cur; updateFrame(); end
    function btnOK(~,~)
        startF = selStart; endF = selEnd; close(hFig);
    end
    function btnCancel(~,~)
        startF = []; endF = []; close(hFig);
    end

uiwait(hFig);
end

% Local helpers
function n = get_frame_count(v, vidPath)
    % Try fast approaches first, then fall back to counting frames.
    try
        n = v.NumFrames;
        if isempty(n) || ~isfinite(n) || n < 1
            error('invalid');
        end
        return;
    catch
    end
    try
        n = max(1, floor(v.Duration * v.FrameRate));
        return;
    catch
    end
    % Last resort: iterate through file to count frames
    try
        vt = VideoReader(vidPath);
        ncnt = 0;
        while hasFrame(vt)
            readFrame(vt); ncnt = ncnt + 1;
        end
        n = max(1, ncnt);
        clear vt;
    catch
        n = 1;
    end
end

function C = paste_mask_safe(C, mask, center, centroid)
    % Paste binary mask into canvas aligning centroid to center, with clipping
    [h, w] = size(mask);
    offx = round(center(1) - centroid(1));
    offy = round(center(2) - centroid(2));
    dstX = offx + (1:w);
    dstY = offy + (1:h);
    dstX = round(dstX); dstY = round(dstY);
    validX = dstX >= 1 & dstX <= size(C,2);
    validY = dstY >= 1 & dstY <= size(C,1);
    if any(validX) && any(validY)
        dstXv = dstX(validX);
        dstYv = dstY(validY);
        srcX = find(validX);
        srcY = find(validY);
        C(dstYv, dstXv) = mask(srcY, srcX);
    end
end
