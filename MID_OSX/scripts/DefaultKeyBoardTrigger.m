function timeBlockOnset = DefaultKeyBoardTrigger(TriggerDevice)
while true
    [keyIsDown,timeBlockOnset] = KbCheck(TriggerDevice);
    if keyIsDown
        break;
    end
end
WaitSecs(0.001);
end