% function [t_locs] = tWave(data,rwave)
% 
%     roi = 400;
%     locMax = 0;
% 
%     for i = 1:length(rwave)
%     for k = 1:roi
%         if((data(i+k)>locMax)
%             locMax = data(i+k);
%             t_locs(i)=rwave(i)+k;
%         end
%     end
% 
% end
% figure(1);
% plot(ecg_filtfilt_t);
% hold on
% scatter(locs_t,pks_t);
