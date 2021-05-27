%% Mechanical Testing Processing 
% Copyright: Andy Zhang, version 1.1, 05/26/21
clear all 
close all

%% README: Instruction
% This code is for processing 1) Compression, 2) Indentation and 3) Dynamic
% Testing (updating). To start, simply runs the program and select the
% folder which contains all data you would like to process. For each
% sample, there will be EXACTLY four text files. Make sure there is no
% extra/missing text file in the folder. 
% After initiate the program, 
%   1) Select testing method
%   2.1) For compression, input the diameter (mm), %strain (example, 10 -> 10%)
%      and relax time (s). 
%   2.2) For indentation, select the testing method and indentor diameter.
%      Input the indentation depth.
%   2.3) For dynamic Testing, not supported yet.
%   3) Hit confirm after double check all selection/input. Note: make sure to 
%      double check everything before confirm to save time. 
% In the workspace, the output will be 
%   1) Modulus -> the calculated young's modulus in kPa
%   2) PeakForce -> the maximum load in gram
%   3) Diameter -> diameter of each sample if doing compression 
% In the directory of this code, an excel file that contains all the result will be generated.

%% Main driving code

% Load file
Files = Read_file();

% Choose Testing Method, Determine if creeping exsit, then process
Test = Methods();

% Based on selection, return [Modulus(kPa),PeakForce]
[Modulus,PeakForce,Diameter] = Process(Test,Files);

%% Select file
function Files = Read_file(~)
    % Locate the directory of the folder
    selpath = uigetdir;
    cd(selpath)
    files = dir('*.txt');
    
    Creep_file = {};
    Height_file = {};
    Dynamic_file = {};
    Data_file = {};
    
    % Sort different files
    for i = 1:length(files)
        file_name = files(i).name;
        if contains(file_name,'creeptime')
           Creep_file = [Creep_file; cellstr(file_name)];
        elseif contains(file_name,'height')
           Height_file = [Height_file;cellstr(file_name)];
        elseif contains(file_name,'startime')
           Dynamic_file = [Dynamic_file;cellstr(file_name)];
        else
           Data_file = [Data_file;cellstr(file_name)];
        end      
    end
    
    % Format Output
    Files = struct('Raw_data',Data_file,'Height',Height_file,...
                   'Creep',Creep_file,'Dynamic',Dynamic_file); 
end

%% Select Testing Method
function Test = Methods(~)
    
    % Create interface
    Fig = uifigure('Name',"What test did you do?",'Position',[0 0 300 300]);
    Fig.Resize = 'off';
    movegui(Fig,'center')

    % Select testing method 
    Method = uibuttongroup(Fig,'Position',[100 150 110 70]);
    Ind = uiradiobutton(Method,'Position',[10 50 91 15]);
    Com = uiradiobutton(Method,'Position',[10 30 91 15]);
    Dyn = uiradiobutton(Method,'Position',[10 10 91 15]);
    
    Ind.Text = 'Indentation';
    Com.Text = 'Compression';
    Dyn.Text = 'Dynamic';

    % Confirm Selection 
    Confirm = uibutton(Fig,'Position',[100 40 100 50],...
        'ButtonPushedFcn', @(Confirm,event) ButtonPushed(Fig));
    Confirm.Text = 'Confirm';
    uiwait(Fig);
    
    % Return choice
    Test = [Ind.Value,Com.Value,Dyn.Value];
    delete(Fig);
    
    function ButtonPushed(Fig)
        uiresume(Fig);
    end
    
end 

%% Processing Decision
function [Modulus,PeakForce,Diameter] = Process(Test,Files)
    [~,Index] = max(Test);
    
    if Index == 1 % Indentation
      [Modulus,PeakForce] = Indentation(Files);
      Diameter = nan;
    elseif Index == 2 % Compression 
      [Modulus,PeakForce,Diameter] = Compression(Files);
    else % Dynamic Testing

    end

end

%% Compression Process
function [Modulus,PeakForce,Diameter] = Compression(Files)
    % Create UI figure for diameter input 
    Fig = uifigure('Name',"Please put in the diameters and strian");
    
    % Sort Files
    for i = 1:length(Files)
        FileName{i,1} = Files(i).Raw_data;
        SampleHeight(i,1) = importdata(string(Files(i).Height));
        CreepTime(i,1) = importdata(string(Files(i).Creep));
        Diameter(i,1) = 0;
    end
    Columns = {'Filename','Sample Height(mm)','Creep Time(s)','Diameter(mm)'};
    Table = table(FileName,SampleHeight,CreepTime,Diameter);
    InputTable = uitable(Fig,'Position',[30 100 500 300],'ColumnName',Columns,...
                              'Data',Table,'ColumnEditable',[false false false true]);
                          
    % Input Strain and relax Time
    Strain_label = uilabel(Fig,'Position',[100 50 100 20],'Text','Input % Strain');
    Strain_edt = uieditfield(Fig,'numeric','Position',[200 50 50 20]);
    Strain_edt.Value = 10;
    RelaxT_label = uilabel(Fig,'Position',[80 30 150 20],'Text','Input Relax Time (s)');
    RelaxT_edt = uieditfield(Fig,'numeric','Position',[200 30 50 20]);
    RelaxT_edt.Value = 600;
    
    % Confirm Input
    Confirm = uibutton(Fig,'Position',[400 40 100 50],...
        'ButtonPushedFcn', @(Confirm,event) ButtonPushed(Fig));
    Confirm.Text = 'Confirm';
    uiwait(Fig);
    
    % Return Diameter and strain
    Diameter = InputTable.Data{:,4}; 
    Strain = Strain_edt.Value/100; % To decimal, Ex. 10% -> 0.1 
    RelaxTime = RelaxT_edt.Value;
    
    delete(Fig);
    function ButtonPushed(Fig)
        uiresume(Fig);
    end

    % Processing and assign output 
    for i = 1:length(FileName)
        [Modulus(i,1),PeakForce(i,1)] = CompressionProcess(FileName(i),CreepTime(i),...
                                    Diameter(i),RelaxTime,Strain);
        continue;
    end
    
    % Output data to spreadsheet
    Filename = string(datetime('now')) + ".xlsx";
    ColumnName = {'File name','Height(mm)','Creep Time(s)','Diameter(mm)','PeakForce(g)','Modulus(kPa)'};
    OutputTable = table(FileName,SampleHeight,CreepTime,Diameter,PeakForce,Modulus,...
                        'VariableNames',ColumnName);
    writematrix([RelaxTime;Strain],Filename,'Sheet','Result','Range','B1:B2');
    writecell({'Relax Time(s)';'Strain'},Filename,'Sheet','Result','Range','A1:A2');
    writetable(OutputTable,Filename,'WriteVariableNames',true,...
                                    'WriteMode','append');
end

function [Modulus,PeakForce] = CompressionProcess(FileName,CreepTime,Diameter,RelaxTime,Strain)
    RawData = importdata(string(FileName));
    
    % Extract data
    Position = -RawData.data(:,1);
    Load = -(RawData.data(:,2) - RawData.data(1,2)); 
    
    % Convert Time
    Time = RawData.textdata;
    Reference = convertTo(datetime(Time(1),'InputFormat','dd-mm-yyyy HH:mm:ss.SS'),'posixtime');
    TimeScale = zeros(size(Time));
    TimeScale(1,1) = 0;
    TimeScale(2:end,1) = convertTo(datetime(Time(2:end,1),'InputFormat',...
                                   'dd-mm-yyyy HH:mm:ss.SS'),'posixtime') - Reference;
    
    % Error check for relax time
    if RelaxTime > max(TimeScale)
        msg = "Please double check your relax time(s)";
        error(msg);
    end
    
    % Find initial load based on creep time
    CreepIndex = TimeScale >= CreepTime;
    InitLoad = mean(Load(find(CreepIndex,5),1));
    
    % Find final load based on peak force and relax time 
    [PeakForce,PeakIndex] = max(Load);
    RelaxIndex = TimeScale >= (TimeScale(PeakIndex) + RelaxTime);
    AverageWindow = 10; % Final Load average range
    FinalLoad = mean(Load(find(RelaxIndex,1)-AverageWindow:find(RelaxIndex,1),1));
    
    % Error check and Calculate Modulus 
    Area = pi*(Diameter/2 * (10^-3) )^2; % m^2
    Force = abs(FinalLoad-InitLoad) * 9.81 * (10^-3); % N
    Modulus = Force / Area / Strain / (10^3); % kPa
    
end

%% Indentation Process
function [Modulus,PeakForce] = Indentation(Files)
    % Create uifigure for model selection
    Fig = uifigure('Name',"Please enter parameters",'Position',[0,0,300,300]);
    Fig.Resize = 'off';
    movegui(Fig,'center')
    
    % Sort Files
    for i = 1:length(Files)
        FileName{i,1} = Files(i).Raw_data;
        CreepTime(i,1) = importdata(string(Files(i).Creep));
    end
    
    % Model Selection
    Modlabel = uilabel(Fig,'Position',[20 265 250 50],'Text','Please Select a Model: ');
    ModelChoice = uibuttongroup(Fig,'Position',[20 200 260 80]);
    Hertz = uiradiobutton(ModelChoice,'Position',[10 50 250 15]);
    OliPhar = uiradiobutton(ModelChoice,'Position',[10 30 280 15]);
    Hertz.Text = 'Hertz Model (Using Loading Curve)';
    OliPhar.Text = 'Oliver-Phar Model (Using Unloading Curve)';
    
    % Oliver-Phar Model relax time
    RelaxT_label = uilabel(Fig,'Position',[48 190 150 50],'Text','Oliver-Phar Relax Time (s)');
    RelaxT_edt = uieditfield(Fig,'numeric','Position',[200 205 50 20]);
    RelaxT_edt.Value = 0;
    
    % Indentor Size Selection
    Sizelabel = uilabel(Fig,'Position',[20 160 250 50],'Text','Please Select a Indentor Size: ');
    IndSizeHoice = uibuttongroup(Fig,'Position',[20 100 110 70]);
    one = uiradiobutton(IndSizeHoice,'Position',[10 50 91 15]);
    two = uiradiobutton(IndSizeHoice,'Position',[10 30 91 15]);
    three = uiradiobutton(IndSizeHoice,'Position',[10 10 91 15]);
    one.Text = "1mm";
    two.Text = "2mm";
    three.Text = "3mm";
    
    % Indentation Depth
    Depth_label = uilabel(Fig,'Position',[20 70 300 20],'Text','Input Indentation Depth (Micron); ');
    Depth_edt = uieditfield(Fig,'numeric','Position',[200 70 50 20]);
    Depth_edt.Value = 100;
    
    % Confirm Input
    Confirm = uibutton(Fig,'Position',[20 15 100 50],...
        'ButtonPushedFcn', @(Confirm,event) ButtonPushed(Fig));
    Confirm.Text = 'Confirm';
    uiwait(Fig);
    
    % Collect Parameters 
    Model = [Hertz.Value,OliPhar.Value];
    IndentorSize = [one.Value,two.Value,three.Value]; 
    Depth = Depth_edt.Value; % Collect Depth just in case 
    RelaxTime = RelaxT_edt.Value;
    
    delete(Fig);
    function ButtonPushed(Fig)
        uiresume(Fig);
    end

    % Processing and assign output
    [~,Index] = max(Model);
    if Index == 1
        [Modulus,PeakForce] = HertzProcess(FileName,CreepTime,find(IndentorSize,1));
        TestingMethod = "Hertz";
    else
        [Modulus,PeakForce] = OliPharProcess(FileName,find(IndentorSize,1),RelaxTime);
        TestingMethod = "Oliver-Phar";
    end
    
    % Output data to spreadsheet
    Filename = string(datetime('now')) + ".xlsx";
    ColumnName = {'File name','Creep Time(s)','PeakForce(g)','Modulus(kPa)'};
    OutputTable = table(FileName,CreepTime,PeakForce,Modulus,...
                        'VariableNames',ColumnName);
    OutputParameter = [0.45; find(IndentorSize,1); Depth;RelaxTime];
    OutputParaName = {'Paisson Ratio';'Indentor Size(mm)';'Depth (micron)';'Relax Time(s)'};
    writecell({"Model",TestingMethod},Filename,'Sheet','Result','Range','A1:B1');
    writecell(OutputParaName,Filename,'Sheet','Result','Range','A2:A5');
    writematrix(OutputParameter,Filename,'Sheet','Result','Range','B2:B5');
    writetable(OutputTable,Filename,'WriteVariableNames',true,...
                                    'WriteMode','append');

end

function [Modulus,PeakForce] = HertzProcess(FileName,CreepTime,IndentorSize)
    % Hertz model parameters    
    PoissonRatio = 0.45;
    IndentorSize = IndentorSize * (10^-3) / 2; % Radius, m
        
    for i = 1: length(FileName)
        % Import raw data, extract data
        RawData = importdata(string(FileName(i)));
        Position = -RawData.data(:,1);
        Load = -(RawData.data(:,2) - RawData.data(1,2)); 
        
        % Convert Time
        Time = RawData.textdata;
        Reference = convertTo(datetime(Time(1),'InputFormat','dd-mm-yyyy HH:mm:ss.SS'),'posixtime');
        TimeScale = zeros(size(Time));
        TimeScale(1,1) = 0;
        TimeScale(2:end,1) = convertTo(datetime(Time(2:end,1),'InputFormat',...
                                       'dd-mm-yyyy HH:mm:ss.SS'),'posixtime') - Reference;
        % Find loading curve based on start point and peak force
        CreepIndex = TimeScale >= CreepTime(i);
        Start = find(CreepIndex,1);
        [PeakForce(i,1),End] = max(Load);
        Force = Load(Start:End) * (9.81 * 10^-3); % N
        Deformation = Position(Start:End) * (10^-6); % m
        Modulus(i,1) = real((4 * Deformation.^(3/2) * sqrt(IndentorSize))...
            \(3 * (1-PoissonRatio^2) * Force )) * (10^-3); %kPa
    end
    
end

function [Modulus,PeakForce] = OliPharProcess(FileName,IndentorSize,RelaxTime)
     % Oliver Phar model parameters    
    PoissonRatio = 0.45;
    IndentorSize = IndentorSize * (10^-3) / 2; % Radius, m

    for i = 1: length(FileName)
        % Import raw data, extract data
        RawData = importdata(string(FileName(i)));
        Position = -RawData.data(:,1);
        Load = -(RawData.data(:,2) - RawData.data(1,2)); 
        
        % Convert Time
        Time = RawData.textdata;
        Reference = convertTo(datetime(Time(1),'InputFormat','dd-mm-yyyy HH:mm:ss.SS'),'posixtime');
        TimeScale = zeros(size(Time));
        TimeScale(1,1) = 0;
        TimeScale(2:end,1) = convertTo(datetime(Time(2:end,1),'InputFormat',...
                                       'dd-mm-yyyy HH:mm:ss.SS'),'posixtime') - Reference;
                                   
        % Find the unloading curve based on peak force and relax time 
        [PeakForce(i,1),PeakIndex] = max(Load);
        RelaxIndex = TimeScale >= (TimeScale(PeakIndex) + RelaxTime + 5); % +5 for delayed movement
        Start = find(RelaxIndex,1);
        WindowSize = 15; % Loading Curve size
        UnLoadCurve = Load(Start:Start+WindowSize) * (9.81 * 10^-3); % N
        Deformation = Position(Start:Start+WindowSize) * (10^-6); % m
        Area = pi * IndentorSize * max(Position); % m^2
        
        % Find slope of unloading curve, and modulusw
        Stiffness = polyfit(Deformation,UnLoadCurve,1);
        Modulus(i,1) = (sqrt(pi)/2) * (1 - PoissonRatio^2) * ( Stiffness(1,1) / sqrt(Area)); %kPa
    end
    
end



