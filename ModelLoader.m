classdef ModelLoader < handle
    properties
    end
    
    methods(Static)
        function mesh = loadOBJ(filename)
			% If you don't operate Windows 64-bit, use the line with 'readOBJ' instead of 'readOBJ_mex'.
			% It is a lot slower, but does not rely on precompiled code.
            if all(computer == 'PCWIN64')
                [V,F] = readOBJ_mex(filename);
            else
                [V,F] = readOBJ(filename);
            end
			
            % -Z forward, Y up
            V = V*[0 -1 0; 0 0 1; -1 0 0];
            % uniformly resize to fit into unit cube
            r = max(range(V,1));
            V = V/r;
            % put in the center of the ground plane
            V = bsxfun(@minus, V, [mean(V(:,1:2),1) min(V(:,3),[],1)]);
            mesh = TriangleMesh(V,F);
        end
    end
end