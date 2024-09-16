
classdef ImaqCam < mic.Base
        

    
    properties
        
    end
    
    
    properties (Access = private)
        
      
        % {char 1xm} 
        cCameraName = 'UI225xSE-M R3_4102658007'
        cFrameFormat = 'RGB24_1600x1200'
        cProtocol = 'winvideo'
        
        % {double 1x1} timeout
        hCameraHandle = []
        hSrcHandle = []

        hImageHandle = []
        dROI = [] % ROI position (in pixels) [x, y, width, height]
        
        lImaqAvail = false
        lIsPreviewing = false

    end
    
    methods
        
        
        function this = ImaqCam(varargin)
            
            for k = 1 : 2: length(varargin)
                this.msg(sprintf('passed in %s', varargin{k}));
                if this.hasProp( varargin{k})
                    this.msg(sprintf('settting %s', varargin{k}));
                    this.(varargin{k}) = varargin{k + 1};
                end
            end
            
            if this.isImaqAvail()
                this.lImaqAvail = true;
            end
            
        end

        function connect(this)
            dID = this.getCameraDeviceID();
            if dID < 0
                error('Camera not found');
            end
            this.hCameraHandle = videoinput(this.cProtocol, dID, this.cFrameFormat);
            if ~isempty(this.dROI)
                this.hCameraHandle.ROIPosition = this.dROI;
            end
            
            this.hCameraHandle.FramesPerTrigger = 1;

            
            start(this.hCameraHandle)
            this.hSrcHandle = getselectedsource(this.hCameraHandle);
        end

        function preview(this, hAxes)  
            if (this.lIsPreviewing)
                return;
            end
            if ~this.isConnected()
                error('Camera not connected');
            end
            
            vidRes = this.getResolution();
            nBands = this.getNumberOfBands(); 

            if ~isempty(this.dROI)
                vidRes = this.dROI([3 4]);
            end
            this.hImageHandle = image(zeros(vidRes(2), vidRes(1), nBands), 'Parent', hAxes);
            this.hCameraHandle.ROIPosition = this.dROI;
            preview(this.hCameraHandle, this.hImageHandle);
            this.lIsPreviewing = true;
        end
        
        function stopPreview(this)
            stoppreview(this.hCameraHandle);
            this.lIsPreviewing = false;
        end

        function lVal = isPreviewing(this)
            lVal = this.lIsPreviewing;
        end

        function dRes = getResolution(this)
            if ~this.isConnected()
                error('Camera not connected');
            end
            dRes = this.hCameraHandle.VideoResolution;
        end

        function dNBands = getNumberOfBands(this)
            if ~this.isConnected()
                error('Camera not connected');
            end
            dNBands = this.hCameraHandle.NumberOfBands;
        end

        
        function disconnect(this)
            try
                % Stop the preview if it is running
                if this.lIsPreviewing
                    this.stopPreview();
                end

                % Stop the acquisition if it is still running
                if isvalid(this.hCameraHandle) && islogging(this.hCameraHandle)
                    stop(this.hCameraHandle);
                end
                
                % Clear any buffered data from the camera
                if isvalid(this.hCameraHandle)
                    flushdata(this.hCameraHandle);
                end
                
                % Delete the camera object if it's valid
                if isvalid(this.hCameraHandle)
                    delete(this.hCameraHandle);
                end
                
                % Set the handle to empty
                this.hCameraHandle = [];

                imaqreset;
                
            catch mE
                this.msg(mE.message);
            end
        end

        function lVal = isConnected(this)

            lVal = ~isempty(this.hCameraHandle);

            % Additionally check if the camera is still available, if not then disconnect
            if (lVal)
                dID = this.getCameraDeviceID();
                if dID < 0
                    this.disconnect();
                    lVal = false;
                    msgbox(sprintf('Camera %s is no longer available', this.cCameraName));
                end
            end
        end

        function refreshIMAQ(this)
            if (this.lImaqAvail)
                imaqreset;
            else
                msgbox('Image Acquisition Toolbox is not available');
            end
        end

        function lVal = isAvailable(this)
            if ~this.lImaqAvail()
                lVal = false;
                return;
            end
            
            dID = this.getCameraDeviceID();
            lVal = dID > -1;
        end
        
        function lVal = isImaqAvail(this)
            % Get the list of installed toolboxes
            toolboxes = ver;
            
            % Initialize a flag to check if the toolbox is found
            lVal = false;
            
            % Loop through the list of toolboxes and check for 'Image Acquisition Toolbox'
            for i = 1:length(toolboxes)
                if strcmp(toolboxes(i).Name, 'Image Acquisition Toolbox')
                    lVal = true;
                    break;
                end
            end
        end

        function dID = getCameraDeviceID(this)
            if ~this.lImaqAvail()
                dID = -1;
                return;
            end


            stCamList = imaqhwinfo(this.cProtocol);

            % Loop through and check if the camera is available
            if isempty(stCamList.DeviceInfo)
                dID = -1;
                return
            end

            for k = 1:length(stCamList.DeviceInfo)
                if strcmp(stCamList.DeviceInfo(k).DeviceName, this.cCameraName)
                    dID = stCamList.DeviceIDs{k};
                    return
                end
            end

            dID = -1;
        end

        function dData = acquire(this, nFrames)

            if this.lIsPreviewing
                this.stopPreview();
            end

            if nargin == 1
                nFrames = 1;
            end
            
            dData = double(getsnapshot(this.hCameraHandle));

%             dData = double(getdata(this.hCameraHandle));
            dData = sum(dData, 4);
            dData = mean(dData, 3);
            dData = dData / 255;
        end
        
        
        function delete(this)
            this.disconnect();
        end
        
      
    end
    
    
    
    
        
    
end

