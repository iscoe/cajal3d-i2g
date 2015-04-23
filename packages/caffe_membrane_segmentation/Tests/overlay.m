function overlay(baseImage, overlay1, color1, overlay2, color2)
% OVERLAY Quick function for overlaying a probability map on top of a base image.
%
%  Here we have in mind as a base image an EM data slice.

if nargin < 5, color2 = [1,0,0]; end
if nargin < 4, overlay2 = []; end
if nargin < 3, color1 = [0,1,0]; end

% render the base image
imshow(baseImage, 'InitialMag', 'fit');
hold on;

% overlay 1
r = color1(1); g = color1(2); b = color1(3);
layer1 = cat(3, r*ones(size(baseImage)), g*ones(size(baseImage)), b*ones(size(baseImage)));
h = imshow(layer1);
set(h, 'AlphaData', double(overlay1));

% overlay 2 (optional)
if length(overlay2) > 0
    r = color2(1); g = color2(2); b = color2(3);
    layer2 = cat(3, r*ones(size(baseImage)), g*ones(size(baseImage)), b*ones(size(baseImage)));
    h = imshow(layer2);
    set(h, 'AlphaData', double(overlay2));
end

hold off;

