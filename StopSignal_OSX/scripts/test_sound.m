function test_sound% initialize psychtoolbox soundevalc('InitializePsychSound(1)');evalc('pahandle = PsychPortAudio(''Open'', -1, [], 2, 22254, 2)'); %open the audio devicewave=sin(1:0.25:1000);wave=repmat(wave,2,1);  %want to make it stereo, so 2 channelswhile true    beep_sound(pahandle,wave);    PROMPT = input('Good? (''Q'' to quit):','s');    if strcmpi(PROMPT,'Q')        break;    endend    endfunction beep_sound(pahandle,wave)% Test beep soundPsychPortAudio('FillBuffer', pahandle, wave);PsychPortAudio('Start', pahandle, 1, 0, 0);%test beepWaitSecs(1);PsychPortAudio('Stop', pahandle);% Old function:% Snd('Open');% samp = 22254.545454;% aud_stim = sin(1:0.25:1000);% Snd('Play',aud_stim,samp);end