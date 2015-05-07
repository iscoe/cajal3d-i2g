function M = subsample(X, ds, method)
% SUBSAMPLE Creates a masking matrix that corresponds to
% downsampling the tensor X by some fixed factor in the XY plane.
%
%   X : A a tensor with shape (x, y, z/slices)
%   ds : a scalar downsampling factor
%  

if nargin < 3, method='xy'; end
assert(isscalar(ds) && ds > 1);
ds = floor(ds);

[x,y,z] = size(X);
M = logical(zeros(x,y,z));


switch lower(method)
  case 'xy'
    M(1:ds:x, 1:ds:y, :) = 1;
      
  case 'sobol'
    nSamp = x*y*z/ds;
    p = sobolset(3);
    sub = net(p, nSamp);
    sub = 1 + floor(bsxfun(@times, sub, [x y z]));  % map indices from [0 1] to integer indices
    idx = sub2ind(size(M), sub(:,1), sub(:,2), sub(:,3));
    M(idx) = 1;
    
  otherwise
    error('unrecognized method')
end
