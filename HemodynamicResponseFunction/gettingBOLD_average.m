%% Getting average map for each specie 31/Oct/2021

clear
getDriveFolder;
addpath([dropboxFolder,'\MVPA\Complex\functions']);
experiment = 'Complex';
saveFolder = [dropboxFolder,'\MVPA\',experiment,'\runsData\complete'];
niiOutput = [driveFolder,'\Results\',experiment,'\HRF']; 
saveMatPath = ['D:\Raul\results\Complex\HRF'];


TR = 2.5;
volumes = 124;
timeStep = 0.02;
minTime = 1; %time before the onset
maxTime = 12; %time after onset to calculate HRF
timeLine = -minTime:timeStep:maxTime;

mapsPossible = {'visual','visual1','visual2','visual3','blanks','err'};
mapType = 4;
mapToCreate = mapsPossible{mapType};
specie = 'H'; %takes D or H

switch mapToCreate
    case 'visual'
        getError = true; %calculate stdError 
        blanks = false; %calculate from visual (false) or blank (true)
    case 'visual1'
        getError = true; %calculate stdError 
        blanks = false; %calculate from visual (false) or blank (true)
    case 'visual2'
        getError = true; %calculate stdError 
        blanks = false; %calculate from visual (false) or blank (true)
    case 'visual3'
        getError = true; %calculate stdError 
        blanks = false; %calculate from visual (false) or blank (true)
    case 'blanks'
        getError = true;%calculate stdError 
        blanks = true; %false run as normal. true, get the HRF when there was no visual stimulation
    case 'err'
        getError = false;%calculate stdError 
        blanks = false;%calculate from visual (false) or blank (true)
end

switch specie
    case 'D'
        subsPossible = 1:15;
        ref = 'Barney2mm';
    case 'H'
        subsPossible = 1:13;
        ref = 'MNI2mm';
end
coordsFile = [saveMatPath,'\',specie,'_coords.mat'];
if exist(coordsFile,'file')
    load(coordsFile)
    disp('coords file found, loading')
else
    coords = []; %initializes coords
    error('coords file not found')
end

allSubs = cell(1,length(subsPossible)); %Here the maps for each participant will be stored
for nSub = 1:length(subsPossible)
    sub = subsPossible(nSub);
    disp(['sub',sprintf('%03d',sub)]);
    saveFile = [saveMatPath,'\',specie,'_sub',sprintf('%03d',sub),'.mat']; %save file of data for that participant
    e = load(saveFile);
    switch mapToCreate
        case 'visual'
            allSubs{nSub} = e.flatHRFMap;
        case 'visual1'
            allSubs{nSub} = e.flatHRFMap1;
        case 'visual2'
            allSubs{nSub} = e.flatHRFMap2;
        case 'visual3'
            allSubs{nSub} = e.flatHRFMap3;
        case 'blanks'
            allSubs{nSub} = e.flatHRFMapBlank;
        case 'err'
            allSubs{nSub} = e.flatSTDMap;
    end
end
clear e

avFlatMap = zeros(size(coords,1),length(timeLine));%map containing all participants
errFlatMap = zeros(size(coords,1),length(timeLine));%map containing all participants error
%row denotes a coordinate, col denotes time point
%the loop will fill one time step at a time to reduce memory load (at the cost of running time)
for nTime = 1:length(timeLine) 
    disp(['Running time point ',num2str(nTime), ' / ', num2str(length(timeLine)) ]);
    avFlatMapStep = zeros(length(subsPossible),size(coords,1)); %map for each step
    for nSub = 1:length(subsPossible)
        sub = subsPossible(nSub);
        subMap = allSubs{nSub};
        avFlatMapStep(nSub,:) = subMap(:,nTime);%repeat for Map1, Map2, Map3
    end
    avFlatMap(:,nTime) = mean(avFlatMapStep);
    if getError
        errFlatMap(:,nTime) = std(avFlatMapStep)/sqrt(size(avFlatMapStep,1));
    end
end
clear allSubs afFlatMapStep

% ---------Saving BOLD to represent the signal on each timestep-----------
%Loads a nii file to be used as template
[BOLD,BOLDnii] = getCortex([ref,'BOLD']);%Group average 4D matrix where the 4th dimension represents each time step.
BOLD(:) = 0;
BOLDerr = BOLD;
for nCoord = 1:size(coords,1)
    x = coords(nCoord,1);
    y = coords(nCoord,2);
    z = coords(nCoord,3);
    disp(['Assigning: ',num2str(nCoord),' / ',num2str(size(coords,1))])
    for nTime = 1:length(timeLine) 
        BOLD(x,y,z,nTime) = avFlatMap(nCoord,nTime);
        if getError
            BOLDerr(x,y,z,nTime) = errFlatMap(nCoord,nTime);
        end
    end
    
end
BOLDnii.img = BOLD;
BOLDnii.hdr.dime.dim(5) = length(timeLine); %changing header so it considers all time steps

switch mapToCreate
        case 'visual'
            BOLDFile = [niiOutput,'\',specie,'_HRF_4D.nii.gz']; %#ok<*UNRCH>
            BOLDerrFile = [niiOutput,'\',specie,'_HRF_4Derr.nii.gz'];
        case 'visual1'
            BOLDFile = [niiOutput,'\',specie,'_HRF1_4D.nii.gz']; %#ok<*UNRCH>
            BOLDerrFile = [niiOutput,'\',specie,'_HRF1_4Derr.nii.gz'];
        case 'visual2'
            BOLDFile = [niiOutput,'\',specie,'_HRF2_4D.nii.gz']; %#ok<*UNRCH>
            BOLDerrFile = [niiOutput,'\',specie,'_HRF2_4Derr.nii.gz'];
        case 'visual3'
            BOLDFile = [niiOutput,'\',specie,'_HRF3_4D.nii.gz']; %#ok<*UNRCH>
            BOLDerrFile = [niiOutput,'\',specie,'_HRF3_4Derr.nii.gz'];
        case 'blanks'
            BOLDFile = [niiOutput,'\',specie,'_HRFnoVisual_4D.nii.gz'];
            BOLDerrFile = [niiOutput,'\',specie,'_HRFnoVisual_4Derr.nii.gz'];
        case 'err'
            BOLDFile = [niiOutput,'\',specie,'_HRF_4DstdErr.nii.gz'];
end

save_untouch_nii(BOLDnii,BOLDFile);
disp([BOLDFile, ' saved'])

if getError %Whether to save the error as well
    BOLDnii.img = BOLDerr;
    save_untouch_nii(BOLDnii,BOLDerrFile);
    disp([BOLDerrFile, ' saved'])
end
clear
% -------------------------------------------------------------