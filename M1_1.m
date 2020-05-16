clear

%=============================================================================
%=========================Beállítandó paraméterek:============================
%=============================================================================

addpath("/home/bela/Desktop/bme/szgepgyak/ekg/mit/Felvetelek");         %az adatfájlok elérési útvonala
data = "nagyzaj1.hhm";                                %adatfájl neve

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
ppg = data_raw.ppgr_nir_dc(x(1):x(2));
press = data_raw.press(x(1):x(2));

ppgnir = data_raw.ppgr_nir(x(1):x(2));
ppgnirdc = data_raw.ppgr_nir_dc(x(1):x(2));

ppgred = data_raw.ppgl_red(x(1):x(2));
ppgreddc = data_raw.ppgl_red_dc(x(1):x(2));

%=============================================================================
%===========================Mért értékek átváltása============================
%=============================================================================

for i = 1 : length(ecg)                             %Átszámítjuk az EKG fesz. értékeit mV-ba
    ecg_mv(i) = (3.3/4096) * (ecg(i) - 2048);
end

for i = 1 : length(ppg)                  %A mandzsetta nyomásértékének átváltása mmhg-be
    press_mmhg(i) = (press(i) - 175)/15.5;
end

%=============================================================================
%=============================================================================

%=============================================================================
%=====================ECG szűrések============================================
%=============================================================================

W = 35;                                             %Törésponti feri (Hz)
nFilt = 5;                                      %szűrő fokszáma
nNotch = 3;                                         %lyukszűrő fokszáma

Fs = 1000;                                          %mintavételi feri
Wn = W / (Fs / 2);                                  %Wn normalizált feri

[b, a]=butter(nFilt,Wn);                            %normál szűrő
[bn, an]=butter(nNotch, [49 51]./(Fs/2), 'stop');   %lyukszűrő


ecg_notch = filtfilt(bn, an, ecg_mv);

ecg_filtfilt = filtfilt(b, a, ecg_mv);
ecg_filter = filter(b, a, ecg_mv);

%=============================================================================
%=====================ECG R csúcsdetektálás=====================================
%=============================================================================


qrsPos = pan_tompkins(ecg_filtfilt);                %R hullámok identifikálása
qrsLen = diff(qrsPos);                              %R hullámok távolságának számítása
qrsId = 1:1:length(ecg_filtfilt);                   %Lineáris vektor a kijelzéshez

for i = 1 : length(qrsLen)                          %Periódusidő átváltása HR értékké
    hr(i) = 60/(qrsLen(i)/1000);
end

trend = movmean(hr,50);
trend(length(trend)+1)=trend(length(trend));


% %=============================================================================
% %=====================ECG Saját R hullám keresése=============================
% %=============================================================================
% 
% W_t = 8;                                             %Törésponti feri (Hz)
% nFilt_t = 3;                                          %szűrő fokszáma
% 
% Fs = 1000;                                          %mintavételi feri
% Wn = W_t / (Fs / 2);                                  %Wn normalizált feri
% [b, a]=butter(nFilt,Wn);                            
% 
% ecg_filtfilt_t = - diff(filtfilt(b, a, ecg_mv));
% 
% 
% [pks_t,locs_t] = findpeaks(ecg_filtfilt_t, 'MinPeakHeight',0.002, 'minPeakDistance', 300);
% 
% for tpeaklocs = 1 : length(locs_t)-1
%     ecgmvLoc =1;
%     
%     while (diff(ecg_mv(ecgmvLoc))>0)
%         ecgmvLoc=ecgmvLoc+1;
%     end
%     locs_t(tpeaklocs) = ecgmvLoc;
% end
% 
% figure(1);
% plot(ecg_filtfilt_t);
% hold on
% scatter(locs_t,pks_t);

%=============================================================================
%=====================ECG SNR============================================
%=============================================================================

nNotch = 4;                                         %lyukszűrő fokszáma
band = 5;                                           %lyukszűrő sáv
Fs = 1000;                                          %mintavételi feri                                

[bs, as]=butter(nNotch, [50-band/2 50+band/2]./(Fs/2), 'stop');   %jel
[bn, an]=butter(nNotch, [50-band/2 50+band/2]./(Fs/2), 'bandpass');   %zaj

ecg_notch = filtfilt(bs, as, ecg_mv);
ecg_noise = filtfilt(bn, an, ecg_mv);

disp ("Jel-zaj viszony: "+ snr(ecg_notch,ecg_noise));

%=============================================================================
%=====================légzési frekvencia=====================================
%=============================================================================

hr(end+1) = hr(end);

t = 1:1:length(ecg_filtfilt);
legzes=interp1(qrsPos,hr,t,'spline');
legzesDiff=diff(legzes);
[pks,locs] = findpeaks(legzesDiff, 'MinPeakDistance',1000);
legzesLen=diff(locs);

for i = 1 : length(legzesLen)                          %Periódusidő átváltása HR értékké
    legzesFr(i) = 60/(legzesLen(i)/1000);
end

ecg_spectrum = fft(ecg_filtfilt);
n = length(ecg_spectrum);                       % Mintaszám
f = (0:n-1)*(Fs/n);                             % Frekvencia tartomány számítás (dokumentáció alapján)
powerEcg = abs(ecg_spectrum).^2/n;              % Teljesítmény spektrum számítás a komplex fft-ből

ppg_nodc = ppg-mean(ppg);
ppg_filtfilt = filtfilt(b, a, ppg_nodc);
ppg_spectrum = fft(ppg_filtfilt);
n = length(ppg_spectrum);                       % Mintaszám
f = (0:n-1)*(Fs/n);                             % Frekvencia tartomány számítás (dokumentáció alapján)
powerPpg = abs(ppg_spectrum).^2/n;              % Teljesítmény spektrum számítás a komplex fft-ből

figure(1)
plot((ecg_filtfilt),'r');
grid on
xlabel('Idő (ms)');
ylabel('Amplitudo [mV]');
hold on
plot(ecg_filter,'g');
hold on
plot(ecg_mv,'b');
grid on
legend('filtfilt() szűrés','filter() szűrés','eredeti jel');
title("Különböző szűrési algoritmusok összehasonlítása. Szűrő fokszáma:"+nFilt+"  fájl: "+data);
%title("Alapvonal vándorlás nagy belégzés esetén")

figure(2)
plot(ecg_filtfilt,'r');
xlabel('Idő (ms)');
ylabel('Amplitudo [mV]');
hold on
%plot(qrsPos,ecg_filtfilt(qrsPos),'bx');             %X ekkel jelölük a megtalált R hullámokat
%plot(locs_t,ecg_filtfilt(locs_t),'gx');             %X ekkel jelölük a megtalált R hullámokat
grid on
%title("R hullám detektálás eredménye, az annotált pontok piros X-el jelölve."+"  fájl: "+data)
title("Alapvonal vándorlás nagy belégzés esetén."+"  fájl: "+data)
legend('filtfilt() szűrés');

figure(3)
plot(qrsPos,hr);
hold on
plot(qrsPos,trend);
xlabel('Idő (ms)');
ylabel('HR (1/min)');
grid on
title("Szívfrekvencia (HR): " + round(mean(hr),1) + ", Max. HR: " + round(max(hr),1) + ", Min. HR: " + round(min(hr),1)+" Szórás: "+round(mad(hr),1)+" fájl: "+data);
legend('Szívfrekvencia','trend');

figure(4);
plot(legzesDiff);
hold on
scatter(locs,pks);
xlabel('Idő (ms)');
ylabel('HR változás');
title("Légzési frekvencia: " + round(mean(legzesFr),1) + ", Max. légzés: " + round(max(legzesFr),1) + ", Min. légzés: " + round(min(legzesFr),1)+" Szórás: "+round(mad(hr),1)+" fájl: "+data);

figure(5)
plot(f,powerEcg);
axis([0 55 0 inf]);
grid on
xlabel('Frekvencia [Hz]');
ylabel('Teljesítmény [A.U.]');
title("Az ECG jel teljesítmény spektruma"+"  fájl: "+data);

figure(6)
yyaxis left
plot(ppg_filtfilt,'b');
ylabel('ppg amplitudo [Relatív egység]');
yyaxis right
plot(ecg_filtfilt,'r');
ylabel('ecg amplitudo [mV]');
grid on
xlabel('Idő (ms)');
legend('PPG','ECG');
title("PPG és ECG jel."+"  fájl: "+data);

figure(7)
plot(f,powerPpg)
axis([0 55 0 inf]);
grid on
xlabel('Frekvencia [Hz]');
ylabel('Teljesítmény [A.U.]');
title("A PPG jel teljesítmény spektruma"+"  fájl: "+data);

figure(8)
yyaxis left
plot(press_mmhg,'b');
grid on
xlabel('Idő [ms]');
ylabel('Nyomás [mmHg]');
yyaxis right
plot(ppg_filtfilt,'r');
ylabel('PPG jel [A.U.]');
title("A mandzsetta nyomása"+"  fájl: "+data);

figure(9)
plot(ecg_notch,'k');
hold on;
plot(ecg_mv,'r');
grid on
xlabel('Idő');
ylabel('feszültség (mv)');
legend("50Hz lyukszűrő Fokszám:"+nNotch+" Sávszélesség:"+band+"Hz","Eredeti jel")
title("ECG jel 50Hz lyukszűrővel"+"  fájl: "+data);