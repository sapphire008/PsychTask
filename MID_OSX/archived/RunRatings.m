function ratings = RunRatings()

    
    % cue presentation order, categorized 1-6:
    % 1 = low square
    % 2 = med square
    % 3 = high square
    % 4 = low circle
    % 5 = med cirlce
    % 6 = high circle
    %
    
    var.cues = [1 2 3 4 5 6]; 
    

    var.cue_pen = 6;
    var.cue_box = [0 0 250 250];
    
    var.starname = 'tri_up.png';
    var.starrect = [0 0 200 200];
    
    
    %change this reference text size depending on how big your screen is!
    var.textsize = 38;    
    var.cuetextsize = 80;
    

    var.usedecimals = 1;
    var.amount_below_cue = 1;
    
    if var.usedecimals == 1
        var.value_extension = '.00';
    else
        var.value_extension = '';
    end
    
    
    %% SCREEN SETUP:
    if max(Screen('Screens'))>0 %dual screen
        dual=get(0,'MonitorPositions');
        resolution = [0,0,dual(2,3),dual(2,4)];
    elseif max(Screen('Screens'))==0 % one screen
        resolution = get(0,'ScreenSize') ;
    end
    var.scrX = resolution(3);
    var.scrY = resolution(4);
    

    testing = 0;
    
    %% SUBJECT/BLOCK CONSOLE PROMPT:
    if ~testing
        var.subjectID = input('Please enter your subject ID number: ','s');
        var.runinstructions = str2num(input('Play the instructions? (1 or 0) ','s'));
    else
        var.subjectID = 0;
        var.runinstructions = 0;
    end
    
    
    %% PREPARE EXPERIMENT STRUCTURE:
    var.filepath = MakePathStruct();
    var.bkg_color = 0;
    var.textcolor = 255;
    var.font = 'Helvetica';

    screenNumber = max(Screen('Screens'));
    [Window,var.winrect] = Screen('OpenWindow',screenNumber,0);
    
    
    starimg = imread(var.starname);
    var.star = Screen('MakeTexture',Window,starimg);
    
    [var.starrect,dh,dv] = CenterRect(var.starrect,var.winrect);
        
    %% ENTER SCRIPTS DIRECTORY:
    cd(var.filepath.scripts)

    
    
    %% INITIALIZE SCREEN:
    Screen('FillRect',Window,var.bkg_color); 
    Screen('Flip',Window);
    Screen('TextSize',Window,var.textsize);
    Screen('TextFont',Window,var.font);
    
    
    
    Screen('TextSize',Window,var.textsize);
    

    charwrap = 70;
    c.textColor = 255;
    %slider bar stuff
    
    c.linestart=var.scrX/8;
    c.lineend=var.scrX*7/8;
    c.linelength=(c.lineend-c.linestart);

    % circle rater stuff
    c.numEls = 7; % number of elements on the scale... e.g. for a 1-7 scale, enter 7
    c.radius = .04*var.scrY;
    c.height = .75*var.scrY;
    c.circleSep = (c.linelength)/(c.numEls-1);

    greenColors =[[250 255 250];[200 255 200];[150 255 150];[100 255 100];[50 255 50];[25 255 25];[0 200 0]];
    greenColors = greenColors';
    
    twoColors =[[0 0 255];[50 50 255];[100 100 255];[245 245 220];[245 165 79];[255 150 50];[255 100 50]];
    twoColors = twoColors';
    
    % text heights
    c.qnHeight = .65*var.scrY;
    c.scaleHeight = .8*var.scrY;
    c.instrHeight = .9*var.scrY;

    % circle slider
    c.slideRadius = 2*c.radius/3;

    % rating text

    ascaleArr={'  Very Low','      Moderate','       Very High'};
    aratingArr = 'AROUSAL';
    
    vscaleArr = {'Very Negative','       Neutral','    Very Positive'};
    vratingArr = 'VALENCE';


    aratings = [];
    vratings = [];
    dummy = [];
    
    % instructions:
    
    if var.runinstructions

        inst1 = ['You will now see a selection of the cues that you just played.\n\n' ...
            'You will see the cue accompanied by a rating scale.\n\n' ...
            'The title above each scale indicates which rating you are being asked to make.  Please pay attention as to which of the following 2 ratings you will be asked to make:\n\n' ...
            'The VALENCE scale\n' ...
            'The AROUSAL scale\n'];

        Screen('TextSize',Window,var.textsize);
        DrawFormattedText(Window,inst1,'center','center',225,charwrap);
        Screen('Flip',Window);
        WaitSecs(0.2);
        GetKeyOld()

        
        inst2 = ['THE VALENCE SCALE measures how positive or negative you are feeling. \n\n' ...
            'At the far left you would be feeling very negative, that could be unhappy, upset, irritated, frustrated, angry, sad, depressed, or some other negative feeling. \n\n ' ...
            'At the far right you would be feeling very positive: That could be happy, pleased, satisfied, competent, proud, content, delighted, or some other positive feeling. \n\n' ...
            'In the middle of this scale you would be feeling completely neutral, neither positive or negative.  From the neutral midpoint, the ratings get gradually more negative as you move left, and gradually more positive as you move right.\n\n' ...
            'Use the left button to move the indicator on the scale towards negative and the right button to move the indicator towards positive.'];

        
        Screen('TextSize',Window,var.textsize);
        DrawFormattedText(Window,inst2,'center','center',225,charwrap);
        Screen('Flip',Window);
        WaitSecs(0.2);
        GetKeyOld()

        c.slidepos = round(c.numEls/2);
        c.colors = twoColors;

        circleRaterOrig(c,vratingArr,vscaleArr,Window);
        WaitSecs(0.05);

        KbName('UnifyKeyNames');
        while true
            key = GetKeyOld({'1!' '2@' '3#' '4$'});

            if strcmp(key, '4$') && c.slidepos < c.numEls
                c.slidepos = c.slidepos + 1;
                circleRaterOrig(c,vratingArr,vscaleArr,Window);
            elseif strcmp(key, '1!') && c.slidepos > 1
                c.slidepos = c.slidepos - 1;
                circleRaterOrig(c,vratingArr,vscaleArr,Window);
            elseif strcmp(key, '3#') || strcmp(key, '2@')
                dummy=c.slidepos;
                break;
            end

        end

        
        inst3 = ['THE AROUSAL SCALE measures how aroused you are feeling at a given time.\n\n' ...
            'At the far right on this scale, you would be feeling very alert, aroused, activated, charged or energized, very physically or mentally aroused.\n\n' ...
            'At the far left, you would be feeling completely unaroused, slow, still, de-energized, no physical or mental arousal at all.\n\n' ...
            'Notice that this AROUSAL scale is a continuum going from low to high arousal.  The point in the middle of the scale would represent being moderately aroused; a point in between the two extremes.  It does not mean neutral.\n\n'...
            'Use the right arrow key to move the indicator on the scale towards higher arousal.\n\n' ...
            'Press any button to continue.'];

        Screen('TextSize',Window,var.textsize);
        DrawFormattedText(Window,inst3,'center','center',225,charwrap);
        Screen('Flip',Window);
        WaitSecs(0.2);
        GetKeyOld()

        %(VALENCE RATE DEMO SCREEN)
        
        c.slidepos = 1;
        c.colors = greenColors;
        

        circleRaterOrig(c,aratingArr,ascaleArr,Window);
        WaitSecs(0.05);

        KbName('UnifyKeyNames');
        while true
            key = GetKeyOld({'1!' '2@' '3#' '4$'});

            if strcmp(key, '4$') && c.slidepos < c.numEls
                c.slidepos = c.slidepos + 1;
                circleRaterOrig(c,aratingArr,ascaleArr,Window);
            elseif strcmp(key, '1!') && c.slidepos > 1
                c.slidepos = c.slidepos - 1;
                circleRaterOrig(c,aratingArr,ascaleArr,Window);
            elseif strcmp(key, '3#') || strcmp(key, '2@')
                dummy=c.slidepos;
                break;
            end
        end

        inst4 = ['Think about the scales as capturing separate aspects of your how you are feeling.\n\n' ...
            'So, the arousal scale doesn''t tell us whether you are feeling good or bad; it''s capturing more this idea of physical or mental activation.  So, for example you could be feeling very aroused and positive (suppose you were really excited because you had just won a prize) or very aroused and negative (suppose you were really angry because someone had just stolen your parking space).\n\n' ...
            'On the other hand, you could be feeling really unaroused and positive (if you were relaxing and looking at a beautiful sunset) or really unaroused and negative (if you were feeling down and depressed).\n\n' ...
            'We want you to report the negative or positive dimension of your feeling on the one scale, and the arousal aspect on the other.'];

        Screen('TextSize',Window,var.textsize);
        DrawFormattedText(Window,inst4,'center','center',225,charwrap);
        Screen('Flip',Window);
        WaitSecs(0.2);
        GetKeyOld()

        inst5 = ['Please make each rating individually for that particular cue.\n\n' ...
            'Please make your ratings as quickly and accurately as possible. \n\n' ...
            'Press a middle button to select your rating and advance to the next trial.'];

        Screen('TextSize',Window,var.textsize);
        DrawFormattedText(Window,inst5,'center','center',225,charwrap);
        Screen('Flip',Window);
        WaitSecs(0.2);
        GetKeyOld()


        DisplayITI(Window);
        
    end
    
    
    for i = 1:length(var.cues)
        %PassiveCircleAnimation(Window,scrX,scrY,circles{i});
        
        c.slidepos = round(c.numEls/2);
        c.colors = twoColors;
        
        cueRater(c,var,var.cues(i),vratingArr,vscaleArr,Window);
        WaitSecs(0.05);
        
        KbName('UnifyKeyNames');
        while true
            key = GetKeyOld({'1!' '2@' '3#' '4$'});

            if strcmp(key, '4$') && c.slidepos < c.numEls
                c.slidepos = c.slidepos + 1;
                cueRater(c,var,var.cues(i),vratingArr,vscaleArr,Window);
            elseif strcmp(key, '1!') && c.slidepos > 1
                c.slidepos = c.slidepos - 1;
                cueRater(c,var,var.cues(i),vratingArr,vscaleArr,Window);
            elseif strcmp(key, '3#') || strcmp(key, '2@')
                vratings(i)=c.slidepos;
                break;
            end

        end
        
        
        c.slidepos = 1;
        c.colors = greenColors;
        

        cueRater(c,var,var.cues(i),aratingArr,ascaleArr,Window);
        WaitSecs(0.05);
        
        KbName('UnifyKeyNames');
        while true
            key = GetKeyOld({'1!' '2@' '3#' '4$'});

            if strcmp(key, '4$') && c.slidepos < c.numEls
                c.slidepos = c.slidepos + 1;
                cueRater(c,var,var.cues(i),aratingArr,ascaleArr,Window);
            elseif strcmp(key, '1!') && c.slidepos > 1
                c.slidepos = c.slidepos - 1;
                cueRater(c,var,var.cues(i),aratingArr,ascaleArr,Window);
            elseif strcmp(key, '3#') || strcmp(key, '2@')
                aratings(i)=c.slidepos;
                break;
            end

        end
        
        DisplayITI(Window);

    end
    
    ParseData(var.filepath,var.subjectID,aratings,vratings,{'lowsquare','medsquare','highsquare','lowcircle','medcircle','highcircle'});
    
    sca;
    
end

function circleRaterOrig(c,ratingArr,scaleArr,Window)
    Screen('TextSize',Window,34);
        
    DrawFormattedText(Window, ratingArr,'center',c.qnHeight,c.textColor);

    rects=[];

    %determine position of circles
    for x=1:c.numEls
        centerX = c.linestart+c.circleSep*(x-1);
        rects(1,x) = centerX-c.radius;
        rects(2,x) = c.height-c.radius;
        rects(3,x) = centerX+c.radius;
        rects(4,x)= c.height+c.radius;
    end

    % draw circles
    Screen('FillOval', Window, c.colors, rects);

    % draw slider
    c.slideposX = (c.slidepos-1)*c.circleSep + c.linestart;
    Screen('FillOval', Window, [0 0 0], [c.slideposX-c.slideRadius, c.height-c.slideRadius, c.slideposX+c.slideRadius, c.height+c.slideRadius]);

    % draw legend
    scalekey=scaleArr;  % extra spaces so they spread out evenly
    for y=1:3
        DrawFormattedText(Window, scalekey{y}, (c.linestart+(c.linelength)*(y-1)/2)-150, c.scaleHeight,c.textColor);
    end
    %draw instruction
    Screen('TextSize',Window,28);
    DrawFormattedText(Window, 'Move the indicator with the arrow keys, then press a middle button to confirm', 'center', c.instrHeight,c.textColor);

    Screen('Flip',Window);
end


function cueRater(c,var,cue,ratingArr,scaleArr,Window)
    Screen('TextSize',Window,34);
    
    PresentCueRating(Window,var,cue);
    Screen('TextSize',Window,var.textsize);
    
    DrawFormattedText(Window, ratingArr,'center',c.qnHeight,c.textColor);

    rects=[];

    %determine position of circles
    for x=1:c.numEls
        centerX = c.linestart+c.circleSep*(x-1);
        rects(1,x) = centerX-c.radius;
        rects(2,x) = c.height-c.radius;
        rects(3,x) = centerX+c.radius;
        rects(4,x)= c.height+c.radius;
    end

    % draw circles
    Screen('FillOval', Window, c.colors, rects);

    % draw slider
    c.slideposX = (c.slidepos-1)*c.circleSep + c.linestart;
    Screen('FillOval', Window, [0 0 0], [c.slideposX-c.slideRadius, c.height-c.slideRadius, c.slideposX+c.slideRadius, c.height+c.slideRadius]);

    % draw legend
    scalekey=scaleArr;  % extra spaces so they spread out evenly
    for y=1:3
        DrawFormattedText(Window, scalekey{y}, (c.linestart+(c.linelength)*(y-1)/2)-150, c.scaleHeight,c.textColor);
    end
    %draw instruction
    Screen('TextSize',Window,28);
    DrawFormattedText(Window, 'Move the indicator with the arrow keys, then press a middle button to confirm', 'center', c.instrHeight,c.textColor);

    Screen('Flip',Window);
end


function CircleDrawer(Window,scrX,scrY,c)
        
    if c.degree > 0
        Screen('DrawLines',Window,[0,c.lineX(1),0,c.line2X(1);0,c.lineY(1),0,c.line2Y(1)], ...
            c.linewidth,c.linecolor,[scrX/2,(.7*scrY)/2]);
    end
    Screen('FrameArc',Window,c.linecolor,c.position,0,360,c.linewidth);

    if length(c.gamble) == 1
        DrawFormattedText(Window,c.gamble{1},'center',(.7*scrY)/2,c.linecolor);
    else
        DrawFormattedText(Window,c.gamble{1},'center',(.7*scrY)/2-3*c.diameter/8,c.linecolor);
        DrawFormattedText(Window,c.gamble{2},'center',(.7*scrY)/2+2*c.diameter/8,c.linecolor);
    end


end

function DisplayITI(Window)

    Screen('TextSize',Window,100);
    Screen('FillRect',Window,0);
    DrawFormattedText(Window,'+','center','center',225);
    Screen('Flip',Window);
    Screen('TextSize',Window,32);

    WaitSecs(0.5);
    %GetKeyOld()

end


function data = PresentCueRating(Window,var,cue)
    
    
    Screen('TextSize',Window,var.cuetextsize);
    
    % Center the cue-box on screen:
    ratings_cuerect = [var.winrect(1) var.winrect(2)-.2*var.scrY var.winrect(3) var.winrect(4)-.2*var.scrY];
    [cuebox,dh,dv] = CenterRect(var.cue_box,ratings_cuerect);
    radius = (cuebox(3)-cuebox(1))/2;
    deviation = sqrt((radius^2)/2);
    
    % Draw shape and value depending on trialtype:
    value = [];
    switch cue
        case 1
            value = '-$0';
            shape = 'square_lowline';     
        case 2
            value = '-$1';
            shape = 'square_midline';     
        case 3
            value = '-$5';
            shape = 'square_highline';
        case 4
            value = '+$0';
            shape = 'circle_lowline';
        case 5
            value = '+$1';
            shape = 'circle_midline';
        case 6
            value = '+$5';
            shape = 'circle_highline';
    end
    
    
    [valuebox,dh,dv] = CenterRect(Screen('TextBounds',Window,[value var.value_extension]),cuebox);
    if var.amount_below_cue
        valuebox(2) = valuebox(2)+radius*1.65;
    end
    
    % Draw the full cue to screen:
    Screen('FillRect',Window,var.bkg_color);
    
    if strcmp(shape,'circle_plain')
        Screen('FrameArc',Window,var.textcolor,cuebox,0,360,var.cue_pen);
        
    elseif strcmp(shape,'circle_lowline')
        Screen('FrameArc',Window,var.textcolor,cuebox,0,360,var.cue_pen);
        startX = cuebox(1)+radius-deviation;
        startY = cuebox(2)+radius+deviation;
        finX = cuebox(1)+radius+deviation;
        finY = cuebox(2)+radius+deviation;
        Screen('DrawLine',Window,var.textcolor,startX,startY,finX,finY,var.cue_pen);
        
    elseif strcmp(shape,'circle_midline')
        Screen('FrameArc',Window,var.textcolor,cuebox,0,360,var.cue_pen);
        startX = cuebox(1);
        startY = cuebox(2)+radius;
        finX = cuebox(3);
        finY = cuebox(2)+radius;
        Screen('DrawLine',Window,var.textcolor,startX,startY,finX,finY,var.cue_pen);
        
    elseif strcmp(shape,'circle_highline')
        Screen('FrameArc',Window,var.textcolor,cuebox,0,360,var.cue_pen);
        startX = cuebox(1)+radius-deviation;
        startY = cuebox(2)+radius-deviation;
        finX = cuebox(1)+radius+deviation;
        finY = cuebox(2)+radius-deviation;
        Screen('DrawLine',Window,var.textcolor,startX,startY,finX,finY,var.cue_pen);
        
    elseif strcmp(shape,'square_plain')
        Screen('FrameRect',Window,var.textcolor,cuebox,var.cue_pen);
        
    elseif strcmp(shape,'square_lowline')
        Screen('FrameRect',Window,var.textcolor,cuebox,var.cue_pen);
        setY = cuebox(2)+radius+deviation;
        Screen('DrawLine',Window,var.textcolor,cuebox(1),setY,cuebox(3),setY,var.cue_pen);
        
    elseif strcmp(shape,'square_midline')
        Screen('FrameRect',Window,var.textcolor,cuebox,var.cue_pen);
        setY = cuebox(2)+radius;
        Screen('DrawLine',Window,var.textcolor,cuebox(1),setY,cuebox(3),setY,var.cue_pen);
      
    elseif strcmp(shape,'square_highline')
        Screen('FrameRect',Window,var.textcolor,cuebox,var.cue_pen)
        setY = cuebox(2)+radius-deviation;
        Screen('DrawLine',Window,var.textcolor,cuebox(1),setY,cuebox(3),setY,var.cue_pen);
        
    end
    
    
    DrawFormattedText(Window,[value var.value_extension],valuebox(1),valuebox(2),var.textcolor);
    

end
