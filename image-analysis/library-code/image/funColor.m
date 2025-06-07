function img2show = funColor(chanaux,color)

%%% Specify the color to display (chanaux is a 2D matrix, can't be 3D)
switch color
    case 'c'
        img2show = cat(3,zeros(size(chanaux)),chanaux,chanaux); % CYAN
    case 'm'
        img2show = cat(3,chanaux,zeros(size(chanaux)),chanaux); % MAGENTA
    case 'y'
        img2show = cat(3,chanaux,chanaux,zeros(size(chanaux))); % YELLOW
    case 'r'
        img2show = cat(3,chanaux,zeros(size(chanaux)),zeros(size(chanaux))); % RED
    case 'g'
        img2show = cat(3,zeros(size(chanaux)),chanaux,zeros(size(chanaux))); % GREEN
    case 'b'
        img2show = cat(3,zeros(size(chanaux)),zeros(size(chanaux)),chanaux); % BLUE
    otherwise
        img2show = cat(3,chanaux,chanaux,chanaux); % GRAY
end

end