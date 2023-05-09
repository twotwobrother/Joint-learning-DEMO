function [acc,ME]=paradigm(threshold,sessdata,parameter,channelNames,fs,trial)
ME=[];
%%%%% for psychtoolbox %%%%%
    % load picture
    leftpic=imread('./picture/left3.jpg');
    rightpic=imread('./picture/right3.jpg');
    % resize
    leftpic = imresize(leftpic, [500 NaN]);
    rightpic = imresize(rightpic, [500 NaN]);
    pic{1}=leftpic;
    pic{2}=rightpic;
    % trial time
    timeRelax=2;
    timeFix=2;
    timeSti=2;
    feedbacktime=5;
    % Keyboard
    KbName('UnifyKeyNames');
    onExit = 'execution halted by experimenter';
    disp('preparation2');
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'TextEncodingLocale','');
    AssertOpenGL;
    screenID=1;
    [window, windowRect] = Screen('OpenWindow', screenID);
    [winWidth, winHeight] = RectSize(windowRect);
    winBlack = BlackIndex(window);
    winWhite = WhiteIndex(window);
    winGrey = round((winBlack+winWhite)/2);
    winRed = [winWhite, winBlack, winBlack];
    Priority(MaxPriority(window));
    HideCursor;
    Screen('Preference', 'SkipSyncTests', 1);
    disp('preparation end');
    try
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    [xCenter, yCenter] = RectCenter(windowRect);
    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    ifi = Screen('GetFlipInterval', window);
    % oval rect position
    xmid = screenXpixels/2;
    ymid = screenYpixels/2;
    sqrsize = 300;
    sqrdistance =500;
    % left sqr position
    leftsqrleftx = xmid-sqrdistance/2-sqrsize;
    leftsqrrightx = xmid-sqrdistance/2;
    leftsqrlefty = ymid-sqrsize/2;
    leftsqrrighty = ymid+sqrsize/2;
    % right sqr position
    rightsqrleftx = xmid+sqrdistance/2;
    rightsqrrightx = xmid+sqrdistance/2+sqrsize;
    rightsqrlefty = ymid-sqrsize/2;
    rightsqrrighty = ymid+sqrsize/2;              
    % Sync us and get a time stamp
    vbl = Screen('Flip', window);
    waitframes = 1;
    % Maximum priority level
    topPriorityLevel = MaxPriority(window);
    Priority(topPriorityLevel);
    dotColors = [1,1,1];
    % preperations
    Screen('TextSize', window, floor(winHeight/4));
    Screen('FillRect', window, winBlack);
    DrawFormattedText(window, '+', 'center', 'center', winWhite);
    Screen('Flip', window);
    textureFix = Screen('MakeTexture', window, Screen('GetImage', window, windowRect));
    Screen('FillRect', window, winBlack);
    DrawFormattedText(window, '+', 'center', 'center', winGrey);
    Screen('Flip', window);
    textureQuestion = Screen('MakeTexture', window, Screen('GetImage', window, windowRect));
    Screen('TextSize', window, floor(winHeight/20));
    Screen('FillRect', window, winBlack);
    Screen('Flip', window);
    textureRelax = Screen('MakeTexture', window, Screen('GetImage', window, windowRect));
    Screen('FillRect', window, winBlack);
    DrawFormattedText(window, 'Press CTRL to start the experiment', 'center', 'center', winWhite);
    Screen('Flip', window);
    KbWait([],2); % wait for keyboard input
    
    for iRun = 1:length(trial)
        for rounds=1:2 % for first/next trials
        fprintf('iRun: %d \n',iRun);
        Screen('DrawTexture', window, textureFix);
        Screen('Flip', window);
        
        timeRunStart = GetSecs;
        while GetSecs - timeRunStart < timeRelax
            [keyIsDown , keySecs, keyCode] = KbCheck;
            assert(~(keyIsDown && keyCode(KbName('ESCAPE'))), onExit);
        end
    
        Screen('DrawTexture', window, textureQuestion);
        Screen('Flip', window);
        while GetSecs - timeRunStart < timeFix + timeRelax
             [keyIsDown , keySecs, keyCode] = KbCheck; 
             assert(~(keyIsDown && keyCode(KbName('ESCAPE'))), onExit);
        end
        imageTexturePic = Screen('MakeTexture', window, pic{trial(iRun)});
        
        Screen('DrawTexture', window, imageTexturePic);
    %     Screen('Flip', window);
        if rounds==2 % for the next trial
            Screen('DrawText', window, instrctiontext,xmid-50,ymid-200,winWhite, winBlack);
        end
        Screen('Flip', window);
        while GetSecs - timeRunStart < timeFix + timeRelax + timeSti
             [keyIsDown , keySecs, keyCode] = KbCheck; 
             assert(~(keyIsDown && keyCode(KbName('ESCAPE'))), onExit);
        end
        labelnow=trial(iRun)+1;
        % color buffer to smooth the color change
        colorbuffer=[];
        colorbufferlength=10;
        point=1000;
        dataset=sessdata{(iRun-1)*2+rounds};
        leftcount=0;
        rightcount=0;
        nomovecount=0;
        for i=1:round(feedbacktime/ifi)
            % calculate acc every frame
            slidewidth=floor((size(dataset,2)-1000)/round(feedbacktime/ifi));
            longdata=dataset(:,slidewidth*(i-1)+1:slidewidth*(i-1)+1+1000);
            [ddeltax,~]=feedbackweightedCSPcell(parameter,longdata,point,fs,channelNames);
            % color buffer to smooth the color change
            colorindex=ddeltax/2+0.5;
            if isempty(colorbuffer)
                colorbuffer(1)=colorindex;
            elseif length(colorbuffer) < colorbufferlength
                colorbuffer(length(colorbuffer)+1)=colorindex;
            elseif length(colorbuffer)==colorbufferlength
                for ii=1:colorbufferlength-1
                colorbuffer(ii)=colorbuffer(ii+1);
                end
                colorbuffer(colorbufferlength)=colorindex;
            end
            colorindex=mean(colorbuffer);
            ColorRight=[colorindex colorindex colorindex];
            ColorLeft=[1-colorindex 1-colorindex 1-colorindex];
            % draw text left
            Screen('DrawText', window, 'Left', leftsqrleftx+100, leftsqrlefty-100, ...
                        winWhite, winBlack);
            % draw text right
            Screen('DrawText', window, 'Right', rightsqrleftx+100, rightsqrlefty-100, ...
            winWhite, winBlack);
            % draw left sqr 
            Screen('FillRect', window, floor(ColorLeft*255), [leftsqrleftx; leftsqrlefty; leftsqrrightx; leftsqrrighty]);
            % draw right sqr
            Screen('FillRect', window, floor(ColorRight*255), [rightsqrleftx; rightsqrlefty; rightsqrrightx; rightsqrrighty]);
            Screen('Flip', window);
            % calculate acc
            if ddeltax<0
                leftcount=leftcount+1;
            elseif ddeltax>0
                rightcount=rightcount+1;
            elseif ddeltax==0
                nomovecount=nomovecount+1;
            end
            if trial(iRun)==1
                acc(iRun)=leftcount/(leftcount+rightcount+nomovecount);
            else
                acc(iRun)=rightcount/(leftcount+rightcount+nomovecount);
            end
            if rounds==1 % for the first trial  calculate acc
               if acc(iRun)>threshold
                   instrctiontext='Copy';
               else
                   instrctiontext='New';
               end
            end
        end
        end
    end
    Screen('CloseAll');
    catch ME
    Screen('CloseAll');
    end
end