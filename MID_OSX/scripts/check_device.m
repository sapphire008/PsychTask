function varargout = check_device(varargin)
% [inputDevice,inputDeviceTTL] = check_device('device1','device2')
%   For 'option':
%       1). empty, or, '', or both 'response' and 'ttl' together: 
%                         will query both response box and TTL device
%       2). 'response':   will query only response box device
%       3). 'ttl':        will query only ttl device
%
% manually check input devices

% written by David (Drew) Fegen May 2013
% Updated as a function by Edward Cui September 2013

Type_Devices = {'response','ttl'};
Device_prompt = {'Keyboard Input Device Number: ',...
    'TTL pulse Input Device Number: '};


%find the number of devices
numDevices=PsychHID('NumDevices');

%get the device info, returned as a structure with different fields
devices=PsychHID('Devices');


%loop through each device and print out the important and relevant data required in the script
disp('---------------------------------------------');
for n=1:numDevices,
fprintf('Device #%d\n',n); %this is the device number which the Psychtoolbox scripts need
disp(devices(n));
disp('---------------------------------------------');
end

if isempty(varargin)|| isempty(varargin{1})
    flag = Type_Devices;
else
    flag = cellfun(@lower,varargin,'un',0);
    %make sure the prompt is still the same order correpondingly
    [tmp,LOCB] = ismember(varargin,Type_Devices);
    Device_prompt = Device_prompt(LOCB);
end

% ask the user to input the corresponding device numbers
varargout = cell(1,numel(flag));
for n = 1:numel(flag)
    varargout{n} = input(Device_prompt{n});
end
end
