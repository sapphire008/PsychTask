function [timeBlockOnset,timeDeadline]=TaskTrigger(Window,auto_trigger,...
    TriggerMode,TriggerDevice,TriggerChar,TaskWaitSecs)
if auto_trigger%boolIsFmri && TF %if using the scanner
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
            timeBlockOnset=KbTriggerWait(TriggerChar,TriggerDevice);
            DisableKeysForKbCheck(TriggerChar); % So trigger is no longer detected
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
    DrawFormattedText(Window,'x','center','center');
    Screen('Flip', Window);
    % advance the block onset time to the time after wait
    timeDeadline = timeBlockOnset+TaskWaitSecs;
else
    timeDeadline = timeBlockOnset;
end
end

function timeBlockOnset = serial_trigger_scan()
% triggering the scanner by sending a bit of data
% Requires global variables TRIGGER and MARKER to be constructed 
% by create_trigger
global TRIGGER;
global MARKER;

% write to the port
fprintf(TRIGGER,MARKER);
% get current time of onset
timeBlockOnset = GetSecs();
% close the port
fclose(TRIGGER);
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