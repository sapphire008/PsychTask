function varargout = MID_gui(varargin)
% Pops up a GUI interface to initialize tasks.
% MID_GUI M-file for MID_gui.fig

% Last Modified by GUIDE v2.5 21-Aug-2013 21:07:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MID_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @MID_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

% End initialization code - DO NOT EDIT

% --- Executes just before MID_gui is made visible.
function MID_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MID_gui (see VARARGIN)

% Add interface variables to the GUI structure
handles.params.subject_ID = '';
handles.params.baseline_RT = 0;
handles.params.block_num = '';
handles.params.use_scanner = 0;
handles.params.play_instructions = 0;

% Update handles structure
guidata(hObject, handles);

initialize_gui(hObject, handles, false);

% UIWAIT makes MID_gui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MID_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Output the set parameters to the command window
varargout{1} = handles.params;
%close the input figure
close(handles.figure1);


% --- Executes during object creation, after setting all properties.
function subject_ID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subject_ID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function subject_ID_Callback(hObject, eventdata, handles)
% hObject    handle to subject_ID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subject_ID as text

% Save the new subject_ID value
handles.params.subject_ID = get(hObject,'String');
% Update the handles structure
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function baseline_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to baseline_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function baseline_RT_Callback(hObject, eventdata, handles)
% hObject    handle to baseline_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of baseline_RT as text
%        str2double(get(hObject,'String')) returns contents of baseline_RT as a double
baseline_RT = str2double(get(hObject, 'String'));
if isnan(baseline_RT)
    set(hObject, 'String', 0);
    errordlg('Input must be a number','Error');
end

% Save the new baseline_RT value
handles.params.baseline_RT = baseline_RT;
% Update the handles structure
guidata(hObject,handles)

% --- Executes on button press in calculate.
function Start_Callback(hObject, eventdata, handles)
% hObject    handle to calculate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get all the parameters and return the value
handles.params.subject_ID = get(handles.subject_ID, 'String');
handles.params.baseline_RT = str2double(get(handles.baseline_RT,'String'));
contents = get(handles.block_num,'String');
handles.params.block_num = contents{get(handles.block_num,'Value')};
handles.params.use_scanner = get(handles.use_scanner,'Value');
handles.params.play_instructions = get(handles.play_instructions,'Value');
% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);
return;

% --- Executes on button press in reset.
function reset_Callback(hObject, eventdata, handles)
% hObject    handle to reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%return all values to the default
initialize_gui(gcbf, handles, true);



% --------------------------------------------------------------------
function initialize_gui(fig_handle, handles, isreset)
%set all the parameters to default
set(handles.subject_ID, 'String', '');%set Subject ID to be empty
set(handles.baseline_RT,  'String', '250');%set baseline RT to 250
set(handles.block_num, 'Value',1);%set block number to Practice
set(handles.use_scanner,'Value',true);%turn on use scanner
set(handles.play_instructions,'Value',false);%turn off play instructions

% Update handles structure
guidata(handles.figure1, handles);


% --- Executes on button press in "Use Scanner"
function use_scanner_Callback(hObject, eventdata, handles)
% hObject    handle to use_scanner (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of use_scanner
handles.params.use_scanner = get(hObject,'Value');
guidata(hObject,handles);

% --- Executes on button press in "Play Instructions"
function play_instructions_Callback(hObject, eventdata, handles)
% hObject    handle to play_instructions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of play_instructions
handles.params.play_instructions = get(hObject,'Value');
guidata(hObject,handles);

% --- Executes on selection change in block_num.
function block_num_Callback(hObject, eventdata, handles)
% hObject    handle to block_num (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns block_num contents as cell array
%        contents{get(hObject,'Value')} returns selected item from block_num
contents = get(hObject,'String');
block_select = contents{get(hObject,'Value')};%find which one is selected
%pass down the parameter according to which block is selected.
switch block_select
    case {1}
        handles.params.block_num = 'Practice';
    case {2}
        handles.params.block_num = 'Block1';
    case {3}
        handles.params.block_num = 'Block2';
end
% Update handles structure
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function block_num_CreateFcn(hObject, eventdata, handles)
% hObject    handle to block_num (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
