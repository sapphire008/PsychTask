function [var,data] = PresentCue(Window,var,data,ind,phase_dur)
% This function displays the cues:
Screen('TextSize',Window,var.cuetextsize);

% Center the cue-box on screen:
cuebox = CenterRect(var.cue_box,var.winrect);
radius = (cuebox(3)-cuebox(1))/2;
deviation = sqrt((radius^2)/2);

% Draw shape and value depending on trialtype:
value = [];
switch var.cues(ind)
    case 1
        value = '-$0';
        shape = 'square_lowline';
    case 2
        value = '-$1';
        shape = 'square_midline';
    case 3
        value = '-$5';
        shape = 'square_highline';
    case 4
        value = '+$0';
        shape = 'circle_lowline';
    case 5
        value = '+$1';
        shape = 'circle_midline';
    case 6
        value = '+$5';
        shape = 'circle_highline';
end
%save the money gain/loss condition
data.cues_vector{ind} = value;

valuebox = CenterRect(Screen('TextBounds',Window,[value var.value_extension]),cuebox);
if var.amount_below_cue%show money amount below the figure
    valuebox(2) = valuebox(2)+radius*1.65;
end

% Draw the full cue to screen:
Screen('FillRect',Window,var.bkg_color);

% parse Screen/values based on shape of the cue
switch shape
    case {'circle_plain'}
        Screen('FrameArc',Window,var.textcolor,cuebox,0,360,var.cue_pen);    
    case {'circle_lowline'}
        Screen('FrameArc',Window,var.textcolor,cuebox,0,360,var.cue_pen);
        startX = cuebox(1)+radius-deviation;
        startY = cuebox(2)+radius+deviation;
        finX = cuebox(1)+radius+deviation;
        finY = cuebox(2)+radius+deviation;
        Screen('DrawLine',Window,var.textcolor,startX,startY,finX,finY,var.cue_pen);
    case {'circle_midline'}
        Screen('FrameArc',Window,var.textcolor,cuebox,0,360,var.cue_pen);
        startX = cuebox(1);
        startY = cuebox(2)+radius;
        finX = cuebox(3);
        finY = cuebox(2)+radius;
        Screen('DrawLine',Window,var.textcolor,startX,startY,finX,finY,var.cue_pen);
    case {'circle_highline'}
        Screen('FrameArc',Window,var.textcolor,cuebox,0,360,var.cue_pen);
        startX = cuebox(1)+radius-deviation;
        startY = cuebox(2)+radius-deviation;
        finX = cuebox(1)+radius+deviation;
        finY = cuebox(2)+radius-deviation;
        Screen('DrawLine',Window,var.textcolor,startX,startY,finX,finY,var.cue_pen);
    case {'square_plain'}
        Screen('FrameRect',Window,var.textcolor,cuebox,var.cue_pen);
    case {'square_lowline'}
        Screen('FrameRect',Window,var.textcolor,cuebox,var.cue_pen);
        setY = cuebox(2)+radius+deviation;
        Screen('DrawLine',Window,var.textcolor,cuebox(1),setY,cuebox(3),setY,var.cue_pen);
    case {'square_midline'}
        Screen('FrameRect',Window,var.textcolor,cuebox,var.cue_pen);
        setY = cuebox(2)+radius;
        Screen('DrawLine',Window,var.textcolor,cuebox(1),setY,cuebox(3),setY,var.cue_pen);
    case {'square_highline'}
        Screen('FrameRect',Window,var.textcolor,cuebox,var.cue_pen)
        setY = cuebox(2)+radius-deviation;
        Screen('DrawLine',Window,var.textcolor,cuebox(1),setY,cuebox(3),setY,var.cue_pen);        
end
%display the value below the figure
Screen('TextSize',Window,var.textsize);%make sure text size is correct
DrawFormattedText(Window,[value var.value_extension],valuebox(1),valuebox(2),var.textcolor);
%show the figure
[VBLTimestamp,StimulusOnsetTime, FlipTimestamp, Missed, Beampos]=...
    Screen('Flip',Window,PredictVisualOnsetForTime(Window, var.ref_end));%freeze the screen
% do calculations at the meantime while the cue is on the screen;
data.cue_onset(ind) = VBLTimestamp-var.abs_start;%onset of cue
% if ind-1>1E-07%duration of feedback
%     data.feedback_t(ind-1) = VBLTimestamp-data.iti_onset(ind-1);
% end
var.ref_end = var.ref_end + phase_dur;%advance reference end time
end



