function [allRuns,avHRF,timeLine,avHRFSplit,durations,avSTD] = calculateHRF(valuesMat,complete,runsPossible,varargin)
%The function takes valuesMat which has the timeseries of a single voxel
%for all runs in runsPossible
%valuesMat: rows=runs cols=volumes
%gives back the aligned HRF for all trials across all runs (allRuns) an 
% average HRF (avHRF), the timeLine and avHRFsplit (one row for each
% stimuli duration) and durations, the stim durations found in avHRFSplit
getDriveFolder;

TR = getArgumentValue('TR',2.5,varargin{:});
volumes = getArgumentValue('volumes',124,varargin{:});
timeStep = getArgumentValue('timeStep',0.02,varargin{:});
minTime = getArgumentValue('minTime',1,varargin{:});
maxTime = getArgumentValue('maxTime',10,varargin{:});
blanks = getArgumentValue('blanks',false,varargin{:});


realTimeLine = 0:TR:TR*(volumes-1);
newTimeLine = 0:timeStep:TR*(volumes-1);

allRuns = [];
for nRun = 1:length(runsPossible)
    runN = runsPossible(nRun);
    values = valuesMat(nRun,:);
    complete2 = filterBy(complete,'run',{runN});

    newValues = interp1(realTimeLine,values,newTimeLine);
    minIndxs = [complete2.minIndx];
    maxIndxs = [complete2.maxIndx];
    vectorLen = max(maxIndxs - minIndxs)+1;
    
    nTrials = numel(minIndxs);
    allTimes = nan(nTrials,vectorLen); %container for all vectors aligned
    %row-trial,col-time vector
    for nRow = 1:numel(minIndxs)
        minIndx = minIndxs(nRow);
        maxIndx = maxIndxs(nRow);
        
        allTimes(nRow,1:length(minIndx:maxIndx)) = newValues(minIndx:maxIndx);
       
    end
    allRuns = [allRuns;allTimes]; %#ok<AGROW>
end


if blanks
    avHRFSplit = [];
    durations = [];
else
    durations = unique([complete.duration]);
    avHRFSplit = zeros(length(durations),vectorLen);
    for nDuration = 1:length(durations)
        duration = durations(nDuration);
        indx = logical([complete.duration] == duration);
        allRunsx = allRuns(indx,:);
        avHRFx = nanmean(allRunsx); %#ok<NANMEAN>
        avHRFSplit(nDuration,:) = avHRFx;
    end
end

avHRF = nanmean(allRuns); %#ok<NANMEAN>
avSTD = nanstd(allRuns);
timeLine = -minTime:timeStep:maxTime;
