function Data = FracBack_OSX(subject_ID,sub_session,...
    InputDevice,TriggerMode,TriggerDevice,TriggerWaitSecs,TaskWaitSecs)
% FracBack_OSX(subject_ID,session_type,InputDevice,TriggerMode,TriggerDevice,TriggerWaitSecs,TaskWaitSecs)
%
% Inputs:
%       subject_ID: numeric subject ID number
%
%       sub_session: 1 = behave, 2 = fMRI
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
%       TriggerWaitSecs: time to wait before triggering the scanner
%                        after the first screen of the task ('Get Ready'). 
%                        Only relevant if use script to trigger scanner, 
%                        in which case TriggerDevice is a string of path 
%                        to serial device.
%       
%       TaskWaitSecs: time to wait after trigger completed and before task
%                     starts. A crosshair will be displayed at the
%                     meantime.
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

% Author: Julian Y. Cheng
% Adaption to OSX: Edward Cui 8/9/2013

SCRIPT_VER = 'v0.1beta';

%user settings-------------------------------------------------------------
%debugging options
DEBUG = true;
    %if set to true, will print debug messages reporting the durations
    %of each trial phase
DEBUG_FORCE_1024_768 = false;
    %if set to true, will display screen in 1024x768 resolution instead of
    %full screen. Used to test the script on a display larger than 1024x768
    %Also, will adjust font-related settings to those noted in their
    %respectful comments:
    %   intTextSize = 28;
    %   arrPolynomial = [-0.7 370];
    %note: do not use this to run subjects on 1024x768 screens, it is for
    %testing purposes only
%whether or not use mirror text
boolUseMirroredText = false;
%response mapping for match response
arrMatchResponse = [KbName('1!'),KbName('1'),KbName('6^'), KbName('6')];
%response mapping for non-match response
arrMismatchResponse = [KbName('2@'),KbName('2'),KbName('7&'),KbName('7')];
%the trigger keys
TTLTrigger = [KbName('t'),KbName('5'),KbName('5%')];
SerialTrigger = 't';%character that triggers the scanner

%design parameters---------------------------------------------------------
strCode = [filesep,'scripts',filesep];                     %location for supporting functions
strResource = [filesep,'Resource',filesep];             %location for import data
strBehave = [filesep,'Behave data',filesep];            %location for behave output data
strFmri = [filesep,'fMRI data',filesep];                %location for fmri output data
strStudy = 'pilot';                     %will be appended before the subject number
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
dblLeeWay = 0.1;            %if TaskWaitSecs is less than 
dblPostTrialDuration = 1;   %time after end of last ITI
                            %note: make sure that the scanner protocol
                            %covers the entire block period, which is
                            %pre-trial + trials + post-trial
dblRuleDuration = 3;        %time to show the task condition rule
dblRestDuration = 33;       %time to rest every 3 task conditions
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
arrHeader = {'Block','Miniblock','Trial','Type','Cue','IsMatch',...
    'KeyPressed','Acc','Rt_us','CueDuration_us','ITIDuration_us',...
    'BlockOnset_us','MiniBlockOnset_us','CueOnset_us','ITIOnset_us' ...	
    'EventCodeSequence'};% column header
%possible formats that the images are
targetImgFormats = {'.bmp','.gif','.jpg','.jpeg','.png','.tif'};
packagedir = mfilename('fullpath');% package directory,assuming current 
packagedir = fileparts(packagedir);% script is directly under the package
addpath(genpath(packagedir));%add current package to MATLAB
                       
% Block structures
arrBehaveBlockStructure = { ... %use this for behave
    {0,'KJXGXRSXMNLXPXQ'}; {1,'SZZLGQQRDVVRRHH'}; {2,'LPLHGHNWNTNTKVQ'};... %block 1
    {1,'SSGNJJZLLWWCFFP'}; {2,'RNKVWVPGPJTJMJM'}; {0,'HXPZJXDXPHDXLXM'};... %block 2
    {1,'ZZLGQQRDVVRRHHM'}; {0,'DTXLFXZDXZXWXHJ'}; {2,'TKTKDJDHKZNZNKP'};... %block 3
    };
arrFmriBlockStructure = { ...   %use this for actual fMRI session
    %block 1
    {0,'VXNFTXBXNVBCXRX'}, {1,'SGGLQQBNNCCTTWK'}, {2,'JSJSBTBVSFPFPSN'}, {3,'REST'}, ... %mini-blocks 1-4
    {1,'FFRWMMLHHBRRBBQ'}, {2,'RNRVWVPGPJTJMQM'}, {0,'SXBXHNCXDSXGTXZ'}, {3,'REST'}, ... %mini-blocks 5-8
    {2,'QGQGZFZDGTKTKGL'}, {0,'DTXLFXZXDZWXHXJ'}, {1,'SSGNJJZLLWWCFFP'}, {3,'REST'}; ... %mini-blocks 9-12
    %block 2
    {2,'HLPDPDKSKQFQFSW'}, {1,'TTHCMMNZZRRWVSS'}, {0,'GXCXRLGWXVXSPXD'}, {3,'REST'}, ... %mini-blocks 1-4
    {1,'KWWRMMDPPCCJJGS'}, {0,'HXPZJXDXPHDXMLX'}, {2,'TKTKDJDHKZNZNKP'}, {3,'REST'}, ... %mini-blocks 5-8
    {0,'KXNVXPCXBKXWGXV'}, {2,'LPLHGHNWNTJTKVK'}, {1,'ZZLGQQRDVVRRHHM'}, {3,'REST'}; ... %mini-blocks 9-12
    %block 3
    {1,'WTRRCRDDFFQQPPS'}, {2,'TRTDJVJVLPGPDQD'}, {0,'XLDKWXWVXWXPKXH'}, {3,'REST'}, ... %mini-blocks 1-4
    {2,'KNKNCZCBVTVPQPH'}, {0,'BDXTXBJXTXLXHZR'}, {1,'SSZZKCSJJVBBDDK'}, {3,'REST'}, ... %mini-blocks 5-8
    {0,'DKJXVNXWXFTJXSX'}, {2,'KPLBLBDDRCRCFLF'}, {1,'TTCWWGBBSLLRNSS'}, {3,'REST'}; ... %mini-blocks 9-12
    };

%event codes (for pupillometry)
structEventCodes.block_wait = -1;               %used for pre/post-block fixation
structEventCodes.block_onset = 0;               %to be set as the block number
structEventCodes.rule.zero = 11;                %0-bak
structEventCodes.rule.one = 12;                 %1-bak
structEventCodes.rule.two = 13;                 %2-bak
structEventCodes.cue.match = 21;
structEventCodes.cue.mismatch = 22;
structEventCodes.cue.debug = 91;                %error occured in cue
structEventCodes.ITI = 30;
structEventCodes.response.correct = 41;
structEventCodes.response.incorrect = 42;
structEventCodes.response.no_response = 43;
structEventCodes.response.debug = 92;           %error occured in response
structEventCodes.rest = 50;
structEventCodes.debug = 93;                    %general error occured

%**************************************************************************
% Algorithm
%**************************************************************************

if DEBUG_FORCE_1024_768
    intTextSize = 28;
    arrPolynomial = [-0.7 370];
end

%% Parse inputs
if nargin<1 || isempty(subject_ID)
    subject_ID = input('Subject ID: ');
end
if nargin<2 || isempty(sub_session)
    sub_session = input('Session type? 0=practice, 1=behave, 2=fMRI :   ');
end
switch sub_session
    case 0 % self paced practice
        boolIsFmri = false;
        play_instructions = true;
        InputDevice = -1;
        TriggerDevice = -1;
        TriggerWaitSecs = 0;
        TaskWaitSecs = 2;
    case 1 % behave
        boolIsFmri = false;
        play_instructions = true;
        InputDevice = -1;
        TriggerDevice = -1;
        TriggerWaitSecs = 0;
        TaskWaitSecs = 2;
    case 2 % fMRI
        boolIsFmri = true;
        play_instructions = false;
        %prompt for input device
        if nargin<3 || isempty(InputDevice)
            InputDevice = check_device('response');
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
                    TriggerDevice = check_device('ttl');
                case {2,4}%via Serial
                    TriggerDevice = create_serial_trigger([],SerialTrigger);
                    disp('created trigger device');
            end
        end
        %Set trigger wait times: only for task triggers scanner
        switch TriggerMode
            case {1,2}%task triggers scanner
                %trigger wait time
                if nargin<6
                    TriggerWaitSecs = input('How many seconds to wait before triggering? ');
                elseif isempty(TriggerWaitSecs) || ~isnumeric(TriggerWaitSecs)
                    TriggerWaitSecs = str2double(TriggerWaitSecs);
                    TriggerWaitSecs(isnan(TriggerWaitSecs)) = 0;
                end
            case {3,4}%scanner triggers task
                TriggerWaitSecs = 0;
        end
        %prompt for task wait time
        if nargin<7
            TaskWaitSecs = input('How many seconds to wait before starting the task? ');
        elseif isempty(TaskWaitSecs) || ~isnumeric(TaskWaitSecs)
            TaskWaitSecs = str2double(TriggerWaitSecs);
            TaskWaitSecs(isnan(TaskWaitSecs)) = 0;
        end
end

%% Construct filename and directories
if boolIsFmri
    strFilename = [strStudy, num2str(subject_ID, '%03i'), '_', ...
                   strFmriPostfix];
    dirOutput = fullfile(packagedir,strFmri);
else
    strFilename = [strStudy, num2str(subject_ID, '%03i'), '_', ...
                   strBehavePostfix];
    dirOutput = fullfile(packagedir,strBehave);
end
dirCode = fullfile(packagedir,strCode);

addpath(dirCode);

%overwrite protection
if exist(fullfile(dirOutput,[strFilename,'.mat']), 'file')
    %file exist, create new filename that doesn't collide with existing
    %files
    intCount = 2;
    strFilename = [strFilename,'_'];
    while exist(fullfile(dirOutput,[strFilename,num2str(intCount),'.mat']), 'file')
        intCount = intCount +1;
    end
    strFilename = [strFilename,num2str(intCount)];
    
    fprintf('\nWarning: Found existing output file. Will append "_%i" to filename\n\n', intCount)
        
    clear intCount
end

%record history
History = fnGetHistory('script', mfilename, 'version', SCRIPT_VER);

%% Initialize the log file
%
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

%% Initialize the data structure

%construct general information fields
Data.subjectID = [strStudy,num2str(subject_ID,'%03i')];

%get the block structure
if boolIsFmri
    arrMyBlocks = arrFmriBlockStructure;
else
    arrMyBlocks = arrBehaveBlockStructure;
end

%check that block structure is valid
arrCheckedFilesString = '';     %will be consumed after images are loaded
for i = 1:size(arrMyBlocks,1)
    for j = 1:size(arrMyBlocks,2)
        if isempty(arrMyBlocks{i,j}), continue; end     %don't process empty cells
        
        intTrialType = arrMyBlocks{i,j}{1};
        arrTrialOrderString = arrMyBlocks{i,j}{2};
        
        %check trial type
        if intTrialType == 3, continue;     %rest, ignore trial order string
        elseif ~any(intTrialType == [0,1,2])
            error('Unknown trial type %i defined for block %i mini-block %i', ...
                  intTrialType, i, j);
        end
        
        %loop through trials
        for k = 1:length(arrTrialOrderString)
            strTrial = arrTrialOrderString(k);
            
            %check if this file has been verified
            if any(strfind(arrCheckedFilesString,strTrial)), continue; end
            
            %verify that it exists
            IMG_CHECK = find(cell2mat(cellfun(@(x) exist(fullfile(...
                packagedir,strResource,[strTrial,x]),'file'),...
                targetImgFormats,'un',0)),1);
            if isempty(IMG_CHECK)
                error('Failed to find image %s for block %i mini-block %i trial %i', ...
                      strTrial, i, j, k);
            else
                arrCheckedFilesString = [arrCheckedFilesString,strTrial];
                clear IMG_CHECK;
            end
        end
    end
end

%construct trial structure
myTrial.block = 0;
myTrial.miniblock = 0;
myTrial.trial = 0;
myTrial.type = 0;
myTrial.cue = '';
myTrial.is_match = false;
myTrial.key_pressed = '';
myTrial.acc = 0;
myTrial.rt = 0;
myTrial.durations.cue = 0;
myTrial.durations.iti = 0;
myTrial.onsets.block = 0;
myTrial.onsets.miniblock = 0;
myTrial.onsets.cue = 0;
myTrial.onsets.iti = 0;
myTrial.event_codes = [];

%construct block cell matrix
%note: each row is a block, each column is a trial
%note: the block structure in the data is stored in <block x trial>
%format, ignoring mini-blocks. All mini-blocks are concatenated
%together, and all trials re-referenced to trials since block onset.
%Also, rest blocks are counted as having 1 trial.
for i = 1:size(arrMyBlocks,1)
    %count how many trials are in this block
    intTrailCount = 0;
    for j = 1:size(arrMyBlocks,2)
        if isempty(arrMyBlocks{i,j}), continue; end     %don't process empty cells
        
        intTrialType = arrMyBlocks{i,j}{1};
        arrTrialOrderString = arrMyBlocks{i,j}{2};
        
        %check trial type
        if intTrialType == 3
            intTrailCount = intTrailCount +1;
        else
            intTrailCount = intTrailCount + length(arrTrialOrderString);
        end
    end
    
    Data.matrix(i,1:intTrailCount) = {myTrial};
end
clear i j k myTrial intTrialType arrTrialOrderString strTrial intTrailCount

%% Initialize screen

%open main screen
%note: opens the highest device number, which is the secondary monitor if
%it exists
if DEBUG_FORCE_1024_768
    [ptrWindow, arrWindowSize] = Screen('OpenWindow', max(Screen('Screens')), arrBackground, [0 0 1024 768]);
elseif ~DEBUG_FORCE_1024_768 && DEBUG
    [ptrWindow, arrWindowSize] = Screen('OpenWindow', max(Screen('Screens')), arrBackground, [0 0 800  600]);
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

%% Adjust operating environment
Priority(1);
HideCursor();
%rng(subject_ID);
%cleanupObj = onCleanup(@() myCleanup(dirCode));

%% Initialize screen textures
%load all images to structure array
structImages.filename = '';
structImages.pointer = 0;
structImages.size = [];
structImages.destination = [];
for i = 1:length(arrCheckedFilesString)
    %load the image
    IMG_CHECK = find(cell2mat(cellfun(@(x) exist(fullfile(...
        packagedir,strResource,[arrCheckedFilesString(i),x]),'file'),...
        targetImgFormats,'un',0)),1);
    if isempty(IMG_CHECK)
        error('Failed to load image %s', arrCheckedFilesString(i));
    else
        dataImage = imread(fullfile(packagedir,strResource,...
            [arrCheckedFilesString(i),targetImgFormats{IMG_CHECK}]));
    end
    
    %construct the destination rectangle
    %note: scaling is specified here and done during screen draw
    arrSize = [0,0,size(dataImage,1),size(dataImage,2)];
    arrDestination = CenterRect(arrSize .* dblImageScale, arrWindowSize);
    
    %construct the texture in OpenGL
    ptrTexture = Screen('MakeTexture', ptrWindow, dataImage);
    
    %save pointer into structure
    if isempty(structImages(end).filename)
        structImages(1).filename = arrCheckedFilesString(i);
        structImages(1).pointer = ptrTexture;
        structImages(1).size = arrSize;
        structImages(1).destination = arrDestination;
    else
        structImages(end+1).filename = arrCheckedFilesString(i);
        structImages(end).pointer = ptrTexture;
        structImages(end).size = arrSize;
        structImages(end).destination = arrDestination;
    end
end

%load all textures to VRAM
intSuccess = Screen('PreloadTextures', ptrWindow);
if intSuccess ~= 1
    warning('Failed to pre-load all textures');
end

clear i arrCheckedFilesString dataImage arrSize arrDestination ptrTexture intSuccess

%% Display instructions
if play_instructions
    DisplayInstructions(ptrWindow,boolUseMirroredText,InputDevice,arrWindowSize);
end
clear strMessage* boolKeyPress arrKeys intKey

%% Remind the subject about the 0-back target block
if boolIsFmri
    idxZeroTarget = strfind([structImages.filename], strTargetFile);
    Screen('DrawTexture', ptrWindow, structImages(idxZeroTarget).pointer,...
        [], structImages(idxZeroTarget).destination);
    Screen('Flip',ptrWindow);
    KbWait(-1);
end

%% Run trial blocks
for intBlock = 1:size(arrMyBlocks,1)
    %reset KbCheck filter
    DisableKeysForKbCheck([]);
    
    %display pre-block message
    %note: this notifies both the subject and the operator that the
    %task is ready. The subject should be prepared to start the task at
    %any time, and the operator should make sure that the TTL pulses
    %start sending AFTER this message has been shown, otherwise the
    %task won't be ready for it.
    if intBlock == 1
        strMessage = 'Get Ready!';
    elseif intBlock>1 && ~boolIsFmri
        strMessage = 'Press any key to proceed to the next block';
    else
        strMessage = sprintf('Get Ready for Block %d',intBlock);
    end
    Screen('TextSize', ptrWindow, intFixationSize);
    DrawFormattedText(ptrWindow, strMessage,'center','center',[],[],boolUseMirroredText);
    Screen('Flip', ptrWindow);
    
    % Trigger mode in fMRI
    if isnumeric(TriggerDevice) && TriggerDevice>0
        TF = true;
    elseif ischar(TriggerDevice) && ~isempty(TriggerDevice)
        TF = true;
    else
        TF = false;
    end
    
    %write start of block code to port
    structEventCodes.block_onset = intBlock;
    
    %start counting trials
    intTrialCount = 0;

    for intMiniblock = 1:size(arrMyBlocks,2)
        clear worksheet;
        %note: fixation is still shown
        
        if isempty(arrMyBlocks{intBlock,intMiniblock}), continue; end     %don't process empty cells
        
        %get trial type definition and trial order
        intTrialType = arrMyBlocks{intBlock,intMiniblock}{1};
        arrTrialOrderString = arrMyBlocks{intBlock,intMiniblock}{2};
        
        %setup trial information by trial type
        %note: intOffset is used to reference previous trials
        switch intTrialType
            case 0  %0-back
                strRule = 'Rule I\n\n0 back';
                intOffset = 0;
                myRuleEventCode = structEventCodes.rule.zero;
            case 1  %1-back
                strRule = 'Rule II\n\n1 back';
                intOffset = 1;
                myRuleEventCode = structEventCodes.rule.one;
            case 2  %2-back
                strRule = 'Rule III\n\n2 back';
                intOffset = 2;
                myRuleEventCode = structEventCodes.rule.two;
            case 3 % rest
                %show fixation
                %DrawFormattedText(ptrWindow, 'x','center',polyval(arrPolynomial,intTextSize));
                DrawFormattedText(ptrWindow,'x','center','center');
                [timeRestOnset, timeRestFlip] = Screen('Flip', ptrWindow, PredictVisualOnsetForTime(ptrWindow, timeDeadline));
                
                %write rest onset code to port
                
                %increment trial count
                intTrialCount = intTrialCount +1;
                
                %save information to data structure
                Data.matrix{intBlock,intTrialCount}.block = intBlock;
                Data.matrix{intBlock,intTrialCount}.miniblock = intMiniblock;
                Data.matrix{intBlock,intTrialCount}.trial = 0;
                Data.matrix{intBlock,intTrialCount}.type = intTrialType;
                Data.matrix{intBlock,intTrialCount}.cue = 'REST';
                Data.matrix{intBlock,intTrialCount}.is_match = false;
                Data.matrix{intBlock,intTrialCount}.key_pressed = '';
                Data.matrix{intBlock,intTrialCount}.acc = 0;
                Data.matrix{intBlock,intTrialCount}.rt = 0;
                Data.matrix{intBlock,intTrialCount}.durations.cue = 0;
                Data.matrix{intBlock,intTrialCount}.durations.iti = 0;
                Data.matrix{intBlock,intTrialCount}.onsets.block = timeBlockOnset;
                Data.matrix{intBlock,intTrialCount}.onsets.miniblock = timeRestOnset;
                Data.matrix{intBlock,intTrialCount}.onsets.cue = 0;
                Data.matrix{intBlock,intTrialCount}.onsets.iti = 0;
                Data.matrix{intBlock,intTrialCount}.event_codes = structEventCodes.rest;
                
                %write trial to CSV
                cell2csv(FILEPATH,{intBlock,intMiniblock,0,intTrialType,...
                    'REST',0,'',0,0,0,0,timeBlockOnset,timeRestOnset,...
                    0,0,num2str(structEventCodes.rest)},',','a+');
                
                %push deadline back and continue
                timeDeadline = timeDeadline + dblRestDuration;
                %print resting period to the command window
                %fprintf('[Block %i Mini-block %i-1] REST\n', intBlock, intMiniblock)
                continue;
            otherwise % unrecognized block
                if DEBUG
                    fprintf('[DEBUG] failed to parse trial type, skipping\n')
                end
                continue;
        end
        
        % Trigger at the first mini-block --------------------------------
        if intMiniblock==1 && any(intTrialType==[0,1,2])
            if boolIsFmri && TF %if using the scanner
                switch TriggerMode
                    case 1%task triggers scanner, USB
                        % Not Implemented
                        Screen('CloseAll');
                        ShowCursor;
                        error('task triggers scanner via USB: Not implemented\n');
                    case 2%task triggers scanner, serial port
                        % User must manually advance to the next screen which sends
                        % a trigger after TriggerWaitSecs
                        DefaultKeyBoardTrigger(-1);
                        %wait for TriggerWaitSecs
                        if TriggerWaitSecs>0
                            WaitSecs(TriggerWaitSecs);
                        end
                        %trigger scan first, then wait for tasks
                        timeBlockOnset=serial_trigger_scan();
                        fprintf('triggered scan at %.3f\n',GetSecs());
                    case 3%scanner triggers task, USB
                        timeBlockOnset=KbTriggerWait(TTLTrigger,TriggerDevice);
                        DisableKeysForKbCheck(TTLTrigger); % So trigger is no longer detected
                    case 4%scanner triggers taks, serial port
                        % Not Implemented
                        Screen('CloseAll');
                        ShowCursor;
                        error('scanner triggers task via serial port: Not implemented\n');
                end
            else% manually start the task
                timeBlockOnset=DefaultKeyBoardTrigger(TriggerDevice);
            end
            
            % task wait
            if TaskWaitSecs>0
                %show fixation screen after the trigger
                DrawFormattedText(ptrWindow,'x','center','center');
                Screen('Flip', ptrWindow);
                % advance the block onset time to the time after wait
                timeDeadline = timeBlockOnset+TaskWaitSecs;
            else
                timeDeadline = timeBlockOnset;
            end
        end

        %Instruction-------------------------------------------------------
        
        %render message
        DrawFormattedText(ptrWindow, strRule,'center','center',[],[],boolUseMirroredText);
        
        %block until message onset
        [timeRuleOnset,tmp,timeRuleFlip] = Screen('Flip', ptrWindow, PredictVisualOnsetForTime(ptrWindow, timeDeadline));
        
        %write rule onset code to port
        
        %set trial onset
        timeDeadline = timeDeadline + dblRuleDuration;
        
        %set miniblock onset time
        %note: this is set to ideal value and will be updated when the
        %actual flip occurs
        timeMiniblockOnset = timeDeadline;
        
        %fprintf('[Block %i Mini-block %i-0] RULE\n', intBlock, intMiniblock)
        
        for intTrial = 1:length(arrTrialOrderString)
            arrEventCodes = [];
            
            %find the texture
            strImage = arrTrialOrderString(intTrial);
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
                [timeCueOnset, timeCueFlip] = Screen('Flip', ptrWindow, PredictVisualOnsetForTime(ptrWindow, timeDeadline));
                
                %increment trial count
                intTrialCount = intTrialCount +1;
                
                %save information to data structure
                %note: durations are ideal
                Data.matrix{intBlock,intTrialCount}.block = intBlock;
                Data.matrix{intBlock,intTrialCount}.miniblock = intMiniblock;
                Data.matrix{intBlock,intTrialCount}.trial = intTrial;
                Data.matrix{intBlock,intTrialCount}.type = intTrialType;
                Data.matrix{intBlock,intTrialCount}.cue = 'ERROR';
                Data.matrix{intBlock,intTrialCount}.is_match = false;
                Data.matrix{intBlock,intTrialCount}.key_pressed = '';
                Data.matrix{intBlock,intTrialCount}.acc = 0;
                Data.matrix{intBlock,intTrialCount}.rt = 0;
                Data.matrix{intBlock,intTrialCount}.durations.cue = dblCueDuration;
                Data.matrix{intBlock,intTrialCount}.durations.iti = dblITIDuration; 
                Data.matrix{intBlock,intTrialCount}.onsets.block = timeBlockOnset;
                Data.matrix{intBlock,intTrialCount}.onsets.miniblock = timeMiniblockOnset;
                Data.matrix{intBlock,intTrialCount}.onsets.cue = timeCueOnset;
                Data.matrix{intBlock,intTrialCount}.onsets.iti = 0;
                Data.matrix{intBlock,intTrialCount}.event_codes = structEventCodes.cue.debug;

                %write trial to CSV
                cell2csv(FILEPATH,{intBlock,intMiniblock,intTrial,...
                    intTrialType,'ERROR',0,'',0,0,dblCueDuration,...
                    dblITIDuration, timBBlockOnset,...
                    timeMiniblockOnset,timeCueOnset,0,...
                    num2str(structEventCodes.cue.debug)},',','a+');
                
                %set next trial onset
                timeDeadline = timeDeadline + dblCueDuration + dblITIDuration;
                %print error to command window
                %fprintf('[Block %i Mini-block %i-%2i] ERROR\n', intBlock, intMiniblock, intTrial)
                
                continue;
            end
           
            %draw texture to screen
            Screen('DrawTexture', ptrWindow, structImages(idxTexture).pointer, [], structImages(idxTexture).destination);

            %determine correct response
            if intOffset == 0                                    %zero back
                if strcmpi(strImage,strTargetFile)
                    myAcceptedResponse = arrMatchResponse;
                    myCueEventCode = structEventCodes.cue.match;
                else
                    myAcceptedResponse = arrMismatchResponse;
                    myCueEventCode = structEventCodes.cue.mismatch;
                end
            else                                              %one/two back
                if (intOffset < intTrial) && strcmpi(strImage,arrTrialOrderString(intTrial - intOffset))
                    myAcceptedResponse = arrMatchResponse;
                    myCueEventCode = structEventCodes.cue.match;
                else
                    myAcceptedResponse = arrMismatchResponse;
                    myCueEventCode = structEventCodes.cue.mismatch;
                end
            end
            
            if DEBUG && (GetSecs >= timeDeadline)
                fprintf('[DEBUG] cue is late\n')
            end
            
            %block until cue onset
            [timeCueOnset,tmp,timeCueFlip] = Screen('Flip', ptrWindow, PredictVisualOnsetForTime(ptrWindow, timeDeadline));

            %write cue onset code to port
            arrEventCodes(end+1) = myCueEventCode;
            
            %update miniblock onset time if this is first trial
            if intTrial == 1
                timeMiniblockOnset = timeCueOnset;
            end
            
            %calculate ITI onset
            timeDeadline = timeDeadline + dblCueDuration;
            boolShowITI = true;
            
            %render ITI
            %DrawFormattedText(ptrWindow, num2str(intTrialType),'center',polyval(arrPolynomial,intTextSize));
            DrawFormattedText(ptrWindow, num2str(intTrialType),'center','center');
            
            %get flip duration
            dblFlipDuration = Screen('GetFlipInterval', ptrWindow);
            
            %start response loop
            %note: actual duration is decreased by pre cue reserve to give
            %ample time for trial preperation in the case of no response
            timeResponse = 0;
            boolResponseGiven = false;
            while GetSecs < (timeCueOnset + dblCueDuration + dblITIDuration - dblPreCueReserve/1000)
                %check if ITI should be shown
                if boolShowITI && (GetSecs >= timeDeadline + dblFlipDuration)   %add flip duration to account for cue flip; helps make cue duration closer to ideal
                    %show fixation
                    [timeITIOnset, timeITIFlip] = Screen('Flip', ptrWindow);
                    
                    boolShowITI = false;
                end
                
                %check if loop should be terminated or response check
                %skipped
                if ~boolShowITI && boolResponseGiven, break;
                elseif boolResponseGiven, continue; end
                
                %check response
                [boolKeyPress,timeResponse,arrKeys] = KbCheck(InputDevice);
                if boolKeyPress
                    intKey = find(arrKeys);

                    if any(intKey(1) == [arrMatchResponse,arrMismatchResponse])
                        boolResponseGiven = true;
                    end
                else
                    intKey = [];
                end
            end
            
            %process the response------------------------------------------

            %calculate RT
            if ~boolResponseGiven    %no response
                dblRT = 0;
            else
                dblRT = timeResponse - timeCueOnset;
            end

            %parse ACC and event code
            if (dblRT > 0) && any(intKey(1) == myAcceptedResponse)    
                %correct
                intACC = 1;
                myResponseEventCode = structEventCodes.response.correct;
            elseif (dblRT > 0)                                        
                %incorrect
                intACC = 0;
                myResponseEventCode = structEventCodes.response.incorrect;
            elseif dblRT == 0                                               	
                %no response
                intACC = -1;
                myResponseEventCode = structEventCodes.response.no_response;
            else
                %something went wrong and couldn't parse response correctly
                intACC = -2;
                myResponseEventCode = structEventCodes.response.debug;
            end
            
            %--------------------------------------------------------------

            %write response code to port
            arrEventCodes(end+1) = myResponseEventCode;
            
            %calculate next cue onset
            timeDeadline = timeDeadline + dblITIDuration;
            
            %increment trial count
            intTrialCount = intTrialCount +1;

            %parse response key
            if isempty(intKey)
                myKey = '';
            else
                myKey = KbName(intKey);
            end

            %save information to data structure
            %note: all times in seconds
            %note: the ITI duration will be an estimate since the next cue
            %flip is unavailable at this moment in time
            Data.matrix{intBlock,intTrialCount}.block = intBlock;
            Data.matrix{intBlock,intTrialCount}.miniblock = intMiniblock;
            Data.matrix{intBlock,intTrialCount}.trial = intTrial;
            Data.matrix{intBlock,intTrialCount}.type = intTrialType;
            Data.matrix{intBlock,intTrialCount}.cue = strImage;
            Data.matrix{intBlock,intTrialCount}.is_match = all(myAcceptedResponse == arrMatchResponse);
            Data.matrix{intBlock,intTrialCount}.key_pressed = myKey;
            Data.matrix{intBlock,intTrialCount}.acc = intACC;
            Data.matrix{intBlock,intTrialCount}.rt = dblRT;
            Data.matrix{intBlock,intTrialCount}.durations.cue = (timeITIOnset - timeCueOnset);
            Data.matrix{intBlock,intTrialCount}.durations.iti = (timeDeadline - timeITIOnset); 
            Data.matrix{intBlock,intTrialCount}.onsets.block = timeBlockOnset;
            Data.matrix{intBlock,intTrialCount}.onsets.miniblock = timeMiniblockOnset;
            Data.matrix{intBlock,intTrialCount}.onsets.cue = timeCueOnset;
            Data.matrix{intBlock,intTrialCount}.onsets.iti = timeITIOnset;
            Data.matrix{intBlock,intTrialCount}.event_codes = arrEventCodes;

            %write trial to CSV
            cell2csv(FILEPATH,{intBlock,intMiniblock,intTrial,...
                intTrialType,strImage,all(myAcceptedResponse == arrMatchResponse),...
                myKey,intACC,dblRT,(timeITIOnset-timeCueOnset),...
                (timeDeadline-timeITIOnset),timeBlockOnset,timeMiniblockOnset,...
                timeCueOnset,timeITIOnset,num2str(arrEventCodes)},',','a+');

            %report to command window
%             fprintf('[Block %i Mini-block %i-%2i] Rule: %i | Cue: %s | IsMatch: %i | ACC: %2i | RT: %4.0f ms | Key: %s\n', ...
%                 intBlock, intMiniblock, intTrial, intTrialType, strImage, all(myAcceptedResponse == arrMatchResponse), intACC, dblRT * 1000, myKey);
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
                    temp1 = arrTrialOrderString(intTrial - intOffset);
                    temp2 = strcmpi(strImage,arrTrialOrderString(intTrial - intOffset));
                end
%                 fprintf('[DEBUG] Last cue: %s | This cue: %s | intOffset < intTrial: %i | strcmpi: %i\n', temp1, strImage, intOffset < intTrial, temp2)
            end
        end
    end
    
    %extend deadline to end of post-trial duration
    timeDeadline = timeDeadline + dblPostTrialDuration;
    
    %check if there are more blocks to run
    if intBlock ~= size(arrMyBlocks,1)                          %more to go
        %display progress
        if boolIsFmri
            strMessage = [ ...
                'You just finished block ' num2str(intBlock) ' of ' num2str(size(arrMyBlocks,1)) '\n\n\n' ...
                'The operator will let you know when the next block begins'];
            %show the message
            DrawFormattedText(ptrWindow, strMessage, 'center', 'center', [],[],boolUseMirroredText);
            Screen('Flip', ptrWindow, PredictVisualOnsetForTime(ptrWindow, timeDeadline));
            WaitSecs(5);% prepare for next run
        end
    else                                                        %last block
        strMessage = [ ...
            'Congratulations! You finished the task!\n\n\n' ...
            'Thank you for your participation' ...
            ];
        
        %show the message
        DrawFormattedText(ptrWindow, strMessage, 'center', 'center', [],[],boolUseMirroredText);
        Screen('Flip', ptrWindow, PredictVisualOnsetForTime(ptrWindow, timeDeadline));
        
        WaitSecs(3);
    end
end

%save mat file
if DEBUG
    save(fullfile(dirOutput,[strFilename,'.mat'])); %save everything
else
    save(fullfile(dirOutput,[strFilename,'.mat']), 'Data', 'History');
end
DisableKeysForKbCheck([]);%remove any disabled keys
Screen('CloseAll');%close the window
ShowCursor();%show mouse cursor
end