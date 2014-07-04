function RunInstructions(Window)

    inst_fontsize = 30;
    inst_charwrap = 80;


    inst1 = {'You will now see a selection of the gambles that you just played.\n\n' ...
        'You will see the gamble, followed by two rating scales for that gamble.\n\n' ...
        'The top of each screen with a rating scale will indicate which rating you are being asked to make.  Please pay attention as to which of the following 2 ratings you will be asked to make:\n\n' ...
        'The AROUSAL scale\n' ...
        'The VALENCE scale\n'};

    inst2 = {'THE AROUSAL SCALE measures how aroused you are feeling at a given time.\n\n' ...
        'At the far right on this scale, you would be feeling very alert, aroused, activated, charged or energized, very physically or mentally aroused.\n\n' ...
        'At the far left, you would be feeling completely unaroused, slow, still, de-energized, no physical or mental arousal at all.\n\n' ...
        'Notice that this AROUSAL scale is a continuum going from low to high arousal.  The point in the middle of the scale would represent being moderately aroused � a point in between the two extremes.  It does not mean neutral.\n\n'...
        'Use the right arrow key to move the indicator on the scale towards higher arousal.\n\n' ...
        'Press ''space'' to continue.'};

    %(AROUSAL RATE DEMO SCREEN)

    inst3 = {'THE VALENCE SCALE measures how positive or negative you are feeling. \n\n' ...
        'At the far left you would be feeling very negative, that could be unhappy, upset, irritated, frustrated, angry, sad, depressed, or some other negative feeling. \n\n ' ...
        'At the far right you would be feeling very positive: That could be happy, pleased, satisfied, competent, proud, content, delighted, or some other positive feeling. \n\n' ...
        'In the middle of this scale you would be feeling completely neutral, neither positive or negative.  From the neutral midpoint, the ratings get gradually more negative as you move left, and gradually more positive as you move right.\n\n' ...
        'Use the left arrow key to move the indicator on the scale towards negative and the right arrow key to move the indicator towards positive.'};

    %(VALENCE RATE DEMO SCREEN)

    inst4 = {'Think about the scales as capturing separate aspects of your how you are feeling.\n\n' ...
        'So, the arousal scale doesn�t tell us whether you are feeling good or bad; it�s capturing more this idea of physical or mental activation.  So, for example you could be feeling very aroused and positive (suppose you were really excited because you had just won a prize) or very aroused and negative (suppose you were really angry because someone had just stolen your parking space).\n\n' ...
        'On the other hand, you could be feeling really unaroused and positive (if you were relaxing and looking at a beautiful sunset) or really unaroused and negative (if you were feeling down and depressed).\n\n' ...
        'We want you to report the negative or positive dimension of your feeling on the one scale, and the arousal aspect on the other.'};

    inst5 = {'Please make each rating individually for that particular gamble.\n\n' ...
        'Please make your ratings as accurately as possible. \n\n' ...
        'Press ''space'' after a rating when you are ready to advance to the next trial.'}


end