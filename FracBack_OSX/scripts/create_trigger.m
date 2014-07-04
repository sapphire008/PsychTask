function TRIGGER_PORT = create_trigger(TRIGGER_PORT, TRIGGER_MARKER)
% query to open the trigger port
% In addition to return the TRIGGER_PORT used to create the current
% trigger, the function also construct a global variable TRIGGER to be
% accessed later by trigger_scan to send trigger signal

% clear the variables constructed previously
clearvars -global TRIGGER MARKER;

global TRIGGER;
global MARKER;

% Parse TRIGGER_PORT
if nargin<1 || isempty(TRIGGER_PORT)
    % Try Lucas 7T Serial to USB trigger
    TRIGGER_PORT = dir('/dev/tty.USA*');
    PLACE = 'LUCAS';%record the facility name recognized by the trigger
    if isempty(TRIGGER_PORT)
        % if not found, try CNI Serial to USB trigger
        TRIGGER_PORT = dir('/dev/tty.usbmodem*');
        PLACE = 'CNI';%record the facility name recognized by the trigger
    end
    
    if ~isempty(TRIGGER_PORT)
        TRIGGER_PORT = fullfile('/dev',TRIGGER_PORT.name);
    else
        TRIGGER_PORT = '/dev/tty.s0_default';%put in a fake port
    end
    %TRIGGER_PORT = '/dev/tty.USA19H62P1.1';%default port name, /dev/tty.USA*
else
    %if input is TRIGGER_PORT input is not empty, recognize PLACE
    if ~isempty(regexpi(TRIGGER_PORT,'tty.USA'))
        PLACE = 'LUCAS';
    elseif ~isempty(regexpi(TRIGGER_PORT,'tty.usbmodem'))
        PLACE = 'CNI';
    else
        PLACE = 'Unrecognized';
    end
end

% parse MARKER to trigger the scanner
if nargin<2 || isempty(TRIGGER_MARKER)
    switch PLACE
        case 'CNI'
            MARKER = '[t]';
        case 'LUCAS'
            MARKER = 't';
        otherwise
            MARKER = 't';
    end
else
    MARKER = TRIGGER_MARKER;
end
    

% construct serial port object
%serial will create object with any name
TRIGGER = serial(TRIGGER_PORT);

% try to connect the serial port object to the serial port
try
    fopen(TRIGGER);
    fprintf('Created Trigger %s\n',TRIGGER);
    fprintf('Marker %s\n',MARKER);
catch ERR
    warning(ERR.message);%give a warning instead of error
    Query = input('Which port to use instead? ','s');
    if ~isempty(Query)
        TRIGGER_PORT = Query;
    end
    % try again
    TRIGGER_PORT = create_trigger(TRIGGER_PORT);
end
end