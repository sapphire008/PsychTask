%find the number of devices
numDevices=PsychHID('NumDevices');

%get the device info, returned as a structure with different fields
devices=PsychHID('Devices');


%loop through each device and print out the important and relevant data required in the script
for n=1:numDevices,
n %this is the device number which the Psychtoolbox scripts need
devices(n)
end;
