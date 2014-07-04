KbQueueCreate;
KbQueueStart; KbQueue_Start_Time = GetSecs;
numtrial = 10;
timeResponse = zeros(1,numtrial);
intKey = zeros(1,numtrial);
dblRT = zeros(1,numtrial);
dur_first = zeros(1,numtrial);
real_RT = zeros(1,numtrial);
WaitSecs(5);
for n = 1:numtrial
    timeDeadline = GetSecs+3;
    disp('start responding ...');
    timeCueOnset = GetSecs;
    while GetSecs<timeDeadline
        [responded, firstpress,firstrelease,lastpress,lastrelease] = KbQueueCheck;
        if responded
            disp(GetSecs);
            timeResponse(n) = min(firstpress(firstpress>0));
            intKey(n) = find(abs(firstpress-timeResponse(n))<1E-6,1);
            dblRT(n) = timeResponse(n) - timeCueOnset;
            real_RT(n) = GetSecs - timeCueOnset;
            disp(dblRT(n));
            temp = firstrelease - firstpress;
            dur_first(n) = temp(intKey(n));
            KbQueueFlush;
            break;
        end
        WaitSecs(0.001);
    end
end
KbQueueStop;
KbQueueRelease;