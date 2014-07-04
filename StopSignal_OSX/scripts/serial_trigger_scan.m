function timeBlockOnset = serial_trigger_scan()
% triggering the scanner by sending a bit of data
% Requires global variables TRIGGER and MARKER to be constructed 
% by create_trigger
global TRIGGER;
global MARKER;

% write to the port
fprintf(TRIGGER,MARKER);
% get current time of onset
timeBlockOnset = GetSecs();
% close the port
fclose(TRIGGER);
%clear GLOBAL TRIGGER MARKER;
end