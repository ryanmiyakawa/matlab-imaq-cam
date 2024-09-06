

addpath ..

imaqreset

hCam = imaqcam.ImaqCam(...
'cCameraName', 'UI225xSE-M R3_4102658007', ...
'cProtocol', 'winvideo', ...
'dROI', [485 - 150,  935 - 75, 300, 150 ], ... % Set the ROI position (in pixels) [x, y, width, height]
'cFrameFormat', 'RGB24_1600x1200' ...
);

% Check if camera is available:
if hCam.isAvailable()
    fprintf('Camera is available\n');


    % Connect to camera:
    hCam.connect();

    fprintf('Connected to camera\n');
else
    fprintf('Camera is not available\n');
end



%% Preview camera

h = figure;
a = axes(h);

hCam.preview(a);
hold on
plot([0, 300], [75 75], 'm', 'linewidth', 3)


%%
hCam.stopPreview();


%% Acquire image:
img = hCam.acquire(1);
imagesc(a, img);
axis image
colorbar

