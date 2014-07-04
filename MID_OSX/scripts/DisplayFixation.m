function [var,data] = DisplayFixation(Window,var,data,ind,phase_dur,letter)
% Drew: modified numerous things, inlcuding output
% display fixation period
Screen('TextSize',Window,var.textsize);
Screen('FillRect',Window,var.bkg_color);
DrawFormattedText(Window,letter,'center','center',var.textcolor);
%note: internally, there will be some delay between the deadline
        %(var.ref_end), the VBL sync (time***StartDraw), and the flip
        %timestamp (time***Onset). The VBL sync will be about 10ms later
        %than the expected deadline, and the flip timestamp will be about
        %5ms later than the VBL sync. In short, the screen starts drawing
        %10ms after the deadline, and finishes drawing 15ms after the
        %deadline. This will be true for every call to Screen('Flip'), even
        %the ones that do not have the deadline specified, because
        %internally that is interpreted as deadline = GetSecs. 
        %(Julian Cheng)
VBLTimestamp =...
    Screen('Flip',Window,PredictVisualOnsetForTime(Window, var.ref_end));%freeze the screen
% do calculations at the meantime
if ind>0
    data.delay_onset(ind) = VBLTimestamp-var.abs_start;%delay onset
    data.cue_t(ind) = VBLTimestamp-data.cue_onset(ind)-var.abs_start;%duration of cue
end
var.ref_end = var.ref_end + phase_dur;%advance the end of this phase
end