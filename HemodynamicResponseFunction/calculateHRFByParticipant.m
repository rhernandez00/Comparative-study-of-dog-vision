%{ 
This script calculates the brain response on each voxel for each
participant. The data is saved so it can be loaded by other scripts
%}
clear
clf
getDriveFolder;
experiment = 'Viscat';
addpath([dropboxFolder,'\MVPA\',experiment,'\functions']);
saveFolder = [dropboxFolder,'\MVPA\',experiment,'\runsData\complete'];
saveMatPath = [driveFolder,'\Results\',experiment,'\HRF'];


TR = 2.5;
volumes = 124;
timeStep = 0.02;
%realTimeLine = 0:TR:TR*(volumes-1);
% newTimeLine = 0:timeStep:TR*(volumes-1);
minTime = 1; %time before the onset
maxTime = 12; %time after onset to calculate HRF
timeLine = -minTime:timeStep:maxTime;

runsPossible = 1:6; 
subsPossible = 1:15;
specieS = 'Dog';

specie = specieS(1);
coordsFile = [saveMatPath,'\',specie,'_coords.mat'];
if exist(coordsFile,'file')
    load(coordsFile)
    disp('coords file found, loading')
else
    coords = []; %initializes coords
    error('coords file not found')
end

for nSub = 1:length(subsPossible)
    sub = subsPossible(nSub);
    complete = getComplete(specieS,sub,'experiment',experiment,...
        'runsPossible',runsPossible,'TR',TR,'volumes',volumes,...
        'timeStep',timeStep,'minTime',minTime,'maxTime',maxTime);

    [imgs,coords] = BOLDToFlat(experiment,specie,sub,runsPossible,'coords',...
        coords, 'checkVolumes', 'dontCare');%each imgs contains
    % a flatBOLD in each cell. flatBOLD: rows=voxels cols=volumes. coords will
    % be calculated only the first time (as coords=[]);
    volumes = size(imgs{1},2);
    flatHRFMap = zeros(size(coords,1),length(timeLine));
    flatHRFMap1 = zeros(size(coords,1),length(timeLine));
    flatHRFMap2 = zeros(size(coords,1),length(timeLine));
    flatHRFMap3 = zeros(size(coords,1),length(timeLine));
    flatSTDMap = zeros(size(coords,1),length(timeLine));
    disp('Calculating HRF for each voxel')
    for nVox = 1:size(coords,1)
        disp(['nVox: ',num2str(nVox),' / ', num2str(size(coords,1))]);
        %Getting data for a single voxel (all runs)
        valuesMat = zeros(length(runsPossible),volumes);
        for nRun = 1:length(runsPossible)
            flatBOLD = imgs{nRun};
            valsPerRun = flatBOLD(nVox,:);
            valuesMat(nRun,1:length(valsPerRun)) = valsPerRun;
        end
        %getting the HRF for that voxel
        [allRuns,avHRF,timeLine,avHRFSplit,durations,avSTD] = calculateHRF(valuesMat,complete,runsPossible,...
            'TR',TR,'volumes',volumes,'timeStep',timeStep,'minTime',minTime,...
            'maxTime',maxTime);
        flatSTDMap(nVox,:) = avSTD;
        flatHRFMap(nVox,:) = avHRF;
        flatHRFMap1(nVox,:) = avHRFSplit(1,:);
        flatHRFMap2(nVox,:) = avHRFSplit(2,:);
        flatHRFMap3(nVox,:) = avHRFSplit(3,:);

    end

    if ~exist(coordsFile,'file')
        save(coordsFile,'coords');
    end
    
    disp(['Calculating blanks']);
    complete = getComplete(specieS,sub,'experiment',experiment,...
        'runsPossible',runsPossible,'TR',TR,'volumes',volumes,...
        'timeStep',timeStep,'minTime',minTime,'maxTime',maxTime,'blanks',true);
    
    
    flatHRFMapBlank = zeros(size(coords,1),length(timeLine));
    flatSTDMapBlank = zeros(size(coords,1),length(timeLine));
    disp('Calculating HRF for each voxel')
    for nVox = 1:size(coords,1)
        disp(['nVox: ',num2str(nVox),' / ', num2str(size(coords,1))]);
        %Getting data for a single voxel (all runs)
        valuesMat = zeros(length(runsPossible),volumes);
        for nRun = 1:length(runsPossible)
            flatBOLD = imgs{nRun};
            valsPerRun = flatBOLD(nVox,:);
            valuesMat(nRun,1:length(valsPerRun)) = valsPerRun;
        end
        %getting the HRF for that voxel
        [~,avHRF,~,~,~,avSTD] = calculateHRF(valuesMat,complete,runsPossible,...
            'TR',TR,'volumes',volumes,'timeStep',timeStep,'minTime',minTime,...
            'maxTime',maxTime,'blanks',true);
        flatSTDMapBlank(nVox,:) = avSTD;
        flatHRFMapBlank(nVox,:) = avHRF;

    end

    if ~exist(coordsFile,'file')
        save(coordsFile,'coords');
    end
    
    saveFile = [saveMatPath,'\',specie,'_sub',sprintf('%03d',sub),'.mat'];
    save(saveFile,'flatHRFMap','flatHRFMap1','flatHRFMap2',...
        'flatHRFMap3','timeLine','durations','flatSTDMap','flatSTDMapBlank','flatHRFMapBlank');
end
