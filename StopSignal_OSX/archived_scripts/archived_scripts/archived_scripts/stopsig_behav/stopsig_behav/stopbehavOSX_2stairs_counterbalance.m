
%%% Adam Aron 12-01-2005
%%% Adapted for OSX Psychtoolbox by Jessica Cohen 12/2005
%%% This version allows you to choose order of two input files, is for use with a keyboard, and also
%%% fixes timing so trials are 2500 ms as they should be
%%%2/11/08 use new sound functions so more accurate


clear all;
% output version
script_name='Stopbehav: optimized SSD tracker';
script_version='3';
revision_date='2-11-08';

notes={'Design developed by Aron, Newman and Poldrack, based on Aron et al. 2003'};

% read in subject initials
fprintf('%s %s (revised %s)\n',script_name,script_version, revision_date);
subject_code=input('Enter subject number: ');
run_num = input('Enter run number (max is 4): ');
while isempty(find(run_num==[1 2 3 4])),
  run_num=input('Run number must be 1 through 4 - please re-enter: ');
end;
if run_num==1,
    order_num = input('Which order do you want to use, 1-4? ');
    while isempty(find(order_num==[1 2 3 4])),
    order_num=input('Order number must be 1 through 4 - please re-enter: ');
    end;
    LADDER1IN=input('Ladder1 start val (e.g. 250): ');
    LADDER2IN=input('Ladder2 start val (e.g. 350): ');
end;

% write trial-by-trial data to a text logfile
d=clock;
logfile=sprintf('sub%dstopsig_behav.log',subject_code);
fprintf('A log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,
    error('could not open logfile!');
end;

fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));
WaitSecs(1);

%Seed random number generator
rand('state',subject_code);

if run_num==1,  %only sets this stuff up once
	%Ladder Starts (in ms):
	Ladder1=LADDER1IN;
	Ladder(1,1)=Ladder1;
	Ladder2=LADDER2IN;
	Ladder(2,1)=Ladder2;
    
    if order_num==1,
        inputfile='behav1.mat';
    elseif order_num==2,
        inputfile='behav2.mat';
    elseif order_num==3,
        inputfile='behav3.mat';
    elseif order_num==4,
        inputfile='behav4.mat';
    end;
end; %end of run_num==1 setup
	

%% this code looks up the last value in each staircase
if run_num>1,
    run_num_temp=run_num; %because first file has run_num saved as 1, overwrite that for inputted scan number
    trackfile=input('Enter name of prior behavioral file to open: ','s');
    load(trackfile);
    clear Seeker; %gets rid of this so it won't interfere with current Seeker
    run_num=run_num_temp; %to save actual run_num instead of run 1s number

    %startval=17; 
	startval=length(Ladder1);
    Ladder(1,1)=Ladder1(startval);
	Ladder(2,1)=Ladder2(startval);
    
    if order_num==1,
        order_num=2;
        inputfile='behav2.mat';
    elseif order_num==2,
        order_num=3;
        inputfile='behav3.mat';
    elseif order_num==3,
        order_num=4;
        inputfile='behav4.mat';
    elseif order_num==4,
        order_num=1;
        inputfile='behav1.mat';
    end;
end;

load(inputfile); %variable is trialcode

try,  % goes with catch at end of script

    %% set up input devices
    numDevices=PsychHID('NumDevices');
    devices=PsychHID('Devices');
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
    Screen('TextSize',w,36);
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
    min_break_time=20; %minimum time computer waits during break

    %%% FEEDBACK VARIABLES
    LEFT=[197];  % <
    RIGHT=[198]; % >
    
    error=zeros(1, NUMCHUNKS/2);
    rt = zeros(1, NUMCHUNKS/2);
    count_rt = zeros(1, NUMCHUNKS/2);


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
    % The 12th column is absolute time since beginning of task
    % The 13th column is the time elapsed since the beginning of the block at moment when arrows are shown
    % The 14th column is the actual SSD for error check (time from arrow displayed to beep played)
    % The 15th column is the duration of the trial from trialcode
    % The 16th column is the time_course from trialcode
    

    %this puts trialcode into Seeker 
    % trialcode was generated in opt_stop and is balanced for 4 staircase types every 16 trials, and arrow direction
    %  see opt_stop.m in /gng/optmize/stopping/
    % because of interdigitated null and true trial, there will thus be four staircases per 32 trials in trialcode

    for  tc=1:256,                         %go/nogo        arrow dir       staircase    initial staircase value                    duration       timecourse
        if trialcode(tc,5)>0, 
            Seeker(tc,:) = [tc 1  trialcode(tc,1) trialcode(tc,4) trialcode(tc,5) Ladder(trialcode(tc,5)) 0 0 0 0 0 0 0 0 trialcode(tc,2) trialcode(tc,3)];
        else,
            Seeker(tc,:) = [tc 1 trialcode(tc,1) trialcode(tc,4) trialcode(tc,5) 0 0 0 0 0 0 0 0 0 trialcode(tc,2) trialcode(tc,3)];
        end;	 	
    end;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% TRIAL PRESENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    Screen('DrawText',w,'Press the left button (<) if you see <',100,175);
    Screen('DrawText',w,'Press the right button (>) if you see >',100,225);
    Screen('DrawText',w,'Press the button as FAST as you can',100,300);
    Screen('DrawText',w,'when you see the arrow.',100,350);
    Screen('DrawText',w,'But if you hear a beep, try very hard',100,425);
    Screen('DrawText',w,'to STOP yourself from pressing the button.',100,475);
    Screen('DrawText',w,'Stopping and Going are equally important.',100,550);
    Screen('DrawText',w,'Press any key to go on.',100,625);    
    Screen('Flip',w);


    % to start task
    noresp=1;
    while noresp,
        [keyIsDown,secs,keyCode] = KbCheck(inputDevice);
        if keyIsDown & noresp,
            noresp=0;
        end;
        WaitSecs(0.001);
    end;
    WaitSecs(0.5);
    anchor=GetSecs;	    

    Pos=1;

    for block=1:2, %2	  %because of way it's designed, there are two blocks for every scan

        for a=1:8, %8     %  now we have 8 chunks of 8 trials (but we use 16 because of the null interspersed trials)
            for b=1:16,   %  (but we use 16 because of the null interspersed trials)

                if Seeker(Pos,3)~=2, %% ie this is not a NULL event	
                    Screen('TextSize',w,CircleSize);
                    Screen('TextFont',w,'Courier');
                    Screen('DrawText',w,'o', CirclePosX, CirclePosY);
                    Screen('TextSize',w,ArrowSize);
                    Screen('TextFont',w,'Arial');
                    Screen('Flip',w);
                    trial_start_time = GetSecs;
                    Seeker(Pos,12)=trial_start_time-anchor; %absolute time since beginning of block
                    WaitSecs(0.5); 
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
                    Screen('Flip',w);
                    arrow_start_time = GetSecs;
                    
                    noresp=1;
                    notone=1;
                    
                    while (GetSecs-arrow_start_time < arrow_duration & noresp),
                        [keyIsDown,secs,keyCode] = KbCheck(inputDevice);
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
                
                if Seeker(Pos,3)~=2, %% ie this is not a NULL event	
                    WaitSecs(1); %ITI
                end;		
               
                % print trial info to logfile
                tmpTime=GetSecs;
                try,
                    fprintf(fid,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\n',...
                       Seeker(Pos,1:16));
                catch,   % if sub responds weirdly, trying to print the resp crashes the log file...instead print "ERR"
                    fprintf(fid,'ERROR SAVING THIS TRIAL\n');
                end;
 
               Pos=Pos+1;
            
            end; % end of trial loop

            % after each 8 trials, this code does the updating of staircases	
            %These three loops update each of the ladders
            for c=(Pos-16):Pos-1,
                %This runs from one to two, one for each of the ladders
                for d=1:2,
                    if (Seeker(c,7)~=0&Seeker(c,5)==d),	%col 7 is sub response
                        if Ladder(d,1)>=Step,
                            Ladder(d,1)=Ladder(d,1)-Step;
                            Ladder(d,2)=-1;
                        elseif Ladder(d,1)>0 & Ladder(d,1)<Step,
                            Ladder(d,1)=0;
                            Ladder(d,2)=-1;
                        else,
                            Ladder(d,1)=Ladder(d,1);
                            Ladder(d,2)=0;
                        end;
                        if (d==1),
                            [x y]=size(Ladder1);
                            Ladder1(x+1,1)=Ladder(d,1);
                        else if (d==2),
                            [x y]=size(Ladder2);
                            Ladder2(x+1,1)=Ladder(d,1);
                        end;end;
                    else if (Seeker(c,5)==d & Seeker(c,7)==0),
                        Ladder(d,1)=Ladder(d,1)+Step;
                        Ladder(d,2)=1;
                        if (d==1),
                            [x y]=size(Ladder1);
                            Ladder1(x+1,1)=Ladder(d,1);
                        else if (d==2),
                            [x y]=size(Ladder2);
                            Ladder2(x+1,1)=Ladder(d,1);
                        end;end;
                    end;end;
                end;
            end;
            %Updates the time in each of the subsequent stop trials
            for c=Pos:256,
                if (Seeker(c,5)~=0), %i.e. staircase trial
                    Seeker(c,6)=Ladder(Seeker(c,5),1);
                end;
            end;
            %Updates each of the old trials with a +1 or a -1
            for c=(Pos-16):Pos-1,
                if (Seeker(c,5)~=0),
                    Seeker(c,8)=Ladder(Seeker(c,5),2);
                end;
            end;

      end; %end of miniblock
      
      %make the subject take a break halfway through testing
      if block==1,
          %%%%%%%%%%%%%%%CALCULATING FEEDBACK %%%%%%%%%%%%%%%%
          for t=1:128,
                % go trial   &  left arrow          respond right   OR  right arrow       respond left
                if (Seeker(t,3)==0 & ((Seeker(t,4)==0 & sum(Seeker(t,7)==RIGHT)==1)|(Seeker(t,4)==1 & sum(Seeker(t,7)==LEFT)==1))), 
                  error(1)=error(1)+1;  % for incorrect responses
                end;
                    % go trial   &   RT (so respond)  &      left arrow          respond left    OR  right arrow       respond right
                if (Seeker(t,3)==0 & Seeker(t,9)>0 & ((Seeker(t,4)==0 & sum(Seeker(t,7)==LEFT)==1)|(Seeker(t,4)==1 & sum(Seeker(t,7)==RIGHT)==1))),
                  rt(1)=rt(1)+Seeker(t,9);   % cumulative RT
                  count_rt(1)=count_rt(1)+1; %number trials
                end;
          end;
          Screen('TextFont',w,theFont);
          Screen('TextSize',w,36);
          Screen('DrawText',w,sprintf('Mistakes with arrow direction on Go trials: %d', error(1)),100,140);
          Screen('DrawText',w,sprintf('Correct average RT on Go trials: %.1f (ms)', rt(1)/count_rt(1)*1000),100,180);
          Screen('TextSize',w,48);
          Screen('DrawText',w,'Take a short break!',xcenter-150,ycenter);
          Screen('Flip',w);
          WaitSecs(min_break_time);
          Screen('TextSize',w,36);
          Screen('DrawText',w,sprintf('Mistakes with arrow direction on Go trials: %d', error(1)),100,140);
          Screen('DrawText',w,sprintf('Correct average RT on Go trials: %.1f (ms)', rt(1)/count_rt(1)*1000),100,180);
          Screen('TextSize',w,48);
          Screen('DrawText',w,'Take a short break!',xcenter-150,ycenter);
          Screen('DrawText',w,'Press any key to continue.',xcenter-215,ycenter+100);
          Screen('Flip',w);
          noresp=1;
          while noresp,
            [keyIsDown,secs,keyCode] = KbCheck(inputDevice);
            if keyIsDown & noresp,
                noresp=0;
            end;
            WaitSecs(0.001);
          end;
          WaitSecs(0.5);
      end;
      
    end; %end block loop
    
    % Close the audio device:
    PsychPortAudio('Close', pahandle);
 
% try,   %dummy try if need to troubleshoot

 catch,    % (goes with try, line 61)
    rethrow(lasterror);   %command returns to keyboard

    Screen('CloseAll');
    ShowCursor;
 end;

 
%%%%%%%%%%%%%%% FEEDBACK %%%%%%%%%%%%%%%%
for t=129:256 
           % go trial   &  left arrow                 respond right   OR  right arrow       respond left
   if (Seeker(t,3)==0 & ((Seeker(t,4)==0 & sum(Seeker(t,7)==RIGHT)==1)|(Seeker(t,4)==1 & sum(Seeker(t,7)==LEFT)==1))), 
       error(2)=error(2)+1;  % for incorrect responses
   end;
           % go trial   &   RT (so respond)  & left arrow            respond left    OR  right arrow       respond right
   if (Seeker(t,3)==0 & Seeker(t,9)>0 & ((Seeker(t,4)==0 & sum(Seeker(t,7)==LEFT)==1)|(Seeker(t,4)==1 & sum(Seeker(t,7)==RIGHT)==1))),
       rt(2)=rt(2)+Seeker(t,9);   % cumulative RT
       count_rt(2)=count_rt(2)+1; %number trials 
   end;
end;
   
Screen('TextSize',w,36);
Screen('TextFont',w,'Ariel');

Screen('DrawText',w,sprintf('Part One: '),100,140);
Screen('DrawText',w,sprintf('Mistakes with arrow direction on Go trials: %d', error(1)),100,180);
Screen('DrawText',w,sprintf('Correct average RT on Go trials: %.1f (ms)', rt(1)/count_rt(1)*1000),100,220);
Screen('DrawText',w,sprintf('Part Two: '),100,300);
Screen('DrawText',w,sprintf('Mistakes with arrow direction on Go trials: %d', error(2)),100,340);
Screen('DrawText',w,sprintf('Correct average RT on Go trials: %.1f (ms)', rt(2)/count_rt(2)*1000),100,380);
Screen('DrawText',w,'Press any button to continue',100,420);

Screen('Flip',w);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
d=clock;
outfile=sprintf('%dstop_behav%d_order%d_%s_%02.0f-%02.0f.mat',subject_code,run_num,order_num,date,d(4),d(5));

Snd('Close');

params = cell (7,2);
params{1,1}='NUMCHUNKS';   
params{1,2}=NUMCHUNKS;
params{2,1}='Ladder1 start';   
params{2,2}=Ladder1(1,1);
params{3,1}='Ladder2 start';   
params{3,2}=Ladder2(1,1);
params{4,1}='Step';   
params{4,2}=Step;
params{5,1}='ISI';   
params{5,2}=ISI;
params{6,1}='BSI';   
params{6,2}=BSI;
params{7,1}='OCI';   
params{7,2}=OCI;

%%% It's better to access these variables via parameters, rather than
%%% saving them...
try,
    save(outfile, 'Seeker', 'params', 'Ladder1', 'Ladder2', 'error', 'rt', 'count_rt','run_num','order_num');
catch,
	fprintf('couldn''t save %s\n saving to stopsig_behav.mat\n',outfile);
	save stopsig;
end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
noresp=1;
while noresp,
    [keyIsDown,secs,keyCode] = KbCheck(inputDevice);
    if keyIsDown & noresp,
        noresp=0;
    end;
    WaitSecs(0.001);
end;
WaitSecs(0.5);


Screen('TextSize',w,36);
Screen('TextFont',w,'Ariel');
Screen('DrawText',w,'Great Job. Thank you!',xcenter-200,ycenter);
Screen('Flip',w);

noresp=1;
while noresp,
    [keyIsDown,secs,keyCode] = KbCheck(inputDevice);
    if keyIsDown & noresp,
        noresp=0;
    end;
    WaitSecs(0.001);
end;
WaitSecs(0.5);
    
Screen('Flip',w);
Screen('CloseAll');
ShowCursor;

