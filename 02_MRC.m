clear
clc
%{
    AUTHOR: Khang Pham
    DATE:   October 20, 2022
    TITLE:  "EE5368 Project 2:
            BER simulation for different wireless 
            channel methods"
    REFERENCES: (1) Dr. Qilian Liang
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

%RICIAN CHANNEL 1:
[GI1,GQ1] = Rician_KPham(fd, length(TXoutput), SymR8, K_dB);
G1 = GI1 + 1j*GQ1;
Rician_output1 = TXoutput1 .* G1;

%RICIAN CHANNEL 2:
[GI2,GQ2] = Rician_KPham(fd, length(TXoutput), SymR8, K_dB);
G2 = GI2 + 1j*GQ2;
Rician_output2 = TXoutput2 .* G2;

%RICIAN CHANNEL 3:
[GI3,GQ3] = Rician_KPham(fd, length(TXoutput), SymR8, K_dB);
G3 = GI3 + 1j*GQ3;
Rician_output3 = TXoutput .* G3;

%RICIAN CHANNEL 4:
[GI4,GQ4] = Rician_KPham(fd, length(TXoutput), SymR8, K_dB);
G4 = GI4 + 1j*GQ4;

%ADD AWGN NOISE:
EsNo_dB = EbNo_dB + 3; %for QPSK
POWERnoise = (10^(-EsNo_dB/20))*(VARsignal/VARnoise); %derived in class
    %VARsignal from channel calibration
    %VARnoise from channel calibration
    
noise1 = randn(1,length(Rician_output1)) + 1j*randn(1,length(Rician_output1));
noise1 = noise1 / sqrt(2); %NORMAIZE THE DAMN NOISE. avg(|noise|^2) = 1
noise1 = POWERnoise * noise1; %correct?
CHoutput1 = Rician_output1 + noise1;

noise2 = randn(1,length(Rician_output2)) + 1j*randn(1,length(Rician_output2));
noise2 = noise2 / sqrt(2); %NORMAIZE THE DAMN NOISE. avg(|noise|^2) = 1
noise2 = POWERnoise * noise2; %correct?
CHoutput2 = Rician_output2 + noise2;

noise3 = randn(1,length(Rician_output3)) + 1j*randn(1,length(Rician_output3));
noise3 = noise3 / sqrt(2); %NORMAIZE THE DAMN NOISE. avg(|noise|^2) = 1
noise3 = POWERnoise * noise3; %correct?
CHoutput3 = Rician_output3 + noise3;

noise4 = randn(1,length(Rician_output4)) + 1j*randn(1,length(Rician_output4));
noise4 = noise4 / sqrt(2); %NORMAIZE THE DAMN NOISE. avg(|noise|^2) = 1
noise4 = POWERnoise * noise4; %correct?
CHoutput4 = Rician_output4 + noise4;

% RX SIGNAL PROCESSING + DEMODULATOR DESIGN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MATCHED FILTER:
RXfilter = rcosdesign(beta, span, sps, 'sqrt');

RXFilterOutput1 = conv(CHoutput1, RXfilter);
RXinput1 = TRUNCATOR(RXFilterOutput1, RXfilter);

RXFilterOutput2 = conv(CHoutput2, RXfilter);
RXinput2 = TRUNCATOR(RXFilterOutput2, RXfilter);

RXFilterOutput3 = conv(CHoutput3, RXfilter);
RXinput3 = TRUNCATOR(RXFilterOutput3, RXfilter);

RXFilterOutput4 = conv(CHoutput4, RXfilter);
RXinput4 = TRUNCATOR(RXFilterOutput4, RXfilter);

%DOWNSAMPLING:
downsamp1 = DOWNSAMPLER(RXFilterOutput1 , RXfilter);
downsamp2 = DOWNSAMPLER(RXFilterOutput2 , RXfilter);
downsamp3 = DOWNSAMPLER(RXFilterOutput3 , RXfilter);
downsamp4 = DOWNSAMPLER(RXFilterOutput4 , RXfilter);

%BLOCK PHASE ESTIMATION:
[Z1,G1,the1]= BPE_test([downsamp1],... ENTIRE DOWNSAMPLED RX-INPUT
             [unique],... UNIQUE SYMBOL VECTOR(48 symbols)
             [length(guard)+1:(length(unique)+length(guard))],...
             50,...  BLOCK SIZE (keep constant)
             10);%   STEP SIZE (decrease for higher estimation resolution
[Z2,G2,the2]= BPE_test([downsamp2],... ENTIRE DOWNSAMPLED RX-INPUT
             [unique],... UNIQUE SYMBOL VECTOR(48 symbols)
             [length(guard)+1:(length(unique)+length(guard))],...
             50,...  BLOCK SIZE (keep constant)
             10);%   STEP SIZE (decrease for higher estimation resolution
[Z3,G3,the3]= BPE_test([downsamp3],... ENTIRE DOWNSAMPLED RX-INPUT
             [unique],... UNIQUE SYMBOL VECTOR(48 symbols)
             [length(guard)+1:(length(unique)+length(guard))],...
             50,...  BLOCK SIZE (keep constant)
             10);%   STEP SIZE (decrease for higher estimation resolution
[Z4,G4,the4]= BPE_test([downsamp4],... ENTIRE DOWNSAMPLED RX-INPUT
             [unique],... UNIQUE SYMBOL VECTOR(48 symbols)
             [length(guard)+1:(length(unique)+length(guard))],...
             50,...  BLOCK SIZE (keep constant)
             10);%   STEP SIZE (decrease for higher estimation resolution
         
mu = zeros(1,4);
s = [1 1j -1 -1j];
for a = 1:length(Blockphase1)
rsum(a) = conj(rxburst_1) * Blockphase1(a) + ...
          conj(rxburst_2) * Blockphase2(a) + ...
          conj(rxburst_3) * Blockphase3(a) + ...
          conj(rxburst_4) * Blockhpahse4(a);
mu(1) = rsum(a) * conj(s(1));
mu(2) = rsum(a) * conj(s(2));
mu(3) = rsum(a) * conj(s(3));
mu(4) = rsum(a) * conj(s(4));
[Y,I] = max(real(mu));
blockphaseout(a) = s(I);
end

%HARDSLICER/DEMODULATION:
RXburst = QPSK_demod(blockpahseout); %USE QPSK_demod() FUNCTION

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

