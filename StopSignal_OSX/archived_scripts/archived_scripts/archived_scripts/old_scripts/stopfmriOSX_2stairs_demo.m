%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% Stopfmri %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Adam Aron 12-01-2005
%%% Adapted for OSX Psychtoolbox by Jessica Cohen 12/2005
%%% Modified for use with new BMC trigger-same device as button box by JC 1/07
%%% Sound updated and modified for Jess' dissertation by JC 10/08
%%% This version is a demo, updated 11-5-08 by Jess

clear all;
scannum=1;
MRI=input('Are you scanning? 1 if yes, 0 if no: ');

LADDER1IN=150;
LADDER2IN=200;
%Ladder Starts (in ms):
Ladder1=LADDER1IN;
Ladder(1,1)=LADDER1IN;
Ladder2=LADDER2IN;
Ladder(2,1)=LADDER2IN;	

inputfile='demo.mat';
load(inputfile);


try,  % goes with catch at end of script

    %% set up input devices
    numDevices=PsychHID('NumDevices');
    devices=PsychHID('Devices');
    if MRI==1,
        for n=1:numDevices,
            if (findstr(devices(n).transport,'USB') & findstr(devices(n).usageName,'Keyboard') & (devices(n).productID==16385 | devices(n).vendorID==6171 | devices(n).totalElements==274)),
                inputDevice=n;
            %else,
            %    inputDevice=2; % my keyboard
            end;
        end;
        fprintf('Using Device #%d (%s)\n',inputDevice,devices(inputDevice).product);
    else,
        for n=1:numDevices,
            if (findstr(devices(n).transport,'USB') & findstr(devices(n).usageName,'Keyboard')),
                inputDevice=n;
                break,
            elseif (findstr(devices(n).transport,'Bluetooth') & findstr(devices(n).usageName,'Keyboard')),
                inputDevice=n;
                break,
            elseif findstr(devices(n).transport,'ADB') & findstr(devices(n).usageName,'Keyboard'),
                inputDevice=n;
            end;
        end;
        fprintf('Using Device #%d (%s)\n',inputDevice,devices(n).product);
    end;

    % set up screens
    fprintf('setting up screen\n');
    screens=Screen('Screens');
    screenNumber=max(screens);
    w=Screen('OpenWindow', screenNumber,0,[],32,2);
    [wWidth, wHeight]=Screen('WindowSize', w);
    grayLevel=120;
    Screen('FillRect', w, grayLevel);
    Screen('Flip', w);

    black=BlackIndex(w); % Should equal 0.
    white=WhiteIndex(w); % Should equal 255.

    xcenter=wWidth/2;
    ycenter=wHeight/2;

    theFont='Arial';
    Screen('TextSize',w,24);
    Screen('TextFont',w,theFont);
    Screen('TextColor',w,white);
   
    CircleSize=400;
    CirclePosX=xcenter-92;
    CirclePosY=ycenter-250;
    ArrowSize=150;
    ArrowPosX=xcenter-25;
    ArrowPosY=ycenter-125;

    HideCursor;

    %Adaptable Constants
    % "chunks", will always be size 64:
    NUMCHUNKS=4;  %gngscan has 4 blocks of 64 (2 scans with 2 blocks of 64 each--but says 128 b/c of interspersed null events)
    %StepSize = 50 ms;
    Step=50;
    %Interstimulus interval (trial time-.OCI) = 2.5s
    ISI=1.5; %set at 1.5 
    %BlankScreen Interval is 1.0s
    BSI=1 ;  %NB, see figure in GNG4manual (set at 1 for scan)
    %Only Circle Interval is 0.5s
    OCI=0.5;
    arrow_duration=1; %because stim duration is 1.5 secs in opt_stop

    %%% FEEDBACK VARIABLES
    if MRI==1,
        trigger = KbName('t');
        blue = KbName('b');
        yellow = KbName('y');
        green = KbName('g');
        red = KbName('r');
        LEFT=[98 5 10];   %blue (5) green (10)
        RIGHT=[121 28 21]; %yellow (28) red (21)
    else,
        LEFT=[197];  %<
        RIGHT=[198]; %>
    end;
    
    if scannum==1;
        error=zeros(1, NUMCHUNKS/2);
        rt = zeros(1, NUMCHUNKS/2);
        count_rt = zeros(1, NUMCHUNKS/2);
    end;

    %%%% Setting up the sound stuff
    %%%% Psychportaudio
    load soundfile.mat %%% NEED SOMETHING PERSONALIZED TO ME????? I.E. IF WANT THE SOUND HIGHER??
    %wave=y;
    wave=sin(1:0.25:1000);
    %freq=Fy*1.5; % change this to change freq of tone
    freq=22254;
    nrchannels = size(wave,1);    
    % Default to auto-selected default output device:
    deviceid = -1;
    % Request latency mode 2, which used to be the best one in our measurement:
    reqlatencyclass = 2; % class 2 empirically the best, 3 & 4 == 2
    % Initialize driver, request low-latency preinit:
    InitializePsychSound(1);
    % Open audio device for low-latency output:
    pahandle = PsychPortAudio('Open', deviceid, [], reqlatencyclass, freq, nrchannels);
    %Play the sound
    PsychPortAudio('FillBuffer', pahandle, wave);
    PsychPortAudio('Start', pahandle, 1, 0, 0);
    WaitSecs(1);
    PsychPortAudio('Stop', pahandle);
    %%%% Old way
%     Snd('Open');
%     samp = 22254.545454;
%     aud_stim = sin(1:0.25:1000);
%     Snd('Play',aud_stim,samp);


    %%%%%%%%%%%%%% Stimuli and Response on same matrix, pre-determined
    % The first column is trial number;
    % The second column is numchunks number (1-NUMCHUNKS);
    % The third column is 0 = Go, 1 = NoGo; 2 is null, 3 is notrial (kluge, see opt_stop.m)
    % The fourth column is 0=left, 1=right arrow; 2 is null
    % The fifth column is ladder number (1-2);
    % The sixth column is the value currently in "LadderX", corresponding to SSD
    % The seventh column is subject response (no response is 0);
    % The eighth column is ladder movement (-1 for down, +1 for up, 0 for N/A)
    % The ninth column is their reaction time (sec)
    % The tenth column is their actual SSD (for error-check)
    % The 11th column is their actual SSD plus time taken to run the command
    % The 12th column is absolute time since beginning of task that trial begins
    % The 13th column is the time elapsed since the beginning of the block at moment when arrows are shown
    % The 14th column is the actual SSD for error check (time from arrow displayed to beep played)
    % The 15th column is the duration of the trial from trialcode
    % The 16th column is the time_course from trialcode
    

    %this puts trialcode into Seeker 
    % trialcode was generated in opt_stop and is balanced for 4 staircase types every 16 trials, and arrow direction
    %  see opt_stop.m in /gng/optmize/stopping/
    % because of interdigitated null and true trial, there will thus be four staircases per 32 trials in trialcode

    for  tc=1:16,                         %go/nogo        arrow dir       staircase    initial staircase value                    duration       timecourse
        if trialcode(tc,5)>0, 
            Seeker(tc,:) = [tc scannum  trialcode(tc,1) trialcode(tc,4) trialcode(tc,5) Ladder(trialcode(tc,5)) 0 0 0 0 0 0 0 0 trialcode(tc,2) trialcode(tc,3)];
        else,
            Seeker(tc,:) = [tc scannum  trialcode(tc,1) trialcode(tc,4) trialcode(tc,5) 0 0 0 0 0 0 0 0 0 trialcode(tc,2) trialcode(tc,3)];
        end;	 	
    end;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% TRIAL PRESENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% REMEMBER MAKE MRI OR NOT VERSION, WITH WHICH BUTTONS TO PUSH!!!
    if MRI==1,
        Screen('DrawText',w,'Press the left button (index finger) if you see <',100,100);
        Screen('DrawText',w,'Press the right button (middle finger) if you see >',100,130);
    else,
        Screen('DrawText',w,'Press the left button (<) if you see <',100,100);
        Screen('DrawText',w,'Press the right button (>) if you see >',100,130);
    end;
    Screen('DrawText',w,'Press the button as QUICKLY and as ACCURATELY',100,180);
    Screen('DrawText',w,'as you can when you see the arrow.',100,210);
    Screen('DrawText',w,'But if you hear a beep, try very hard to STOP',100,240);
    Screen('DrawText',w,'yourself from pressing the button on that arrow only.',100,270);
    Screen('DrawText',w,'GOING and STOPPING are equally important.',100,300);
    Screen('DrawText',w,'So DO NOT slow down your response to wait for the beep,',100,330);
    Screen('DrawText',w,'because then you are no longer going when you are supposed to.',100,360);
    Screen('DrawText',w,'You won''t always be able to stop when you hear a beep,',100,390);
    Screen('DrawText',w,'but as long as you go quickly all of the time',100,420);
    Screen('DrawText',w,'(while pushing the correct button for arrow direction),',100,450);
    Screen('DrawText',w,'and can stop some of the time, you are doing the task correctly.',100,480);
    Screen('DrawText',w,'Ask the experimenter if you have any questions.',100,530);
    Screen('DrawText',w,'Press any key to go on.',100,560);    
    Screen('Flip',w);

    
    noresp=1;
    while noresp,
    [keyIsDown,secs,keyCode] = KbCheck(inputDevice);
        if keyIsDown & noresp,
            noresp=0;
        end;
    end;
    WaitSecs(0.001);
    WaitSecs(0.5);  % prevent key spillover--ONLY FOR BEHAV VERSION
 
    anchor=GetSecs;
    Pos=1;

    for b=1:16,   %  (8 trials, but but we use 16 because of the null interspersed trials)

        if Seeker(Pos,3)~=2, %% ie this is not a NULL event	
            Screen('TextSize',w,CircleSize);
            Screen('TextFont',w,'Courier');
            Screen('DrawText',w,'o', CirclePosX, CirclePosY);
            Screen('TextSize',w,ArrowSize);
            Screen('TextFont',w,'Arial');

            while GetSecs - anchor < Seeker(Pos,16), 
            end; %waits to synch beginning of trial with 'true' start

            Screen('Flip',w);
            trial_start_time = GetSecs;
            Seeker(Pos,12)=trial_start_time-anchor; %absolute time since beginning of task
            WaitSecs(OCI); 
        end;

        if Seeker(Pos,3)~=2, %% ie this is not a NULL event		
            Screen('TextSize',w,CircleSize);
            Screen('TextFont',w,'Courier');
            Screen('DrawText',w,'o', CirclePosX, CirclePosY);
            Screen('TextSize',w,ArrowSize);
            Screen('TextFont',w,'Arial');
            if (Seeker(Pos,4)==0),
                Screen('DrawText',w,'<', ArrowPosX, ArrowPosY);						
            else,
                Screen('DrawText',w,'>', ArrowPosX+10, ArrowPosY);						
            end;	
            noresp=1;
            notone=1;
            Screen('Flip',w);
            arrow_start_time = GetSecs;


            while (GetSecs-arrow_start_time < arrow_duration & noresp),
                [keyIsDown,secs,keyCode] = KbCheck(inputDevice);
                if MRI==1,
                    if keyIsDown & noresp,
                        tmp=KbName(keyCode);
                        Seeker(Pos,7)=KbName(tmp(1));
                        Seeker(Pos,9)=GetSecs-arrow_start_time;
                        noresp=0;
                    end;
                else,
                    if keyIsDown & noresp,
                        try,
                            tmp=KbName(keyCode);
                            if length(tmp) > 1 & (tmp(1)==',' | tmp(1)=='.'),
                                Seeker(Pos,7)=KbName(tmp(2));
                            else,
                                Seeker(Pos,7)=KbName(tmp(1));
                            end;
                        catch,
                            Seeker(Pos,7)=9999;
                        end;
                        if b==1 & GetSecs-arrow_start_time<0,
                            Seeker(Pos,9)=0;
                            Seeker(Pos,13)=0;
                        else,
                            Seeker(Pos,9)=GetSecs-arrow_start_time; % RT
                        end;
                        noresp=0;
                    end;
                end;
                WaitSecs(0.001);
                if Seeker(Pos,3)==1 & GetSecs - arrow_start_time >=Seeker(Pos,6)/1000 & notone,
                    %% Psychportaudio
                    PsychPortAudio('FillBuffer', pahandle, wave);
                    PsychPortAudio('Start', pahandle, 1, 0, 0);
                    Seeker(Pos,14)=GetSecs-arrow_start_time;
                    notone=0;
                    %WaitSecs(1); % So sound plays for set amount of time; if .05, plays twice, otherwise doen't really make it last longer
                    %PsychPortAudio('Stop', pahandle);
                    % Try loop to end sound after 1 sec, while
                    % still looking for responses-DOESN"T WORK!!!!!
                    while GetSecs<Seeker(Pos,14)+1,
                        %%% check for escape key %%%
                        [keyIsDown,secs,keyCode] = KbCheck(inputDevice);
                        escapekey = KbName('escape');
                        if keyIsDown & noresp,
                            try,
                                tmp=KbName(keyCode);
                                if length(tmp) > 1 & (tmp(1)==',' | tmp(1)=='.'),
                                    Seeker(Pos,7)=KbName(tmp(2));
                                else,
                                    Seeker(Pos,7)=KbName(tmp(1));
                                end;
                            catch,
                                Seeker(Pos,7)=9999;
                            end;
                            if b==1 & GetSecs-arrow_start_time<0,
                                Seeker(Pos,9)=0;
                                Seeker(Pos,13)=0;
                            else,
                                Seeker(Pos,9)=GetSecs-arrow_start_time; % RT
                            end;
                            noresp=0;
                        end;
                    end;
                    %PsychPortAudio('Stop', pahandle);
                    %% Old way to play sound
                    %Snd('Play',aud_stim,samp);
                    %Seeker(Pos,14)=GetSecs-arrow_start_time;                          
                    %notone=0;
                end;
                % To try to get stopping sound outside of sound
                % loop so can collect responses as well; if do
                % this, it doesn't play
%                         if GetSecs-Seeker(Pos,14)>=1,
%                             % Stop playback:
%                             PsychPortAudio('Stop', pahandle);
%                         end;
            end; %end while	
            PsychPortAudio('Stop', pahandle); % If do this,
            % response doesn't end loop
        end; %end non null

        Screen('Flip',w);

        while(GetSecs - anchor < Seeker(Pos,16) + Seeker(Pos,15)), 
        end;



       Pos=Pos+1;

    end; % end of trial loop

%     % after each 8 trials, this code does the updating of staircases	
%     %These three loops update each of the ladders
%     for c=(Pos-16):Pos-1,
%         %This runs from one to two, one for each of the ladders
%         for d=1:2,
%             if (Seeker(c,7)~=0&Seeker(c,5)==d),	%col 7 is sub response
%                 if Ladder(d,1)>=Step,
%                     Ladder(d,1)=Ladder(d,1)-Step;
%                     Ladder(d,2)=-1;
%                 elseif Ladder(d,1)>0 & Ladder(d,1)<Step,
%                     Ladder(d,1)=0;
%                     Ladder(d,2)=-1;
%                 else,
%                     Ladder(d,1)=Ladder(d,1);
%                     Ladder(d,2)=0;
%                 end;
%                 if (d==1),
%                     [x y]=size(Ladder1);
%                     Ladder1(x+1,1)=Ladder(d,1);
%                 else if (d==2),
%                     [x y]=size(Ladder2);
%                     Ladder2(x+1,1)=Ladder(d,1);
%                 end;end;
%             else if (Seeker(c,5)==d & Seeker(c,7)==0),
%                 Ladder(d,1)=Ladder(d,1)+Step;
%                 Ladder(d,2)=1;
%                 if (d==1),
%                     [x y]=size(Ladder1);
%                     Ladder1(x+1,1)=Ladder(d,1);
%                 else if (d==2),
%                     [x y]=size(Ladder2);
%                     Ladder2(x+1,1)=Ladder(d,1);
%                 end;end;
%             end;end;
%         end;
%     end;
%     %Updates the time in each of the subsequent stop trials
%     for c=Pos:16,
%         if (Seeker(c,5)~=0), %i.e. staircase trial
%             Seeker(c,6)=Ladder(Seeker(c,5),1);
%         end;
%     end;
%     %Updates each of the old trials with a +1 or a -1
%     for c=(Pos-16):Pos-1,
%         if (Seeker(c,5)~=0),
%             Seeker(c,8)=Ladder(Seeker(c,5),2);
%         end;
%     end;

    
    % Close the audio device:
    PsychPortAudio('Close', pahandle);
 
 
 %try,   %dummy try if need to troubleshoot

 catch,    % (goes with try, line 61)
 rethrow(lasterror);

 Screen('CloseAll');
 ShowCursor;

 end;

Screen('TextSize',w,36);
Screen('TextFont',w,'Ariel');
Screen('DrawText',w,'Great Job. Thank you!',xcenter-200,ycenter);
Screen('Flip',w);

WaitSecs(1);
Screen('Flip',w);
Screen('CloseAll');
ShowCursor;

