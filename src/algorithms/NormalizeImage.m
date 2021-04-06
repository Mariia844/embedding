function img8bpp = NormalizeImage(imgDouble)

minImgDouble =  min(imgDouble(:));

factor = (255-0)/(max(imgDouble(:)) - minImgDouble);

%img8bppB = im2uint8(imgDouble-minImgDouble);

img8bpp = uint8((imgDouble-minImgDouble).*factor);

%im2uint8 does not work, duno y
%imgDif = img8bppB - img8bpp;

end