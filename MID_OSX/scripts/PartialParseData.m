function PartialParseData(var,data,boolHead,ind,shift_ind)
% PartialParseData takes in the data at each trial and writes it to the
% file using another function PartialDataWriter
% The name of the datafile is the subject's name
% shift_ind: increase index number temporarily to accommondate additional
% blocks

% Prepare a cell array for data
cellout = cell(1,22);
% Take all the data at the specified index from the data object, and
% convert everything to string variables:
%a). Subject
cellout{1,1} = var.subjectID;
%b). RunTime
cellout{1,2} = var.run_time;
%c). Trial
cellout{1,3} = num2str(ind+shift_ind);
%d). TR
cellout{1,4} = round((var.dur.cue+var.dur.delay+var.dur.target+...
    var.dur.feedback+var.itis(ind))/var.tr);
%e). Trial Type
cellout{1,5} = num2str(var.cues(ind));
%f). Cue Value
cellout{1,6} = data.cues_vector{ind};
%g). Trial Onset Time
cellout{1,7} = num2str(data.onset_t(ind));
%h). Cue Onset Time
cellout{1,8} = num2str(data.cue_onset(ind));
%i). Delay Onset Time
cellout{1,9} = num2str(data.delay_onset(ind));
%j). Target Onset Time
cellout{1,10} = num2str(data.target_onset(ind));
%k). Feedback Onset Time
cellout{1,11} = num2str(data.feedback_onset(ind));
%l). Cue Duration (actual duration measured by the script)
cellout{1,12} = num2str(data.cue_t(ind));
%m). Target Duration (actual duration measured by the script)
cellout{1,13} = num2str(data.target_t(ind));
%n). Current Target Duration (calibrated duration of target)
cellout{1,14} = num2str(data.calibration_current(ind),'%1.3f');   %Drew
%o). ITI
cellout{1,15} = num2str(var.itis(ind));
%p). RT
cellout{1,16} = num2str(data.rt(ind));
%q). ACC
cellout{1,17} = num2str(data.wins_vector(ind));
%r). Key Pressed
if ~isnan(data.key(ind))
    cellout{1,18} = KbName(data.key(ind));
else
    cellout{1,18} = NaN;
end
%s). Trial Gain
cellout{1,19} = data.gains_vector{ind};
%t). Total Gain
cellout{1,20} =  ['$' num2str(data.total, '%#4.2f')];
%u). Total Win Percentage
cellout{1,21} =  num2str(sum(data.wins_vector)/length(data.wins_vector));
%v). Timing (hit, too early, too late, no response)
tmp_timing = nansum(data.binned_rts(:,ind),1);
switch tmp_timing
    case -2
        cellout{1,22} = 'early';
    case -1
        cellout{1,22} = 'late';
    case 0
        cellout{1,22} = 'noResponse';
    otherwise
        cellout{1,22} = 'hit';
end



% trialonset = num2str(data.onset_t(ind));
%
% trialtype = num2str(var.cues(ind));
%
% target_ms = num2str(data.calibration_vector(ind));
%
% cue_value = data.cues_vector{ind};
%
% rt = num2str(data.rt_vector(ind));
%
% hit = num2str(data.wins_vector(ind));
%
% trial_gain = data.gains_vector{ind};
%
% total = ['$' num2str(data.total, '%#4.2f')];
%
% iti = num2str(var.itis(ind));
%
% drift = num2str(data.drifts(ind));
%
% total_winpercent = num2str(sum(data.wins_vector)/length(data.wins_vector));
%
% binned_winpercent = num2str(sum(data.wins{var.cues(ind)})/length(data.wins{var.cues(ind)}));
%
% current_calibration=num2str(data.calibration_current(ind),'%1.3f');   %Drew
% cue_onset=num2str(data.cue_onset(ind));   %Drew
% delay_onset=num2str(data.delay_onset(ind));   %Drew
% target_onset=num2str(data.target_onset(ind));   %Drew
% feedback_onset=num2str(data.feedback_onset(ind));   %Drew
% feedback_key_all=num2str(data.key_all(ind));   %Drew
% feedback_rt_all=num2str(data.rt_all(ind));   %Drew



% Prepare one row of data with these string variables (with a
% placeholder 'tr' for now:
% row = {trial,'tr',trialonset,trialtype,target_ms,rt,cue_value,hit, ...
%     trial_gain,total,iti,drift,total_winpercent,binned_winpercent,current_calibration,cue_onset,delay_onset,target_onset,feedback_onset,feedback_key_all,feedback_rt_all};
%
% % Iterate over the number of TRs in this trial (trial trs+iti) and for
% % each write the data in that row. It replaces the temporary 'tr' with
% % the actual tr number over each iteration of the 'k' for-loop:
% for k = 1:(4+var.itis(ind)/2)
%     for j = 1:length(row)
%         if j == 1
%             cellout{head+k,j} = row{j};
%         elseif j == 2
%             cellout{head+k,j} = num2str(k);
%         else
%             cellout{head+k,j} = row{j};
%         end
%     end
% end


% if new file, add the header
if boolHead
    % Header of the data table
    header = {'Subject','RunTime','Trial','TR','TrialType','CueValue',...
        'TrialOnset','CueOnset','DelayOnset','TargetOnset','FeedBackOnset',...
        'CueDuration','TargetDuration','CurrentTargetDuration',...
        'ITI','RT','ACC','KeyPressed','TrialGain','Total','TotalWinPercent',...
        'Timing'};
    % 'trialonset','trialtype','target_ms','rt','cue_value','hit', ...
    %'trial_gain','total','iti','drift','total_winpercent',...
    %'binned_winpercent','Drew_current_calib','Drew_cue_onset',...
    % 'Drew_delay_onset','Drew_target_onset','Drew_feedback_onset',...
    %'Drew_key_all','Drew_RT_all'};
    cellout = [header;cellout];
end
% Use PartialDataWriter to write the file to a new or already existing
% file:
PartialDataWriter(['MID_',var.subjectID,'_',date,'.csv'],...
    cellout,var.filepath.data,',');


end