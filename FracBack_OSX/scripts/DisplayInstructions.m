function DisplayInstructions(ptrWindow,structImages,strTargetFile,boolUseMirroredText,intInputDevice,arrWindowSize)

 %screen 1--------------------------------------------------------------
    
    strMessage = [ ...
        'In this task you will be shown one picture at a time.\n\n\n' ...
        'You will need to respond to each picture\n\n' ...
        'depending on which rule was given.\n\n\n' ...
        'There are three rules in this task:\n\n' ...
        '1. Zero back   2. One back   3. Two back\n\n\n' ...
        '[Press any key to continue]' ...
        ];

    %show the message
    DrawFormattedText(ptrWindow, strMessage,'center','center',[],[],boolUseMirroredText);
    Screen('Flip', ptrWindow);

    %show at least 1 second
    WaitSecs(0.1);

    %wait for input
    KbWait(intInputDevice);
    
    %screen 2--------------------------------------------------------------
    
    strMessage1 = [ ...
        'Rule I: 0 back\n\n\n' ...
        'Press your index finger whenever you see this image.\n\n' ...
        'Press your middle finger if you see any other image.' ...
        ];
    strMessage2 = [ ...
        'You will never see this image in the other rules.\n\n\n' ...
        '[Press any key to continue]' ...
        ];
    
    %get text boundaries
    %note: everything is draw such that the bounding box is fitted on the
    %top left corner of the screen
    arrMessage1Boundaries = Screen('TextBounds', ptrWindow, strMessage1, 0, 0);
    arrMessage2Boundaries = Screen('TextBounds', ptrWindow, strMessage2, 0, 0);
    
    %Calculate text box positions------------------------------------------
    
    intScreenWidth = arrWindowSize(3);
    intScreenHeight = arrWindowSize(4);
    
    %message1 should be x-centered and 15% from top of the screen
    intMessage1Y = round(intScreenHeight * .15) - round((arrMessage1Boundaries(4) - arrMessage1Boundaries(2)) / 2);
    
    %message2 should be x-centered and 80% from top of the screen
    intMessage2Y = round(intScreenHeight * .8) - round((arrMessage2Boundaries(4) - arrMessage2Boundaries(2)) / 2);
    
    %----------------------------------------------------------------------

    %show the message
    DrawFormattedText(ptrWindow, strMessage1,'center',intMessage1Y,[],[],boolUseMirroredText);
    DrawFormattedText(ptrWindow, strMessage2,'center',intMessage2Y,[],[],boolUseMirroredText);
    
    %find the target image in the loaded textures
    idxTarget = strfind([structImages.filename], strTargetFile);
    if isempty(idxTarget)
        Screen('CloseAll');
        error('Failed to load target image')
    end
    
    %draw the target image without scaling
    arrPosition = structImages(idxTarget).size * .65; %slightly shrink the image  
    arrPosition(1) = arrPosition(1) + intScreenWidth * .5 - arrPosition(3) * .5;      
    arrPosition(2) = arrPosition(2) + intScreenHeight * .57 - arrPosition(4) * .5;   %adjust the image to be slightly below center
    arrPosition(3) = arrPosition(3) + intScreenWidth * .5 - arrPosition(3) * .5;
    arrPosition(4) = arrPosition(4) + intScreenHeight * .57 - arrPosition(4) * .5;
    Screen('DrawTexture', ptrWindow, structImages(idxTarget).pointer, [], arrPosition);
    
    Screen('Flip', ptrWindow);
    
    %show at least 1 second
    WaitSecs(0.1);

    %wait for input
    KbWait(intInputDevice);
    
    clear arrMessage*Boundaries intMessage*X intMessage*Y
    clear intScreenHeight intScreenWidth idxTarget arrPosition
    
    %screen 3--------------------------------------------------------------
    
    strMessage = [ ...
        'Rule II: 1 back\n\n\n' ...
        'Press your index finger whenever the image\n\n' ...
        'you see matches the previous one.\n\n' ...
        'Press your middle finger if there is no match.\n\n\n' ...
        'Since the first image has nothing before it,\n\n' ...
        'press your middle finger for the first image.\n\n\n' ...
        '[Press any key to continue]' ...
        ];

    %show the message
    DrawFormattedText(ptrWindow, strMessage,'center','center',[],[],boolUseMirroredText);
    Screen('Flip', ptrWindow);
    
    %show at least 1 second
    WaitSecs(0.1);

    %wait for input
    KbWait(intInputDevice);
    
    %screen 4--------------------------------------------------------------
    
    strMessage = [ ...
        'Rule III: 2 back\n\n\n' ...
        'Press your index finger whenever the image\n\n' ...
        'you see matches the one shown two images before.\n\n' ...
        'Press your middle finger if there is no match.\n\n\n' ...
        'Since the first two images have no images before it,\n\n' ...
        'press your middle finger for the first two images.\n\n\n' ...
        '[Press any key to continue]' ...
        ];

    %show the message
    DrawFormattedText(ptrWindow, strMessage,'center','center',[],[],boolUseMirroredText);
    Screen('Flip', ptrWindow);
    
    %show at least 0.1 second
    WaitSecs(0.1);

    %wait for input
    KbWait(intInputDevice);
    
    %screen 5--------------------------------------------------------------
    
    strMessage = [ ...
        'Before the trials actually begin,\n\n' ...
        'you will always see a screen telling you the rule.\n\n' ...
        'In between the trials, you will also see numbers\n\n' ...
        'reminding you of the rule (0, 1, or 2)\n\n\n' ...
        'The rule will stay the same until the next rule is shown.\n\n' ...
        'You will have a brief rest period after three rules.\n\n\n' ...
        '[Press any key to continue]' ...
        ];

    %show the message
    DrawFormattedText(ptrWindow, strMessage,'center','center',[],[],boolUseMirroredText);
    Screen('Flip', ptrWindow);
    
    %show at least 0.1 second
    WaitSecs(0.1);

    %wait for input
    KbWait(intInputDevice);
    
    %screen 6--------------------------------------------------------------
    
    strMessage = [ ...
        'Do you have any questions?\n\n' ...
        'We will begin the task shortly.\n\n\n' ...
        '[Press any key to continue]' ...
        ];

    %show the message
    DrawFormattedText(ptrWindow, strMessage,'center','center',[],[],boolUseMirroredText);
    Screen('Flip', ptrWindow);

    %show at least 0.1 second
    WaitSecs(0.1);

    %wait for input
    KbWait(intInputDevice);
end