function [VAR,params,Seeker] = StopSignal_OSX(subject_code,sub_session,...
    run_num,order_num,Ladder,InputDevice,TriggerMode,TriggerDevice)
%
% StopSignal_OSX(subject_code,sub_session,run_num,order_num,ladder,InputDevice,TriggerDevice,TriggerWaitSecs,TaskWaitSecs)
%
%   Inputs:
%           subject_code: Subject ID
%           sub_session: type of session to run
%                        (1=Behavioral, 2=fMRI, 3=demo)
%           run_num: run number for behavioral and fMRI session
%           order_num: order of task in behavioral session
%           ladder: SSD to start off with (ms).
%                   For the 2 staircase behvaioral use a 2x1 column vector
%           InputDevice: keyboard input device for response
%           TriggerMode: mode of trigger device. input as a numeric with the
%                 following options:
%                 1). Task triggers scanner via USB;
%                 2). Task triggers scanner via Serial Port;
%                 3). Scanner triggers task via USB;
%                 4). Scanner triggers task via Serial Port.
%                 Only relevent for fMRI mode (sub_session = 2). See also
%                 exampled in the bottom for more details.
%           TriggerDevice: TTL pulse sequence device for trigger or a
%                          serial port directory (string) to write to.
%                          Always pass [] when using fMRI mode to check
%                          device every time running the script, though
%                          this input provides more flexibility when
%                          knowing the triggering device beforehand
%                          (especially serial port devices)


%
% Example usage for each sub_session
%   1). Behavioral
%
%    StopSignal_OSX(subject_code,1,run_num,order_num,ladder)
%
%     # InputDevice and TriggerDevice will be set to -1
%
%   2). fMRI
%      
%   Four modes available depending on the TriggerDevice input:
%
%    1). Task triggers scanner via USB devices: the current task script
%    will send a signal to the scanner after waiting a certain time defined
%    by TriggerWaitSecs; then the task will start after waiting for a
%    certain time defined by TaskWaitSecs (Currently not implemented)
%       
%    StopSignal_OSX(subject_code,2,run_num,[],[],InputDevice,1,TriggerDevice)
%       
%    2). Task triggers scanner via Serial Port. Similar to mode 1, except
%    that TriggerDevice is the full path to serial port
%   
%    3). Scanner triggers task via USB devices: the scanner will send a
%    signal to the task script and the task starts after waiting a certain
%    time defined by TaskWaitSecs
%    
%    StopSignal_OSX(subject_code,2,run_num,[],[],InputDevice,3,TriggerDevice)
%
%    4). Scanner triggers task via Serial Port: similar to mode 3 above,
%    except that the TriggerDevice is the full path to serial port
%
%   3). demo
%
%    StopSignal_OSX(subject_code,3)
%
%     # InputDevice and TriggerDevice will be set to -1
%
%
% Stop Signal Behave and fMRI
% Adam Aron 12-01-2005
% Adapted for OSX Psychtoolbox by Jessica Cohen 12/2005
% Modified for use with new BMC trigger-same device as button box by JC 1/07
% Sound updated and modified for Jess' dissertation by JC 10/08
% Presenting task with pseudorandom order by David (Drew) Fegen 05/2013
% Polymorphism of the script allowing to run three different sessions of
%       the task by Edward D. Cui 09/10/2013
% Added ACC structure with field that records accuracy for GO and NO-GO by
% EDC 09/11/13
% Added capability of the script to automatically seek previous trackfile
% in fMRI mode. (EDC 09/11/13): This means, the user must run the behave
% before the fMRI session
% Used Julian Cheng's code for task presentation (Cue, Probe, ITI,
% behav break period) for better Flip timing accuracy
% EDC 10/04/13: Allowed the script to trigger the scanner
% EDC 02/15/14: Added capability of task/trigger waiting
%
% Notes:
% 1). Originally in Behav, if the subject changed mind about which
%     direction to respond to, the script will get the last/final response
% 2). Arrow direction mistake calculation
%   a). at Go trials
%       AND
%   b). When arrow direction is 0(left), response right
%       OR
%   c). When arrow direction is 1(right), response left

% ###########################################################
%InputDevice=1; % scanner fORP keyboard - change depending on which USB port use???
%TriggerDevice=2; %whatever device index the TTL pulse is, if same as fORP then just put same number
% ###########################################################

% Script/header information
script_name='Stop Signal: optimized SSD tracker';
script_version='1';
revision_date='04-24-14';
DEBUG = false;%whether or not running in debug mode
TrialCodeHeader={'NumChunksNum','TrialDur','TrialCourse','TrialType','ArrowDirection'};
% Arrow Direction: 0 is left ('<'), and 1 is right ('>'), while 2 indicates
%                   null events interspersed, which is ITI
% Beep sound (TrialType): 1 is NoGo (Beep) and 0 is Go, where as 2
%                   indicates null events interspersed, which is ITI
SeekerColHeader = {'TrialNumber','NumChunksNum','Trial',...
    'ArrowDirection','LadderNumber','LadderNum_SSD','SubjectResponse',...
    'LadderMovement','RT','SSD','actualSSD_plusCMDtime',...
    'absoluteTime','TimeStartBlock','DrewsActualSSD','TrialDuration_trialcode',...
    'TrialCourse_trialcode'};%column header of the Seeker matrix
target_response_keyboard_name = 'Current';%use this string to locate response device
target_ttl_keyboard_name = 'ttlpulse_device_product_name';%enter some jibberish so that the script will list all the devices

%some explanations:
% absoluteTime: onset of the cue/empty circle
% TimeStartBlock: onset of the probe/arrow
% DrewactualSSD: beep time after the onset of probe

% Adaptable Constants
% "chunks", will always be size 64:
%NUMCHUNKS=4;  %gngscan has 4 blocks of 64 (2 scans with 2 blocks of 64 each--but says 128 b/c of interspersed null events)
%StepSize = 50 ms;
VAR.Step=50;
%Interstimulus interval (trial time-OCI) = 2.5s
VAR.ISI=1.5; %set at 1.5
%BlankScreen Interval is 1.0s
VAR.BSI=1 ;  %NB, see figure in GNG4manual (set at 1 for scan)
%Only Circle Interval is 0.5s
VAR.OCI=0.5;
VAR.arrow_duration=1; %because stim duration is 1.5 secs in opt_stop
VAR.postbeep_duration = 1;%arrow duration after the beep
VAR.BreakTimeSecs = 60;%in behavioral take this many seconds of break
TextFont='Arial';%font of text and figure
TextSize = 36;%size of text
%stimuli parameters
CircleSize=400;
CircleFont = 'Courier';
ArrowSize=150;
ArrowFont = 'Arial';
grayLevel=120;%bacground color
%response allowed
VAR.LEFT = KbName({'1!','1','6^','6',',<','LeftArrow'});
VAR.RIGHT = KbName({'2@','2','7&','7','.>','RightArrow'});
VAR.AllowedKeys = KbName({'1!','1','2@','2','3#','3','4$','4','5%','5',...
    '6^','6','7&','7','8*','8','9(','9','0)','0',',<','.>','LeftArrow',...
    'RightArrow'});
VAR.TTLTrigger = '[t]';%TTL trigger sent from the scanner to task
VAR.SerialTrigger = '[t]';%serial trigger to scanner
VAR.numBlocks = 2;%number of blocks to divide the trialcode into
VAR.numChunks = 8;%number of chunks of 64 trials per block (after each chunk, staircase will be updated)
VAR.numRunfMRI = 3;%number of fMRI runs expected
VAR.numRunBehav = 1;%number of behavioral run expected
% Setting up Stop Signal beep sound
% sound upon the start of the script (Dennis Thompson)
wave=sin(1:0.25:1000);
freq=22254; %Dennis thinks this is a strange frequency, Dennis would rather use 2250
nrchannels = 2;%number of sound channels
wave=repmat(wave,nrchannels,1);  %want to make it stereo, so 2 channels
sounddeviceid = -1; %this ID of -1 means default to auto-selected output device
reqlatencyclass=2;

% setting variables
VAR.package_dir = mfilename('fullpath');%find dir of current script
VAR.package_dir = fileparts(VAR.package_dir);%find dir of current package
VAR.scripts = fullfile(VAR.package_dir,'scripts');%supporting functions dir
VAR.results = fullfile(VAR.package_dir,'results');%result saving dir
VAR.trialcode = fullfile(VAR.package_dir,'trialcodes');%trialcode dir
VAR.notes={'Design developed by Aron, Newman and Poldrack, based on Aron et al. 2003'};
VAR.behav_run_orders = {[1,2],[2,3],[3,4],[4,1]};%2 staircase orders
addpath(VAR.package_dir,VAR.scripts);
fprintf('%s %s (revised %s)\n',script_name,script_version, revision_date);

TriggerWaitSecs = 0; %only relevant when task triggers scanner;
%                     seconds to wait after the first screen of the
%                     task to trigger the scanner.
TaskWaitSecs = 6; %task wait time after trigger starts (either the
%                  task end or the scanner end). Regular EPI use 6, mux 2
%                  use 16, mux 3 use 24.
VAR.DefaultKeyboardDevice = get_device_osx([],[],[],false);%default keyboard device number.

% read in subject initials
if nargin<1 || isempty(subject_code)%if not enough inputs specified
    subject_code=input('Enter subject ID number: '); 
end
if nargin<2 || isempty(sub_session)
    sub_session=input('Session Number? 1=Behavioral, 2=fMRI, 3=demo : ');
end
%prompt for run number of the behavioral task
if nargin<3 && sub_session ~= 3
    run_num = input('Enter run number (max is 3): ');
    %make sure user only enters allowed run number
    while ~any(run_num==[1 2 3])
        run_num=input('Run number must be 1 through 3 - please re-enter: ');
    end
end

% parsing subject files and recordings
switch sub_session
    case 1 %behavioral
        %for the firstrun, prompt for run order
        if run_num ==1
            if nargin<4
                order_num = input('Which order do you want to use, 1-4? ');
                %make sure user only enters allowed order number
                while ~any(order_num==[1 2 3 4])
                    order_num=input('Order number must be 1 through 4 - please re-enter: ');
                end
            end
            IncorrectResponse=zeros(1,VAR.numRunBehav);
            rt = zeros(1,VAR.numRunBehav);
            %count_rt = zeros(1,VAR.numRunBehav);
        elseif run_num>1%there are previous runs
            %find the previous trackfile with format
            %    %dstopsign_behav%d_order%d_mm-dd-yyyy_HH-MM-SS
            trackfile = dir(fullfile(VAR.results,...
                sprintf('%dstop_behav%d_*.mat',...
                subject_code,run_num-1)));
            %see if the above line can find any files of the format
            if length(trackfile)>1 || isempty(trackfile)
                cellfun(@disp,{trackfile.name});
                trackfile=input('Enter name of prior behavioral file to open: ','s');
                trackfile=fullfile(VAR.results,trackfile);
                trackfile = fullfile(VAR.results,regexprep(trackfile,' ',''));
            else
                trackfile = fullfile(VAR.results,trackfile.name);
            end
            load(trackfile,'Ladder1','Ladder2');
        end
        %inputs of each trial (trialcode)
        inputfile = fullfile(VAR.trialcode,...
            sprintf('behav%d.mat',...
            VAR.behav_run_orders{order_num}(run_num)));
        %ladders of SSD (ms)
        if nargin<5
            Ladder(1,1)=input('Ladder1 start val (e.g. 250): ');
            Ladder(2,1)=input('Ladder2 start val (e.g. 350): ');
        else
            Ladder = Ladder(:);%make sure it is column vector
        end
        Ladder1= Ladder(1);
        Ladder2 = Ladder(2);
        %set default input devices
        InputDevice = VAR.DefaultKeyboardDevice;% default input keyboard
        TriggerDevice = VAR.DefaultKeyboardDevice;%default or no TTL pulse input
        MRI = 0;%not using scanner
        VAR.session_name = 'behav';
        % force manual start of the trials and tasks appear 2 seconds after
        TaskWaitSecs = 2;
        TriggerWaitSecs = -1;
    case 2 %fMRI
        if run_num==1
            %look for files with the format
            %  %dstop_behav%d_order%d_mm-dd-yyyy_HH-MM-SS.mat
            lookup_format = sprintf('%dstop_behav*.mat',subject_code);
            %expected to have 3 runs
            IncorrectResponse=zeros(1,VAR.numRunfMRI);
            rt = zeros(1,VAR.numRunfMRI);
            %count_rt = zeros(1,VAR.numRunfMRI);
        elseif run_num>1
            %look for files with the format
            %  %dstop_fmri%d_mm-dd-yyyy_HH-MM-SS.mat
            lookup_format = sprintf('%dstop_fMRI%d*.mat',subject_code,run_num-1);
        end
        if nargin<6 || isempty(InputDevice)
            InputDevice = get_device_osx(target_response_keyboard_name,[],[],true);%check_device('response');
        end
        if nargin<7 || isempty(TriggerMode)
            % first ask the user which mode of triggering is used
            disp('Which mode of triggering is used?');
            TriggerMode = input([...
                '1). Task triggers scanner via USB;\n',...
                '2). Task triggers scanner via Serial Port;\n',...
                '3). Scanner triggers task via USB;\n',...
                '4). Scanner triggers task via Serial Port.\n']);
        end
        %Get device and trigger behaviors
        if nargin<8 || isempty(TriggerDevice)
            switch TriggerMode
                case {1,3}%via USB
                    TriggerDevice = get_device_osx(target_ttl_keyboard_name,[],'TTL Device: ',true);%check_device('ttl');
                case {2,4}%via Serial
                    TriggerDevice = create_serial_trigger([],VAR.SerialTrigger);
                    disp('created trigger device');
            end
        end
        %Set trigger wait times: only for task triggers scanner
        switch TriggerMode
            case {1,2}%task triggers scanner
                %trigger wait time
%                 if nargin<9
%                     TriggerWaitSecs = input('How many seconds to wait before triggering? ');
%                 elseif isempty(TriggerWaitSecs) || ~isnumeric(TriggerWaitSecs)
%                     TriggerWaitSecs = str2double(TriggerWaitSecs);
%                     TriggerWaitSecs(isnan(TriggerWaitSecs)) = 0;
%                 end
            case {3,4}%scanner triggers task
                TriggerWaitSecs = 0;
        end
        % task wait time
%         if nargin<10
%             TaskWaitSecs = input('How many seconds to wait before starting the task? ');
%         elseif isempty(TaskWaitSecs) || ~isnumeric(TaskWaitSecs)
%             TaskWaitSecs = str2double(TriggerWaitSecs);
%             TaskWaitSecs(isnan(TaskWaitSecs)) = 0;
%         end
        %trialcode
        inputfile = fullfile(VAR.trialcode,sprintf('st1b%d',run_num));
        %load previous trackfile for fMRI session
        trackfile = dir(fullfile(VAR.results,lookup_format));
        if length(trackfile)>1 || isempty(trackfile)
            cellfun(@disp,{trackfile.name});
            trackfile = input('Enter the name of prior behavioral file to open: ','s');
            trackfile = fullfile(VAR.results,regexprep(trackfile,' ',''));
        else
            trackfile = fullfile(VAR.results,trackfile.name);
        end
        load(trackfile,'Ladder1','Ladder2');
        %use the last ladder of previous run as initial ladder of current run
        Ladder = [Ladder1(end);Ladder2(end)];
        MRI = 1;%use scanner
        VAR.session_name = 'fMRI';
    case 3 %demo
        Ladder = [250;350];%start off ladder (ms)
        Ladder1 = Ladder(1);
        Ladder2 = Ladder(2);
        inputfile = fullfile(VAR.trialcode,'demo.mat');
        InputDevice = VAR.DefaultKeyboardDevice;% default input keyboard
        TriggerDevice = VAR.DefaultKeyboardDevice;%default or no TTL pulse input
        MRI = 0;%not using MRI
        run_num = 1;
        VAR.numChunks = 1;%upate the staircase after this number of trials completed
        VAR.numBlocks = 1;%number of blocks to divide the trialcode into
        %expected to have 1 run
        IncorrectResponse=0;
        rt = 0;
        %count_rt = zeros(1,1);
        VAR.session_name = 'demo';
        % % force manual start of the trials and tasks appear 2 seconds after
        TriggerWaitSecs = -1;
        TaskWaitSecs = 2;
end
%load trialcode
load(inputfile);

% write trial-by-trial data to a text logfile
d=clock;
logfile=sprintf('sub%d_%s%d_stopsig.log',subject_code,VAR.session_name,run_num);
fprintf('A log of this session will be saved to %s\n',logfile);
fid=fopen(fullfile(VAR.results,logfile),'a');
if fid<1,
    error('could not open logfile!');
end
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));
cellfun(@(x) fprintf(fid,'%s\t',x),SeekerColHeader,'un',0);
fprintf(fid,'\n');
WaitSecs(1);

% manually test and adjust sound
if sub_session == 2 && run_num == 1 %first fMRI run
    disp('Test beep volume');
    test_sound;
end

%Seed random number generator: to generate stimuli file for each subject
%rand('state',subject_code);%if subject code is a number
% tmp_state = regexp(subject_code,'\d*','match');%if subject_code is a string
% if ~isempty(tmp_state)
%     rand('state',str2double(tmp_state{1}));%use the first number in the subject ID
% end

%Drew: this loop below was used by Poldrack to ID and then connect to
%   devices - i commented them out

try  % goes with catch at end of script
    
    % set up input devices
    %numDevices=PsychHID('NumDevices');
    %devices=PsychHID('Devices');
    
    % set up screens
    fprintf('setting up screen\n');
    Priority(1);%give highest priority to the script
    HideCursor();% hide the distracting mouse cursor
    if DEBUG
        w=Screen('OpenWindow',max(Screen('Screens')),0,[0,0,800,600],32,2);%debug
    else
        w=Screen('OpenWindow', max(Screen('Screens')),0,[],32,2);
    end
    [wWidth, wHeight]=Screen('WindowSize', w);
    
    Screen('FillRect', w, grayLevel);
    Screen('Flip', w);
    
    %black=BlackIndex(w); % Should equal 0.
    %white=WhiteIndex(w); % Should equal 255.
    %set up screen parameters
    Screen('TextSize',w,TextSize);
    Screen('TextFont',w,TextFont);
    Screen('TextColor',w,WhiteIndex(w));
    
    %stimuli position
    xcenter=wWidth/2;
    ycenter=wHeight/2;
    CirclePosX=xcenter-92;
    CirclePosY=ycenter-250;
    ArrowPosX=xcenter-25;
    ArrowPosY=ycenter-125;
    
    % initilize Seeker, recording as a table
    Seeker = zeros(size(trialcode,1),16);
    ACC.GO = -1*ones(size(trialcode,1),1);%accuracy column
    ACC.STOP = -1*ones(size(trialcode,1),1);%accuracy column
    
    % Test beep sound upon opening
    InitializePsychSound(1);
    pahandle = PsychPortAudio('Open', sounddeviceid, [],reqlatencyclass, freq, nrchannels); %open the audio device
    PsychPortAudio('FillBuffer', pahandle, wave);
    PsychPortAudio('Start', pahandle, 1, 0, 0);%test beep
    WaitSecs(1);
    PsychPortAudio('Stop', pahandle);
    
    % Initialize response keyboard
    keysOfInterest = zeros(1,256);
    keysOfInterest(VAR.AllowedKeys)=1;
    KbQueueCreate(InputDevice,keysOfInterest);
    
    %this puts trialcode into Seeker
    % trialcode was generated in opt_stop and is balanced for 4 staircase types every 16 trials, and arrow direction
    %  see opt_stop.m in /gng/optmize/stopping/ (LEGACY, NO LONGER EXISTS, EDC 091113)
    % because of interdigitated null and true trial, there will thus be four staircases per 32 trials in trialcode
    for  tc=1:size(trialcode,1)
        if trialcode(tc,5)>0
            %go/nogo    arrow dir       staircase       initial staircase value                    duration       timecourse
            Seeker(tc,:) = [tc run_num  trialcode(tc,1) trialcode(tc,4) trialcode(tc,5) Ladder(trialcode(tc,5)) 0 0 0 0 0 0 0 0 trialcode(tc,2) trialcode(tc,3)];
        else
            Seeker(tc,:) = [tc run_num trialcode(tc,1) trialcode(tc,4) trialcode(tc,5) 0 0 0 0 0 0 0 0 0 trialcode(tc,2) trialcode(tc,3)];
        end
    end
    
    % Trial Presentation
    if sub_session == 2% for fMRI session, display scan number
        startstring = sprintf('Get ready for scan number %d!',run_num);
    else
        startstring = sprintf('Get ready');
    end
    Screen('DrawText',w,startstring,100,100);
    if MRI%use scanner, skip instruction
        %Screen('DrawText',w,'Waiting for trigger...',xcenter-150,ycenter);
        DrawFormattedText(w,['Go/NoGo task\n\n',...
            'Respond to the arrows as quickly as possible\n\n',...
            'Try not to respond when hearing a beep\n\n',...
            'Get Ready! ...'],...
            'center','center');
        Screen('Flip',w);
    else%in practice, display instruction
        DrawFormattedText(w,[...
            '           Press the left button if you see <\n',...
            '           Press the right button if you see >\n',...
            '           Press the button as Fast as you can \n',...
            '           when you see the arrow.\n',...
            '           But if you hear a beep, try very hard\n',...
            '           to STOP yourself from pressing the button.\n',...
            '           Stopping and Going are equally important.\n',...
            '           \n',...
            '           Press any key to go on.'],'left','center');
        Screen('Flip',w);
    end
    
    % Trigger mode in fMRI
    if isnumeric(TriggerDevice) && TriggerDevice>0
        TF = true;
    elseif ischar(TriggerDevice) && ~isempty(TriggerDevice)
        TF = true;
    else
        TF = false;
    end
    if MRI && TF %if using the scanner
        switch TriggerMode
            case 1%task triggers scanner, USB
                % Not Implemented
                Screen('CloseAll');
                ShowCursor;
                error('task triggers scanner via USB: Not implemented\n');
            case 2%task triggers scanner, serial port
                % User must manually advance to the next screen which sends
                % a trigger after TriggerWaitSecs
                KbWait(VAR.DefaultKeyboardDevice,3);%DefaultKeyBoardTrigger(-1);
                %wait for TriggerWaitSecs
                if TriggerWaitSecs>0,WaitSecs(TriggerWaitSecs);end
                %trigger scan first, then wait for tasks
                timeBlockOnset=serial_trigger_scan();
                fprintf('triggered scan at %.3f\n',GetSecs());
            case 3%scanner triggers task, USB
                timeBlockOnset=KbTriggerWait(VAR.TTLTrigger,TriggerDevice);
                DisableKeysForKbCheck(VAR.TTLTrigger); % So trigger is no longer detected
            case 4%scanner triggers taks, serial port
                % Not Implemented
                Screen('CloseAll');
                ShowCursor;
                error('scanner triggers task via serial port: Not implemented\n');
        end 
    else% manually start the task
        timeBlockOnset=KbWait(VAR.DefaultKeyboardDevice,3);%DefaultKeyBoardTrigger(TriggerDevice);
    end
    %task wait
    if TaskWaitSecs>0
        DrawFormattedText(w,'+','center','center');
        Screen('Flip', w);
        % advance the block onset time to the time after wait
        timeBlockOnset = timeBlockOnset+TaskWaitSecs;
    end
    
    Pos=1;%row index
    KbQueueStart;
    
    for block=1:VAR.numBlocks, %2	  %because of way it's designed, there are two blocks for every scan
        for a=1:VAR.numChunks %8     %  now we have 8 chunks of 8 trials (but we use 16 because of the null interspersed trials)
            for b=1:16%(size(trialcode,1)/numBlocks/numChunks)=16 (but we use 16 because of the null interspersed trials)
                % check if this is a null trial
                if Seeker(Pos,3) == 2
                    %write to file and continue to next trial
                    try
                        fprintf(fid,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\n',...
                            Seeker(Pos,1:16));
                    catch % if sub responds weirdly, trying to print the resp crashes the log file...instead print "ERR"
                        fprintf(fid,'ERROR SAVING THIS TRIAL\n');
                    end
                    Pos = Pos +1;
                    continue;%go to next line
                end
                
                %Cue-------------------------------------------------------
                
                Screen('TextSize',w,CircleSize);
                Screen('TextFont',w,CircleFont);
                DrawFormattedText(w,'o',CirclePosX,CirclePosY);
                
                %block until trial start
                timeCueOnset = Screen('Flip',w, PredictVisualOnsetForTime(w, Seeker(Pos,16) + timeBlockOnset));
                Seeker(Pos,12)=timeCueOnset - timeBlockOnset;
                
                %write cue onset code to port
                %             if FLAG_NO_PORT_WRITE, %do nothing
                %             elseif FLAG_USE_32_BIT, io32(objPortIO,dblAddress,structEventCodes.cue);
                %             else io64(objPortIO,dblAddress,structEventCodes.cue);
                %             end
                
                %Probe-----------------------------------------------------
                
                Screen('TextSize',w,CircleSize);
                Screen('TextFont',w,CircleFont);
                DrawFormattedText(w,'o',CirclePosX,CirclePosY);
                Screen('TextSize',w,ArrowSize);
                Screen('TextFont',w,ArrowFont);
                if Seeker(Pos,4)==0         %left
                    DrawFormattedText(w,'<',ArrowPosX,ArrowPosY);
                else%Seeker(Pos,4)==1       %right
                    DrawFormattedText(w,'>',ArrowPosX+10,ArrowPosY);
                end
                
                %block until arrow start
                [timeProbeOnset] = Screen('Flip',w, PredictVisualOnsetForTime(w, timeCueOnset + VAR.OCI));
                Seeker(Pos,13) = timeProbeOnset - timeBlockOnset;
                
                %             %write probe onset code to port
                %             if FLAG_NO_PORT_WRITE, %do nothing
                %             elseif FLAG_USE_32_BIT, io32(objPortIO,dblAddress,myProbeEventCode);
                %             else io64(objPortIO,dblAddress,myProbeEventCode);
                %             end
                
                %Response--------------------------------------------------
                
                %setup response-phase variables
                boolKeyDown = false;
                boolPerformBeep = Seeker(Pos,3) == 1;
                boolCheckBeepTime = boolPerformBeep;
                if boolPerformBeep
                    timeBeepTarget = timeProbeOnset + Seeker(Pos,6)/1000;
                    timeProbeDeadline = timeBeepTarget + VAR.postbeep_duration;
                else
                    timeProbeDeadline = timeProbeOnset + VAR.arrow_duration;
                end
                
                KbQueueFlush;
                while (~boolKeyDown || boolPerformBeep) && (GetSecs <= timeProbeDeadline)
                    %check if beep should be performed
                    if boolPerformBeep && (GetSecs >= timeBeepTarget)
                        PsychPortAudio('Start', pahandle, 1, 0, 0); %async call
                        Seeker(Pos,14)=GetSecs - timeProbeOnset;%SSD
                        boolPerformBeep = false;
                        
%                     %write beep onset code to port
%                     if FLAG_NO_PORT_WRITE, %do nothing
%                     elseif FLAG_USE_32_BIT, io32(objPortIO,dblAddress,structEventCodes.beep);
%                     else io64(objPortIO,dblAddress,structEventCodes.beep);
%                     end
                    end
                    
                    %don't check keyboard more than once
                    %note: this is mainly for when the beep is yet to be
                    %played but the subject gave the response already
                    if boolKeyDown, continue; end
                    
                    %check keyboard for input
                    %[boolKeyDown,timeKeyDown,arrKeyCode] = KbCheck(InputDevice);
                    [boolKeyDown,firstpress]=KbQueueCheck;
                    if boolKeyDown
                        %get the beep onset from async call
                        %if call 'Stop' here, beep will stop immediately
                        %after key press (Original design seen in
                        % Drew's version)
                        if boolCheckBeepTime
                            PsychPortAudio('Stop',pahandle,1);
                        end
                        timeKeyDown = min(firstpress(firstpress>0));
                        intKeyCode = find(abs(firstpress-timeKeyDown)<1E-6,1);                                                
                        Seeker(Pos,7) = intKeyCode(1); %take only the first key if multiples exist
                        Seeker(Pos,9) = timeKeyDown-timeProbeOnset;
                        if DEBUG, fprintf('[DEBUG] Key: %2s | Time: %.2fms | RT: %.0fms\n', KbName(intKeyCode), (timeKeyDown-timeCueOnset)*1000, (timeKeyDown-timeProbeOnset)*1000), end
                    end
                end%end while loop, end of Probe and Response period
                
                %ITI-------------------------------------------------------
                %start ITI immediately by clearing the screen
                %timeITIOnset = Screen('Flip',w);
                Screen('Flip',w);
                
                %write response code to port
                %             if FLAG_NO_PORT_WRITE, %do nothing
                %             elseif FLAG_USE_32_BIT, io32(objPortIO,dblAddress,myResponseEventCode);
                %             else io64(objPortIO,dblAddress,myResponseEventCode);
                %             end
                
                %get the beep onset from async call
                %if call 'Stop' here, beep will not be terminated by key
                %press but will likely finish (Julian Cheng's version)
                %if boolCheckBeepTime
                %    timeBeepOnset = PsychPortAudio('Stop',pahandle,1);
                %    Seeker(Pos,14) = timeBeepOnset - timeProbeOnset;
                %end
                % print trial info to log file
                try
                    fprintf(fid,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\n',...
                        Seeker(Pos,1:16));
                catch ERR   % if sub responds weirdly, trying to print the resp crashes the log file...instead print "ERR"
                    fprintf(fid,'ERROR SAVING THIS TRIAL\n');
                end
                
                %calculate accuracy
                if Seeker(Pos,3) == 0
                    ACC.GO(Pos,1)=...%IS_GO & IS_LEFT/RIGHT & RESPONSE_IS_LEFT/RIGHT
                        (Seeker(Pos,4)==0 & ismember(Seeker(Pos,7),VAR.LEFT)) | ...
                        (Seeker(Pos,4)==1 & ismember(Seeker(Pos,7),VAR.RIGHT));
                else
                    %IS_STOP & RT==0
                    ACC.STOP(Pos,1) = (Seeker(Pos,9)==0);
                end
                Pos=Pos+1;%advance to next row of trialcode
                
            end % end of trial loop
            if sub_session ==3
                break;%if demo, skip the rest
            end
            
            % after each 8 trials, this code does the updating of staircases
            %These three loops update each of the ladders
            for c=(Pos-16):Pos-1
                %This runs from one to two, one for each of the ladders
                for d=1:2
                    if (Seeker(c,7)~=0 && Seeker(c,5)==d),	%col 7 is sub response
                        if Ladder(d,1)>=VAR.Step,
                            Ladder(d,1)=Ladder(d,1)-VAR.Step;
                            Ladder(d,2)=-1;
                        elseif Ladder(d,1)>0 && Ladder(d,1)<VAR.Step,
                            Ladder(d,1)=0;
                            Ladder(d,2)=-1;
                        else
                            Ladder(d,1)=Ladder(d,1);
                            Ladder(d,2)=0;
                        end
                        if (d==1),
                            x=size(Ladder1,1);
                            Ladder1(x+1,1)=Ladder(d,1);
                        else if (d==2)
                                x=size(Ladder2,1);
                                Ladder2(x+1,1)=Ladder(d,1);
                            end
                        end
                    else if (Seeker(c,5)==d && Seeker(c,7)==0),
                            Ladder(d,1)=Ladder(d,1)+VAR.Step;
                            Ladder(d,2)=1;
                            if (d==1),
                                x=size(Ladder1,1);
                                Ladder1(x+1,1)=Ladder(d,1);
                            else if (d==2),
                                    x=size(Ladder2,1);
                                    Ladder2(x+1,1)=Ladder(d,1);
                                end
                            end
                        end
                    end
                end
            end
            %Updates the time in each of the subsequent stop trials
            for c=Pos:size(trialcode,1)
                if (Seeker(c,5)~=0), %i.e. staircase trial
                    Seeker(c,6)=Ladder(Seeker(c,5),1);
                end
            end
            %Updates each of the old trials with a +1 or a -1
            for c=(Pos-16):Pos-1
                if (Seeker(c,5)~=0),
                    Seeker(c,8)=Ladder(Seeker(c,5),2);
                end
            end
        end %end of miniblock
        
        %Report any mistakes made during the Go trials
        %Report the RT of all correct Go trials
        IncorrectResponse(run_num)=nansum(ACC.GO(1:Pos-1,1)>-1)-nansum(ACC.GO(1:Pos-1,1)>0);
        rt(run_num) = nanmean(Seeker(find(ACC.GO(1:Pos-1)>0),9))*1000;
        % In behavrioal mode, take a break in between the two blocks
        if (block == 1) && (sub_session == 1)
            %wait the last ITI of the end of the first block
            timeBreakStart = WaitSecs('UntilTime', timeBlockOnset + Seeker(Pos-1, 16) + Seeker(Pos-1, 15));
            
            Screen('TextFont',w,TextFont);
            Screen('TextSize',w,TextSize);
            
            arrDisplayText = [ ...
                sprintf('Mistakes with arrow direction on Go trials: %d', IncorrectResponse(run_num)),'\n\n' ...
                sprintf('Correct-response average RT on Go trials: %.1f ms', rt(run_num)),'\n\n\n' ...
                ];
            
            DrawFormattedText(w,[arrDisplayText,'\t\tTake a short break!'],100,140);
            Screen('Flip',w);
            
            WaitSecs(VAR.BreakTimeSecs);
            
            DrawFormattedText(w,[arrDisplayText,'\t\tPress any key to continue'],100,140);
            Screen('Flip',w);
            
            KbQueueFlush;
            while true
                if KbQueueCheck, break;end
                WaitSecs(0.001);
            end
            WaitSecs(0.5);
            
            %add the break duration to the block onset time
            %note: this is done because all trial times in the imported
            %trialcode use the first trial as reference without taking into
            %account of the break between blocks in behave mode
            timeBlockOnset = timeBlockOnset + GetSecs - timeBreakStart;
        elseif block == 2 && sub_session ~= 3%at the end of 2nd block of all sessions except demo
            WaitSecs('UntilTime', timeBlockOnset + Seeker(Pos-1, 16) + Seeker(Pos-1, 15));
        end
    end %end block loop
    
    KbQueueStop;
    
catch ERR    % (goes with try)
    try
        outfile=sprintf('%dstop_%s%d_%s.mat',subject_code,VAR.session_name,...
            run_num,datestr(now,'mm-dd-yyyy_HH-MM-SS'));
        outfile = fullfile(VAR.results,outfile);
        switch sub_session
            case 1%behav
                save(outfile,'Seeker','SeekerColHead','TrialCodeHeader',...
                    'params','Ladder1',...
                    'Ladder2','IncorrectResponse','rt','count_rt',...
                    'subject_code','run_num','order_num','VAR','ACC');
            case 2%fMRI
                save(outfile, 'Seeker', 'SeekerColHeader','TrialCodeHeader',...
                    'params', 'Ladder1','Ladder2', 'IncorrectResponse', 'rt', ...
                    'count_rt','subject_code', 'run_num','VAR','ACC',...
                    'TriggerWaitSecs','TaskWaitSecs','TriggerMode');
            case 3%demo
                save(outfile,'Seeker','SeekerColHeader','TrialCodeHeader',...
                    'params','Ladder1','Ladder2','subject_code','VAR');
        end
    end
    
    Screen('CloseAll');
    ShowCursor;
    KbQueueStop;KbQueueFlush;KbQueueRelease;
    rethrow(ERR);
end

%%%%%%%%%%%%%%% FEEDBACK at the End %%%%%%%%%%%%%%%%
Screen('TextSize',w,TextSize);
Screen('TextFont',w,TextFont);
%in behave and fMRI, report the final incorrect response and RT
if sub_session ~=3
    for rr = 1:run_num
        Screen('DrawText',w,sprintf('Scanning Block %d',1),100,100);
        Screen('DrawText',w,sprintf('Mistakes with arrow direction on Go trials: %d\n\n', IncorrectResponse(run_num)),100,140+(rr-1)*140);
        Screen('DrawText',w,sprintf('Correct average RT on Go trials: %.1f (ms)\n\n', rt(run_num)),100,180+(rr-1)*140);
    end
    Screen('Flip',w);
    WaitSecs(10);   %Drew
else
    WaitSecs(1);%in demo mode
end
% Save Data
outfile=sprintf('%dstop_%s%d_%s.mat',subject_code,VAR.session_name,...
    run_num,datestr(now,'mm-dd-yyyy_HH-MM-SS'));
outfile = fullfile(VAR.results,outfile);
%Snd('Close');

%store some record information
params = {...
    'NumBlobkcs',VAR.numBlocks;...
    'NumChunks',VAR.numChunks;...
    'NumTrialsPerChunk',size(trialcode,1)/VAR.numBlocks/VAR.numChunks;...
    'RT',rt(run_num);...
    'IncorrectResponse',IncorrectResponse(run_num);...
    'NumErrors',IncorrectResponse(run_num);...
    'Ladder1 start',Ladder1(1,1);...
    'Ladder2 start',Ladder2(1,1);...
    'Step',VAR.Step;...
    'ISI',VAR.ISI;...
    'BSI',VAR.BSI;...
    'OCI',VAR.OCI};

%%% It's better to access these variables via parameters, rather than
%%% saving them...

try
    %save different things for different session
    switch sub_session
        case 1%behav
            save(outfile,'Seeker','SeekerColHeader','TrialCodeHeader',...
                'params','Ladder1','Ladder2','IncorrectResponse','rt',...
                'subject_code','run_num','order_num','VAR','ACC');
        case 2%fMRI
            save(outfile,'Seeker','SeekerColHeader','TrialCodeHeader',...
                'params','Ladder1','Ladder2','IncorrectResponse','rt',...
                'subject_code', 'run_num','VAR','ACC','TriggerWaitSecs',...
                'TaskWaitSecs','TriggerMode');
        case 3%demo
            save(outfile,'Seeker','SeekerColHeader','TrialCodeHeader',...
                'params','Ladder1','Ladder2','subject_code','VAR');
    end
    
catch ERR
    fprintf('couldn''t save %s\n saving to stopsig_fmri.mat\n',outfile);
    save(fullfile(VAR.results,['stopsig_fmri',datestr(now,'mm-dd-yyyy_HH-MM-SS'),'.mat']));
    KbQueueFlush;KbQueueRelease;
    rethrow(ERR);
end

Screen('TextSize',w,TextSize);
Screen('TextFont',w,TextFont);
Screen('DrawText',w,'Great Job. Thank you!',xcenter-200,ycenter);
Screen('Flip',w);

WaitSecs(1);
DisableKeysForKbCheck([]);%remove any disabled keys
KbQueueFlush;KbQueueRelease;
Screen('CloseAll');%close the screen
ShowCursor();%show mouse cursor
clear GLOBAL TRIGGER MARKER;

% Do a quick behav analyis if it is Behave sessions
if sub_session == 1
    quick_behav_analysis(outfile, 16);
end
rmpath(VAR.package_dir);rmpath(VAR.scripts);

end

