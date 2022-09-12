classdef GeometryHelper < handle
    methods(Static)
        function [V,E] = buildBoxEdges(p_min,p_max)
            V = [p_min(1) p_min(2) p_min(3);... %1
                p_min(1) p_min(2) p_max(3);... %2
                p_min(1) p_max(2) p_min(3);... %3
                p_min(1) p_max(2) p_max(3);... %4
                p_max(1) p_min(2) p_min(3);... %5
                p_max(1) p_min(2) p_max(3);... %6
                p_max(1) p_max(2) p_min(3);... %7
                p_max(1) p_max(2) p_max(3)]; %8
            E = [1 2; 1 3; 1 5; 2 4; 2 6; 3 4; 3 7; 4 8; 5 6; 5 7; 6 8; 7 8];
        end
    end
end