%SetupPsychtoolbox; % in case Psychtoolbox is not loaded correctly
% Start MID task
% [var,data] = MID_OSX(subject_ID,block_num,baseline_RT,InputDevice,TriggerMode,TriggerDevice,TriggerWaitSecs)


subject_ID = '127';%subject number
baseline_RT = 600;%baseline RT
InputDevice = [];
TriggerMode = 2;%1.T->S,USB;2.T->S,Serial;3.S->T,USB;4.S->T,Serial
TriggerDevice = [];

% run 1
%MID_OSX(subject_ID,'1',baseline_RT,InputDevice,TriggerMode,TriggerDevice);
% run 2
%MID_OSX(subject_ID,'2',baseline_RT,InputDevice,TriggerMode,TriggerDevice);
% practice
 [var,data] = MID_OSX(subject_ID,'3',baseline_RT);
% demo
% [var,data] = MID_OSX(subject_ID,'4',450,0,1);
% debug
% [var,data] = MID_OSX(subject_ID,'5',450,0,1);


