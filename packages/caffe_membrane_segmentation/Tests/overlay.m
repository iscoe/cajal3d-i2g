function overlay(baseImage, alphaImage)
% OVERLAY Quick function for overlaying a probability map on top of a base image.
%
%  Here we have in mind as a base image an EM data slice.

imshow(baseImage, 'InitialMag', 'fit');
green = cat(3, zeros(size(baseImage)), ones(size(baseImage)), zeros(size(baseImage)));

hold on;
h = imshow(green);
hold off;

set(h, 'AlphaData', double(alphaImage));

