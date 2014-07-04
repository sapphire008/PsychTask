function [var,data] = PresentFeedback(Window,var,data,ind,phase_dur)
% This function displays the feedback

%set up screen
Screen('TextSize',Window,var.cuetextsize);
% Get the relevant values:
won = data.binned_rts(var.cues(ind),ind);
valuenum = var.cues(ind);

% parse feedback result
switch valuenum
    case 1
        if won > 0
            value = 0;
            valuestr = '$0';
        else
            value = 0.0;
            valuestr = '-$0';
        end
    case 2
        if won > 0
            value = 0;
            valuestr = '$0';
        else
            value = -1.0;
            valuestr = '-$1';
        end
    case 3
        if won > 0
            value = 0;
            valuestr = '$0';
        else
            value = -5.0;
            valuestr = '-$5';
        end
    case 4
        if won > 0
            value = 0;
            valuestr = '+$0';
        else
            value = 0.0;
            valuestr = '$0';
        end
    case 5
        if won > 0
            value = 1.0;
            valuestr = '+$1';
        else
            value = 0;
            valuestr = '$0';
        end
    case 6
        if won > 0
            value = 5.0;
            valuestr = '+$5';
        else
            value = 0;
            valuestr = '$0';
        end
end

% Draw the feedback window
if var.display_totals
    DrawFormattedText(Window,['Trial: ' valuestr var.value_extension],'center',var.scrY*0.4,var.textcolor);
    if data.total >= 0
        DrawFormattedText(Window,['Total: $' num2str(abs(data.total), '%4.2f')], 'center', ...
            var.scrY*0.6, var.textcolor);
    else
        DrawFormattedText(Window,['Total: -$' num2str(abs(data.total), '%4.2f')], 'center', ...
            var.scrY*0.6, var.textcolor);
    end
else
    DrawFormattedText(Window,[valuestr var.value_extension],'center','center',var.textcolor);
end

% present the feedback
[VBLTimestamp,StimulusOnsetTime, FlipTimestamp, Missed, Beampos]=...
    Screen('Flip',Window,PredictVisualOnsetForTime(Window, var.ref_end));%freeze the screen
% do calculations at the meantime
data.feedback_onset(ind) = VBLTimestamp - var.abs_start;%onset of feedback
var.ref_end = var.ref_end + phase_dur;%advance reference end time
data.total = data.total+value;%calculate the total earned
data.gains_vector{ind} = valuestr;%record total in data
%wait until the next frame to flip
end



