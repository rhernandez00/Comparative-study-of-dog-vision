function [results] = calculateVideoValues(videoName)
%{
Returns results, a structure with the fields described below. Each property
represents the average across all frames, the properties calculated are: 
.hue: hue calculated as the first element in the MATLAB transformation 
from RGB to HSV
.saturation: saturation calculated as the second element in the MATLAB 
transformation from RGB to HSV
.brightness: brightness calculated by transforming each frame to a grey 
scale and calculating the average intensity across the image
.contrast: contrast defined as the root mean square of the grey scale frame
.motion: motion calculated using blockMatcher a MATLAB method to estimate
changes in movement between two frames
.numberOfFrames: number of frames in the video
%}

%reading the file
videoObject = VideoReader(videoName);
numberOfFrames = videoObject.NumFrames;
videoObject = VideoReader(videoName);

%Initializing variables
hue = zeros(1,numberOfFrames);
saturation = zeros(1,numberOfFrames);
brightness = zeros(1,numberOfFrames);
contrast = zeros(1,numberOfFrames);
for j = 1:numberOfFrames %runs through every frame and calculates the values
    
    img1 = readFrame(videoObject);
    img2 = rgb2hsv(img1);
    hue(j) = mean2(img2(:,:,1));
    saturation(j) = mean2(img2(:,:,2));
    imgGray = rgb2gray(img1);
    brightness(j) = mean2(imgGray);
    contrast(j) = rms(imgGray(:));%defined as root mean square
end
%averaging across frames
hue = mean(hue);
saturation = mean(saturation);
brightness = mean(brightness);
contrast = mean(contrast);

%Calculates motion using MATLAB's BlockMatcher function
[~,motion] = calculateMotion(videoName,'method','blockMatcher');

%Writing properties in the results structure
results.hue = hue;
results.saturation = saturation;
results.brightness = brightness;
results.contrast = contrast;
results.motion = motion;
results.numberOfFrames = numberOfFrames;