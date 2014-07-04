function History = fnGetHistory(varargin)
%Author: Julian Y. Cheng
%3/11/2013
%
%This function returns a structure containing parameters relevent to the
%current execution of a script.
%
%Overloads:
%   History = fnGetHistory()
%       Returns a structure containing the fields:
%       .date: the date of when this function was called, in
%              "YYYY/MM/DD HH:SS" format.
%       .vars: all variables defined in the caller workspace; each variable
%              having its own subfield.
%
%   History = fnGetHistory('-except',{CELL_ARRAY})
%       Returns the same structure but ignores any variables defined in the
%       cell array for storage in the "vars" field.
%
%Keys:
%The follow key-value pairs are available as inputs should you wish to have
%additional subfields in the return structure. The subfields will have the
%same name as the key string, and will always be lower case. The order in
%which they appear will match that of the function call, with the exception
%that the first subfield will always be 'date', and the last subfield will
%always be 'vars'.
%   'script','STRING': the name of the caller script
%   'ver','STRING'   : the version number of the caller script
%   'id','STRING'    : a unique identifier string
%   ANY,ANY          : a custom key-value pair; the first input will be the
%                      subfield name and the second input will be assigned
%                      as its value

%get the date
arrTime = fix(clock);
History.date = [num2str(arrTime(1)),'/',num2str(arrTime(2)),'/',num2str(arrTime(3)),' ',num2str(arrTime(4)),':',num2str(arrTime(5))];

%input integrity check
if (rem(length(varargin),2) ~= 0)
    error('Odd number of inputs detected.')
end

%parse input (if any)
boolThisIsValue = false;
lstIgnore = {};
for i = 1:length(varargin)
    if boolThisIsValue  %value is stored in the key-parsing iteration
        boolThisIsValue = false;
        continue
    end
    
    switch varargin{i}
        case '-except'
            lstIgnore = varargin{i+1};
            boolThisIsValue = true;
        otherwise
            strKey = lower(varargin{i});
            eval(['History.',strKey,' = varargin{i+1};'])
            boolThisIsValue = true;
    end
end

%get all vars in caller workspace
lstVars = evalin('caller','who');
for i = 1:length(lstVars)
    if ismember(lstVars{i},lstIgnore), continue, end
    myValue = evalin('caller',lstVars{i});
    eval(['History.vars.',lstVars{i},' = myValue;'])
end