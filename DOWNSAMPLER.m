%{
    AUTHOR: Khang Pham
    DATE:   December 1, 2022
    TITLE:  "Downsampler"
%}
function [downsamp] = DOWNSAMPLER(SYMBOLinput, num_downsamp)
    % 'SYMBOLinput'  = (VECTOR) input being downsampled
    % 'num_downsamp' = (INTEGER) number of times upsampled

    downsamp = [];
    downsample_array = 1;  %ESTABLISHES DOWNSAMPLE VARIABLE ARRAY VALUE
    
    for i = 1 : num_downsamp : length(SYMBOLinput) %INCR BY SAMPLES/SECOND
        downsamp(downsample_array) = SYMBOLinput(i);
        downsample_array = downsample_array + 1;
    end
end