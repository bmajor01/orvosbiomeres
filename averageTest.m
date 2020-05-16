clear
addpath("/home/bela/Desktop/bme/szgepgyak/ekg/mit/Felvetelek");         %az adatfájlok elérési útvonala

data = "nocuff2.hhm";                                %adatfájl neve

%=============================================================================
%===========================Adat betöltése====================================
%=============================================================================

data_raw = hhmbinread(data);
plot(data_raw.ecg1,'r');
hold on
plot(data_raw.press,'b');
grid on
xlabel('Idő (ms)');
ylabel('Amplitudo [Relatív egység]');
legend('ECG','Pressure');
title("Jelölje ki a használni kívánt jeltartományt!");
[x,y]=ginput(2);
close;

ecg = data_raw.ecg1(round(x(1)):round(x(2)));

disp("Az adatsor hossza: "+(length(ecg)/1000)+"s");


for i = 1 : length(ecg)                             %Átszámítjuk az EKG fesz. értékeit mV-ba
    ecg_mv(i) = (3.3/4096) * (ecg(i) - 2048);
end

W = 25;                                             %Törésponti feri (Hz)
nFilt = 5;                                          %szűrő fokszáma
nNotch = 3;                                         %lyukszűrő fokszáma

Fs = 1000;                                          %mintavételi feri
Wn = W / (Fs / 2);                                  %Wn normalizált feri
[b, a]=butter(nFilt,Wn);                            %normál szűrő
[bn, an]=butter(nNotch, [49 51]./(Fs/2), 'stop');   %lyukszűrő

ecg_notch = filtfilt(bn, an, ecg_mv);

ecg_filtfilt = filtfilt(b, a, ecg_mv);
ecg_filter = filter(b, a, ecg_mv);

[ret,med] = average (ecg_mv,200); 

disp("Jel-zaj viszony:" + snr(ret,med));

figure(2)
plot(ret,'k');
hold on;
plot(med,'r');
axis([0 length(med) min(med)-0.1 max(med)+0.1]);
xlabel('Idő (ms)');
ylabel('Amplitudo [mV]');
hold on
grid on
title("Átlagolt jelalak."+"Jel-zaj viszony: " + snr(ret,med)+"dB.  fájl: "+data)
legend('Átlagolt jelalak', 'Medián jelalak');