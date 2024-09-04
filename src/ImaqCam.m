
classdef ImaqCam < mic.Base
        
    properties (Constant)
        
        cName = 'imaq-cam';
    end
    
    properties
        
    end
    
    
    properties (Access = private)
        
      
        % {char 1xm} 
        cCameraName = 'UI225xSE-M R3_4102658007'
        cFrameFormat = 'RGB24_1600x1200'
        cProtocol = 'winvideo'
        
        % {double 1x1} timeout
        hCameraHandle = []

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
            
        end

        function connect(this)
            dID = this.getCameraDeviceID();
            if dID < 0
                error('Camera not found');
            end
            this.hCameraHandle = videoinput(this.cProtocol, dID, this.cFrameFormat);
            start(this.hCameraHandle)
        end

        function disconnect(this)
            stop(this.hCameraHandle);
            if isempty(this.hCameraHandle)
                return
            end
            delete(this.hCameraHandle);
            this.hCameraHandle = [];
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

        function lVal = isAvailable(this)
            dID = this.getCameraDeviceID();
            lVal = dID > -1;
        end

        function dID = getCameraDeviceID(this)
            stCamList = imaqhwinfo(this.cProtocol);

            % Loop through and check if the camera is available
            if isempty(stCamList.DeviceInfo)
                dID = -1;
                return
            end

            for k = 1:length(stCamList.DeviceInfo)
                if strcmp(stCamList.DeviceInfo(k).DeviceName, this.cCameraName)
                    dID = stCamList.DeviceIDs(k);
                    return
                end
            end

            dID = -1;
        end

        function dData = acquire(this, nFrames)
            dData = double(getdata(this.hCameraHandle, nFrames));
            dData = mean(dData, 4);
            dData = mean(dData, 3);
            dData = dData / 255;
        end
        
        
        function delete(this)
            this.disconnect();
        end
        
      
    end
    
    
    
    
        
    
end

