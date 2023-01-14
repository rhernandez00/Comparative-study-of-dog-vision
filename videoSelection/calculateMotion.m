function [motionPerFrame,motion] = calculateMotion(videoFile,varargin)
%takes a video and measures the movement in every frame.
%Note: for opticalFlow, the first frame does something weird, so the
%movement there is replaced by the average across the entire video
pauseTime = 0.5;
method = getArgumentValue('method','blockMatcher',varargin{:}); %method for evaluating motion. Takes blockMatcher or opticalFlow
%takes opticalFlow and blockMatcher
testing = getArgumentValue('testing',false,varargin{:});
%reading the file
% disp(videoFile)
videoObject = VideoReader(videoFile);
totalFrames = videoObject.NumFrames;


switch method
    case 'blockMatcher'
        blockSize = 35; %size of the search-compare box
        %Creating the videoreader object
        hbm = vision.BlockMatcher('ReferenceFrameSource','Input port', 'SearchMethod', 'Three-step','BlockSize',[blockSize blockSize]);
        %hbm.OutputValue = 'Horizontal and vertical components in complex form';
        halphablend = vision.AlphaBlender;
    case 'opticalFlow'
        opticFlow = opticalFlowHS;
end

%obtains first frame and transforms it to gray and then double
img1 = im2double(rgb2gray(readFrame(videoObject)));

motionPerFrame = zeros(1,totalFrames-1);
for j = 1:totalFrames-1
    imgColor = readFrame(videoObject);
    switch method
        case 'blockMatcher'
%             motion = step(hbm, img1, img2);
            img2 = im2double(rgb2gray(imgColor));
            motion = hbm(img1,img2);
            img1 = img2;
        case 'opticalFlow'
            frameGray = im2gray(imgColor);
            
            flow = estimateFlow(opticFlow,frameGray);
            motion = flow.Magnitude;
    end
    
    motionPerFrame(j) = sum(motion(:));
    
end
if strcmp(method,'opticalFlow')
    motionPerFrame(1) = mean(motionPerFrame(2:end));
end

motion = sum(motionPerFrame);


if testing
    switch method
        case 'blockMatcher'
            %clf
            videoObject = VideoReader(videoFile);
            for j = 1:totalFrames-1
                imgColor = readFrame(videoObject);
                img2 = im2double(rgb2gray(imgColor));
                %motion{j} = step(hbm,currFrame,prevFrame);

                motion = step(hbm, img1, img2);
                [X,Y] = meshgrid(1:blockSize:size(img1,2),1:blockSize:size(img1,1));         
                imshow(imgColor)
                hold on
                quiver(X(:),Y(:),real(motion(:)),imag(motion(:)),0)
                hold off
                pause(pauseTime)
            end
        case 'opticalFlow'
            vidReader = VideoReader(videoFile);
            opticFlow = opticalFlowHS;
            h = figure;
            movegui(h);
            hViewPanel = uipanel(h,'Position',[0 0 1 1],'Title','Plot of Optical Flow Vectors');
            hPlot = axes(hViewPanel);

            while hasFrame(vidReader)
                frameRGB = readFrame(vidReader);
                frameGray = im2gray(frameRGB);  
                flow = estimateFlow(opticFlow,frameGray);
                imshow(frameRGB)
                hold on
                plot(flow,'DecimationFactor',[5 5],'ScaleFactor',60,'Parent',hPlot);
                hold off
                pause(10^-3)
            end
    end
end