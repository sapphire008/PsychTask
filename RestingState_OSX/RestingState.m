function T = RestingState(Duration,Text,TextSize,...
    TextColor,BackGroundColor,Window)
% Resting State cross-hair stimuli.
%
% Inputs:
%   Duration: duration of the crosshair. Specified when inserted to other
%             tasks. By default, the script will run indefinitely until a
%             key is pressed to terminate the script.
%
%   Text: text to be displayed. Default is a crosshair
%
%   TextSize, TextColor, BackGroundColor: parameters for display
%   
%   Window: Window object returned by Screen. Texts will be drawn directly
%           to the provided Window object. If not specified, will start a 
%           new window (when running Resting State)
%

% By default, run the script indefinitely
if nargin<1 || isempty(Duration)
    Duration = -1;
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
if nargin<5 || isempty(Window)
    % set up screens
    fprintf('setting up screen\n');
    Priority(1);%give highest priority to the script
    HideCursor();% hide the distracting mouse cursor
    Window=Screen('OpenWindow', max(Screen('Screens')),0,[],32,2);
    % set stimulus parameters
    Screen('FillRect', Window, BackGroundColor);
    Screen('Flip', Window);
end
%set up screen parameters
Screen('TextSize',Window,TextSize);
Screen('TextFont',Window,TextFont);
Screen('TextColor',Window,TextColor);

% display the crosshair
DrawFormattedText(Window,Text,'center','center',TextColor);
Screen('Flip',Window);

% hold the screen
if Duration>0%used when inserting to other tasks
    WaitSecs(Duration);
else%used by itself
    % hold indefinitely
    KbWait(-1);
    %DefaultKeyBoardTrigger(-1);
    
end
T = GetSecs();
% close the screen
Screen('CloseAll');
end

% function timeBlockOnset = DefaultKeyBoardTrigger(TriggerDevice)
% while true
%     [keyIsDown,timeBlockOnset] = KbCheck(TriggerDevice);
%     if keyIsDown
%         break;
%     end
% end
% WaitSecs(0.001);
% end