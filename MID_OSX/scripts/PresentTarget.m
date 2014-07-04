function [var,data] = PresentTarget(Window,var,data,ind,phase_dur,inputDevice)
% This function displays the targets
% get the calibration vector for this cue
prior_calibrations = var.calibrations{var.cues(ind)};
% get the wins vector for this cue
prior_wins = data.wins{var.cues(ind)};
% if the calibration vector is empty, set calibration to base RT
if isempty(prior_calibrations)
    current_calibration = var.basert;
    % if there are at least 3 responses in this category, calculate a
    % recalibration
elseif length(prior_wins) > 2
    % if the ratio of wins to losses is greater than 0.66, decrement by
    % the specified rt_change. otherwise increment
    ratio = sum(prior_wins)/length(prior_wins);
    if ratio > 0.66
        current_calibration = prior_calibrations(end) - var.rt_change;
    elseif ratio <= 0.66
        current_calibration = prior_calibrations(end) + var.rt_change;
    end
else
    % if under 3 occurences, just set the current calibration to the
    % prior
    current_calibration = prior_calibrations(end);
end

% add the current calibration to the prior calibration vector
prior_calibrations(end+1) = current_calibration;

% reset the history of calibrations to add the new one
var.calibrations{var.cues(ind)} = prior_calibrations;

% add the current calibration to the absolute calibration vecor (1D)
data.calibration_vector(ind) = current_calibration;

% set up the front buffer: time before target appears. This is a
% random amount between 0.25 and 0.75 seconds
frontbuffer = min(var.target_jitter) + rand()*max(var.target_jitter);

% Draw target object
Screen('DrawTexture',Window,var.target,[],var.targetrect);%draw target
Screen('DrawingFinished', Window);% no further drawing will be issued

% until until target period starts, check if early response occured
% if desired to check the entire delay period, turn this off.
%WaitSecs('UntilTime',var.ref_end);

% keep track of whether a key was pressed early
earlyResponse = false;
HIT = true;%suppose all are hit, will modify if necessary

% check to see whether a button was pressed during the front buffer by
% looping over the delay period. A press before the target appears is
% to be counted as a loss
%caluclate how much time it takes to flip the screen
dblFlipDuration = Screen('GetFlipInterval',Window);
%check early response right before the 1/2 the duration that the screen
%needs to flip.
%fprintf('At Present Target, the inputDevice is %d\n',inputDevice);
KbQueueFlush;
while GetSecs() < (var.ref_end+ frontbuffer-dblFlipDuration/2)
    %keyIsDown = KbCheck(inputDevice);
    keyIsDown = KbQueueCheck;
    if keyIsDown
        earlyResponse = true;
    end
    WaitSecs(0.001);%keep the CPU threading down/protect CPU
end

% Present the target on the screen
VBLTimestamp = Screen('Flip',Window,PredictVisualOnsetForTime(Window, ...
    var.ref_end+frontbuffer));

% prepare to turn the target off
Screen('FillRect',Window,var.bkg_color);

% check for a keypress during the target presentation, timed according
% to the current_calibration variable determined above
%[key,rt] = GetKey(var.allowed_keys,...
    %current_calibration-dblFlipDuration,[],inputDevice);   %Drew
KbQueueFlush; rt = NaN; key=NaN;
while GetSecs<var.ref_end+frontbuffer+current_calibration-dblFlipDuration/2
    [keyIsDown,firstpress]=KbQueueCheck;
    if keyIsDown
        rt = min(firstpress(firstpress>0));
        key = KbName(find(abs(firstpress-rt)<1E-6,1));
        break;
    end%terminate immediately
end
% turn off the target
% Option 1: turn off at scheduled time instead of immediately after the response
% VBLTimestamp2 = Screen('Flip',Window,PredictVisualOnsetForTime(Window,...
%     var.ref_end+frontbuffer+current_calibration));
% Option 2: turn off the screen immediately after the response or until the
% end of the wait duration by the GetKey function
VBLTimestamp2=Screen('Flip',Window);
% check for keypress after the target presentation but if still within the
% response window
if isnan(rt)
    %[key,rt] = GetKey(var.allowed_keys,...
    %var.response_window-current_calibration,[],inputDevice);   %Drew
    KbQueueFlush;
    while GetSecs<var.ref_end+phase_dur-dblFlipDuration/2
        [keyIsDown,firstpress]=KbQueueCheck;
        if keyIsDown
            rt = min(firstpress(firstpress>0));
            key = KbName(find(abs(firstpress-rt)<1E-6,1));
            break;
        end%terminate immediately
    end
    HIT = false;%record as non-hit
end
rt = rt - VBLTimestamp;%re-reference RT to onset of target
% Do calculations while the screen is still blank
data.rt(ind) = rt; %record RT
if ~isnan(key)%record key press
    data.key(ind) = KbName(key);
else
    data.key(ind) = NaN;
end
data.target_onset(ind) = VBLTimestamp-var.abs_start;%target onset
data.target_t(ind) = VBLTimestamp2 - VBLTimestamp;%duration of target

% if a key was pressed prior to the target, then they do NOT win
if earlyResponse
    % rt flagged as -2 for a early press
    data.binned_rts(var.cues(ind),ind) = -2;
    % add a 0 to wins to that cue's win vector and the absolute win
    % vector
    prior_wins(end+1) = 0;
    data.wins{var.cues(ind)} = prior_wins;
    data.wins_vector(ind) = 0;
    
    % if they didn't press early, then check to see if they made it
else
    % in the case of a non-hit, the rt will be NaN
    if ~HIT
        if ~isnan(rt)
        % non hits are categorized as -1 in RT
        data.binned_rts(var.cues(ind),ind) = -1;
        prior_wins(end+1) = 0;
        data.wins{var.cues(ind)} = prior_wins;
        data.wins_vector(ind) = 0;
        % a hit will have a positive rt value
        else
            data.binned_rts(var.cues(ind),ind) = 0;
            prior_wins(end+1) = 0;
            data.wins{var.cues(ind)} = prior_wins;
        end
    else
        % wait out the remainder of the calibration prior to the rt
        %WaitSecs(current_calibration-rt);
        %Screen('Flip',Window);
        data.binned_rts(var.cues(ind),ind) = rt;
        prior_wins(end+1) = 1;
        data.wins{var.cues(ind)} = prior_wins;
        data.wins_vector(ind) = 1;
    end
end

%Drew: store the current calibration
data.calibration_current(ind)=current_calibration;
%advance to next period
var.ref_end = var.ref_end + phase_dur;
end



