function lstFiles = fnGetFileList(strPath,varargin)
%Author: Julian Y. Cheng
%3/21/2013
%
%This function returns a cell array of all filenames found within a path 
%(wildcards accepted).
%
%Overloads:
%   lstFiles = fnGetFileList(strPath)
%       Returns all files found matching the search path.
%
%   lstFiles = fnGetFileList(strPath, true)
%       Returns all directories found matching the search path.
%
%   lstFiles = fnGetFileList(strPath, strFilter)
%       Returns all files found matching the search path and the filter
%       regular expression.
%
%Changelog:
%   7/10/2013:  Added file filter.

lstResults = dir(strPath);
lstFiles = {lstResults.name};

%check if files or directories should be returned
if (nargin > 1) && ...
   ((islogical(varargin{1}) && logical(varargin{1})) || (isnumeric(varargin{1}) && logical(varargin{1})))
    lstFiles(~[lstResults.isdir]) = [];
else
    lstFiles([lstResults.isdir]) = [];
end

%remove "." and ".." entries
lstFiles(cellfun(@(x) strcmp(x,'.'),lstFiles)) = [];
lstFiles(cellfun(@(x) strcmp(x,'..'),lstFiles)) = [];

%check if file filter is on
if (nargin > 1) && ischar(varargin{1})
    strRegex = varargin{1};
    lstFiles(cellfun(@isempty,regexp(lstFiles,strRegex))) = [];
end