 function [scoreout,figout]=feedbackweightedCSPcell(parameter,longdata,points,fs,channelNames)
numFilterPairs=3;
numFeatures=6;
electrodeset={'FC5';'FC3';'FC1';'FCz';'FC2';'FC4';'FC6'; ...
                'C5';'C3';'C1';'Cz';'C2';'C4';'C6'; ...
                'CP5';'CP3';'CP1';'CP2';'CP4';'CP6'};
    electrodeindex=zeros(size(electrodeset));
    for i=1:size(electrodeset,1)           
    electrodeindex(i)=find(ismember(channelNames, electrodeset{i}));
    end
    % filt and electrode selection
    [braw,araw]=butter(4,[8 30]/fs*2,'bandpass');
    filtdata=zeros(points,length(electrodeindex));
    filtdata(:,:)=filtfilt(braw,araw,longdata(electrodeindex,end-points+1:end)');
    % CSP
    featureall=[];
    filttraindata=squeeze(filtdata(:,:));
    EEGSignals.x=filttraindata;
    EEGSignals.s=fs;
    [feature,projectedTrial,Filter] = extractCSP(EEGSignals, parameter.CSPMatrix{1}, numFilterPairs);
    featureall=cat(2,featureall,feature);
    trainfeatureall=featureall; 
    % predict
    [predlabel,score] = predict(parameter.LDA,trainfeatureall);
    % adjust score 
    scoreout=-1*score(1)+1*score(2);
    figout=[0;1;0;1];
end