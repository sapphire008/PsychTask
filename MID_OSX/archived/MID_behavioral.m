%function MID()

    
    %Drew:
    
    %inputDevice=1;     %find out button-box (fORP) device number
    %inputDeviceTTL=7;  %7find out TTL (t) pulse device number
    
    inputDevice=-1;   %to run behavioral or practice just on laptop use -1
    inputDeviceTTL=-1;



    %% EXPERIMENT VARIABLES:
    
    % variables contained with in the var data object, for ease of variable
    % passing. Maintains experimental state.
    
    % data specific variables are stored within the data object, this
    % object is for those variables recorded from the subject or relevant
    % to the writing out of the data. This also allows someone to save a
    % .mat instead of csv of only the relevant data.
    
    % DETAILS:
    % The mid task is set up  8 seconds each trial + a
    % variable iti of 2/4/6 seconds.
    %
    % TR 1 = Cue
    % TR 2 = Fixation
    % TR 3 = Target
    % TR 4 = Feedback
    % TR 5~7 = ITI
    %
    % BLOCK LENGTHS:
    %
    %   Block 1: 262 TR     (524 secs)
    %
    %   Block 2: 298 TR     (596 secs)
    %
    %
    
    
    % leadin/leadout times:
    var.leadin = 4.0;
    var.leadout = 2.0;
    
    % %%%%%%truly randomize ITI and cue presentation order%%%%%%%%%
    var.itis_type = [2,4,6];%types of ITI durations, in seconds
    var.num_trial.b1 = 42;%number of trials in run 1
    var.num_trial.b2 = 48;%number of trials in run2
    % itis are 2,4,6 seconds of equal probability
    %requires Statistics Toolbox
    var.itis_b1 = shuffle(repmat(var.itis_type,1,var.num_trial.b1/length(var.itis_type)));
    var.itis_b2 = shuffle(repmat(var.itis_type,1,var.num_trial.b2/length(var.itis_type)));
    % cue presentation order, categorized 1-6:
    % 1 = low square
    % 2 = med square
    % 3 = high square
    % 4 = low circle
    % 5 = med cirlce
    % 6 = high circle
    var.cue_type = 1:6;
    var.cue_b1 = shuffle(repmat(var.cue_type,1,var.num_trial.b1/length(var.cue_type)));
    var.cue_b2 = shuffle(repmat(var.cue_type,1,var.num_trial.b2/length(var.cue_type)));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
        % pseudorandom itis for block 1 and 2:
%     var.itis_b1 = [6 6 6 2 4 4 6 4 6 4 6 2 2 6 2 4 4 6 2 4 6 6 4 2 4 6 4 ...
%         2 2 6 6 6 2 2 4 4 2 4 2 2 2 4];
%     
%     var.itis_b2 = [6 4 2 2 4 4 6 2 2 6 6 4 6 4 2 6 2 6 4 6 2 6 6 4 2 4 6 ...
%         2 6 2 4 6 6 4 2 4 4 4 2 4 4 4 6 2 6 2 2 2];

   %var.itis_practice = [2 4 2 4 2 6 6 4 4 2 6 6];    %Drew: save time
   var.itis_practice = [6 2 2 2 2 2 2 2 2 2 2 2];    %Drew

    
    % cue presentation order, categorized 1-6:
    % 1 = low square
    % 2 = med square
    % 3 = high square
    % 4 = low circle
    % 5 = med cirlce
    % 6 = high circle
    %
    
%     var.cues_b1 = [1 2 6 4 3 6 4 5 3 2 4 1 5 1 2 3 4 2 5 6 6 5 2 5 3 6 3 ...
%         6 1 2 4 5 3 1 3 1 5 6 3 1 2 4];
%     
%     %trial order for fMRI version:
%     %var.cues_b1 = [1 2 2 4 4 6 4 4 3 2 5 1 5 5 6 3 4 2 1 2 6 3 6 5 3 2 5 ...
%     %    1 5 6 1 4 2 4 6 1 6 3 5 3 3 1];
% 
%      var.cues_b2 = [4 2 2 1 4 2 5 1 3 4 2 6 3 2 3 4 3 2 6 3 3 2 5 2 4 1 6 ...
%         5 1 3 6 3 5 5 6 5 4 1 2 1 5 6 1 4 5 6 1 6];
% 
%     %trial order for fMRI version:
    %var.cues_b2 = [4 2 5 1 6 2 4 1 4 3 2 6 2 4 3 2 3 3 6 6 3 2 1 3 4 5 2 ...
    %   5 1 5 6 5 3 3 6 5 5 2 1 6 4 4 1 4 5 1 1 6];
    
    var.cues_practice = [3 4 6 1 3 2 5 5 1 6 2 4];
    
    
    % image filenames block:
%     var.cir1ow = 'lowcircle.png';
%     var.cirmed = 'medcircle.png';
%     var.cirhigh = 'highcircle.png';
%     var.sqlow = 'lowsquare.png';
%     var.sqmed = 'medsquare.png';
%     var.swhigh = 'highsquare.png';
%     var.tri = 'triangle.png';
%     
%     var.image_names = {var.cirlow, var.cirmed, var.cirhigh, var.sqlow, ...
%         var.sqmed, var.sqhigh, var.tri};

    % cue presentation
    var.cue_pen = 6;
    var.cue_box = [0 0 250 250];
    
    % target presentation
    var.starname = 'tri_up.png'; %use a filled triangle image file
    var.starrect = [0 0 200 200];

    %change this reference text size depending on how big your screen is!
    var.textsize = 50;    
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
        var.usescanner = str2num(input('Use scanner? (1 or 0) ','s'));
        var.blocknumber = str2num(input('Block number? (1, 2 or 3) ','s'));
        var.runinstructions = str2num(input('Play the instructions? (1 or 0) ','s'));
        var.basert = str2num(input('Baseline RT in milliseconds? (~250 usually) ','s'));
        var.basert = var.basert/1000;
    else
        var.subjectID = 0;
        var.usescanner = 0;
        var.blocknumber = 1;
        var.runinstructions = 0;
        var.basert = .250;
        var.leadin = 1;
        var.leadout = 1;
    end
        
    if var.blocknumber == 1
        var.cues = var.cues_b1;
        var.itis = var.itis_b1;
        var.subjectID = [var.subjectID '_b1'];
    elseif var.blocknumber == 2
        var.cues = var.cues_b2;
        var.itis = var.itis_b2;
        var.subjectID = [var.subjectID '_b2'];
    elseif var.blocknumber == 3
        var.cues = var.cues_practice;
        var.itis = var.itis_practice;
        var.leadin = 2;
        var.leadout = 0;
        var.subjectID = [var.subjectID '_p'];
    end
   
    
    var.display_totals = 0;
    var.rt_change = .020;
    
    
    % Leave these empty:
    var.calibrations{1} = [];
    var.calibrations{2} = [];
    var.calibrations{3} = [];
    var.calibrations{4} = [];
    var.calibrations{5} = [];
    var.calibrations{6} = [];
    var.autobaseline = 0;
    
    data.wins{1} = [];
    data.wins{2} = [];
    data.wins{3} = [];
    data.wins{4} = [];
    data.wins{5} = [];
    data.wins{6} = [];
    
    
    %% PREPARE EXPERIMENT STRUCTURE:
    var.filepath = MakePathStruct();
    var.bkg_color = 0;
    var.textcolor = 225;
    var.font = 'Helvetica';

    screenNumber = max(Screen('Screens'));
    [Window,var.winrect] = Screen('OpenWindow',screenNumber,0);
    
    starimg = imread(var.starname);
    var.star = Screen('MakeTexture',Window,starimg);
    
    [var.starrect,dh,dv] = CenterRect(var.starrect,var.winrect);
        
    %% ENTER SCRIPTS DIRECTORY:
    cd(var.filepath.scripts)
    


    %% INITIALIZE DATA OBJECT:
    % The data object stores all of the data as the experiment runs, but
    % should be pre-initialized.
    data.drifts = [];
    data.onset_t = [];
    data.cue_t = [];
    data.target_t = [];
    data.binned_rts = [];
    data.total = 0;
    data.gains_vector = {};
    data.wins_vector = [];
    data.rt_vector = [];
    data.calibration_vector = [];
    data.cues_vector = {};
    data.calibration_current = [];   %Drew
    data.cue_onset = [];   %Drew
    data.delay_onset = [];   %Drew
    data.target_onset = [];   %Drew
    data.feedback_onset = [];   %Drew
    data.rt_all = [];   %Drew
    data.key_all = [];   %Drew

    
    %% INITIALIZE SCREEN:
    Screen('FillRect',Window,var.bkg_color); 
    Screen('Flip',Window);
    Screen('TextSize',Window,var.textsize);
    Screen('TextFont',Window,var.font);
    
    
    %% RUN THE INSTRUCTIONS:
    if var.runinstructions
        Instructions(Window)
    end
    
    
    %% WAIT TO TRIGGER SCAN:
    % Put up a "Get Ready" screen until the experimenter presses a button.
    Screen('TextSize',Window,50);
    DrawFormattedText(Window,'Get ready!','center','center',225);
    Screen('Flip',Window);
    %Drew: comment below out
%     WaitSecs(0.4);
%     triggerscanner = 0;
%     
%     while ~triggerscanner
%         [down secs key d] = KbCheck(-1);
%         if (down == 1)
%             if strcmp('space',KbName(key))
%                 triggerscanner = 1;
%             end
%         end
%         WaitSecs(.01);
%     end
%     
    Screen('TextSize',Window,var.textsize);
    
    % If the experiment is in scan mode, StartScan() will send the trigger
    % information to the scanner to begin the experiment.
    %if var.usescanner
    %    [status, scanStartTime] = StartScan();
    %    var.abs_start = scanStartTime;
    %else
    %    var.abs_start = GetSecs();
    %end
    
   %Drew: added - get the time of the first TTL pulse i.e. start of scan 
    if var.usescanner
        scanStartTime=KbTriggerWait(KbName('t'),inputDeviceTTL);
        var.abs_start = scanStartTime;
    else
        var.abs_start = GetSecs();
    end
    
    
    
    
    %% SET END REFERENCE TIME:
    % ref_end is continually updated as the end time for various functions.
    % This, along with abs_start, allows for absolute timing of functions
    % and thus drift adjust on the ITI is extremely accurate.
    var.ref_end = 0;
    
    %% LEADIN ITI:
    var.ref_end = var.ref_end+var.leadin;
    data.leadin_t = DisplayITI(Window,var,'o');
    
    
    %% MAIN EXPERIMENT LOOP
    % Runs the experiment!
    for i = 1:length(var.itis)
        
        % DETAILS:
    % The mid task is set up with 54 trials, 8 seconds each trial + a
    % variable iti of 2/4/6 seconds.
    % There are 2 blocks.
    %
    % TR 1 = Cue
    % TR 2 = Fixation
    % TR 3 = Target
    % TR 4 = Feedback
    % TR 5~8 = ITI
        
        % This records the absolute onset time of trials:
        data.onset_t(i) = GetSecs()-var.abs_start;
        
        % Present the cue (2s):
        var.ref_end = var.ref_end + 2.0;
        data = PresentCue(Window,var,data,i);
        
        % Present the fixation (2s):
        var.ref_end = var.ref_end + 2.0;
        %Drew comment out, replace with below: data.fixation_t(i) = DisplayITI(Window,var,'x');
        [timeNew,data]=DrewDisplayITI(Window,var,'x',i,data);   %Drew
        data.fixation_t(i) = timeNew;   %Drew
        
        % Present the target (2s):
        var.ref_end = var.ref_end + 2.0;
        [var, data] = PresentTarget(Window,var,data,i,inputDevice);
        
        % Present the win/loss feedback (2s):
        var.ref_end = var.ref_end + 2.0;
        data = PresentFeedback(Window,var,data,i);
        
        % Calculate the possible drift by subtracting the ideal time
        % from the accumulated time of the trial. (Note:
        % the drift time is for all slides prior to the ITI)
        data.drifts(i) = GetSecs()-var.abs_start-data.onset_t(i)-8.0;
        
        % Write the partial data into the file. This way, if the experiment
        % breaks or ends for some reason, you will have data for every
        % completed trial at least:
        PartialParseData(var,data,(i==1),i);
        
        % Update the reference end time by adding the current ITI time:
        var.ref_end = var.ref_end + var.itis(i);
        
        % Display an ITI until the reference end time is reached (this is
        % how drift is corrected for):
        data.iti_t(i) = DisplayITI(Window,var,'o');
        
        ['Cumulative total:  $' num2str(data.total, '%#4.2f')]
        positive_rts = data.rt_vector(data.rt_vector > 0);
        ['Average ms RT:  ' num2str(sum(positive_rts)*1000/length(positive_rts))]
        
    end 
    
    
    %% LEADOUT ITI:
    var.ref_end = var.ref_end+var.leadout;
    data.leadout_t = DisplayITI(Window,var,'o');
    
    cd(var.filepath.main)
     
    Screen('CloseAll');
        

%end
