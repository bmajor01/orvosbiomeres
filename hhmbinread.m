%egyszeru HHM beolvaso - bemenet a fajl neve stringkent
function o=hhmbinread(filename)
fid=fopen(filename,'r','b');
if fid==-1 error('Nincs meg a file'); end

buffer=fread(fid,'bit12=>double'); %uint-ben 4095-ot elszurja, korrigalunk az elojellel
idx=find(buffer<0);
if(~isempty(idx))
    buffer(idx)=buffer(idx)+4096;
end

o.ecg1=buffer(1:8:end);
o.ecg2=buffer(2:8:end);
o.press=buffer(3:8:end);
o.ppgl_red=buffer(4:8:end);
o.ppgl_red_dc=buffer(5:8:end);
o.ppgr_nir=buffer(6:8:end);
o.ppgr_nir_dc=buffer(7:8:end);
o.ppgl_nir=buffer(8:8:end);


