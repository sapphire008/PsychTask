

function [circle,lastkey,firstRT,lastRT] = ActiveCircleAnimation(Window,scrX,scrY,ct,cb,righttop,condition,textsize_ref)
    
    startT = GetSecs();
    
    lastkey = 0;
    firstRT = 0;
    lastRT = 0;
    lettersize = 70;
    
    yellow = [190 190 0];
    
    if condition == 0
        waittime = 2.0;
    elseif condition == 1 || condition == 2
        waittime = 4.0;
    end
    
    currentT = GetSecs()-startT;
    
    if condition == 1 || condition == 2
        
        left = 0;
        right = 0;
        wasdown = 0;
        presses = 0;
        oldkey = 0;
        dirchanges = 0;
        pressT = 0;
        
        circles = DrawCircleHelper(Window,scrX,scrY,ct,cb,left,right,righttop,yellow,textsize_ref);
        buttons = DrawDirectionsHelper(Window,scrX,scrY,ct,cb,righttop,0,0,textsize_ref,lettersize,yellow);
        
        while currentT < waittime

            [down secs key d] = KbCheck(-1);
            if down == 1
                pressT = GetSecs()-startT;
                oldkey = key;
            end

            if (down == 0) && (wasdown == 1);
                % for scanner, set to: '1!'
                if strcmp('1!',KbName(oldkey))
                    left = 1;
                    right = 0;
                    presses = presses+1;
                    if firstRT == 0
                        firstRT = pressT;
                    end
                    lastRT = pressT;
                    if lastkey == 4
                        dirchanges = dirchanges+1;
                    end
                    lastkey = 1;
                % for scanner, set to: '4$'
                elseif strcmp('4$',KbName(oldkey))
                    left = 0;
                    right = 1;
                    presses = presses+1;
                    if firstRT == 0
                        firstRT = pressT;
                    end
                    lastRT = pressT;
                    if lastkey == 1
                        dirchanges = dirchanges+1;
                    end
                    lastkey = 4;
                elseif condition == 2 && strcmp('space',KbName(oldkey))
                    currentT = 1;
                    waittime = 0;
                    break;
                end
            end

            wasdown = down;
            
            circles = DrawCircleHelper(Window,scrX,scrY,ct,cb,left,right,righttop,yellow,textsize_ref);
            buttons = DrawDirectionsHelper(Window,scrX,scrY,ct,cb,righttop,0,0,textsize_ref,lettersize,yellow);
            
            [flipT stonset stamp mis beam] = Screen('Flip',Window);
            
            if condition == 1
                currentT = flipT-startT;
            end
        end
        
    elseif condition == 0
        circles = DrawCircleHelper(Window,scrX,scrY,ct,cb,0,0,righttop,yellow,textsize_ref);
        Screen('Flip',Window);
        WaitSecs(waittime-currentT);
    end

    circle = GetSecs()-startT;

end
