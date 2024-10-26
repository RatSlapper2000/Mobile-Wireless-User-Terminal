clear
clc
%{
    AUTHOR: Khang Pham
    DATE:   October 20, 2022
    TITLE:  "EE5368 Project 2:
            BER simulation for different wireless 
            channel methods"
    REFERENCES: (1)  Dr. Qilian Liang
                (2) Mathworks.com
%}

%PROBLEM 3:
boop = [...
0.056281951976541,...                
0.037506128358926,...
0.022878407561085,...   
0.012500818040738,...   
0.005953867147779,...   
0.002388290780933];

%FROM SNR CALIBRATION:
%PROBLEM 1:
 %{
VARsignal = 0.051992549549251; %K_dB = 7, fd = 20
VARnoise = 0.499345336061915;  %K_dB = 7, fd = 20
%}

%PROBLEM 2:
% %{
VARsignal = 2.817770686316203e-04; %K_dB = 12, fd = 100
VARnoise = 0.544908124316449;      %K_dB = 12, fd = 100
%}

% TX OUTPUT SIGNAL CONSTRUCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%UNIQUE WORD CONSTRUCTION:
uni = [0 0 0 0 1 1 1 1]; %generate 8 "unique" bits
unique = [uni uni uni uni uni uni]; %append 6 times for 48 "symbols"
unique_bits = [unique unique]; %two bits per symbol
    %generating unique words takes months to derive.
    %in this case, just create random bits.

%INFORMATION BITS CONSTRUCTION:
n = 500 * 2;  %COLUMNS (500 symbols, 2 bits per symbol)
information = randi([0 1], 1, n); %generate information bits

%GUARD BITS CONSTRUCTION:
guard = [0 0 0];
guard_bits = [guard guard]; %two bits per symbol

%BURST CONSTRUCTION (append all):
burst = [guard_bits, unique_bits, information, guard_bits];

%QPSK MODULATION (function):
symbol = QPSK_mod(burst); %USE QPSK_mod() function

%UPSAMPLING (function):
num_samp = 16; %samples per symbol
upsamp = UPSAMPLER(symbol, num_samp); %USE UPSAMPLER() function

%PULSE SHAPING FILTER + FILTERING + TRUNCATION:
beta = 0.3;     %filter roll-off factor(given)
span = 7;       %samples/symbol and span determine filter's "taps"
sps = num_samp;
filter = rcosdesign(beta, span, sps, 'sqrt');
TXFilterOutput = conv(upsamp, filter); %BURST AFTER PULSE FORMING
TXoutput = TRUNCATOR(TXFilterOutput, filter); %USE TRUNCATOR() function

% CHANNEL SIMULATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
burst_speed = 0.5e-3;
SymR8 = length(symbol) / burst_speed;
fd = 20;        %USER INPUT(Hz)
K_dB = 7;       %USER INPUT(dB)
EbNo_dB = 1;    %USER INPUT(dB)

%GENERATE RICIAN CHANNEL:
[GI,GQ] = Rician_KPham(fd, length(TXoutput), SymR8, K_dB);
G = GI + 1j*GQ;

%GENEARATE CHANNEL OUTPUT:
Rician_output = TXoutput .* (GI + 1j*GQ);

%ADD AWGN NOISE:
EsNo_dB = EbNo_dB + 3; %for QPSK
POWERnoise = (10^(-EsNo_dB/20))*(VARsignal/VARnoise); %derived in class
    %VARsignal from channel calibration
    %VARnoise from channel calibration
noise = randn(1,length(Rician_output)) + 1j*randn(1,length(Rician_output));
noise = noise / sqrt(2); %NORMAIZE THE DAMN NOISE. avg(|noise|^2) = 1
noise = POWERnoise * noise; %correct?
CHoutput = Rician_output + noise;

% RX SIGNAL PROCESSING + DEMODULATOR DESIGN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MATCHED FILTER:
RXfilter = rcosdesign(beta, span, sps, 'sqrt');
RXFilterOutput = conv(CHoutput, RXfilter);
RXinput = TRUNCATOR(RXFilterOutput, RXfilter); %USE TRUCATOR() FUNCTION

%DOWNSAMPLING (function):
downsamp = DOWNSAMPLER(RXinput, num_samp); %USE DOWNSAMPLER() FUNCTION

%BLOCK PHASE ESTIMATION:
[Z,G,theta]= BPE_test([downsamp],... ENTIRE DOWNSAMPLED RX-INPUT
             [unique],... UNIQUE SYMBOL VECTOR(48 symbols)
             [length(guard)+1:(length(unique)+length(guard))],...
             50,...  BLOCK SIZE (keep constant)
             10,...   STEP SIZE (decrease for higher estimation resolution
             angle(G));
         % OUTPUTS: (1) 'Z'     = channel compensation output
         %          (2) 'G'     = 
         %          (3) 'theta' = phase of channel
%{
TROUBLESHOOTING:
figure(21)
plot(theta)
title('ESTIMATED CHANNEL PHASE')
%}
         
%HARDSLICER (function):
RXburst = QPSK_demod(Z); %USE QPSK_demod() FUNCTION

%BURST EXTRACTOR (function):
INFO_bits = Burst_Extractor(RXburst,...
                            length(guard_bits),...
                            length(unique_bits));

%BER CALCULATIONS:
BER = 0;
for i = 1 : length(INFO_bits)
    if (INFO_bits(i) ~= information(i))
        BER = BER + 1;
    end
end
BER = BER / length(INFO_bits)

 %{
%TROUBLESHOOTING:
figure(1)
bar(burst)
title('TRANSMIT BURST')

figure(2)
bar(RXburst)
title('RECEIVED BURST')
%}







