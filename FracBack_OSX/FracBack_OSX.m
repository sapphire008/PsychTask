function FracBack_OSX(subject_ID,sub_session,...
    InputDevice,TriggerMode,TriggerDevice,self_paced)
% FracBack_OSX(subject_ID,session_type,InputDevice,TriggerMode,TriggerDevice,TriggerWaitSecs,TaskWaitSecs)
%
% Inputs:
%       subject_ID: numeric subject ID number
%
%       sub_session: [MRI, blocknum] format
%                    1=fMRI block1
%                    2=fMRI block2
%                    3=fMRI block3
%                    4=behave ZeroBack
%                    5=behave OneBack
%                    6=behave TwoBack
%                    7=behave mixed
%           behave run will only contain 1 run       
%           By default, behave session will use default input device -1,
%           and needs manually start the task, whereas fMRI session handle
%           a variety of input and trigger devices.
%
%       InputDevice: device number to receive subject response.
%       
%       TriggerMode: mode of trigger device. input as a numeric with the
%                    following options:
%                 1). Task triggers scanner via USB;
%                 2). Task triggers scanner via Serial Port;
%                 3). Scanner triggers task via USB;
%                 4). Scanner triggers task via Serial Port.
%                 Only relevent for fMRI mode (sub_session = 2). 
%
%       TriggerDevice:
%               a). numeric USB device number that scanner uses to trigger
%                   the onset of the task in this script
%               b). char/string path to where a serial port device resides
%                   after connection. In Unix, usually, /dev/tty*. The
%                   script will use this device path to trigger the
%                   scanner.
%       
%       self_paced: [true|false] whether run the task as self-paced mode,
%                   in which stimuli will not be turned off until subject
%                   give an response
% 
% Any necessary inputs missing will be prompted at the command window 
%
% *************************************************************************
%                        Fractal Back task
%                      _____________________
%
% This task is a replication of a modified version of FracBack by Dan
% Rangland et al currently in use by Jong Yoon et al. The block structure 
% is dynamic and is controlled by the block structure variable; the script 
% will wait for controller input before continueing onto the next block. 
% If the script is run in fMRI mode, all text shown (including stimuli) 
% will be left-right reversed.
%
% Note: reponse legend (ACC):
%	Correct: 1
%   Incorrect: 0
%   No response: -1
%   DEBUG: -2
%
% Note: the current block structure as of 8/9/2013 is:
%   3 blocks of 9 mini-blocks
%   each trial in a mini-block is 0.5 + 1.5 = 2 seconds
%   with 15 trials per mini-block
%   with a 3 second instruction prior to each mini-block
%   with a 15 second rest period after every 3 mini-blocks
%   the total single block length is ((2*15 + 3)*3 + 15)*3 = 342 seconds
%   with a TR of 3, each block is 114 measurements
%
% ***********************************************************************
%                           Block Design
%                        __________________
% Note: the trial orders are pseudorandom such that they are randomized
% beforehand, and each subject will experience the same randomized blocks.
% Block/trial count is not hard-coded and is dynamically controlled by the
% block structure cell matrix defined below. Each row is a block, and each
% column defines a trial-block (also called mini-block). Each trial block is
% itself a 2-element cell array, with the first cell defining the trial 
% type, and the second cell defining the trial order as a string. 
% Trial type definitions are:
%       0 = 0-back  1 = 1-back  2 = 2-back 3 = rest
%   For example, 2blocks of 3 mini-blocks of 5 trials followed by a rest
%       mini-block would be:
%       {{0,'ABCDE'},{1,'HGSBJ'},{2,'AFBFG'},{3,'REST'}; ...    %block 1
%        {1,'GJSIF'},{2,'SJGIF'},{0,'BHSUE'},{3,'REST'}}        %block 2
%       {1,'ABCDE'; 2,'HGSBJ'; 0,'AFBFG'; 3, 'REST'}
%   Note: column 1 needs to be a double and column 2 needs to be a string
%   Note: the trial order string for the rest block is ignored, so it can
%         be used as a short comment
%   Note: in the beginning of every block the instruction hint screen
%         corresponding to the trial type is shown before the trials begins
%   Note: the letters used in the trial order corresponds to the filenames
%         of the imported images (case-sensitive). It is required to use
%         single-letter filenames for simplicity

% Author: Edward Cui, Julian Y. Cheng

%% PART I: Settings--------------------------------------------------------
%debugging options
DEBUG = false;%if set to true, will print debug messages reporting the 
%             durations of each trial phase
DEBUG_SCREEN_SIZE = [];%[0 0 800 600];% put [] for full screen, otherwise, [0 0 800 600]
%whether or not use mirror text
boolUseMirroredText = false;
%response mapping for match response
arrMatchResponse = [KbName('1!'),KbName('1'),KbName('6^'), KbName('6')];
%response mapping for non-match response
arrMismatchResponse = [KbName('2@'),KbName('2'),KbName('7&'),KbName('7')];
%set allowed keys to monitor, instead of monitoring the whole keyboard
arrAllowedKeys = [KbName('1!'),KbName('1'),KbName('2@'),KbName('2'),...
    KbName('3#'),KbName('3'),KbName('4$'),KbName('4'),KbName('6^'), ...
    KbName('6'),KbName('7&'),KbName('7'),KbName('8*'),KbName('8'),...
    KbName('9('),KbName('9')];
%the trigger keys
TTLTrigger = [KbName('t'),KbName('5'),KbName('5%')];
SerialTrigger = '[t]';%character that triggers the scanner
TriggerWaitSecs = 0;%seconds to wait before triggering the scanner after 
%                   the first screen of the task ('Get Ready'). Only 
%                   relevant if use script to trigger scanner, in which
%                   case TriggerDevice is a string of path to serial device.
TaskWaitSecs = 9;%seconds to wait after trigger completed and before task
%                 starts. A crosshair will be displayed at the meantime.
%                 Regular EPI 9, mux 2 use 24, mux 3 36
SCRIPT_VER = 'EDC052714';
target_response_keyboard_name = 'Current';%use this string to search for keyboards
target_ttl_keyboard_name = 'ttlpulse_device_product_name';%enter some jibberish so that the script will list all the devices

%design parameters---------------------------------------------------------
strCode = [filesep,'scripts',filesep];  %location for supporting functions
strResource = [filesep,'Resource',filesep];%location for import data
strBehave = [filesep,'Behave_data',filesep];%location for behave output data
strFmri = [filesep,'fMRI_data',filesep];%location for fmri output data
strStudy = 'M3';                     %will be appended before the subject number
strFont = 'Arial';                      %the text font
strBehavePostfix = 'FractalBack_Behave';%will be appended to each subject file
strFmriPostfix = 'FractalBack_Fmri';    %will be appended to each subject file
intTextSize = 28;                       %the text size of non-stimuli text
                                        %note: use 28 if resolution is 1024x768
                                        %      use 50 if resolution is 1920x1024
intFixationSize = 50;                   % size of fixation cross hair and the inter-image
                                        % prompt (Edward 090413)
dblImageScale = 2;                      %the scaling of the displayed image
                                        %note: 1.0 = 100% of original;
                                        %upscaling will use bilinear
                                        %filtering
arrBackground = [245,245,245];          %the background color to use (can be single int as well)
arrTextColor = 0;                       %the color of the displayed text (can be single int as well)


%task-specific parameters
dblPostTrialDuration = 1;   %time after end of last ITI
                            %note: make sure that the scanner protocol
                            %covers the entire block period, which is
                            %pre-trial + trials + post-trial
dblRuleDuration = 3;        %time to show the task condition rule
dblRestDuration = 30;       %time to rest every 3 task conditions
                            %note: make sure that the scanner protocol
                            %covers the entire block period
dblCueDuration = 0.5;       %time of cue period in seconds
dblITIDuration = 1.5;       %time of ITI period in seconds
%note: this includes the response duration as
%well
%note: the full trial duration will be =
%cue + ITI
dblPreCueReserve = 50;      %this is the minimum amount of time the task
%will spend preparing for the cue, in
%milliseconds.
%note: during this time the response will not
%be checked, resulting in a no response.
strTargetFile = 'X';        %the filename of the target used in 0-back
%note: do not include file extension
arrHeader = {'RealTime','Block','Miniblock','Trial','TrialType','Cue','IsMatch',...
    'KeyPressed','ACC','RT','CueDuration','ITIDuration',...
    'AbsOnset','MiniBlockOnset','CueOnset','ITIOnset'};% column header
%possible formats that the images are
targetImgFormats = {'.bmp','.gif','.jpg','.jpeg','.png','.tif'};
packagedir = mfilename('fullpath');% package directory,assuming current
packagedir = fileparts(packagedir);% script is directly under the package
dirCode = fullfile(packagedir,strCode); addpath(dirCode); %add current package to MATLAB
DefaultKeyboardDevice = get_device_osx([],[],[],false);%-1% default keyboard device number


%event codes (for pupillometry)
% structEventCodes.block_wait = -1;               %used for pre/post-block fixation
% structEventCodes.block_onset = 0;               %to be set as the block number
% structEventCodes.rule.zero = 11;                %0-bak
% structEventCodes.rule.one = 12;                 %1-bak
% structEventCodes.rule.two = 13;                 %2-bak
% structEventCodes.cue.match = 21;
% structEventCodes.cue.mismatch = 22;
% structEventCodes.cue.debug = 91;                %error occured in cue
% structEventCodes.ITI = 30;
% structEventCodes.response.correct = 41;
% structEventCodes.response.incorrect = 42;
% structEventCodes.response.no_response = 43;
% structEventCodes.response.debug = 92;           %error occured in response
% structEventCodes.rest = 50;
% structEventCodes.debug = 93;                    %general error occured

%% PART II: Parse inputs
if nargin<1 || isempty(subject_ID)
    subject_ID = input('Subject ID: ');
end
if nargin<2 || isempty(sub_session)
    sub_session = input(['Session type?\n1=fMRI block1\n2=fMRI block2\n',...
        '3=fMRI block3\n4=behave ZeroBack\n5=behave OneBack\n',...
        '6=behave TwoBack\n7=behave Practice\n']);
end
%block stucture
switch sub_session
    case 1
        BlockStructure = { ...   %use this for actual fMRI session
            %block 1
            {0,'VXNFTXBXNVBCXRX'}, {1,'SGGLQQBNNCCTTWK'}, {2,'JSJSBTBVSFPFPSN'}, {3,'REST'}, ... %mini-blocks 1-4
            {1,'FFRWMMLHHBRRBBQ'}, {2,'RNRVWVPGPJTJMQM'}, {0,'SXBXHNCXDSXGTXZ'}, {3,'REST'}, ... %mini-blocks 5-8
            {2,'QGQGZFZDGTKTKGL'}, {0,'DTXLFXZXDZWXHXJ'}, {1,'SSGNJJZLLWWCFFP'}, {3,'REST'}; ... %mini-blocks 9-12
            };
        block_name = 'fMRI_block1';
    case 2
        BlockStructure = {...
            %block 2
            {2,'HLPDPDKSKQFQFSW'}, {1,'TTHCMMNZZRRWVSS'}, {0,'GXCXRLGWXVXSPXD'}, {3,'REST'}, ... %mini-blocks 1-4
            {1,'KWWRMMDPPCCJJGS'}, {0,'HXPZJXDXPHDXMLX'}, {2,'TKTKDJDHKZNZNKP'}, {3,'REST'}, ... %mini-blocks 5-8
            {0,'KXNVXPCXBKXWGXV'}, {2,'LPLHGHNWNTJTKVK'}, {1,'ZZLGQQRDVVRRHHM'}, {3,'REST'}; ... %mini-blocks 9-12
            };
        block_name = 'fMRI_block2';
        
    case 3
        BlockStructure = {...
            %block 3
            {1,'WTRRCRDDFFQQPPS'}, {2,'TRTDJVJVLPGPDQD'}, {0,'XLDKWXWVXWXPKXH'}, {3,'REST'}, ... %mini-blocks 1-4
            {2,'KNKNCZCBVTVPQPH'}, {0,'BDXTXBJXTXLXHZR'}, {1,'SSZZKCSJJVBBDDK'}, {3,'REST'}, ... %mini-blocks 5-8
            {0,'DKJXVNXWXFTJXSX'}, {2,'KPLBLBDDRCRCFLF'}, {1,'TTCWWGBBSLLRNSS'}, {3,'REST'}; ... %mini-blocks 9-12
            };
        block_name = 'fMRI_block3';
        
    case 4 % ZeroBack
        BlockStructure = {...
            {0,'KJXGXRSXMNLXPXQ'},{0,'DTXLFXZDXZXWXHJ'},{0,'HXPZJXDXPHDXLXM'}};
        block_name = 'behave_ZeroBack';
        
    case 5 % OneBack
        BlockStructure = {...
            {1,'SZZLGQQRDVVRRHH'},{1,'SSGNJJZLLWWCFFP'},{1,'ZZLGQQRDVVRRHHM'}};
        block_name = 'behave_OneBack';
        
    case 6 % TwoBack
        BlockStructure = {...
            {2,'LPLHGHNWNTNTKVQ'},{2,'RNKVWVPGPJTJMJM'},{2,'TKTKDJDHKZNZNKP'}};
        block_name = 'behave_TwoBack';
        
    case 7
        BlockStructure = { ... %use this for behave
            {0,'KJXGXRSXMNLXPXQ'}; {1,'SZZLGQQRDVVRRHH'}; {2,'LPLHGHNWNTNTKVQ'};... %block 1
            {1,'SSGNJJZLLWWCFFP'}; {2,'RNKVWVPGPJTJMJM'}; {0,'HXPZJXDXPHDXLXM'};... %block 2
            {1,'ZZLGQQRDVVRRHHM'}; {0,'DTXLFXZDXZXWXHJ'}; {2,'TKTKDJDHKZNZNKP'};... %block 3
            };
        block_name = 'behave_Practice';
        
end
% device and run mode info
switch sub_session
    case {1,2,3} % fmri
        MRI = true;
        play_instructions = false;%force off instructions
        self_paced = false;%force off self pace mode
        %prompt for input device
        if nargin<3 || isempty(InputDevice)
            InputDevice = get_device_osx(target_response_keyboard_name,[],[],true);%check_device('response');
        end
        %prompt for trigger mode
        if nargin<4 || isempty(TriggerMode)
            % first ask the user which mode of triggering is used
            disp('Which mode of triggering is used?');
            TriggerMode = input([...
                '1). Task triggers scanner via USB;\n',...
                '2). Task triggers scanner via Serial Port;\n',...
                '3). Scanner triggers task via USB;\n',...
                '4). Scanner triggers task via Serial Port.\n']);
        end
        %Get device and trigger behaviors
        if nargin<5 || isempty(TriggerDevice)
            switch TriggerMode
                case {1,3}%via USB
                    TriggerDevice = get_device_osx(target_ttl_keyboard_name,[],'TTL Device: ',true);%check_device('ttl');
                case {2,4}%via Serial
                    TriggerDevice = create_serial_trigger([],SerialTrigger);
                    disp('created trigger device');
            end
        end
        %Set trigger wait times: only for task triggers scanner
        switch TriggerMode
            case {1,2}%task triggers scanner
            case {3,4}%scanner triggers task
                TriggerWaitSecs = 0;
        end
    case {4,5,6,7} %behave: similar to fmri
        MRI = false;play_instructions = true;InputDevice = DefaultKeyboardDevice;%-1;
        TriggerDevice = DefaultKeyboardDevice;TriggerWaitSecs = 0;TaskWaitSecs = 2;
        TriggerMode = 3;
        if nargin<6 || isempty(self_paced)
            self_paced = input('Self Paced? [0|1] : ');
        end
end
if self_paced,dblCueDuration = -1;end

%% PART III: Construct Output
if MRI
    strFilename = [strStudy, num2str(subject_ID, '%03i'), '_', ...
                   strFmriPostfix];
    dirOutput = fullfile(packagedir,strFmri);
else
    strFilename = [strStudy, num2str(subject_ID, '%03i'), '_', ...
                   strBehavePostfix,'_',block_name];
    dirOutput = fullfile(packagedir,strBehave);
end
strFilename = [strFilename,'_',block_name,'_',datestr(now,'mm-dd-yyyy_HH-MM-SS')];


%record history
History = fnGetHistory('script', mfilename, 'version', SCRIPT_VER);

% Initialize the log file
% This writes to a CSV file on every trial during ITI to have a record of
% crashed sessions for whatever reason.
FILEPATH = fullfile(dirOutput,[strFilename,'.csv']);
%print header information
worksheet = {'Date',History.date;...
    'Script', History.script;...
    'Version',History.version};
cell2csv(FILEPATH,worksheet,',','a+');%record data sheet info
cell2csv(FILEPATH,arrHeader,',','a+');%record header
clear arrHeader;

%check that block structure
%note: each row is a block, each column is a trial
%note: the block structure in the data is stored in <block x trial>
%format, ignoring mini-blocks. All mini-blocks are concatenated
%together, and all trials re-referenced to trials since block onset.
%Also, rest blocks are counted as having 1 trial.
CheckedFilesString = strTargetFile;     %will be consumed after images are loaded
for i = 1:size(BlockStructure,1)%blocks
    %count how many trials are in this block
    intTrailCount = 0;
    for j = 1:size(BlockStructure,2)%mini-blocks of each block
        if isempty(BlockStructure{i,j}), continue; end     %don't process empty cells
        % parse trial type
        TrialType = BlockStructure{i,j}{1};
        switch TrialType
            case {0,1,2}
                intTrailCount = intTrailCount + length(BlockStructure{i,j}{2});
                CheckedFilesString = unique([CheckedFilesString,BlockStructure{i,j}{2}]);
            case 3
                intTrailCount = intTrailCount +1;
            otherwise
                error('Unknown trial type %i defined for block %i mini-block %i', ...
                    TrialType, i, j);
        end
    end
end
IMG_CHECK = [];% index of 
for k = CheckedFilesString
    tmp = find(cell2mat(cellfun(@(x) ...
        exist(fullfile(packagedir,strResource,[k,x]),'file'),...
        targetImgFormats,'un',0)),1);
    if isempty(tmp),tmp = NaN;end
    IMG_CHECK = [IMG_CHECK,tmp];
end
if any(isnan(IMG_CHECK))
    error('Failed to find image(s) %s \n', CheckedFilesString(IMG_CHECK));
else
    CheckedFiles = cellfun(@(x,y) fullfile(packagedir,strResource,...
        [x,targetImgFormats{y}]),num2cell(CheckedFilesString),...
        num2cell(IMG_CHECK),'un',0);
    clear IMG_CHECK;
end
%% PART IV: Initialize keyboards
keysOfInterest = zeros(1,256);
keysOfInterest(arrAllowedKeys)=1;
KbQueueCreate(InputDevice,keysOfInterest);
%% PART V: Initialize screen
%open main screen
%note: opens the highest device number, which is the secondary monitor if
%it exists
if DEBUG
   [ptrWindow, arrWindowSize] = Screen('OpenWindow', max(Screen('Screens')), arrBackground, DEBUG_SCREEN_SIZE);
else
    [ptrWindow, arrWindowSize] = Screen('OpenWindow', max(Screen('Screens')), arrBackground);
end

%set screen settings
Screen('TextSize', ptrWindow, intTextSize);
Screen('TextFont', ptrWindow, strFont);
Screen('TextColor', ptrWindow, arrTextColor);

%display initialize message
DrawFormattedText(ptrWindow, 'Initializing...','center','center',[],[],boolUseMirroredText);
Screen('Flip', ptrWindow);

% Adjust operating environment
Priority(1);
HideCursor();
%ListenChar(2);%disable input to command window, but may be bad if to crash
%the script
%rng(subject_ID);
%cleanupObj = onCleanup(@() myCleanup(dirCode));

% Initialize screen textures
%load all images to structure array
structImages.filename = '';
structImages.pointer = 0;
structImages.size = [];
structImages.destination = [];
for m = 1:length(CheckedFiles)
    %load the image
    dataImage = imread(CheckedFiles{m});
    %construct the destination rectangle
    %note: scaling is specified here and done during screen draw
    arrSize = [0,0,size(dataImage,1),size(dataImage,2)];
    arrDestination = CenterRect(arrSize .* dblImageScale, arrWindowSize);
    
    %construct the texture in OpenGL
    ptrTexture = Screen('MakeTexture', ptrWindow, dataImage);
    
    %save pointer into structure
    if isempty(structImages(end).filename)
        structImages(1).filename = CheckedFilesString(m);
        structImages(1).pointer = ptrTexture;
        structImages(1).size = arrSize;
        structImages(1).destination = arrDestination;
    else
        structImages(end+1).filename = CheckedFilesString(m);
        structImages(end).pointer = ptrTexture;
        structImages(end).size = arrSize;
        structImages(end).destination = arrDestination;
    end
end

%load all textures to VRAM
intSuccess = Screen('PreloadTextures', ptrWindow);
if intSuccess ~= 1,warning('Failed to pre-load all textures');end

clear m CheckedFilesString CheckedFiles dataImage arrSize arrDestination ptrTexture intSuccess;

%% PART VI: Display instructions
if play_instructions
    DisplayInstructions(ptrWindow,structImages,strTargetFile,...
        boolUseMirroredText,DefaultKeyboardDevice,arrWindowSize);%let the laptop user control
end
clear strMessage* boolKeyPress

% Remind the subject about the 0-back target block
if MRI && ~play_instructions
    idxZeroTarget = strfind([structImages.filename], strTargetFile);
    Screen('DrawTexture', ptrWindow, structImages(idxZeroTarget).pointer,...
        [], structImages(idxZeroTarget).destination);
    Screen('Flip',ptrWindow);
    KbWait(DefaultKeyboardDevice);
end
%% PART VII: Run trial blocks
for intBlock = 1:size(BlockStructure,1)
    %reset KbCheck filter
    DisableKeysForKbCheck([]);  
    % start the KbQueue
    KbQueueStart;
    %display pre-block message
    %note: this notifies both the subject and the operator that the
    %task is ready. The subject should be prepared to start the task at
    %any time, and the operator should make sure that the TTL pulses
    %start sending AFTER this message has been shown, otherwise the
    %task won't be ready for it.
    if intBlock == 1 && ~MRI
        strMessage = 'Get Ready!';
    elseif intBlock>1 && ~MRI
        Screen('Flip',ptrWindow);%end of trial blank screen buffer
        WaitSecs(0.5);% time buffer
        strMessage = 'Press any key to proceed to the next block';
    else
        strMessage = sprintf('Get Ready for Block %d',sub_session);
    end
    Screen('TextSize', ptrWindow, intFixationSize);
    DrawFormattedText(ptrWindow, strMessage,'center','center',[],[],boolUseMirroredText);
    Screen('Flip', ptrWindow);
    
    % Trigger mode in fMRI
    if isnumeric(TriggerDevice) && TriggerDevice>0,TF = true;%usb
    elseif ischar(TriggerDevice) && ~isempty(TriggerDevice),TF = true;%serial
    else TF = false;
    end
    
    %write start of block code to port
    %structEventCodes.block_onset = intBlock;
    
    %start counting trials
    intTrialCount = 0;

    for intMiniblock = 1:size(BlockStructure,2)
        clear worksheet;
        %note: fixation is still shown
        % load everythin first before tarting the task.
        
        if isempty(BlockStructure{intBlock,intMiniblock}), continue; end     %don't process empty cells
        
        %get trial type definition and trial order
        TrialType = BlockStructure{intBlock,intMiniblock}{1};
        TrialOrder = BlockStructure{intBlock,intMiniblock}{2};
        
        %setup trial information by trial type
        %note: intOffset is used to reference previous trials
        switch TrialType
            case 0  %0-back
                strRule = 'Rule I\n\n0 back';
                intOffset = 0;
                %myRuleEventCode = structEventCodes.rule.zero;
            case 1  %1-back
                strRule = 'Rule II\n\n1 back';
                intOffset = 1;
                %myRuleEventCode = structEventCodes.rule.one;
            case 2  %2-back
                strRule = 'Rule III\n\n2 back';
                intOffset = 2;
                %myRuleEventCode = structEventCodes.rule.two;
            case 3 % rest
                strRule = 'Rest';
            otherwise % unrecognized block
                fprintf('[WARNING] failed to parse trial type, skipping\n')
                continue;
        end
        
        % Trigger at the first mini-block ---------------------------------
        KbEventFlush();
        if intMiniblock == 1
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
                        KbWait(DefaultKeyboardDevice,3);
%                        DefaultKeyBoardTrigger(DefaultKeyboardDevice);
                        %wait for TriggerWaitSecs
                        if TriggerWaitSecs>0,WaitSecs(TriggerWaitSecs);end
                        %trigger scan first, then wait for tasks
                        AbsOnset=serial_trigger_scan();
                        fprintf('triggered scan at %.3f\n',GetSecs());
                    case 3%scanner triggers task, USB
                        AbsOnset=KbTriggerWait(TTLTrigger,TriggerDevice);
                        DisableKeysForKbCheck(TTLTrigger); % So trigger is no longer detected
                    case 4%scanner triggers taks, serial port
                        % Not Implemented
                        Screen('CloseAll');
                        ShowCursor;
                        error('scanner triggers task via serial port: Not implemented\n');
                end
            else% manually start the task
                AbsOnset = KbWait(DefaultKeyboardDevice,3);
            end
            % task wait
            if TaskWaitSecs>0
                %show fixation screen after the trigger
                DrawFormattedText(ptrWindow,'x','center','center');
                Screen('Flip', ptrWindow);
                % advance the block onset time to the time after wait
                timeDeadline = AbsOnset+TaskWaitSecs;
            else
                timeDeadline = AbsOnset;
            end
        end
        
        %Rule Prompt ------------------------------------------------------
        %render message
        DrawFormattedText(ptrWindow, strRule,'center','center',[],[],boolUseMirroredText);
        %block until message onset
        [timeMiniblockOnset,tmp,timeRuleFlip]=Screen('Flip', ptrWindow, PredictVisualOnsetForTime(ptrWindow, timeDeadline));
        %set trial onset
        timeDeadline = timeDeadline + dblRuleDuration;
                
        %fprintf('[Block %i Mini-block %i-0] RULE\n', intBlock, intMiniblock)
        
        % display crosshair for rest condtions
        if TrialType==3
            % show fixation crosshair
            DrawFormattedText(ptrWindow,'x','center','center');
            [timeRestOnset, timeRestFlip] = Screen('Flip', ptrWindow, PredictVisualOnsetForTime(ptrWindow, timeDeadline));
            
            %increment trial count
            intTrialCount = intTrialCount +1;
            timeDeadline = timeDeadline + dblRestDuration;
            
            %write trial to CSV
            cell2csv(FILEPATH,{datestr(clock),sub_session,intMiniblock,0,TrialType,...
                'REST',0,'',0,0,0,0,AbsOnset,timeMiniblockOnset,...
                timeRestOnset,0},',','a+');
            %print resting period to the command window
            %fprintf('[Block %i Mini-block %i-1] REST\n', intBlock, intMiniblock)
            WaitSecs('UntilTime',timeDeadline);
            continue;
        end
        
        for intTrial = 1:length(TrialOrder)
            %arrEventCodes = [];
            
            %find the texture
            strImage = TrialOrder(intTrial);
            idxTexture = strfind([structImages.filename], strImage);
            if isempty(idxTexture)
                %note: this means that we failed to find the texture stored
                %in the structure array. In theory this should never
                %happen, since all trials are checked prior to loading the
                %textures. If this does occur, something corrupted the
                %structure array.
                
                %show fixation
                %DrawFormattedText(ptrWindow, 'x','center',polyval(arrPolynomial,intTextSize));
                DrawFormattedText(ptrWindow,'x','center','center');
                [timeCueOnset,tmp,timeCueFlip] = Screen('Flip', ptrWindow, PredictVisualOnsetForTime(ptrWindow, timeDeadline));
                
                %increment trial count
                intTrialCount = intTrialCount +1;

                %write trial to CSV
                cell2csv(FILEPATH,{datestr(clock),sub_session,intMiniblock,intTrial,...
                    TrialType,'ERROR',0,'',0,0,dblCueDuration,...
                    dblITIDuration, timBBlockOnset,...
                    timeMiniblockOnset,timeCueOnset,0},',','a+');
                
                %set next trial onset
                timeDeadline = timeDeadline + dblCueDuration + dblITIDuration;
                %print error to command window
                fprintf('[Block %i Mini-block %i-%2i] ERROR\n', intBlock, intMiniblock, intTrial);
                continue;
            end
            
            % CUE ---------------------------------------------------------
            %draw texture to screen
            Screen('DrawTexture', ptrWindow, structImages(idxTexture).pointer, [], structImages(idxTexture).destination);

            %determine expected correct response
            if intOffset == 0                                    %zero back
                if strcmpi(strImage,strTargetFile)
                    myAcceptedResponse = arrMatchResponse;
                    %myCueEventCode = structEventCodes.cue.match;
                else
                    myAcceptedResponse = arrMismatchResponse;
                    %myCueEventCode = structEventCodes.cue.mismatch;
                end
            else                                              %one/two back
                if (intOffset < intTrial) && strcmpi(strImage,TrialOrder(intTrial - intOffset))
                    myAcceptedResponse = arrMatchResponse;
                    %myCueEventCode = structEventCodes.cue.match;
                else
                    myAcceptedResponse = arrMismatchResponse;
                    %myCueEventCode = structEventCodes.cue.mismatch;
                end
            end
            
            if DEBUG && (GetSecs >= timeDeadline)
                fprintf('[DEBUG] cue is late\n')
            end
            
            %block until cue onset
            [timeCueOnset,tmp,timeCueFlip] = Screen('Flip', ptrWindow, PredictVisualOnsetForTime(ptrWindow, timeDeadline));

            %write cue onset code to port
            %arrEventCodes(end+1) = myCueEventCode;
            
            % ITI ---------------------------------------------------------
            %render ITI
            %DrawFormattedText(ptrWindow, num2str(TrialType),'center',polyval(arrPolynomial,intTextSize));
            DrawFormattedText(ptrWindow, num2str(TrialType),'center','center');
            %get flip duration
            dblFlipDuration = Screen('GetFlipInterval', ptrWindow);
 
            % block ITI if holding cue duration indefinitely. Only used in
            % behave, so timing is not all important
            if self_paced
                [timeResponse,intKey]=KbWait(InputDevice);
                timeDeadline = timeResponse;
                boolKeyPress = true;
                [timeITIOnset,tmp,timeITIFlip] = Screen('Flip',ptrWindow);%show ITI
                WaitSecs('UntilTime',timeDeadline+dblITIDuration-dblPreCueReserve/1000);
            else
                %calculate ITI onset
                timeDeadline = timeDeadline + dblCueDuration;
                boolShowITI = true;
                %start response loop
                %note: actual duration is decreased by pre cue reserve to give
                %ample time for trial preperation in the case of no response
                boolKeyPress = false;
                
                KbQueueFlush;
                while GetSecs < (timeCueOnset + dblCueDuration + dblITIDuration - dblPreCueReserve/1000)
                    %check if ITI should be shown
                    if boolShowITI && (GetSecs >= timeDeadline - dblFlipDuration/2)   %add flip duration to account for cue flip; helps make cue duration closer to ideal
                        %show fixation
                        [timeITIOnset,tmp,timeITIFlip] = Screen('Flip', ptrWindow);
                        boolShowITI = false;
                    end
                    
                    %check if loop should be terminated or response check
                    %skipped
                    if ~boolShowITI && boolKeyPress, break;%response is given, and already shown ITI
                    elseif boolKeyPress, continue; end%response given before ITI
                    
                    %check response
                    %[boolKeyPress,timeResponse,arrKeys] = KbCheck(InputDevice);%cannot detect fast button press
                    [boolKeyPress,firstpress] = KbQueueCheck;%get only the first key press

                    WaitSecs(0.001);
                end
            end
            
            %process the response------------------------------------------
            
            %calculate RT
            if ~boolKeyPress    %no response
                dblRT = 0;
                intKey = [];
            elseif self_paced % has response, self-paced
                intKey = find(intKey);
                dblRT = timeResponse - timeCueOnset;
            else %has response, not self-paced
                timeResponse = min(firstpress(firstpress>0));
                intKey = find(abs(firstpress-timeResponse)<1E-6,1);
                dblRT = timeResponse - timeCueOnset;
            end
            
            %parse ACC and event code
            if (dblRT > 0) && any(intKey(1) == myAcceptedResponse)
                %correct
                intACC = 1;
                %myResponseEventCode = structEventCodes.response.correct;
            elseif (dblRT > 0)                                        
                %incorrect
                intACC = 0;
                %myResponseEventCode = structEventCodes.response.incorrect;
            elseif dblRT == 0                                               	
                %no response
                intACC = -1;
                %myResponseEventCode = structEventCodes.response.no_response;
            else
                %something went wrong and couldn't parse response correctly
                intACC = -2;
                %myResponseEventCode = structEventCodes.response.debug;
            end
            
            %--------------------------------------------------------------

            %write response code to port
            %arrEventCodes(end+1) = myResponseEventCode;
            
            %calculate next cue onset
            timeDeadline = timeDeadline + dblITIDuration;
            
            %increment trial count
            intTrialCount = intTrialCount +1;

            %parse response key
            if isempty(intKey)
                myKey = '';
            else
                myKey = KbName(intKey(1));
            end

            %write trial to CSV
            cell2csv(FILEPATH,{datestr(clock),sub_session,intMiniblock,intTrial,...
                TrialType,strImage,all(myAcceptedResponse == arrMatchResponse),...
                myKey,intACC,dblRT,(timeITIOnset-timeCueOnset),...
                (timeDeadline-timeITIOnset),AbsOnset,timeMiniblockOnset,...
                timeCueOnset,timeITIOnset},',','a+');

            %report to command window
%             fprintf('[Block %i Mini-block %i-%2i] Rule: %i | Cue: %s | IsMatch: %i | ACC: %2i | RT: %4.0f ms | Key: %s\n', ...
%                 intBlock, intMiniblock, intTrial, TrialType, strImage, all(myAcceptedResponse == arrMatchResponse), intACC, dblRT * 1000, myKey);
            if DEBUG
                fprintf('[DEBUG] Cue dur: %7.2f ms | ITI dur: %7.2f ms\n', ...
                    (timeITIOnset - timeCueOnset) * 1000, ...
                    (timeDeadline - timeITIOnset) * 1000 ...
                    );
                fprintf('[DEBUG] Cue flip: %6.2f ms | ITI flip: %6.2f ms\n', ...
                    (timeCueFlip - timeCueOnset) * 1000, ...
                    (timeITIFlip - timeITIOnset) * 1000 ...
                    );
                if intOffset >= intTrial
                    temp1 = ' ';
                    temp2 = 0;
                else
                    temp1 = TrialOrder(intTrial - intOffset);
                    temp2 = strcmpi(strImage,TrialOrder(intTrial - intOffset));
                end
%                 fprintf('[DEBUG] Last cue: %s | This cue: %s | intOffset < intTrial: %i | strcmpi: %i\n', temp1, strImage, intOffset < intTrial, temp2)
            end
        end
    end
    
    %extend deadline to end of post-trial duration
    timeDeadline = timeDeadline + dblPostTrialDuration;
    
    %display message for the end of the block
    strMessage ='Great Job!\nThank you!';
    DrawFormattedText(ptrWindow, strMessage, 'center', 'center', [],[],boolUseMirroredText);
    Screen('Flip', ptrWindow, PredictVisualOnsetForTime(ptrWindow, timeDeadline));
    KbQueueStop;
    WaitSecs(3);
end

DisableKeysForKbCheck([]);%remove any disabled keys
Screen('CloseAll');%close the window
ShowCursor();%show mouse cursor
clear GLOBAL TRIGGER MARKER;
rmpath(dirCode);
KbQueueFlush;KbQueueRelease;
%ListenChar(0);%enable command window input, use with ListenChar(2);
end