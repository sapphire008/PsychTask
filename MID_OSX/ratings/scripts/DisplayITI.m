function DisplayITI(Window)

    Screen('TextSize',Window,100);
    Screen('FillRect',Window,0);
    DrawFormattedText(Window,'+','center','center',225);
    Screen('Flip',Window);
    Screen('TextSize',Window,32);

    WaitSecs(0.5);
    %GetKey()

end