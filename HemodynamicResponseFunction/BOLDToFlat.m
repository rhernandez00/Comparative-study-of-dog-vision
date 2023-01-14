function [imgs,coords] = BOLDToFlat(experiment,specie,sub,runsPossible,varargin)
%load all functional images of the participant and returns them in a cell imgs
basePath = getArgumentValue('basePath','D:\Raul\data',varargin{:}); %Base path to find the BOLD images
task = getArgumentValue('task',1,varargin{:}); %Refers to the naming of the BOLD file
ref = getArgumentValue('ref',[],varargin{:});% in case a specific reference
volumes = getArgumentValue('volumes',[],varargin{:}); %if empty, it will
% get it from the first run
% is needed. Default is Barney2mm for D and MNI2mm for H
checkVolumes = getArgumentValue('checkVolumes','allowMore',varargin{:}); %takes:
%'allowMore': allow runs with higher number of volmunes. 'strict': whenever
%a run has more or less, it gives an error.
verbose = getArgumentValue('verbose','full',varargin{:}); %full shows everything that is happenning
zscoreS = getArgumentValue('zscore',true,varargin{:}); %z-scoring?
coords = getArgumentValue('coords',[],varargin{:});

if isempty(ref) %by default ref is empty and the fuction uses Barney and MNI
    switch specie
        case 'D'
            ref = 'Barney2mm';
        case 'H'
            ref = 'MNI2mm';
    end
end


for nRun = 1:length(runsPossible)
    runN = runsPossible(nRun);
    filename = [basePath,'\',experiment,'\',experiment,specie,'STD\data\sub',...
        sprintf('%03d',sub),'\BOLD\task',sprintf('%03d',task),'_run',...
        sprintf('%03d',runN),'\BOLD.nii.gz'];
    if strcmp(verbose,'full')
        disp(['Loading: ',filename]);
    end
    BOLDImg = load_untouch_niiR(filename);
    mask = getCortex([specie,'_fullBrain']);
    if strcmp(verbose,'full')
        disp(['filtering: ',filename]);
    end
    [BOLDFiltered,~,maskIndx] = filterWithMask(BOLDImg.img,mask);
    if nRun == 1
        disp('Run 1, initializing some variables');
        if isempty(volumes)
            volumes = size(BOLDFiltered,4);
        end
        totalVoxels = numel(maskIndx);
        imgs = cell(1,length(runsPossible));
        if isempty(coords)
            coords = zeros(totalVoxels,3);
            for nVox = 1:totalVoxels
                disp(['Coords for nVox: ',num2str(nVox), ' / ', num2str(totalVoxels)]);
                indx = maskIndx(nVox);
                [x,y,z] = flatToXYZ(indx,ref);
                coords(nVox,1) = x;
                coords(nVox,2) = y;
                coords(nVox,3) = z;
            end
        end
    end
    switch checkVolumes %gives and error when a run has more or less volumnes
        case 'strict'
            if size(BOLDFiltered,4) ~= volumes %checks the 
                disp(['Volumes expected: ',num2str(volumes),...
                    ' volumnes in run ',num2str(runN),' : ',...
                    num2str(size(BOLDFiltered,4))]);
                error('Wrong number of volumes');
            end
        case 'allowMore'
            if size(BOLDFiltered,4) < volumes %checks the 
                disp(['The volumes expected where at least: ',num2str(volumes),...
                    'volumnes in run ',num2str(runN),' : ',...
                    num2str(size(BOLDFiltered,4))]);
                error('Wrong number of volumes');
            end
        case 'dontCare'
            %do nothing.
    end
    disp('Flattening volume');
    flatBOLD = zeros(totalVoxels,volumes);%here all the data for the run will be saved
    
    for nVox = 1:totalVoxels
        if strcmp(verbose,'full')
            disp(['nVox: ', num2str(nVox), '/ ',num2str(totalVoxels)]);
        end
        x = coords(nVox,1);
        y = coords(nVox,2);
        z = coords(nVox,3);

        vals =  BOLDFiltered(x,y,z,:); %loads all volmunes
        vals = vals(:); %flats the data
        if zscoreS
            vals = zscore(vals);
        end
        flatBOLD(nVox,1:length(vals)) = vals;

    end
    imgs{nRun} = flatBOLD;
end
