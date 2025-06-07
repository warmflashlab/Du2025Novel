function ffmpegMakeMovieFromDirectory(output_movie_name_no_ext,input_direc,search_format_string,framerate)

% search_format_string = "*.png";
command_string = sprintf('cd %s; /usr/local/Cellar/ffmpeg/7.1.1_1/bin/ffmpeg -y -framerate %d -pattern_type glob -i "%s" -vcodec libx264 -pix_fmt yuv420p -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" %s.mp4',input_direc,framerate,search_format_string,output_movie_name_no_ext);

[status, output] = system(command_string);

if status ~= 0
    % some error happened...
    output
end

end

