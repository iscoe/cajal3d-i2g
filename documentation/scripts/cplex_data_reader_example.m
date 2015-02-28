h1 = h5read('cplexOut0630b.hdf5','/labels');
uid = unique(h1);

h1r = permute(h1,[3,2,1]); %bock

h1r(h1r>0) = h1r(h1r>0)-min(h1r(h1r>0));
h1r = uint16(h1r);

% lost last row and col

%h1r(:,end+1,:) = h1r(:,end,:);
%h1r(end+1,:,:) = h1r(end,:,:);

rho = RAMONVolume;
rho.setCutout(h1r);

I = RAMONVolume;
I.setCutout(im(:,:,1:90));
%I = im;
h = image(I); h.associate(rho)

%%
tt = dir('bockNew/bData*.png');
for i = 1:33
    em(:,:,i) = imread(['bockNew',filesep,tt(i).name]);
end


em = em(:,:,4:end);
h1r = h1r(:,:,4:end);

anno = h1r;