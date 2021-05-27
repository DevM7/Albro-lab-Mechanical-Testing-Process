# Albro-lab-Mechanical-Testing-Process
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
