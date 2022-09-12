classdef Switches < handle
    properties(Constant)
        
        %
        % Disable this switch if you are not running Windows x64 (or if the
        % .mexw64 file in the libigl-mex folder cannot be executed for any
        % other reason...)
        is_win_x64 = 1
    end
end