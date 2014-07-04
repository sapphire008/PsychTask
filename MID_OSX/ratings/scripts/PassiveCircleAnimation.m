

function PassiveCircleAnimation(Window,scrX,scrY,c)
        
    if c.degree > 0
        Screen('DrawLines',Window,[0,c.lineX(1),0,c.line2X(1);0,c.lineY(1),0,c.line2Y(1)], ...
            c.linewidth,c.linecolor,[scrX/2,scrY/2]);
    end
    Screen('FrameArc',Window,c.linecolor,c.position,0,360,c.linewidth);

    if length(c.gamble) == 1
        DrawFormattedText(Window,c.gamble{1},'center','center',c.linecolor);
    else
        DrawFormattedText(Window,c.gamble{1},'center',scrY/2-3*c.diameter/8,c.linecolor);
        DrawFormattedText(Window,c.gamble{2},'center',scrY/2+2*c.diameter/8,c.linecolor);
    end

    Screen('Flip',Window);
    
    WaitSecs(0.05);
    GetKey()

end
