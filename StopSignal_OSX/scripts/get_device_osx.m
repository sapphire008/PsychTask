function deviceID = get_device_osx(manufacturer,usageName,prompt_message,disp_device)
% By default, find Apple Keyboard
if nargin<1 || isempty(manufacturer)
    manufacturer = 'apple';
end
if nargin<2 || isempty(usageName)
    usageName = 'keyboard';
end
if nargin<3 || isempty(prompt_message)
    prompt_message = 'Keyboard Input Device : ';
end
if nargin<4 || isempty(disp_device)
    disp_device = true;
end
% get a list of devices
%find the number of devices
%numDevices=PsychHID('NumDevices');

%get the device info, returned as a structure with different fields
devices=PsychHID('Devices');

% get indices of target product
manufacturer_deviceIND = ~cellfun(@isempty,cellfun(@(x) regexpi(x,manufacturer),{devices.manufacturer},'un',0));

% get indices of target usageNames
usageName_deviceIND = ~cellfun(@isempty,cellfun(@(x) regexpi(x,usageName),{devices.usageName},'un',0));

% get intersection device IND
deviceIND = find(manufacturer_deviceIND & usageName_deviceIND);

% if more than one device meet the criteria, let the user select
if numel(deviceIND)>1
    fprintf('Multiple devices meet the criteria\nproduct: %s\nusageName: %s\n',manufacturer,usageName);
    % Display a list of available devices
    disp('---------------------------------------------');
    for n=1:numel(deviceIND)
        fprintf('Device #%d\n',devices(deviceIND(n)).index); %this is the device number which the Psychtoolbox scripts need
        disp(devices(n));
        disp('---------------------------------------------');
    end
    % prompt user
    deviceID = input(prompt_message);
elseif isempty(deviceIND)
    % if nothing is found, give the user the whole list
    %fprintf('No device meets the criteria\nproduct: %s\nusageName: %s\n',product,usageName);
    disp('Please select the device from the following list:');
    disp('---------------------------------------------');
    for n=1:numel(devices)
        fprintf('Device #%d\n',n); %this is the device number which the Psychtoolbox scripts need
        disp(devices(n));
        disp('---------------------------------------------');
    end
    % prompt user
    deviceID = input(prompt_message);
else%if devices are found
    deviceID = devices(deviceIND).index;
    % display the used device
    if disp_device
        disp('Device used: ');
        disp('---------------------------------------------');
        disp(devices(deviceIND));
        disp('---------------------------------------------');
        % ask the user if satisfied with the device?
        PROMPT = input('Is this device correct? [0|1]');
        if ~PROMPT
            disp('Please select the device from the following list:');
            disp('---------------------------------------------');
            for n=1:numel(devices)
                fprintf('Device #%d\n',n); %this is the device number which the Psychtoolbox scripts need
                disp(devices(n));
                disp('---------------------------------------------');
            end
            % prompt user
            deviceID = input(prompt_message);
        end
    end
end
end