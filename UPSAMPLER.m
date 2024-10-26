%{
    AUTHOR: Khang Pham
    DATE:   December 1, 2022
    TITLE:  "Upsampler"
%}
function [upsamp] = UPSAMPLER(SYMBOLinput, num_upsamp)
    % 'SYMBOL_input'    = (VECTOR) input being upsampled
    % 'num_upsamp'      = (INTEGER) number of times upsampled
    % NOTES: (1)TWO WAYS TO UPSAMPLE, replicating inputs or filling with 0
    
    %REPLICATING INPUTS:
     %{
    upsamp = [];        %upsamp = zeros(1, num_samples*length(symbol));
    upsample_array = 0; %init array assignment for symbol(k)
    
    for i = 1 : length(SYMBOLinput)
        for m = 1 : num_upsamp
            upsamp(upsample_array + m) = SYMBOLinput(i);
        end
        upsample_array = upsample_array + num_upsamp;
    end
    %}
    
    %FILLING WITH ZEROS:
    % %{
    upsamp = [];
    upsample_array = 1;
    
    %for i = 1 : length(SYMBOLinput)
    for i = 1 : length(SYMBOLinput)
        for m = 1 : num_upsamp
        %for m = 1 : num_upsamp
            upsamp(upsample_array) = SYMBOLinput(i);
            upsamp((upsample_array+m) : (upsample_array+num_upsamp-1)) = 0;
        end
        upsample_array = upsample_array + num_upsamp;
    end
    %}
end