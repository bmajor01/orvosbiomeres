function [q,peaks,t,tend,p,pstart,trr,tqt,tpq] = qtDet(data)

%tend = 1;


peaks = pan_tompkins(data) ;
trimLen = 50;
pRange = 200;
pStartRange = 100;
tEndRange = 200;
qRange = 50;
tRange = 400;

for i = 1 : length(peaks)-1
    cycle = data(round(peaks(i)) : round(peaks(i+1)));
    trr(i) = length(cycle);
    n=1;
    
    m=1;
    for l = peaks(i)-qRange:peaks(i)
        qDet(m) = data(l);
        m = m+1;
    end
    
        n=1;
    for l = peaks(i)-pRange:peaks(i) - trimLen
        pDet(n) = data(l);
        n = n+1;
    end
    
    a = 1;
    for l = peaks(i):tRange+peaks(i)
        tDet(a) = data(l + trimLen);
        a = a+1;
    end
    
    p(i) = peaks(i) -1 - pRange + round(find(pDet == max(pDet)));
    q(i) = peaks(i) -1 - qRange + round(find(qDet == min(qDet)));
    t(i) = peaks(i) -1 + trimLen + round(find(tDet == max(tDet)));
    
        n=1;
    for l = p(i)-pStartRange:p(i)
        pStartDet(n) = data(l);
        n = n+1;
    end
    
            n=1;
    for l = t(i):t(i)+tEndRange;
        tEndDet(n) = data(l);
        n = n+1;
    end
    
    pstart(i) = p(i) -1 - pStartRange + round(find(pStartDet == min(pStartDet)));
    tend(i) = t(i) -1 + round(find(tEndDet == min(tEndDet)));
    
    tpq(i)= q(i)-pstart(i);
    tqt(i) = tend(i)-q(i);

end