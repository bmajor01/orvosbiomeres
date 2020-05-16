clear
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

ecg = data_raw.ecg1(x(1):x(2));
ppg = data_raw.ppgl_nir(x(1):x(2));
press = data_raw.press(x(1):x(2));

for i = 1 : length(ecg)                             %Átszámítjuk az EKG fesz. értékeit mV-ba
    ecg_mv(i) = (3.3/4096) * (ecg(i) - 2048);
end

W = 25;                                             %Törésponti feri (Hz)
nFilt = 10                                          %szűrő fokszáma
nNotch = 3;                                         %lyukszűrő fokszáma

Fs = 1000;                                          %mintavételi feri
Wn = W / (Fs / 2);                                  %Wn normalizált feri
[b, a]=butter(nFilt,Wn);                            %normál szűrő
[bn, an]=butter(nNotch, [49 51]./(Fs/2), 'stop');   %lyukszűrő

ecg_notch = filtfilt(bn, an, ecg_mv);

ecg_filtfilt = filtfilt(b, a, ecg_mv);
ecg_filter = filter(b, a, ecg_mv);

lc = peakDetect(ecg_filtfilt);

figure(1)
plot(ecg_filtfilt,'r');
xlabel('Idő (ms)');
ylabel('Amplitudo [mV]');
hold on
plot(lc,ecg_filtfilt(lc),'bx');             %X ekkel jelölük a megtalált R hullámokat
grid on
title("Saját R hullám detektálás eredménye, a felismert pontok kék X-el jelölve."+"  fájl: "+data)
legend('filtfilt() szűrés');