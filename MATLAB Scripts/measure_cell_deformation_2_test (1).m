function measure_cell_deformation()
% Interactive measurement of cell shape at two frames and deformation metrics.
% Run: measure_cell_deformation()

[fn, path] = uigetfile({'*.mp4;*.avi;*.mov;*.m4v','Video files'}, 'Select video');
if isequal(fn,0), return; end
vidPath = fullfile(path, fn);
v = VideoReader(vidPath);

% Let user pick frames visually using a simple browser
defaultStart = 1;
defaultEnd = min(round(v.NumFrames)-1, max(2, round(v.NumFrames/10)));
[f1, f2] = frameBrowser(v, defaultStart, defaultEnd);
if isempty(f1) || isempty(f2)
    disp('No frames selected — aborting.');
    return;
end

fprintf('Measuring frames %d and %d (video: %s)\n', f1, f2, fn);

% Helper to read and show frame and let user draw ROI
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
        B = bwboundaries(false(size(mask)), 'noholes'); % placeholder
        objMask = false(size(mask)); objMask(s.PixelIdxList) = true;
        B = bwboundaries(objMask, 'noholes'); boundary = B{1};
        plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 1.5);
        plot(s.Centroid(1), s.Centroid(2), 'go', 'MarkerFaceColor','g');
        title(sprintf('Area=%.1f  Major=%.2f  Minor=%.2f', s.Area, s.MajorAxisLength, s.MinorAxisLength));

        choice = questdlg('Accept this ROI?', 'Confirm ROI', 'Accept','Redraw','Cancel','Accept');
        close(hPreview);
        if strcmp(choice,'Accept')
            accepted = true;
            % commit s, mask, boundary
            minPixArea = 20;           % tune to your data
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
            % Redraw: loop again (remove previous freehand handle)
            try delete(h); catch; end
            continue;
        end
    end
    % If multiple components, take the largest area
    [~, idxMax] = max([stats.Area]);
    s = stats(idxMax);
    minPixArea = 20;           % tune to your data
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

% --- Calibration: draw a line to set pixel -> micrometer scale (optional) ---
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
canvas1 = false(size(canvas));
h1 = size(mask1,1); w1 = size(mask1,2);
offx1 = center(1) - round(p1.centroid(1)); offy1 = center(2) - round(p1.centroid(2));
xrange1 = (1:w1) + offx1; yrange1 = (1:h1) + offy1;
canvas1(yrange1, xrange1) = mask1;

% place mask2 aligned by centroid
canvas2 = false(size(canvas));
h2 = size(mask2,1); w2 = size(mask2,2);
offx2 = center(1) - round(p2.centroid(1)); offy2 = center(2) - round(p2.centroid(2));
xrange2 = (1:w2) + offx2; yrange2 = (1:h2) + offy2;
canvas2(yrange2, xrange2) = mask2;

intersection = nnz(canvas1 & canvas2);
unionArea = nnz(canvas1 | canvas2);
if unionArea > 0
    iou = intersection / unionArea;
else
    iou = 0;
end

% Display results
    fprintf('Frame %d -> Frame %d\n', f1, f2);
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

% --- frameBrowser helper ---
function [startF, endF] = frameBrowser(v, defaultStart, defaultEnd)
% Simple interactive browser to visually pick two frames. Returns start and end.
startF = []; endF = [];
numFrames = max(1, round(v.NumFrames));
cur = max(1, min(numFrames, defaultStart));
selStart = defaultStart; selEnd = defaultEnd;

hFig = figure('Name','Frame Browser','NumberTitle','off','MenuBar','none','ToolBar','none');
ax = axes('Parent',hFig);
frameIm = imshow(read(v,cur),'Parent',ax);
title(ax, sprintf('Frame %d / %d  —  t=%.3fs   [Start=%d End=%d]', cur, numFrames, (cur-1)/v.FrameRate, selStart, selEnd));

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
            title(ax, sprintf('Frame %d / %d  —  t=%.3fs   [Start=%d End=%d]', cur, numFrames, (cur-1)/v.FrameRate, selStart, selEnd));
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
