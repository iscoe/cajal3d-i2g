function overlay(baseImage, alphaImage, color)
% OVERLAY Quick function for overlaying a probability map on top of a base image.
%
%  Here we have in mind as a base image an EM data slice.

% default to all green
if nargin < 3,
    color = [0,1,0];
end

r = color(1); g = color(2); b = color(3);

imshow(baseImage, 'InitialMag', 'fit');
green = cat(3, r*ones(size(baseImage)), g*ones(size(baseImage)), b*ones(size(baseImage)));

hold on;
h = imshow(green);
hold off;

set(h, 'AlphaData', double(alphaImage));

