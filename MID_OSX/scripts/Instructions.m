function Instructions(Window)

    inst_charwrap = 60;

    inst1 = ['In this experiment you will respond as quickly as possible to earn money.\n\n' ...
        'You will see a cue indicating how much money you can win or avoid losing.\n\n' ...
        'After this cue, a triangle will appear. Hit a button as fast as you can when the triangle appears to win.\n\n' ...
        'Press any button to continue the instructions.'];
    
    inst2 = ['Cues are either circles or squares.\n\n' ...
        'CIRCLE cues mean that you can EARN that amount if you hit the target.\n\n' ...
        'SQUARE cues mean that you can AVOID LOSING that amount if you hit the target.\n\n' ...
        'Press any button to continue the instructions.'];
    
    inst3 = ['If you miss a CIRCLE cue, you will NOT GAIN the amount in the cue.\n\n' ...
        'If you miss a SQUARE cue, you will LOSE the amount in the cue.\n\n' ...
        'Press any button to continue the instructions.'];
    
    inst4 = ['Please HOLD STILL while you are in the scanner.\n\n' ...
        'Press any button when you are ready to begin.'];
    
    all_inst = {inst1,inst2,inst3,inst4};
    
    Screen('TextSize',Window,40);
    for i = 1:4
        DrawFormattedText(Window,all_inst{i},'center','center',225,inst_charwrap);
        Screen('Flip',Window);
        WaitSecs(0.4);
        KbWait(-1);
    end
    

end