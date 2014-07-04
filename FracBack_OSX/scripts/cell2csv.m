function cell2csv(fileName, cellArray, separator, permission, excelYear, decimal)
% Writes cell array content into a *.csv file.
% 
% CELL2CSV(fileName, cellArray, separator, permission, excelYear, decimal)
%
% fileName     = Name of the file to save. [ i.e. 'text.csv' ]
% cellArray    = Name of the Cell Array where the data is in
% separator    = sign separating the values (default = ';')
% permission   = file permission, follows fopen's convention. This
%                potentially allows the user to append data to the written
%                csv file (default:'w')
% Other file permission strings can be:
%         'r'     open file for reading
%         'w'     open file for writing; discard existing contents
%         'a'     open or create file for writing; append data to end of file
%         'r+'    open (do not create) file for reading and writing
%         'w+'    open or create file for reading and writing; discard 
%                 existing contents
%         'a+'    open or create file for reading and writing; append data 
%                 to end of file
%         'W'     open file for writing without automatic flushing
%         'A'     open file for appending without automatic flushing
%
%
% excelYear    = depending on the Excel version, the cells are put into
%                quotes before they are written to the file. The separator
%                is set to semicolon (;)
% decimal      = defines the decimal separator (default = '.')
%
%         by Sylvain Fiedler, KA, 2004
% updated by Sylvain Fiedler, Metz, 06

% fixed the logical-bug, Kaiserslautern, 06/2008, S.Fiedler
% added the choice of decimal separator, 11/2010, S.Fiedler
% allowed file permission specification, 05/2013, E.Cui
% allowed file appending with correct formatting, 07/2013, E.Cui

%% Checking for optional Variables
if ~exist('separator', 'var')
    separator = ',';
end

if ~exist('excelYear', 'var')
    excelYear = 1997;
end

if ~exist('decimal', 'var')
    decimal = '.';
end

if ~exist('permission','var')
    permission = 'w';
end

%% Setting separator for newer excelYears
if excelYear > 2000
    separator = ';';
end

%% Write file

% add a newline if a file is already exist; since the csv file output by
% this function does not have an empty line at the end, appending new data
% will mess up the format
if exist(fileName,'file')
    add_new_line = true;
else
    add_new_line = false;
end

% open file for writing
datei = fopen(fileName, permission);

% add a new line if the add_new_line flag is true
if add_new_line
    fprintf(datei, '\n');
end

for z=1:size(cellArray, 1)
    for s=1:size(cellArray, 2)
        
        var = cellArray{z,s};
        % If zero, then empty cell
        if size(var, 1) == 0
            var = '';
        end
        % If numeric -> String
        if isnumeric(var)
            var = num2str(var);
            % Conversion of decimal separator (4 Europe & South America)
            % http://commons.wikimedia.org/wiki/File:DecimalSeparator.svg
            if decimal ~= '.'
                var = strrep(var, '.', decimal);
            end
        end
        % If logical -> 'true' or 'false'
        if islogical(var)
            if var == 1
                var = 'TRUE';
            else
                var = 'FALSE';
            end
        end
        % If newer version of Excel -> Quotes 4 Strings
        if excelYear > 2000
            var = ['"' var '"'];
        end
        
        % OUTPUT value
        fprintf(datei, '%s', var);
        
        % OUTPUT separator
        if s ~= size(cellArray, 2)
            fprintf(datei, separator);
        end
    end
    if z ~= size(cellArray, 1) % prevent a empty line at EOF
        % OUTPUT newline
        fprintf(datei, '\n');
    end
end
% Closing file
fclose(datei);
% END