function parameter=SPCSPcell(traindata,trainlabel,SampleRate,channelNames)
% input size
% traindata: time points * channel * epoch

% electrode selection
    electrodeset={'FC5';'FC3';'FC1';'FCz';'FC2';'FC4';'FC6'; ...
                'C5';'C3';'C1';'Cz';'C2';'C4';'C6'; ...
                'CP5';'CP3';'CP1';'CP2';'CP4';'CP6'};
    electrodeindex=zeros(size(electrodeset));
    for i=1:size(electrodeset,1)           
    electrodeindex(i)=find(ismember(channelNames, electrodeset{i}));
    end
% numfilter integer 3
    numFilterPairs=3;
    fs=SampleRate;
    % filter 8-30Hz
    [b,a]= butter(4,[8 30]/(SampleRate/2),'bandpass');
    % filt by trial
    % traindata
    epochdata=traindata;
    filtdatafilter=[];
    alltrainlabel=[];
    for i=1:size(epochdata,2)
        tmpdata=epochdata{i};
        for j=1:4
        tmpfiltdata=filtfilt(b,a,squeeze(tmpdata(electrodeindex,200+(j-1)*SampleRate:199+(j)*SampleRate))');
        filtdatafilter=cat(3,filtdatafilter,tmpfiltdata);
        alltrainlabel=cat(2,alltrainlabel,trainlabel(i));
        end
    end
    filttraindata=filtdatafilter;
    filtdatafilter=[];
    stopround=0;
    symbol=[];
    allrounds=17;
    flag=0;
    % split left and right for balance
leftindex=find(alltrainlabel==1);
rightindex=find(alltrainlabel==2);
% init samples ratio
initratio=0.2;
numberofinitsampleleft=floor(initratio/2*length(alltrainlabel));
newweights=zeros(size(alltrainlabel));

for rounds=1:allrounds % start iterations
% new self-paced SVM
if rounds==1
    % init choose 20% samples
    random_num = leftindex(randperm(numel(leftindex),numberofinitsampleleft));
    chosenleftindex = sort(random_num);
    random_num = rightindex(randperm(numel(rightindex),numberofinitsampleleft));
    chosenrightindex = sort(random_num);
    chosenindexall=cat(2,chosenleftindex,chosenrightindex);
    newweights(chosenindexall)=1;
    allweights{1}=newweights;
end
    % for train data
    featureall=[];
    for j=1
        filtdatafilter=squeeze(filttraindata(:,:,:,j));
        EEGSignals.x=filtdatafilter;
        EEGSignals.y=alltrainlabel';
        EEGSignals.s=fs;
        CSPMatrix{j} = learnCSPweighted(EEGSignals,unique(alltrainlabel),newweights);
        [feature,projectedTrial,Filter] = extractCSP(EEGSignals, CSPMatrix{j}, numFilterPairs);
        featureall=cat(2,featureall,feature);
    end
    trainfeatureall=featureall;
    selectedfeaturetrain=trainfeatureall;
    allCSPMatrix{rounds}=CSPMatrix;

% split val set
valratio=0.15;
sizeval=floor(valratio*size(trainfeatureall,1));
alldataindex=1:size(trainfeatureall,1);
valindex=randperm(size(trainfeatureall,1),sizeval);
leftsampleindex=setdiff(alldataindex,valindex);
valfeatureall=selectedfeaturetrain(valindex,:);
vallabel=alltrainlabel(valindex);
trainfeatureall=selectedfeaturetrain(leftsampleindex,:);
selectedtrainlabel=alltrainlabel(leftsampleindex);
newweights=newweights(leftsampleindex);
leftindex=find(selectedtrainlabel==1);
rightindex=find(selectedtrainlabel==2);

% train and test SVM
LDAModel=fitcsvm(trainfeatureall,selectedtrainlabel,'Weights',newweights,'Solver','L1QP');
allLDAModel{rounds}=LDAModel;
[problabel,probscores] =predict(LDAModel,trainfeatureall);
acctrain(rounds)=sum(problabel==selectedtrainlabel')/length(selectedtrainlabel);
[probvallabel,probvalscores] =predict(LDAModel,valfeatureall);
accval(rounds)=sum(probvallabel==vallabel')/length(vallabel);
% 
accindex=((problabel==selectedtrainlabel')-0.5)*2;
losstmp=1-max(probscores,[],2).*accindex;
newlosstmp=losstmp;
newlosstmp(losstmp<0)=0;
lambda=initratio+(1-initratio)/(allrounds-1)*(rounds-1);
kexi=1-lambda;
if kexi==0
    kexi=eps;
end
L(rounds)=0.5* norm(LDAModel.Beta,2)+sum(LDAModel.BoxConstraints.*newlosstmp(newweights>0))+sum(kexi*newweights(newweights>0) ...
-kexi*ones(size(newweights(newweights>0))).^(newweights(newweights>0)/log(kexi)));
Lambda(rounds)=lambda;

% update weights and including more data
leftloss=losstmp(leftindex);
rightloss=losstmp(rightindex);
lambda=initratio+(1-initratio)/(allrounds-1)*(rounds);
if lambda>1
    lambda=1;
end
thresholdleft = quantile(sort(leftloss),lambda);
thresholdright = quantile(sort(rightloss),lambda);
chosenindexleft=find(leftloss<=thresholdleft);
chosenindexright=find(rightloss<=thresholdright);
chosenindexall=cat(2,leftindex(chosenindexleft),rightindex(chosenindexright));
newweights=zeros(size(alltrainlabel));
newweights(chosenindexall)=1;
losstmp(losstmp<0)=0;
normedloss=losstmp/(max(losstmp)+eps);
index=find(newweights>0);
newweights(index)=log(normedloss(index)+kexi)/log(kexi);
newweights=newweights/max(newweights);
newweights(newweights<1e-5)=0;
allweights{rounds+1}=newweights;
end
normL=L./Lambda;
% find stop round
[~,minindex]=max(flip(accval));
minindex=allrounds+1-minindex;
stopround=minindex;
[~,SVscore] = predict(allLDAModel{minindex},allLDAModel{minindex}.SupportVectors);


    % set parameter and output
    parameter.SVscore=SVscore;
    parameter.SVlabel=allLDAModel{minindex}.SupportVectorLabels;
    parameter.CSPMatrix=allCSPMatrix{minindex};
    parameter.LDA=allLDAModel{minindex};
    parameter.acctrain=acctrain;
    parameter.numFilterPairs=numFilterPairs;
    parameter.lambda=Lambda;
    parameter.a=a;
    parameter.b=b;
    parameter.loss=L;
    parameter.normloss=normL;
    parameter.weights=allweights;
    parameter.projectedTrial=projectedTrial;
    parameter.accval=accval;
    parameter.stopround=stopround;
    parameter.trainfeature=selectedfeaturetrain;
    parameter.predlabeltrain=problabel;
    parameter.truelabeltrain=trainlabel';
    parameter.accindexwithval=minindex;
    parameter.allCSPMatrix=allCSPMatrix;
    parameter.allLDAModel=allLDAModel;

end