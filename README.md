# Joint-learning-Demo
for the paper: A Human-Machine Joint Learning Framework to Boost Endogenous BCI Training

# download data
the dataset is too big for uploading to Git. Download the data from the link:
https://drive.google.com/file/d/1DxK0FsAkQY8Hkh_3yWu2GpNwl1Nc8yl4/view?usp=share_link

# requirements
pychtoolbox + matlab 2020

# run
just download the data in the directory and run main.m

# Demo
We recorded a video for the running process of the code to show the result. 

# data structure
There are 4 parts in the demodata.mat, which was selected from one subject in a joint learning session.
- previousparameter: all the parameters trained in the previous session, which is used for the online feedback.
- props: 64 channel names, information from the EEG device.
- sessdata: 1x40 cell, 40 trials in joint learning session. Each cell includes 65x5000+ points, slightly longer than 5 sec data in case for system lag. The last row is for the trigger signal.
- sesslabel: 1x40 double, instruction labels for 40 trials. 1 for left, 2 for right.
