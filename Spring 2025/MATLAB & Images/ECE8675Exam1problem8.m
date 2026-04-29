clear;
[t,f]=meshgrid(0:pi/90:1*pi,2*pi:-pi/45:0);
x=sin(t).*cos(f);
y=sin(t).*sin(f);
z=cos(t);
% Example: normalized pattern of an Ideal dipole: sin(theta). Re-write the
% expression of efield for pattern of other antennas.
efield=sin(t);
ex=efield.*x;
ey=efield.*y;
ez=efield.*z;
view(10,90);
surface(ex,ey,ez);
% hold on
% theta = (-1:.001:1)*pi;
% lambda = 1;          % lambda is arbitrary in this calculation; pick a value 
% d = lambda/4;        % d is entire dipole length, both halves
% k = 2*pi/lambda;
% kd2 = k*d/2;
% y = 20*log10(abs((cos(kd2.*cos(theta))-cos(kd2))./sin(theta)));
% y = y-max(y);        % normalize y to obtain directivity; new max is 0 dB
% y(y<-40) = -40;
% figure(1)
% polarplot(theta,y)
% rlim([-40 0])
% set(gca,'thetazerolocation','top','thetadir','clockwise')
% freq    = 300e6;
% lambda  = 3e8/freq;
% offset  = lambda/50;
% spacing = lambda/2;
% length  = lambda/2.1;
% width   = lambda/50;
% anglevar= 0:10:180;
% freqrange = 200e6:2e6:400e6;
% gndspacing = lambda/4;
% d  = dipole('Length',length,'Width',width);
% ant= dipoleCrossed('Element',d,'Tilt',180,'TiltAxis',[0 1 0]);
% figure; show(ant);
% pattern(ant, freq);

