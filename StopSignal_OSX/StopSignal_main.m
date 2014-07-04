% Stop Signal wrapper script
% Can be used during fMRI sessions when it may save some time to start up
% the new file

subject_code = 2;%subject ID
run_num = 1;% run/block number
order_num = 1;% order number: for behave only
ladder = [250;350];% response window ladder: for behave only
inputDevice = []; % response box input device number
TriggerDevice = []; % either TTL pulse device number or serial port path of scanner
TriggerWaitSecs = 0;%seconds to wait before triggering
TaskWaitSecs = 24;%seconds to wait after the trigger

% run the task
%StopSignal_OSX(subject_code,sub_session,run_num,order_num,Ladder,InputDevice,TriggerMode,TriggerDevice)
% 1). demo
%StopSignal_OSX(subject_code,3);
% 2). Behavioral
% StopSignal_OSX(subject_code,1,run_num,order_num,ladder);
% 3). fMRI
% a). task triggers scanner: Serial port
StopSignal_OX(subject_code,1,run_num,[],[],inputDevice,2,TriggerDevice);
% b). scanner triggers task: USB port
% StopSignal_OSX(subject_code,2,run_num,[],[],inputDevice,3,TriggerDevice);