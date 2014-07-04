%run FracBack task
% Data = FracBack_OSX(subject_ID,sub_session,InputDevice,TriggerMode,TriggerDevice,self_paced)
% 1).behave mode
%FracBack_OSX(999,2,[],[],[],false);
% 2).fMRI mode
subject_ID = 1;
% run 1
FracBack_OSX(subject_ID,1,[-1],[3],[-1],false);
% run 2
FracBack_OSX(subject_ID,2,[-1],[3],[-1],false);
% run 3
FracBack_OSX(subject_ID,3,[-1],[3],[-1],false);


   
 
