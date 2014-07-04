function myCleanup(dirCode)
    Screen('CloseAll');
    ShowCursor;
    Priority(0);
    KbQueueStop();
    DisableKeysForKbCheck([]);
    rmpath(dirCode);
end