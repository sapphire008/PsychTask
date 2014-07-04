function [VAR,data] = MID_OSX(subject_ID,block_num,baseline_RT,...
    InputDevice,TriggerMode,TriggerDevice)
%
% [var,data] = MID_OSX(subject_ID,block_num,baseline_RT,InputDevice,TriggerMode,TriggerDevice,TriggerWaitSecs)
%
% Money Incentive Delay (MID) task
% Inputs:
%       subject_ID: subject identifier ('char')
%       block_num: run number ('char'), either enter as the number or the
%                  name of the block
%           Options for block_num:
%               1).Block 1 (42 trials)
%               2).Block 2 (48 trials)
%               3).Practice (42 trials)
%               4).Demo (12 trials)
%               5).Debug (3 trials)
%       baseline_RT: response window to start off with ('numeric')
%       play_instructions: display instruction screen; will be force off
%                          if using scanner or in fMRI run ('logical')
%       InputDevice: device number for response input, default -1, that is,
%                    to use the default device/keyboard. Forced default in
%                    demo, practice, and debug ('numeric')
%       TriggerMode: mode of trigger device. input as a numeric with the
%                 following options:
%                 1). Task triggers scanner via USB;
%                 2). Task triggers scanner via Serial Port;
%                 3). Scanner triggers task via USB;
%                 4). Scanner triggers task via Serial Port.
%                 Only relevent for fMRI mode (sub_session = 2).
%       TriggerDevice: device number for TTL pulse trigger, default -1.
%                    Forced default in demo, practice, and debug
%                    ('numeric') OR device path for serial port device to
%                    allow the script to trigger the scanner
%
% If any input is missing, user will be prompted
%
% DETAILS:
% The MID task is set up  8 seconds each trial + a variable ITI of
% 2/4/6 seconds.
% TR 1 = Cue
% TR 2 = Fixation
% TR 3 = Target
% TR 4 = Feedback
% TR 5~7 = ITI
%
% BLOCK LENGTHS (with TR2 scans):
%
%   Block 1: 262 TR     (42 trials, 524 secs)
%
%   Block 2: 298 TR     (48 trials, 596 secs)
%
% Cue conditions, categorized 1-6:
% 1 = low square    (-$0.00)
% 2 = med square    (-$1.00)
% 3 = high square   (-$5.00)
% 4 = low circle    (+$0.00)
% 5 = med cirlce    (+$1.00)
% 6 = high circle   (+$5.00)

% Modified by David (Drew) Fegen M.D./Ph.D., May 2013
% Modified by Edward Cui, August 2013
% Modified by Edward Cui, October 2013 to allow the script to trigger the
%             scanner, in addition to allowing the scanner to trigger the
%             script in the original design
% Modified by Edward Cui, February 2014 that allows the setting of trigger
%             mode, trigger wait time, and task wait time

%% Secondary variables that can be adjusted by user
VAR.TTLTrigger = KbName('n');%TTL trigger input
VAR.SerialTrigger = '[t]';%character that triggers the scanner
VAR.allowed_keys = {'1!','2@','3#','4$','5%','space','6^','7&','8*',...
    '9(','0)','1','2','3','4','5','6','7','8','9','0','*','/'};%keys allowed for response
VAR.force_off_instructions = true;%force turning off instruction screen during scanning
DEBUG = false;
DEBUG_input = false;% debug mode or not; will stop and return at the setup step
target_response_keyboard_name = 'Current';%use this string to locate response device
target_ttl_keyboard_name = 'ttlpulse_device_product_name';%enter some jibberish so that the script will list all the devices

%% EXPERIMENT VARIABLES:
% Variables contained within the 'var' data object, for ease of variable
% passing. Maintains experimental state.
% Data specific variables are stored within the data object, this
% object is for those variables recorded from the subject or relevant
% to the writing out of the data. This also allows someone to save a
% .mat instead of csv of only the relevant data.

% leadin/leadout times:
VAR.leadin = 12.0;% seconds before the first trial begins:
VAR.leadout = 8.0;% seconds after the end of the last trial
TriggerWaitSecs = 0; %time to wait between the wait screen of the task
TaskWaitSecs = 6;%delay start of the task 6 for regular epi, 16 for mux 2, 24 for mux 3

%                     the first trigger to be sent to the scanner; only
%                     relevant if TriggerDevice is a path to serial port
%                     device. Use -1 to trigger manually (will wait
%                     indefinitely until a key is pressed) ('numeric')

% durations of each phase
VAR.dur.cue = 2.0;
VAR.dur.delay = 2.0;
VAR.dur.target = 2.0;
VAR.dur.feedback = 2.0;

% pseudorandom itis for all blocks
% itis are 2,4,6 seconds
VAR.itis.b1 = [6 6 6 2 4 4 6 4 6 4 6 2 2 6 2 4 4 6 2 4 6 6 4 2 4 6 4 ...
    2 2 6 6 6 2 2 4 4 2 4 2 2 2 4];
VAR.itis.b2 = [6 4 2 2 4 4 6 2 2 6 6 4 6 4 2 6 2 6 4 6 2 6 6 4 2 4 6 ...
    2 6 2 4 6 6 4 2 4 4 4 2 4 4 4 6 2 6 2 2 2];
VAR.itis.practice = [6 2 2 2 4 4 6 2 4 2 6 4 2 2 4 4 4 6 6 4 6 6 2 4 ...
    6 4 2 2 4 2 6 4 2 6 4 4 6 6 6 2 6 2];%Edward
VAR.itis.demo = [6 2 2 2 2 2 2 2 2 2 2 2];%Drew
VAR.itis.debug = [2 2 2];

% pseudorandom cue conditions for all blocks
VAR.cues.b1 = [1 2 2 4 4 6 4 4 3 2 5 1 5 5 6 3 4 2 1 2 6 3 6 5 3 2 5 ...
    1 5 6 1 4 2 4 6 1 6 3 5 3 3 1];
VAR.cues.b2 = [4 2 5 1 6 2 4 1 4 3 2 6 2 4 3 2 3 3 6 6 3 2 1 3 4 5 2 ...
    5 1 5 6 5 3 3 6 5 5 2 1 6 4 4 1 4 5 1 1 6];
VAR.cues.practice = [3 6 5 1 2 4 6 1 3 4 5 1 1 4 6 1 1 2 2 3 4 5 2 5 6 ...
    1 4 3 3 2 6 2 3 6 3 2 4 5 5 4 6 5];
VAR.cues.demo = [3 4 6 1 3 2 5 5 1 6 2 4];
VAR.cues.debug = [3 1 2];

%change this reference text size depending on how big your screen is!
VAR.cuetextsize = 60;%size of the texts under the cues
VAR.textsize = 50;%size of the text in general (Instructions, etc.)
VAR.textcolor = 225;%color of all the objects
VAR.font = 'Helvetica';%font of money display
VAR.bkg_color = 0;%background color
VAR.value_extension = '.00';%show cents after money amount
VAR.display_totals = 0;% displaying total win/lose at the end
VAR.rt_change = .020;%change rate of RT
VAR.filepath.main = fileparts(mfilename('fullpath'));
VAR.filepath.scripts = fullfile(VAR.filepath.main,'scripts');
addpath(VAR.filepath.scripts);%add the path
VAR.filepath.data = fullfile(VAR.filepath.main,'data');
VAR.cue_pen = 6;%brush size to draw the cues on the screen
VAR.cue_box = [0 0 250 250];%position of the cues
VAR.targetname = fullfile(VAR.filepath.scripts,'tri_up.png');%target img
VAR.targetrect = [0 0 200 200];%position of the target
VAR.target_jitter = [0.25 0.75];
VAR.amount_below_cue = 1;%whether or not show value below the figure
VAR.response_window = 1;%response window, currently given 1 second.
VAR.tr = 2.0; %duration of each scan
VAR.run_time = datestr(now);%current time when the script is run
VAR.calibrations = cell(1,6);%store calibrated durations of target
VAR.autobaseline = 0;
VAR.shift_ind = 0;%do not shift the trial index recorded in the .csv file
VAR.DefaultKeyboardDevice = get_device_osx([],[],[],false);%default keyboard device number.

%% SCREEN SETUP:
% if max(Screen('Screens'))>0 %dual screen
%     %dual=get(0,'MonitorPositions');
%     %resolution = [0,0,dual(2,3),dual(2,4)];
%     resolution = get(max(Screen('Screens')),'ScreenSize');
% elseif max(Screen('Screens'))==0 % one screen
%     resolution = get(0,'ScreenSize') ;
% end
% VAR.scrX = resolution(3);% get horizontal dimension of the screen
% VAR.scrY = resolution(4);% get vertical dimension of the screen

%% SUBJECT/BLOCK CONSOLE PROMPT:
if nargin<1 || isempty(subject_ID)
    subject_ID = input('Subject ID: ','s');
elseif isnumeric(subject_ID)
    subject_ID = num2str(subject_ID);
end
if nargin<2 || isempty(block_num)
    block_num = input('1.Block 1\n2.Block 2\n3.Practice\n4.Demo\n5.Debug\nWhich Block: ','s');
elseif isnumeric(block_num)
    block_num = num2str(block_num);
end
if nargin<3 || isempty(baseline_RT)
    baseline_RT = input('Baseline (ms): ');
elseif ischar(baseline_RT)
    baseline_RT = str2num(baseline_RT);
end
VAR.basert = baseline_RT/1000;

% inspect devcies base on run and trigger mode
switch lower(block_num)
    case {'block1','block 1','block_1','b1','1','block2','block 2','block_2','b2','2'}
        VAR.usescanner = true;
        % inspect input devices
        if nargin<4 || isempty(InputDevice)
            InputDevice = get_device_osx(target_response_keyboard_name,[],[],true);%check_device('response');
        end
        % inspect trigger device
        if nargin<5 || isempty(TriggerMode)
            % first ask the user which mode of triggering is used
            disp('Which mode of triggering is used?');
            TriggerMode = input([...
                '1). Task triggers scanner via USB;\n',...
                '2). Task triggers scanner via Serial Port;\n',...
                '3). Scanner triggers task via USB;\n',...
                '4). Scanner triggers task via Serial Port.\n']);
        end
        %Get device and trigger behaviors
        if nargin<6 || isempty(TriggerDevice)
            disp('asking trigger device');
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
                %                 if nargin<7
                %                     TriggerWaitSecs = input('How many seconds to wait before triggering? ');
                %                 elseif isempty(TriggerWaitSecs) || ~isnumeric(TriggerWaitSecs)
                %                     TriggerWaitSecs = str2double(TriggerWaitSecs);
                %                     TriggerWaitSecs(isnan(TriggerWaitSecs)) = 0;
                %                 end
            case {3,4}%scanner triggers task
                TriggerWaitSecs = 0;
        end
    otherwise
        VAR.usescanner = false;
        InputDevice = VAR.DefaultKeyboardDevice;
        TriggerDevice = VAR.DefaultKeyboardDevice;
        TriggerWaitSecs = 0;
        VAR.leadin = 2;
        VAR.leadout = 0;
end

%inspect block selection and adjust parameters based on block selection
% pass information to the 'data' structure according to block
switch lower(block_num)
    case {'block1','block 1','block_1','b1','1'}
        VAR.subjectID = [subject_ID,'_b1'];%subject ID, append block
        VAR.blocknumber = 'b1';%block number/name
        if VAR.force_off_instructions
            %force turning off instructions in case it is still on
            VAR.runinstructions = false;
        end
    case {'block2','block 2','block_2','b2','2'}
        VAR.subjectID = [subject_ID,'_b2'];
        VAR.blocknumber = 'b2';
        VAR.shift_ind = numel(VAR.cues.b1);
        %force turning off instructions in case it is still on
        if VAR.force_off_instructions
            VAR.runinstructions = false;
        end
    case {'practice','b3','b0','0','3'}
        VAR.subjectID = [subject_ID,'_practice'];
        VAR.blocknumber = 'practice';
        %reduce beginning and end wait time if in practice or demo
        VAR.runinstructions = true;
    case {'demo','-1','4'}
        VAR.subjectID = [subject_ID,'_demo'];
        VAR.blocknumber = 'demo';
        VAR.runinstructions = false;
    case {'debug','-2','5'}
        VAR.subjectID = [subject_ID,'_debug'];
        VAR.blocknumber = 'debug';
        VAR.runinstructions = false;
    otherwise
        VAR.subjectID = [subject_ID,'_',lower(block_num)];
        tmp = regexp(block_num,'(\d*)');
        VAR.blocknumber = ['b',char(tmp{1})];
        clear tmp;
        VAR.runinstructions = false;
end

VAR.cues = VAR.cues.(VAR.blocknumber);%pass cue sequences
VAR.itis = VAR.itis.(VAR.blocknumber);%pass iti sequences
%save subject specific information to 'data' structure
data = struct('cue_onset',[],'delay_onset',[],'target_onset',[],...%onsets
    'feedback_onset',[],...%onsets
    'cue_t',[],'target_t',[],...%durations
    'cues_vector',cellstr(''),'gains_vector',cellstr(''),...%task orders
    'calibration_vector',[],'calibration_current',[],...%task orders
    'wins_vector',[],'binned_rts',[],'rt',[],'key',[],...%results
    'total',0,'wins',cell('') ...%result
    );
data(1).total = 0;%make sure the data structure is size 1x1, not empty
% place holding the arrays in data structure
data = structfun(@(x) zeros(1,length(VAR.cues)),data,'un',0);
data.binned_rts = zeros(6,length(VAR.cues));
data.cues_vector = cell(1,length(VAR.cues));
data.gains_vector = cell(1,length(VAR.cues));
data.wins = cell(1,6);
data.total = 0;
clear N M;close all;

if DEBUG_input
    %disp(Priority);
    fprintf('InputDevice %d\n',InputDevice);
    fprintf('InputDeviceTTL %d\n',TriggerDevice);
    return%for debug
end
%% INITIALIZE SCREEN:
Priority(1);%set script execution to be the highest priority
HideCursor();%hide the cursor
%open a new window, default full screen
if DEBUG
    [Window,VAR.winrect] = Screen('OpenWindow',0,0,[0,0,800,600]);
else
    [Window,VAR.winrect] = Screen('OpenWindow',max(Screen('Screens')),0);
end
%read in target image and convert target image to OpenGL
VAR.target = Screen('MakeTexture',Window,imread(VAR.targetname));
%determine the poisition of the target
VAR.targetrect = CenterRect(VAR.targetrect,VAR.winrect);

% set text and window properties
Screen('FillRect',Window,VAR.bkg_color);
Screen('Flip',Window);
Screen('TextSize',Window,VAR.textsize);
Screen('TextFont',Window,VAR.font);

%% RUN THE INSTRUCTIONS:
if VAR.runinstructions
    Instructions(Window);
end

%% Set up Keyboard response
keysOfInterest = zeros(1,256);
keysOfInterest(KbName(VAR.allowed_keys))=1;
KbQueueCreate(InputDevice,keysOfInterest);
%% WAIT TO TRIGGER SCAN:
% Put up a "Get Ready" screen until the experimenter presses a button.
%Screen('TextSize',Window,50);
DrawFormattedText(Window,'Get ready!','center','center',225);
Screen('Flip',Window);

% Trigger mode in fMRI
if isnumeric(TriggerDevice) && TriggerDevice>0
    TF = true;
elseif ischar(TriggerDevice) && ~isempty(TriggerDevice)
    TF = true;
else
    TF = false;
end
%Drew: added - get the time of the first TTL pulse i.e. start of scan
% Trigger mode in fMRI
if VAR.usescanner && TF %if using the scanner,and trigger is not default -1
    switch TriggerMode
        case 1%task triggers scanner, USB
            % Not Implemented
            Screen('CloseAll');
            ShowCursor;
            error('task triggers scanner via USB: Not implemented\n');
        case 2%task triggers scanner, serial port
            % User must manually advance to the next screen which sends
            % a trigger after TriggerWaitSecs
            KbWait(VAR.DefaultKeyboardDevice,3);
            %DefaultKeyBoardTrigger(-1);
            if TriggerWaitSecs>0,WaitSecs(TriggerWaitSecs);end
            %trigger scan
            VAR.abs_start=serial_trigger_scan();
        case 3%scanner triggers task, USB
            VAR.abs_start=KbTriggerWait(VAR.TTLTrigger,TriggerDevice);
            DisableKeysForKbCheck(VAR.TTLTrigger); % So trigger is no longer detected
        case 4%scanner triggers taks, serial port
            % Not Implemented
            Screen('CloseAll');
            ShowCursor;
            error('scanner triggers task via serial port: Not implemented\n');
    end
else % If using the keyboard, manually advance; allow any key as input
    VAR.abs_start = KbWait(VAR.DefaultKeyboardDevice,3);%DefaultKeyBoardTrigger(TriggerDevice);%get current time in second
end


try%in case manually crashing the run
    %% SET END REFERENCE TIME:
    % ref_end is continually updated as the end time for various functions.
    % This, along with abs_start, allows for absolute timing of functions
    % and thus drift adjust on the ITI is extremely accurate.
    VAR.ref_end = VAR.abs_start;
    
    %% LEADIN:  Period before the onset of the first cue
    VAR = DisplayFixation(Window,VAR,[],0,VAR.leadin+TaskWaitSecs,'x');
    % correct for leadin delay
    if TaskWaitSecs>0
        VAR.abs_start = VAR.abs_start + TaskWaitSecs;
    end
    
    %% MAIN EXPERIMENT LOOP
    % Runs the experiment!
    KbQueueStart;
    for i = 1:length(VAR.itis)
        % This records the absolute onset time of trials:
        data.onset_t(i) = GetSecs()-VAR.abs_start+(TaskWaitSecs>0)*(i==1)*TaskWaitSecs;
        % Present the cue (2s):
        [VAR,data] = PresentCue(Window,VAR,data,i,VAR.dur.cue);
        % Present the delay (2s):
        [VAR,data] = DisplayFixation(Window,VAR,data,i,VAR.dur.delay,'x'); %Drew & Edward
        % Present the target (2s):
        [VAR,data] = PresentTarget(Window,VAR,data,i,VAR.dur.target,InputDevice);
        % Present the win/loss feedback (2s):
        [VAR,data] = PresentFeedback(Window,VAR,data,i,VAR.dur.feedback);
        % Present ITIs
        VAR = DisplayFixation(Window,VAR,[],0,VAR.itis(i),'x');
        
        % Calculate the possible drift by subtracting the ideal time
        % from the accumulated time of the trial. (Note:
        % the drift time is for all slides prior to the ITI)
        data.drifts(i) = GetSecs()-VAR.abs_start-data.onset_t(i)-...
            (VAR.dur.cue+VAR.dur.delay+VAR.dur.target+VAR.dur.feedback);
        
        % Write the partial data into the file. This way, if the experiment
        % breaks or ends for some reason, you will have data for every
        % completed trial at least:
        PartialParseData(VAR,data,i==1,i,VAR.shift_ind);%occurs during ITI
        
        
        %     % Display an ITI until the reference end time is reached (this is
        %     % how drift is corrected for):
        %     data.iti_t(i) = DisplayFixation(Window,var,'x');
    end
    
    %% LEADOUT ITI:
    VAR.ref_end = VAR.ref_end+VAR.leadout;
    VAR = DisplayFixation(Window,VAR,[],0,VAR.leadout,'x');
    %organize data
    VAR = orderfields(VAR);
    data = orderfields(data);
    save(fullfile(VAR.filepath.data,...
        ['MID_results_',VAR.subjectID,'_',datestr(now,'dd-mm-yyyy_HH-MM-SS'),'.mat']),'VAR','data');
    DisableKeysForKbCheck([]);%remove any disabled keys
    Screen('CloseAll');%close the window
    ShowCursor();%show the mouse cursor
    rmpath(VAR.filepath.scripts);
    clear GLOBAL TRIGGER MARKER;
    KbQueueFlush; KbQueueStop; KbQueueRelease;
    %display summary data
    fprintf('\n\n');
    disp(['Cumulative total:  $' num2str(data.total, '%#4.2f')]);
    positive_rts = data.rt(logical(data.wins_vector));
    disp(['Average Correct RT (ms):  ', num2str(nanmean(positive_rts(:))*1000)]);
    disp(['Average All RT (ms): ', num2str(nanmean(data.rt(:))*1000)]);
catch ERR% upon crashing
    DisableKeysForKbCheck([]);%remove any disabled keys
    Screen('CloseAll');%close the screen
    ShowCursor();%show mouse cursor
    clear GLOBAL TRIGGER MARKER;
    rmpath(VAR.filepath.scripts);
    KbQueueFlush; KbQueueStop; KbQueueRelease;
    rethrow(ERR);
end
end
