function CSPMatrix = learnCSPweighted(EEGSignals,classLabels,weight)
%Input:
%EEGSignals: the training EEG signals, composed of 2 classes. These signals
%are a structure such that:
%   EEGSignals.x: the EEG signals as a [Ns * Nc * Nt] Matrix where
%       Ns: number of EEG samples per trial
%       Nc: number of channels (EEG electrodes)
%       nT: number of trials
%   EEGSignals.y: a [1 * Nt] vector containing the class labels for each trial
%   EEGSignals.s: the sampling frequency (in Hz)
%
%Output:
%CSPMatrix: the learnt CSP filters (a [Nc*Nc] matrix with the filters as rows)
%
%See also: extractCSPFeatures

%check and initializations
nbChannels = size(EEGSignals.x,2);      % channel
nbTrials = size(EEGSignals.x,3);        % trials
nbClasses = length(classLabels);        % class

if nbClasses ~= 2
    disp('ERROR! CSP can only be used for two classes');
    return;
end

covMatrices = cell(nbClasses,1); %the covariance matrices for each class

%% Computing the normalized covariance matrices for each trial
trialCov = zeros(nbChannels,nbChannels,nbTrials);
for t=1:nbTrials
    E = EEGSignals.x(:,:,t)';                       %note the transpose
    EE = E * E';
    trialCov(:,:,t) = EE ./ trace(EE);
end
clear E;
clear EE;


%computing the covariance matrix for each class
for c=1:nbClasses      
    %EEGSignals.y==classLabels(c) returns the indeces corresponding to the class labels 
    index = find(EEGSignals.y==classLabels(c));
    chosenweight=weight(index);
    chosentrial=trialCov(:,:,index);
    for i=1:length(index)
        chosentrial(:,:,i)=chosentrial(:,:,i).*chosenweight(i);
    end
    tmp = sum(chosentrial,3);
    tmp = tmp/sum(weight(index));
    covMatrices{c} = tmp;  
end

%the total covariance matrix
covTotal = covMatrices{1} + covMatrices{2};

[Ut Dt] = eig(covMatrices{1},covTotal);
eigenvalues = diag(Dt);
[eigenvalues egIndex] = sort(abs(eigenvalues), 'descend');
Ut = Ut(:,egIndex);
eigenvalues = eigenvalues(egIndex);
CSPMatrix = Ut';
