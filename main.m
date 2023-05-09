% main 
% psuedo online demo for a session with joint learning on CSP+SVM
% data was recorded from subject 4 in training session 4
clear all;
% load data 
load('.\demodata.mat');
% load previous parameter
parameter=previousparameter;
channelNames=props.channelNames;
fs=1000;
threshold=0.7;
% load trial label
index=linspace(1,39,20); % two trials as a set, so load the first one
triallabel=sesslabel(index);
% experiment start
[acc,ME]=paradigm(threshold,sessdata,parameter,channelNames,fs,triallabel);
% update parameter
parameter=SPCSPcell(sessdata,sesslabel,fs,channelNames);