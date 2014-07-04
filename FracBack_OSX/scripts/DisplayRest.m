function T = DisplayRest(Duration,Text,TextSize,...
    TextColor,BackGroundColor,ptrWindow)
% Resting State cross-hair stimuli.
%
% Inputs:
%   Duration: duration of the crosshair. Specified when inserted to other
%             tasks. When running resting state, set to -1, which is
%             terminated by press any key on the keyboard
%
%   Text: text to be displayed. Default is a crosshair
%
%   TextSize, TextColor, BackGroundColor: parameters for display
%   
%   Window: Window object returned by Screen. Texts will be drawn directly
%           to the provided Window object. If not specified, will start a 
%           new window (when running Resting State)
%

% terminate immediately after the 
if nargin<1 || isempty(Duration)
    return;
end
if nargin<2 || (isempty(Text) && ~ischar(Text))
    Text = '+';
end
% parse inputs
if nargin<3 || isempty(TextSize)
    TextSize = 72;
end
if nargin<4 || isempty(TextColor)
    TextColor = 225;%default white
end
if nargin<5 || isempty(BackGroundColor)
    BackGroundColor = 0;%default black
end
TextFont = 'Arial';
if nargin<5 || isempty(ptrWindow)
    % set up screens
    fprintf('setting up screen\n');
    Priority(1);%give highest priority to the script
    HideCursor();% hide the distracting mouse cursor
    ptrWindow=Screen('OpenWindow', max(Screen('Screens')),0,[],32,2);
    % set stimulus parameters
    Screen('FillRect', ptrWindow, BackGroundColor);
    Screen('Flip', ptrWindow);
end
%set up screen parameters
Screen('TextSize',ptrWindow,TextSize);
Screen('TextFont',ptrWindow,TextFont);
Screen('TextColor',ptrWindow,TextColor);

% display the crosshair
DrawFormattedText(ptrWindow,Text,'center','center',TextColor);
Screen('Flip',ptrWindow);

% hold the screen
if Duration>0%used when inserting to other tasks
    WaitSecs(Duration);
else%used by itself
    % hold indefinitely
    DefaultKeyBoardTrigger(-1);
    % close the screen
    Screen('CloseAll');
end
T = GetSecs();
end

function timeBlockOnset = DefaultKeyBoardTrigger(TriggerDevice)
while true
    [keyIsDown,timeBlockOnset] = KbCheck(TriggerDevice);
    if keyIsDown
        break;
    end
end
WaitSecs(0.001);
end