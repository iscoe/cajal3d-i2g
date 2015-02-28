function linepts = linepoints(pt1,pt2)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% © [2014] The Johns Hopkins University / Applied Physics Laboratory All Rights Reserved. Contact the JHU/APL Office of Technology Transfer for any additional rights.  www.jhuapl.edu/ott
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%    http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%linepts=myline(pt1,pt2) is a function that returns the points in the line between
%pt1=[x,y] and pt2=[x,y]

%Suresh E Joel, Feb 2001

dx = pt2(1) - pt1(1);
dy = pt2(2) - pt1(2);

t = 0.4;	%rounding offset

linepts(1,1) = pt1(1);
linepts(2,1) = pt1(2);

if(dx==0 & dy==0),
   return;
end

linepts = zeros(2,max([dx dy]));

if(abs(dx) > abs(dy))	%if slope is less than 1
   m = dy/dx;				% m is slope
   t = t + pt1(2);
   if dx < 0
      dx = -1;
   else
      dx = 1;
   end
   m = m*dx;
   incr = 1;
   while (pt1(1) ~= pt2(1))
      pt1(1) = pt1(1) + dx;
      t = t + m;
      linepts(1,incr) = round(pt1(1));
      linepts(2,incr) = round(t);
      incr = incr + 1;
   end
else							%if slope is greater than 1
   m = dx/dy;
   t = t + pt1(1);
   if dy < 0
      dy = -1;
   else
      dy = 1;
   end
   m = m * dy;
   incr = 1;
   while(pt1(2) ~= pt2(2))
      pt1(2) = pt1(2) + dy;
      t = t + m;
      linepts(1,incr) = round(t);
      linepts(2,incr) = round(pt1(2));
      incr = incr + 1;
   end
end
