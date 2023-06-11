function momento = momentos(im,i,j)
    im = im2double(im);
    im_size=size(im);
    %im = ~im;
    momento=0;
    for x=1:im_size(2)
        for y=1:im_size(1)
            momento = momento + sum(x.^i * y.^j * im(y,x));
        end
    end
end

