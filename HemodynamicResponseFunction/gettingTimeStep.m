%% This script determines the minimum time window between video onsets to be used as minimal distance between time points

clear
getDriveFolder; %loads some paths I commonly use

experiment = 'Viscat';
saveFolder = [dropboxFolder,'\MVPA\',experiment,'\runsData\complete'];
volumes = 124;
newTimeLine = 0:2.5:2.5*(volumes-1);
speciesPossible = {'Hum','Dog'};

totalTimes = [];
for nSpecie = 1:length(speciesPossible)
    specie = speciesPossible{nSpecie};
    switch specie
        case 'Hum'
            subsPossible = 1:13;
        case 'Dog'
            subsPossible = 1:15;
    end

    for nSub = 1:length(subsPossible)
        nParticipant = subsPossible(nSub);
        disp(['Getting: ',num2str(nParticipant),' / ',num2str(length(subsPossible))])

        participant = getList(specie,'nItem',nParticipant,'experiment',experiment); %gets the participant name
        e = load([saveFolder,'\',participant,'.mat']); %loads the participant onsets
        complete = e.complete;
        
        allTimes = zeros(1,size(complete,2));
        for nStim = 1:size(complete,2)    
            onset = complete(nStim).onset;
            dif = newTimeLine - onset;
            dif(dif>0) = -99;
            [val,nVolume] = max(dif);
            timeFromOnset = val;
            allTimes(nStim) = val;
        end
        totalTimes=[totalTimes,allTimes]; %#ok<AGROW>
    end
end

minimumTimeDistance = abs(max(totalTimes(abs(totalTimes)>0)));
