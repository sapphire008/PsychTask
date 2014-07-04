function taskStopSignal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% Stopfmri %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Adam Aron 12-01-2005
%%% Adapted for OSX Psychtoolbox by Jessica Cohen 12/2005
%%% Modified for use with new BMC trigger-same device as button box by JC 1/07
%%% Sound updated and modified for Jess' dissertation by JC 10/08
%
% Changelog:
%   7/17/2013:  Start edits by Julian Y. Cheng.
%   7/18/2013:  Fixed stimulus positioning. Added algorithm to dynamically
%               calculate the y position based on font size.
%               Fixed button recognition.
%   7/19/2013:  Changed stimulus color from pure white to white smoke.
%               Fixed text display.
%   7/23/2013:  Optimized ladder update loop for unnecessary conditional
%               statements.
%               Change to use Screen('Flip') timestamps instead of
%               GetSecs() to avoid extra overhead.
%               Added adjustable variables to top of script.
%               Changed the output behavior. Files are now written to files
%               with simplier names that can be parsed. Also, the next run
%               number is automatically guessed.
%               Changed to function instead of script to allow for JIT
%               optimization.
%               Changed to allow Screen('Flip') to block until stimulus
%               onset for better timing precision.
%   7/26/2013:  Added alternative algorithm to KbTriggerWait().
%   7/30/2013:  Added support for ASL eye-tracking. Automatically detects
%               is system is 32bit or 64bit and uses the correct libraries.
%   8/1/2013:   Optimized the main trial loop. All times now use the
%               VBLTimestamp returned by screen flip as much as possible.
%               Also, changed the beep algorithm to avoid 2 loops, and made
%               the call asyncronous to prevent excess pause between
%               keyboard pollings. Additionally, numerous changes were made
%               to simplify the condition forks, and the waiting loops have
%               been removed in favor of blocking calls to screen flip.
%   8/2/2013:   Merged behave script, now both tasks can be run using the
%               same script.
%               Added adjustment to breaktime, which subtracts the time
%               spent waiting from the cue onsets to avoid rapid-fire of
%               trials after beginning of second block. (behave-only)
%   8/8/2013:   Added automatic cleanup. Will always close relevant handles
%               as well as the screen.
%               Added left-handed response to response-mapping.
%   8/12/2013:  Change to use built in text mirror of DrawFormatterText
%               instead of specifying reversed text and using backwards
%               font.
%               Added option to adjust volume of the audio output. Note
%               that values greater than 1 will amplify the volume but will
%               also cause distortion, clipping...etc
%               Added option to show instructions in fMRI mode.
%   8/21/2013:  Changed event code scheme to remove hard-coded event codes.

SCRIPT_VER = '0.4beta';

%user settings-------------------------------------------------------------
intLadder1 = 250;       %default value, can be overwridden with user input
intLadder2 = 350;       %default value, can be overwridden with user input
intInputDevice = -1;    %the device number as reported by PsychHID for input
                        %note: use -1 for all keyboards
                        %      use -2 for all keyboards and keypads
intTTLDevice = -1;      %the device number as reported by PsychHID for TTL pulse
                        %note: use -1 for all keyboards
                        %      use -2 for all keyboards and keypads
dblAudioVolume = 5;     %the volume to pass to PsychPortAudio
                        %note: a value of 1 is 100% volume of the original
                        %source; any value greater than 1 will amplify the
                        %volume but will also cause distortion
strPort = '1030';       %the hexadecimal parallel port number

%debugging options
DEBUG = false;
    %if set to true, will print debug messages reporting the durations
    %of each trial phase
DEBUG_DISABLE_PARALLEL_PORT = true;
    %if set to true, will avoid all code calling the parallel port
    %functions
DEBUG_DISABLE_MIRROR = true;
    %if set to true, will disable text-mirroring when run in fMRI mode

%design parameters---------------------------------------------------------
dirCode = '.\Code\';                %location for helper functions
dirSettings = '.\Settings\';        %location for settings files
dirBehave = '.\Behave data\';       %location for subject input files (behave)
dirFmri = '.\fMRI data\';           %location for subject output files
strStudy = 'pilot';                 %will be appended before the subject number
strBehavePostfix = '_StopBehave';   %will be appended to each file for subject
strFmriPostfix = '_StopFmri';       %will be appended to each file for subject
arrBackground = 120;                %the background color to use (can be single int as well)
arrTextColor = [245,245,245];       %the color of the displayed text (can be single int as well)
                                    %note: instead of using pure white, use white smoke to avoid blinding the subject
arrPolynomial = [-0.7 370];         %the function used to estimate the y-position based on the font size
                                    %note: x = font size, y = estimated y-position
                                    %      use [-0.7 370] if resolution is 1024x768
                                    %      use [-0.7 520] if resolution is 1920x1080
arrLeftResponse = [ ...             %response mapping for left response
    KbName(',<') ...
    KbName('left') ...
    KbName('1!') ...
    KbName('1') ...
    KbName('3#') ...
    KbName('3') ...
    ];
arrRightResponse = [ ...            %response mapping for right response
    KbName('.>') ...
    KbName('right') ...
    KbName('2@') ...
    KbName('2') ...
    KbName('4$') ...
    KbName('4') ...
    ];
arrTrigger = [ ...                  %the trigger signal
    KbName('t') ...
    KbName('5') ...
    KbName('5%') ...
    ];
arrBeepSignal = sin(1:.25:1000);    %the beep signal to play
strTextFont = 'Arial';              %the font of all displayed text
strCircleFont = 'Courier New';      %the font of the circle
strArrowFont = 'Arial';             %the font of the arrow
intTextSize = 25;                   %the size of all displayed text
                                    %note: use 25 if resolution is 1024x768
                                    %      use 40 if resolution is 1920x1080
intCircleSize = 200;                %the size of the circle
                                    %note: use 200 if resolution is 1024x768
                                    %      use 400 if resolution is 1920x1080
intArrowSize = 80;                 %the size of the arrow
                                    %note: use 80 if resolution is 1024x768
                                    %      use 150 if resolution is 1920x1080
intArrowDuration = 1;               %in seconds
                                    %note: stim duration in opt_stop is 1.5
                                    %seconds, so this should be 1 seconds
intPostBeepDuration = 1;            %the arrow duration after a beep in seconds
                                    %note: the arrow duration on beep trials
                                    %will be = beep onset time since arrow 
                                    %          onset + post beep duration
intMinBreakTime = 10;               %minimum number of seconds to wait in the
                                	%rest period of block 1 in seconds
                                    %note: ignored in fMRI mode
                                
%task-design related (legacy)
%note: unchanged from original code from Jong's team
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

%event codes (for pupillometry)
structEventCodes.block_wait = -1;           %for pre/post block fixation; due to bit-wise representation -1 becomes 255 in recording
structEventCodes.block_onset = 0;           %will be replaced with scan number
structEventCodes.cue = 10;                  %circle
structEventCodes.probe.left = 21;           %left arrow
structEventCodes.probe.right = 22;          %right arrow
structEventCodes.beep = 30;
structEventCodes.response.correct = 41;
structEventCodes.response.incorrect = 42;
structEventCodes.response.no_response = 43;
structEventCodes.response.debug = 91;       %failed to parse response

%**************************************************************************
% Algorithm
%**************************************************************************

addpath(dirCode);

%get subject number
subject_code = input('Enter subject number: ');

%get session number
intSessionType = input('Enter session type (1 = Behave, 2 = fMRI): ');

%Setup data imports--------------------------------------------------------
if intSessionType == 1                                        %BEHAVE setup
    IS_MRI = false;
    boolUseMirroredText = false;
    
    %check if previous run exists
    lstInfiles = fnGetFileList(dirBehave);
    strFilename = [strStudy,num2str(subject_code,'%03i'),strBehavePostfix,'-\d.mat'];
    if any(~cellfun('isempty',regexpi(lstInfiles,strFilename)))
        %some behave has been done, so parse the last run number

        %find all runs for this subject
        lstRuns = regexpi(lstInfiles,['(?<=',strStudy,num2str(subject_code,'%03i'),strBehavePostfix,'-)\d(?=.mat)'],'match');
        lstRuns(cellfun('isempty',lstRuns)) = [];   %cleanup empty entries

        %find last run number
        arrRuns = cellfun(@(x) str2double(cell2mat(x)),lstRuns);
        intLastRun = max(arrRuns);

        if (intLastRun >= 4)
            fprintf('Found existing behave data: last file is run %i\n',intLastRun)
            fprintf('Warning: cannot run more than 4 runs\n')
            run_num = input('Enter run number (max is 4): ');

            while ~any(run_num == [1,2,3,4])
                run_num = input('Run number invalid, re-enter: ');
            end
        else
            fprintf('\nFound existing behave data: last file is run %i\n\n',intLastRun)
            strUserInput = input(sprintf('Continue with run %i (Y/N): ',intLastRun+1),'s');
            if strcmpi(strUserInput,'y')
                run_num = intLastRun +1;
            else
                run_num = input('Enter run number (max is 4): ');

                while ~any(run_num == [1,2,3,4])
                    run_num = input('Run number invalid, re-enter: ');
                end
            end
        end

        clear lstInfiles strFilename lstRuns arrRuns intLastRun strUserInput
    else
        strUserInput = input('Is this the first run (Y/N): ','s');

        if strcmpi(strUserInput,'y')
            run_num = 1;
        else
            run_num = input('Enter run number (max is 4): ');

            while ~any(run_num == [1,2,3,4])
                run_num = input('Run number invalid, re-enter: ');
            end
        end
        clear strUserInput
    end

    %check if file already exists
    strFilename = [strStudy,num2str(subject_code,'%03i'),strBehavePostfix,'-',num2str(run_num),'.mat'];
    if exist(fullfile(dirBehave,strFilename),'file')
        strUserInput = input('Warning: file already exists, do you want to overwrite (Y/N): ','s');

        if ~strcmpi(strUserInput,'y')
            fprintf('Aborted: behave data already exists for this run\n')
            return
        end
    end

    if run_num==1,
        order_num = input('Enter order to use (1-4): ');
        while isempty(find(order_num==[1 2 3 4], 1)),
            order_num=input('Order number invalid, re-enter: ');
        end;

        strUserInput = input('Use default ladder values (Y/N): ','s');
        if strcmpi(strUserInput,'y')
            LADDER1IN = intLadder1;
            LADDER2IN = intLadder2;
        else
            LADDER1IN=input('Enter Ladder1 start value (default 250): ');
            LADDER2IN=input('Enter Ladder2 start value (default 350): ');
        end
    end
    
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
        end
    end %end of run_num==1 setup

    %lookup the last value in the staircase
    if run_num>1,
        run_num_temp=run_num; %because first file has run_num saved as 1, overwrite that for inputted scan number

        %check if file exists
        strFilename = [strStudy,num2str(subject_code,'%03i'),strBehavePostfix,'-',num2str(run_num-1),'.mat'];
        if exist(fullfile(dirBehave,strFilename),'file')
            trackfile = strFilename;
        else
            trackfile=input('Enter name of prior behavioral file to open: ','s');

            while ~exist(fullfile(dirBehave,trackfile),'file')
                trackfile=input('Infile invalid, re-enter: ','s');
            end
        end

        load(fullfile(dirBehave,trackfile));
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

    load(fullfile(dirSettings,inputfile)); %variable is trialcode
    
    % write trial-by-trial data to a text logfile
    logfile = [strStudy,num2str(subject_code,'%03i'),strBehavePostfix,'-',num2str(run_num),'.log'];
    fprintf('A log of this session will be saved to %s\n',logfile);
    fid=fopen(fullfile(dirBehave,logfile),'a');
    if fid<1,
        fprintf('Error: could not open logfile\n');
        return;
    end
else                                                            %FMRI setup
    IS_MRI = true;
    boolUseMirroredText = true && ~DEBUG_DISABLE_MIRROR;
    
    %get scan number
    scannum_temp=input('Enter scan number: ');
    scannum=scannum_temp;
    structEventCodes.block_onset = scannum;

    %check if file already exists
    strFilename = [strStudy,num2str(subject_code,'%03i'),strFmriPostfix,'-',num2str(scannum),'.mat'];
    if exist(fullfile(dirFmri,strFilename),'file')
        strUserInput = input('Warning: file already exists, do you want to overwrite (Y/N): ','s');

        if ~strcmpi(strUserInput,'y')
            fprintf('Aborted: fmri data already exists for this run\n')
            return
        end
    end
    clear strFilename

    %ladder initialization
    if scannum==1 % this code looks up the last value in each staircase
        %check for behave input file
        lstInfiles = fnGetFileList(dirBehave);
        strInfileRegex = [strStudy,num2str(subject_code,'%03i'),strBehavePostfix,'-\d.mat'];
        lstInfiles(cellfun('isempty',regexpi(lstInfiles,strInfileRegex))) = []; %keep only behave mat files
        if isempty(lstInfiles)  %no files matching naming convention
            fprintf('\nWarning: failed to find behave mat files\n')
            strFilename = input('Enter the behave filename: ','s');
            if ~exist(fullfile(dirBehave,strFilename), 'file')
                fprintf('Error: failed to find file %s in path: %s\n', strFilename, dirBehave)
                return
            else
                trackfile = strFilename;
            end
        else
            %find all runs for this subject
            strFilePrefix = regexprep(lstInfiles{1},'-\d\.mat','-');
            lstRuns = regexpi(lstInfiles,['(?<=',strStudy,num2str(subject_code,'%03i'),strBehavePostfix,'-)\d'],'match');
            lstRuns(cellfun('isempty',lstRuns)) = [];   %cleanup empty entries

            %find last run number
            arrRuns = cellfun(@(x) str2double(cell2mat(x)),lstRuns);
            intLastRun = max(arrRuns);

            %ask if last run should be used
            strUserInput = input(['Use found last behave run ',num2str(intLastRun),' (Y/N): '],'s');
            if strcmpi(strUserInput,'y')
                trackfile = [strFilePrefix,num2str(intLastRun),'.mat'];
            else
                intRun = input('Enter run number to use: ');
                strFilename = [strFilePrefix,num2str(intRun),'.mat'];
                if exist(fullfile(dirBehave,strFilename),'file')
                    trackfile = strFilename;
                else
                    fprintf('\nWarning: failed to find behave mat file\n')
                    strFilename = input('Enter the behave filename: ','s');
                    if ~exist(fullfile(dirBehave,strFilename), 'file')
                        fprintf('Error: failed to find file %s in path: %s\n', strFilename, dirBehave)
                        return
                    else
                        trackfile = strFilename;
                    end
                end
            end
        end
        clear lstInfiles strInfileRegex strFilename strFilePrefix lstRuns arrRuns intLastRun strUserInput intRun

        load(fullfile(dirBehave,trackfile));
        clear Seeker; %gets rid of this so it won't interfere with current Seeker
        startval=length(Ladder1); 
        Ladder(1,1)=Ladder1(startval);
        Ladder(2,1)=Ladder2(startval);
    else % this code looks up the last value in each staircase
        %check if previous scan exists
        lstInfiles = fnGetFileList(dirFmri);
        strInfileRegex = [strStudy,num2str(subject_code,'%03i'),strFmriPostfix,'-',num2str(scannum - 1),'.mat'];
        lstInfiles(cellfun('isempty',regexpi(lstInfiles,strInfileRegex))) = []; %keep only behave mat files
        if isempty(lstInfiles)
            fprintf('\nWarning: failed to find previous scan results\n')
            strFilename = input('Enter the scan filename: ','s');
            if ~exist(fullfile(dirFmri,strFilename), 'file')
                fprintf('Error: failed to find file %s in path: %s\n', strFilename, dirFmri)
                return
            else
                trackfile = strFilename;
            end
        else
            strFilename = cell2mat(lstInfiles); %there should be only 1 file due to the strict regexp match string
            strUserInput = input(['Use previous scan file ',strFilename,' (Y/N): '],'s');
            if strcmpi(strUserInput,'y')
                trackfile = strFilename;
            else
                strFilename = input('Enter the scan filename: ','s');
                if ~exist(fullfile(dirFmri,strFilename), 'file')
                    fprintf('Error: failed to find file %s in path: %s\n', strFilename, dirFmri)
                    return
                else
                    trackfile = strFilename;
                end
            end
        end
        clear lstInfiles strInfileRegex strFilename strUserInput

        load(fullfile(dirFmri,trackfile));
        clear Seeker; %gets rid of this so it won't interfere with current Seeker
        scannum=scannum_temp; %because first file has scannum saved as 1, overwrite that for inputted scan number
        startval=length(Ladder1); 
        Ladder(1,1)=Ladder1(startval);
        Ladder(2,1)=Ladder2(startval);
    end

    %load relevant input file for scan (there MUST be st1b1.mat & st1b2.mat)
    inputfile=sprintf('st%ib%i.mat',1,scannum);
    load(fullfile(dirSettings,inputfile)); %variable is trialcode
    
    % write trial-by-trial data to a text logfile
    logfile = [strStudy,num2str(subject_code,'%03i'),strFmriPostfix,'-',num2str(scannum),'.log'];
    fprintf('A log of this session will be saved to %s\n',logfile);
    fid=fopen(fullfile(dirFmri,logfile),'a');
    if fid<1,
        fprintf('Error: could not open logfile!\n');
        return
    end
end

%check whether to show instructions
intUserInput = input('Show instructions (1 = yes, 0 = no): ');
if intUserInput == 0
    boolShowInstructions = false;
else
    boolShowInstructions = true;
end
clear intUserInput

d=clock;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));
WaitSecs(1);

%Seed random number generator
rng(subject_code);

%set high priority
Priority(1);

%setup input devices---------------------------------------------------

inputDevice=intInputDevice; % scanner fORP keyboard - change depending on which USB port use???
inputDeviceTTL=intTTLDevice; %whatever device index the TTL pulse is, if same as fORP then just put same number

%setup screens---------------------------------------------------------

fprintf('setting up screen\n');
Screen('Preference', 'VisualDebugLevel', 1);    %make initial screen black
screens=Screen('Screens');
screenNumber=max(screens);
w=Screen('OpenWindow', screenNumber,0,[],32,2);
Screen('WindowSize', w);
Screen('FillRect', w, arrBackground);
Screen('Flip', w);

Screen('TextSize',w,intTextSize);
Screen('TextFont',w,strTextFont);
Screen('TextColor',w,arrTextColor);

CirclePosY = polyval(arrPolynomial,intCircleSize);
ArrowPosY = polyval(arrPolynomial,intArrowSize);

HideCursor;

%setup parallel port---------------------------------------------------

if ~IS_MRI || DEBUG_DISABLE_PARALLEL_PORT
    FLAG_NO_PORT_WRITE = true;
    warning('Parallel port is disabled\n')
elseif ~exist('io32') && ~exist('io64')
    DrawFormattedText(w,'parallel port library not found','center','center');
    Screen('Flip',w);
    FLAG_NO_PORT_WRITE = true;
    WaitSecs(2);
else
    FLAG_NO_PORT_WRITE = false;

    if strfind(computer,'64')   %64bit machine
        objPortIO = io64;
        status = io64(objPortIO);
        FLAG_USE_32_BIT = false;
    else    %32bit machine
        objPortIO = io32;
        status = io32(objPortIO);
        FLAG_USE_32_BIT = true;
    end

    %check if port open was successful
    if (status ~= 0)
        DrawFormattedText(w,'eye-tracker initialization failed','center','center');
        Screen('Flip',w);
        WaitSecs(2);
    end

    dblAddress = hex2dec(strPort);
end

%write pre-task code to port
if FLAG_NO_PORT_WRITE, %do nothing
elseif FLAG_USE_32_BIT, io32(objPortIO,dblAddress,structEventCodes.block_wait); 
else io64(objPortIO,dblAddress,structEventCodes.block_wait); 
end

%setup sound-----------------------------------------------------------

wave=arrBeepSignal;
wave=[wave;wave];           %want to make it stereo, so 2 channels
freq=Snd('DefaultRate');	%always use default sample rate returned by system
nrchannels = 2;             %always use 2 channels for compatability (some computers choke on single-channel)
deviceid = -1;              %this ID of -1 means default to auto-selected output device
InitializePsychSound(1);
reqlatencyclass=2;
pahandle = PsychPortAudio('Open', deviceid, [],reqlatencyclass, freq, nrchannels); %open the audio device
PsychPortAudio('FillBuffer', pahandle, wave);
PsychPortAudio('Start', pahandle, 1, 0, 0);

%adjust volume
PsychPortAudio('Volume', pahandle, dblAudioVolume);

%----------------------------------------------------------------------

%setup cleanup
cleanupObj = onCleanup(@() myCleanup(pahandle, fid));

%%% FEEDBACK VARIABLES
trigger = arrTrigger;
LEFT = arrLeftResponse;
RIGHT = arrRightResponse;

if ~IS_MRI || (scannum == 1)
    error = zeros(1, NUMCHUNKS/2);
    rt = zeros(1, NUMCHUNKS/2);
    count_rt = zeros(1, NUMCHUNKS/2);
end

%%%%%%%%%%%%%% Stimuli and Response on same matrix, pre-determined
% 1st column:  trial number                                                     [NOT USED]
% 2nd column:  numchunks number (1-NUMCHUNKS)                                   [NOT USED]
% 3rd column:  0 = Go, 1 = NoGo, 2 is null, 3 is notrial                        [IMPORTED]
%              (kluge, see opt_stop.m)
% 4th column:  0=left, 1=right arrow; 2 is null                                 [IMPORTED]
% 5th column:  ladder number (1-2)                                              [IMPORTED]
% 6th column:  the value currently in "LadderX", corresponding to SSD           [IMPORTED][MODIFIED BY ALGORITHM]
% 7th column:  subject response (no response is 0)                              [MODIFIED BY ALGORITHM]
% 8th column:  ladder movement (-1 for down, +1 for up, 0 for N/A)              [MODIFIED BY ALGORITHM]
% 9th column:  reaction time (sec)                                              [MODIFIED BY ALGORITHM]
% 10th column: actual SSD (for error-check)                                     [MODIFIED BY ALGORITHM]
% 11th column: actual SSD plus time taken to run the command                    [NOT USED]
% 12th column: absolute time since beginning of task that trial begins          [MODIFIED BY ALGORITHM]
% 13th column: absoulte time from arrow onset to beginning of task              [MODIFIED BY ALGORITHM]
% 14th column: the actual SSD for error check (time from arrow onset to beep)	[MODIFIED BY ALGORITHM]
% 15th column: the duration of the trial from trialcode                         [IMPORTED]
% 16th column: the time_course from trialcode                                   [IMPORTED]

%this puts trialcode into Seeker 
% trialcode was generated in opt_stop and is balanced for 4 staircase types every 16 trials, and arrow direction
%  see opt_stop.m in /gng/optmize/stopping/
% because of interdigitated null and true trial, there will thus be four staircases per 32 trials in trialcode

if IS_MRI
    intNumChunks = scannum;
else
    intNumChunks = 1;
end
for  tc=1:256                             %go/nogo        arrow dir       staircase    initial staircase value                    duration       timecourse
    if trialcode(tc,5)>0
        Seeker(tc,:) = [tc intNumChunks trialcode(tc,1) trialcode(tc,4) trialcode(tc,5) Ladder(trialcode(tc,5)) 0 0 0 0 0 0 0 0 trialcode(tc,2) trialcode(tc,3)];
    else
        Seeker(tc,:) = [tc intNumChunks trialcode(tc,1) trialcode(tc,4) trialcode(tc,5) 0 0 0 0 0 0 0 0 0 trialcode(tc,2) trialcode(tc,3)];
    end	
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% TRIAL PRESENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if boolShowInstructions
    arrDisplayText = [ ...
        'Press the left button if you see <\n\n' ...
        'Press the right button if you see >\n\n\n' ...
        'When you see the arrow,\n\n' ...
        'press the button as FAST as you can.\n\n\n' ...
        'But if you hear a beep,\n\n' ...
        'try very hard to STOP yourself from pressing the button.\n\n' ...
        'Stopping and Going are equally important.\n\n\n' ...
        'Press any key to continue.' ...
        ];
    
    DrawFormattedText(w,arrDisplayText,'center','center',[],[], boolUseMirroredText);
    Screen('Flip',w);
    
    while true
        [boolKeyPress,~,~] = KbCheck(intInputDevice);

        if boolKeyPress, break; end

        WaitSecs(0.001);
    end
end

if IS_MRI
    arrDisplayText = [ ...
        sprintf('Beginning scan number %i',scannum),'\n\n\n' ...
        'Get Ready!' ...
        ];
else
    arrDisplayText = [ ...
        sprintf('Beginning behave number %i',run_num),'\n\n\n' ...
        'Get Ready!' ...
        ];
    WaitSecs(0.5);
end
DrawFormattedText(w,arrDisplayText,'center','center',[],[], boolUseMirroredText);
Screen('Flip',w);

if IS_MRI
    if (inputDeviceTTL < 0)
        %this won't work with KbTriggerWait(), so use alternative
        while true
            [~,timeKeyDown,arrKeys] = KbCheck(inputDeviceTTL);
            intKey = find(arrKeys);

            if (length(intKey) == 1) && any(intKey == trigger)
                timeBlockOnset = timeKeyDown;
                break
            end
        end
        KbQueueStop();
    else
        timeBlockOnset = KbTriggerWait(trigger,inputDeviceTTL);
    end
else % If using the keyboard, allow any key as input
    boolCheckResponse=1;
    while boolCheckResponse
        [boolKeyDown,timeKeyDown,~] = KbCheck(inputDevice);
        if boolKeyDown && boolCheckResponse
            boolCheckResponse = 0;
            timeBlockOnset = timeKeyDown;
        end
    end
    WaitSecs(0.5);
end

DisableKeysForKbCheck(trigger); % So trigger is no longer detected

Pos=1;

%write block onset code to port
if FLAG_NO_PORT_WRITE, %do nothing
elseif FLAG_USE_32_BIT, io32(objPortIO,dblAddress,structEventCodes.block_onset); 
else io64(objPortIO,dblAddress,structEventCodes.block_onset); 
end

for block=1:2, %2	  %because of way it's designed, there are two blocks for every scan
    for a=1:8, %8     %  now we have 8 chunks of 8 trials (but we use 16 because of the null interspersed trials)
        for b=1:16,   %  (but we use 16 because of the null interspersed trials)
            %check if this is a null trial
            if Seeker(Pos,3) == 2
                %write to file and continue to next trial
                try
                    fprintf(fid,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\n',...
                       Seeker(Pos,1:16));
                catch   % if sub responds weirdly, trying to print the resp crashes the log file...instead print "ERR"
                    fprintf(fid,'ERROR SAVING THIS TRIAL\n');
                end

                fprintf('[Block %i][Trial %i-%2i] NULL\n', block, a, b);

                Pos = Pos +1;

                continue
            end

            %Cue-------------------------------------------------------

            Screen('TextSize',w,intCircleSize);
            Screen('TextFont',w,strCircleFont);
            DrawFormattedText(w,'O','center',CirclePosY);

            %block until trial start
            [timeCueOnset] = Screen('Flip',w, PredictVisualOnsetForTime(w, Seeker(Pos,16) + timeBlockOnset));
            Seeker(Pos,12)=timeCueOnset - timeBlockOnset;

            %write cue onset code to port
            if FLAG_NO_PORT_WRITE, %do nothing
            elseif FLAG_USE_32_BIT, io32(objPortIO,dblAddress,structEventCodes.cue); 
            else io64(objPortIO,dblAddress,structEventCodes.cue); 
            end

            %Probe-----------------------------------------------------

            Screen('TextSize',w,intCircleSize);
            Screen('TextFont',w,strCircleFont);
            DrawFormattedText(w,'O','center',CirclePosY);
            Screen('TextSize',w,intArrowSize);
            Screen('TextFont',w,strArrowFont);
            if Seeker(Pos,4)==0         %left
                DrawFormattedText(w,'<','center',ArrowPosY,[],[],boolUseMirroredText);	
                myProbeEventCode = structEventCodes.probe.left;
            else                            %right
                DrawFormattedText(w,'>','center',ArrowPosY,[],[],boolUseMirroredText);	
                myProbeEventCode = structEventCodes.probe.right;	
            end

            %block until arrow start
            [timeProbeOnset] = Screen('Flip',w, PredictVisualOnsetForTime(w, timeCueOnset + OCI));
            Seeker(Pos,13) = timeProbeOnset - timeBlockOnset;

            %write probe onset code to port
            if FLAG_NO_PORT_WRITE, %do nothing
            elseif FLAG_USE_32_BIT, io32(objPortIO,dblAddress,myProbeEventCode); 
            else io64(objPortIO,dblAddress,myProbeEventCode); 
            end

            %Response--------------------------------------------------

            %setup response-phase variables
            boolCheckResponse = true;
            boolPerformBeep = Seeker(Pos,3) == 1;
            boolCheckBeepTime = boolPerformBeep;
            if boolPerformBeep
                timeBeepTarget = timeProbeOnset + Seeker(Pos,6)/1000;
                timeProbeDeadline = timeBeepTarget + intPostBeepDuration;
            else
                timeProbeDeadline = timeProbeOnset + intArrowDuration;
            end

            while (boolCheckResponse || boolPerformBeep) && (GetSecs <= timeProbeDeadline)
                %check if beep should be performed
                if boolPerformBeep && (GetSecs >= timeBeepTarget) 
                    PsychPortAudio('Start', pahandle, 1, 0, 0); %async call
                    boolPerformBeep = false;

                    %write beep onset code to port
                    if FLAG_NO_PORT_WRITE, %do nothing
                    elseif FLAG_USE_32_BIT, io32(objPortIO,dblAddress,structEventCodes.beep); 
                    else io64(objPortIO,dblAddress,structEventCodes.beep); 
                    end
                end

                %don't check keyboard more than once
                %note: this is mainly for when the beep is yet to be
                %played but the subject gave the response already
                if ~boolCheckResponse, continue; end

                %check keyboard for input
                [boolKeyDown,timeKeyDown,arrKeyCode] = KbCheck(inputDevice);
                if boolKeyDown
                    intKeyCode = find(arrKeyCode);
                    Seeker(Pos,7) = intKeyCode(1); %take only the first key if multiples exist
                    Seeker(Pos,9) = timeKeyDown-timeProbeOnset;
                    boolCheckResponse = false;

                    if DEBUG, fprintf('[DEBUG] Key: %2s | Time: %.2fms | RT: %.0fms\n', KbName(intKeyCode), (timeKeyDown-timeCueOnset)*1000, (timeKeyDown-timeProbeOnset)*1000), end
                end
            end

            %ITI-------------------------------------------------------

            timeITIOnset = Screen('Flip',w);

            %parse trial information
            if Seeker(Pos,3) == 1, strBeep = 'Yes'; else strBeep = 'No'; end
            if Seeker(Pos,4) == 0, strArrow = 'Left'; else strArrow = 'Right'; end
            if Seeker(Pos,7) == 0
                strKey = '';
                myResponseEventCode = structEventCodes.response.no_response;
            elseif Seeker(Pos,7) == 9999 
                strKey = 'EXCEPTION1'; 
                myResponseEventCode = structEventCodes.response.debug;
            else
                if Seeker(Pos,4) == 0  %left probe
                    if any(Seeker(Pos,7) == LEFT)  %correct
                        strKey = 'Correct'; 
                        myResponseEventCode = structEventCodes.response.correct;
                    elseif any(Seeker(Pos,7) == RIGHT) %incorrect
                        strKey = 'Incorrect'; 
                        myResponseEventCode = structEventCodes.response.incorrect;
                    else    %exception
                        strKey = 'EXCEPTION2'; 
                        myResponseEventCode = structEventCodes.response.debug;
                        Seeker(Pos,7) = 0;
                    end
                else %right probe
                    if any(Seeker(Pos,7) == LEFT)  %incorrect
                        strKey = 'Incorrect'; 
                        myResponseEventCode = structEventCodes.response.incorrect;
                    elseif any(Seeker(Pos,7) == RIGHT) %correct
                        strKey = 'Correct'; 
                        myResponseEventCode = structEventCodes.response.correct;
                    else    %exception
                        strKey = 'EXCEPTION2'; 
                        myResponseEventCode = structEventCodes.response.debug;
                        Seeker(Pos,7) = 0;
                    end
                end
            end

            %write response code to port
            if FLAG_NO_PORT_WRITE, %do nothing
            elseif FLAG_USE_32_BIT, io32(objPortIO,dblAddress,myResponseEventCode); 
            else io64(objPortIO,dblAddress,myResponseEventCode); 
            end

            %get the beep onset from async call
            if boolCheckBeepTime
                timeBeepOnset = PsychPortAudio('Stop',pahandle,1);
                Seeker(Pos,14) = timeBeepOnset - timeProbeOnset;
            end

            %calculate statistics
            if Seeker(Pos,3) == 0   %only process go trials
                if IS_MRI
                    index = scannum;
                else
                    index = block;
                end
                if length(rt) < index, rt(index) = 0; end   %safety check to ensure variable has enough elements
                if length(count_rt) < index, count_rt(index) = 0; end
                if length(error) < index, error(index) = 0; end
                if strcmpi(strKey,'correct')
                    rt(index) = rt(index) + Seeker(Pos,9);  %cumulative RT
                    count_rt(index) = count_rt(index) +1;
                elseif strcmpi(strKey,'incorrect')
                    error(index) = error(index) +1;
                end
            end

            % print trial info to log file
            try
                fprintf(fid,'%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\n',...
                   Seeker(Pos,1:16));
            catch   % if sub responds weirdly, trying to print the resp crashes the log file...instead print "ERR"
                fprintf(fid,'ERROR SAVING THIS TRIAL\n');
            end

            fprintf('[Block %i][Trial %i-%2i] Beep: %3s | Arrow: %5s | Response: %9s | RT: %.0fms\n', block, a, b, strBeep, strArrow, strKey, Seeker(Pos,9) * 1000);

            if DEBUG,
                if ~exist('timeBeepOnset','var'), timeBeepOnset = NaN;
                elseif timeBeepOnset < timeCueOnset, timeBeepOnset = NaN; end
                fprintf('[DEBUG] Cue duration: %.2fms | Probe duration: %.2fms | Beep onset: %.2fms\n', (timeProbeOnset-timeCueOnset)*1000, (timeITIOnset-timeProbeOnset)*1000, (timeBeepOnset-timeCueOnset)*1000)
            end

            Pos=Pos+1;

        end % end of trial loop

        % after each 8 trials, this code does the updating of staircases	
        %These three loops update each of the ladders
        for c=(Pos-16):Pos-1
            %This runs from one to two, one for each of the ladders
            for d=1:2
                if Seeker(c,5) ~= d
                    continue
                elseif (Seeker(c,7)~=0)	%col 7 is sub response
                    if Ladder(d,1)>=Step,
                        Ladder(d,1)=Ladder(d,1)-Step;
                        Ladder(d,2)=-1;
                    elseif Ladder(d,1)>0
                        Ladder(d,1)=0;
                        Ladder(d,2)=-1;
                    else
                        Ladder(d,2)=0;
                    end
                    if (d==1)
                        Ladder1(end+1,1)=Ladder(d,1);
                    else %(d==2)
                        Ladder2(end+1,1)=Ladder(d,1);
                    end
                else %response == 0
                    Ladder(d,1)=Ladder(d,1)+Step;
                    Ladder(d,2)=1;
                    if (d==1)
                        Ladder1(end+1,1)=Ladder(d,1);
                    else %(d==2)
                        Ladder2(end+1,1)=Ladder(d,1);
                    end
                end
            end
        end
        %Updates the time in each of the subsequent stop trials
        for c=Pos:256
            if (Seeker(c,5)~=0) %i.e. staircase trial
                Seeker(c,6)=Ladder(Seeker(c,5),1);
            end;
        end;
        %Updates each of the old trials with a +1 or a -1
        for c=(Pos-16):Pos-1
            if (Seeker(c,5)~=0)
                Seeker(c,8)=Ladder(Seeker(c,5),2);
            end
        end
    end %end of miniblock

    %take a break in behave mode
    if ~IS_MRI && (block == 1)
        %wait the last ITI
        timeBreakStart = WaitSecs('UntilTime', timeBlockOnset + Seeker(Pos-1, 16) + Seeker(Pos-1, 15));

        Screen('TextFont',w,strTextFont);
        Screen('TextSize',w,intTextSize);

        arrDisplayText = [ ...
            sprintf('Mistakes with arrow direction on Go trials: %d', error(1)),'\n\n' ...
            sprintf('Correct-response average RT on Go trials: %.1f ms', rt(1)/count_rt(1)*1000),'\n\n\n' ...
            ];

        DrawFormattedText(w,[arrDisplayText,'Take a short break!'],'center','center');
        Screen('Flip',w);

        WaitSecs(intMinBreakTime);

        DrawFormattedText(w,[arrDisplayText,'Press any key to continue'],'center','center');
        Screen('Flip',w);

        boolCheckResponse=1;
        while boolCheckResponse
            [boolKeyDown,~,~] = KbCheck(inputDevice);
            if boolKeyDown && boolCheckResponse
                boolCheckResponse=0;
            end
        end
        WaitSecs(0.5)

        %add the break duration to the block onset time
        %note: this is done because all trial times in the imported
        %trialcode use the first trial as reference without taking into
        %account of the break between blocks in behave mode
        timeBlockOnset = timeBlockOnset + GetSecs - timeBreakStart;
    end
end %end block loop

%wait the last ITI
if IS_MRI || (block == 2)
    WaitSecs('UntilTime', timeBlockOnset + Seeker(Pos-1, 16) + Seeker(Pos-1, 15));
end

%write block offset code to port
if FLAG_NO_PORT_WRITE, %do nothing
elseif FLAG_USE_32_BIT, io32(objPortIO,dblAddress,structEventCodes.block_wait); 
else io64(objPortIO,dblAddress,structEventCodes.block_wait); 
end

%%%%%%%%%%%%%%% FEEDBACK %%%%%%%%%%%%%%%%
   
Screen('TextSize',w,intTextSize);
Screen('TextFont',w,strTextFont);

if IS_MRI
    arrDisplayText = [];
    for i = 1:scannum
        arrDisplayText = [arrDisplayText, 'Block ',num2str(i),'\n\n'];
        arrDisplayText = [arrDisplayText, sprintf('Mistakes with arrow direction on Go trials: %d', error(i)),'\n\n'];
        arrDisplayText = [arrDisplayText, sprintf('Correct-response average RT on Go trials: %.1f ms', rt(i)/count_rt(i)*1000)];
        if i ~= scannum
            arrDisplayText = [arrDisplayText,'\n\n\n'];
        end
    end
elseif ~IS_MRI
    arrDisplayText = [ ...
        'Part One:','\n\n' ...
        sprintf('Mistakes with arrow direction on Go trials: %d', error(1)),'\n\n' ...
        sprintf('Correct-response average RT on Go trials: %.1f ms', rt(1)/count_rt(1)*1000),'\n\n\n' ...
        'Part Two:','\n\n' ...
        sprintf('Mistakes with arrow direction on Go trials: %d', error(2)),'\n\n' ...
        sprintf('Correct-response average RT on Go trials: %.1f ms', rt(2)/count_rt(2)*1000),'\n\n\n' ...
        'Press any button to continue' ...
        ];
end

DrawFormattedText(w,arrDisplayText,'center','center',[],[], boolUseMirroredText);
Screen('Flip',w);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

params = cell(7,2);
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
try
    if IS_MRI
        outfile = [strStudy,num2str(subject_code,'%03i'),strFmriPostfix,'-',num2str(scannum),'.mat'];
        save(fullfile(dirFmri,outfile), 'SCRIPT_VER', 'Seeker', 'params', 'Ladder1', 'Ladder2', 'error', 'rt', 'count_rt', 'subject_code', 'scannum');
    else
        outfile = [strStudy,num2str(subject_code,'%03i'),strBehavePostfix,'-',num2str(run_num),'.mat'];
        save(fullfile(dirBehave,outfile), 'SCRIPT_VER', 'Seeker', 'params', 'Ladder1', 'Ladder2', 'error', 'rt', 'count_rt', 'subject_code','run_num','order_num');
    end
catch
	fprintf('Failed to save file %s\nDumping workspace to %s\n',outfile,'MemDump_Stop_MissionBay.mat');
	save MemDump_Stop_MissionBay;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
if IS_MRI
    WaitSecs(10);   %Drew
    
    arrDisplayText = [ ...
        'Task complete.','\n\n\n' ...
        'Thank you for your participation.' ...
        ];
else
    boolCheckResponse=1;
    while boolCheckResponse
        [boolKeyDown,~,~] = KbCheck(inputDevice);
        if boolKeyDown && boolCheckResponse
            boolCheckResponse=0;
        end
    end
    
    arrDisplayText = [ ...
        'Task complete.','\n\n\n' ...
        'Thank you for your participation.' ...
        ];
end

DrawFormattedText(w,arrDisplayText,'center','center',[],[], boolUseMirroredText);
Screen('Flip',w);

if IS_MRI
    WaitSecs(5);
else
    WaitSecs(3);
end

end

function myCleanup(pahandle, fid)
    PsychPortAudio('Close', pahandle);
    fclose(fid);
    Screen('CloseAll');
    ShowCursor;
    Priority(0);
    KbQueueStop();
    DisableKeysForKbCheck([]);
    
    clear objPortIO
end
