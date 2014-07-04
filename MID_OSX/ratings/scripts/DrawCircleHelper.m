function circles = DrawCircleHelper(Window,scrX,scrY,ct,cb,left,right,righttop,yellow,textsize)
    
    topcolor = ct.linecolor;
    bottomcolor = cb.linecolor;
    
    if righttop
        if left
            bottomcolor = yellow;
        elseif right
            topcolor = yellow;
        end
    else
        if left
            topcolor = yellow;
        elseif right
            bottomcolor = yellow;
        end
    end
    
    if ct.degree > 0
        Screen('DrawLines',Window,[0,ct.lineX(1),0,ct.line2X(1);0,ct.lineY(1),0,ct.line2Y(1)], ...
            ct.linewidth,topcolor,[ct.endX-ct.diameter/2,ct.endY-ct.diameter/2]);
    end
    if cb.degree > 0
        Screen('DrawLines',Window,[0,cb.lineX(1),0,cb.line2X(1);0,cb.lineY(1),0,cb.line2Y(1)], ...
            cb.linewidth,bottomcolor,[cb.endX-cb.diameter/2,cb.endY-cb.diameter/2]);
    end
    
    Screen('FrameArc',Window,topcolor,ct.position,0,360,ct.linewidth);
    Screen('FrameArc',Window,bottomcolor,cb.position,0,360,cb.linewidth);
    
    Screen('TextSize',Window,textsize);
    
    if length(ct.gamble) == 1
        DrawFormattedText(Window,ct.gamble{1},'center',ct.endY-ct.diameter/2,topcolor);
    else
        DrawFormattedText(Window,ct.gamble{1},'center',(ct.endY-ct.diameter/2)-3*ct.diameter/8,topcolor);
        DrawFormattedText(Window,ct.gamble{2},'center',(ct.endY-ct.diameter/2)+2*ct.diameter/8,topcolor);
    end

    if length(cb.gamble) == 1
        DrawFormattedText(Window,cb.gamble{1},'center',cb.endY-cb.diameter/2,bottomcolor);
    else
        DrawFormattedText(Window,cb.gamble{1},'center',(cb.endY-cb.diameter/2)-3*cb.diameter/8,bottomcolor);
        DrawFormattedText(Window,cb.gamble{2},'center',(cb.endY-cb.diameter/2)+2*cb.diameter/8,bottomcolor);
    end
    
    circles = 0;

end