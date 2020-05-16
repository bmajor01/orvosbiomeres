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
%[x,y]=ginput(2);
x = [9.879032258064517e+04;1.512096774193549e+05]
y = [2.250000000000001e+03;2.276239067055394e+03]
close;

ecg = data_raw.ecg1(round(x(1)):round(x(2)));
ppg = data_raw.ppgl_nir(x(1):x(2));

for i = 1 : length(ecg)                             %Átszámítjuk az EKG fesz. értékeit mV-ba
    ecg_mv(i) = (3.3/4096) * (ecg(i) - 2048);
end

ecgPks = pan_tompkins(ecg_mv);

W = 30;                                             %Törésponti feri (Hz)
nFilt = 5;                                          %szűrő fokszáma

Fs = 1000;                                          %mintavételi feri
Wn = W / (Fs / 2);                                  %Wn normalizált feri
[b, a]=butter(nFilt,Wn);                            %normál szűrő

ppg_filtfilt = filtfilt(b, a, ppg);
ppgTrend = movmean(ppg_filtfilt,1000);
ppgdeTrend = ppg_filtfilt - ppgTrend;

[pks,locs] = findpeaks(ppgdeTrend,'MinPeakHeight',100 ,'minPeakDistance', 100);
figure(1);
plot(ppgdeTrend);
hold on
scatter(locs,pks);

ppgCycLen = diff(locs);
ecgCycLen = diff(ecgPks);

plot(ppgCycLen)
hold on;
plot(ecgCycLen)

for n = 1 : length(locs)
    hullamterjedes(n) = ecgPks(n)-locs(n);
end

figure('Name','Hullám terjedési idő')
plot(hullamterjedes,'r');
grid on;
title("Átlag tejredési idő: "+ round(mean(hullamterjedes),2)+ " ms. Terjedési sebesség (l = 85 cm) "+ round(0.85/100*(mean(hullamterjedes)),2)+" m/s. fájl: "+data)
xlabel('R hullám sorszám');
ylabel('Terjedési idő [ms]');
legend("Hullám terjedési ideje");


disp("Az adatsor hossza: "+(length(ecg)/1000)+"s");


W = 30;                                             %Törésponti feri (Hz)
nFilt = 5;                                          %szűrő fokszáma
nNotch = 3;                                         %lyukszűrő fokszáma

Fs = 1000;                                          %mintavételi feri
Wn = W / (Fs / 2);                                  %Wn normalizált feri
[b, a]=butter(nFilt,Wn);                            %normál szűrő
[bn, an]=butter(nNotch, [49 51]./(Fs/2), 'stop');   %lyukszűrő

ecg_notch = filtfilt(bn, an, ecg_mv);

ecg_filtfilt = filtfilt(b, a, ecg_mv);

trend = movmean(ecg_filtfilt,1000);
signal = ecg_filtfilt - trend;

[q,r,t,tend,p,pstart,trr,tqt,tpq] = qtdet (signal); 

disp ("Szívciklusok száma: " + length(trr));
disp ("Átlag tRR: "+round(mean(trr),2)+" Szórás: "+round(mad(trr),2));
disp ("Átlag tQT: "+round(mean(tqt),2)+" Szórás: "+round(mad(tqt),2));
disp ("Átlag tPQ: "+round(mean(tpq),2)+" Szórás: "+round(mad(tpq),2));

figure('Name','P,Q,R,T csúcsok')
plot(signal,'k');
axis([0 length(signal) min(signal)-0.1 max(signal)+0.1]);
xlabel('Idő (ms)');
ylabel('Amplitudo [mV]');
hold on
plot(p,signal(p),'ro');
plot(q,signal(q),'go');             %X ekkel jelölük a megtalált Q hullámokat
plot(t,signal(t),'bo');             %X ekkel jelölük a megtalált T hullámokat
plot(r,signal(r),'rx');
plot(pstart,signal(pstart),'gx');
plot(tend,signal(tend),'bx');
grid on
title("P,Q,R,T csúcsok."+"  fájl: "+data)
legend('ECG jel','P_{peak}','Q','R','T_{peak}','P_{start}','T_{end}');

figure('Name','Poincaré diagram')
plot([min(trr), max(trr)], [min(trr), max(trr)]);
hold on;
plot(trr(1:end-1), trr(2:end), 'ro');
title("Poincaré diagram"+"  fájl: "+data);
xlabel('tRR(i) [ms]');
ylabel('tRR(i+1) [ms]');