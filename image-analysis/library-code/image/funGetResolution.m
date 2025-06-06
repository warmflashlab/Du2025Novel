function [xres,yres] = funGetResolution(magnification,zoom_value)

if ~exist('magnification','var')
    magnification = '20X';
end

if ~exist('zoom_value','var')
    zoom_value = 1;
end

switch magnification
    case '10X'
        xres = 1.25/zoom_value;
        yres = 1.25/zoom_value;
    case '20X'
        xres = 0.625/zoom_value;
        yres = 0.625/zoom_value;
    case '30X'
        xres = 0.4167/zoom_value;
        yres = 0.4167/zoom_value;
    case '40X'
        xres = 0.3125/zoom_value;
        yres = 0.3125/zoom_value;
    case '60X'
        xres = 0.2083/zoom_value;
        yres = 0.2083/zoom_value;
    case '100X'
        xres = 0.125/zoom_value;
        yres = 0.125/zoom_value;
end

end