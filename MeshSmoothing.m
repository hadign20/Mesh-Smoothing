classdef MeshSmoothing < handle
    methods(Static)
        function V_smooth = explicitSmoothing(mesh, L, lambda)
            % Computes a forward Euler step to smooth the mesh with a
            % Laplacian matrix L, and a factor of lambda.

            % TODO_A2 Task 2a
            %
            % Perform explicit mesh smoothing, as described in the
            % slides and in [Desbrun1999], Section 2.2.
            
            %=================================================
            % first try
            %=================================================
            %all_vp = mesh.getAllVertices().getTrait('position');
            %nv = mesh.num_vertices;
            %dt = 0.01;
            %V_smooth = (speye(nv)+ dt * lambda * L) * all_vp;
            
            %=================================================
            % final
            %=================================================
            all_vp = mesh.toFaceVertexMesh();
            %nv = mesh.num_vertices;
            %V_smooth = (speye(nv)+ lambda * L) * all_vp;
			V_smooth = all_vp + lambda * (L * all_vp);

        end
        
        function V_smooth = implicitSmoothing(mesh, L, lambda)
            % Computes a backward Euler step to smooth the mesh with a
            % Laplacian matrix L, and a factor of lambda.

            % TODO_A2 Task 2b
            %
            % Perform implicit mesh smoothing, as described in the
            % slides and in [Desbrun1999], Section 2.3.
            
            
            %=================================================
            % first try
            %=================================================
            %all_vp = mesh.num_vertices.getTrait('position');
            %nv = mesh.num_vertices;
            %dt = 0.01;
            %V_smooth = (speye(nv)- dt * lambda * L * (L~=0)) \ all_vp;
            
            %=================================================
            % final
            %=================================================
            all_vp = mesh.toFaceVertexMesh();
            nv = mesh.num_vertices;
			V_smooth = (speye(nv) - lambda * L) \ all_vp;
                        
        end
        
        function V_smooth = lsqSmoothing(mesh,L,wl,wp)
            % Performs least-squares mesh smoothing as described in
            % [Nealen2006]. wl are weights for the smoothing rows, and wp
            % the weights for the shape-preserving rows.
            
            % TODO_A2 Task 3
            %
            % Implement least-squares mesh smoothing as described in
            % the slides and in [Nealen2006].

            %all_vp = mesh.getAllVertices().getTrait('position');
            all_vp = mesh.toFaceVertexMesh();
            nv = mesh.num_vertices;
            V_smooth = [wl .* L ; wp .* eye(nv)] \ [zeros(nv,3) ; wp .* all_vp];
            
        end
        
        function V_smooth = triangleSmoothing(mesh,L_uniform,L_Cotangent,wl,wp)
            % Performs detail preserving triangle shape optimization as
            % described in [Nealen2006]. wl are the weights for the
            % triangle shape optimization rows, and wp the weights for the
            % detail-preserving rows.

            % TODO_A2 Task 4
            %
            % Implement detail preserving triangle shape optimization
            % mesh smoothing as described in the slides and in
            % [Nealen2006].
            
            %all_vp = mesh.getAllVertices().getTrait('position');
            all_vp = mesh.toFaceVertexMesh();
            nv = mesh.num_vertices;
            V_smooth = [wl .* L_uniform ; wp .* eye(nv)] \ [wl .* (L_Cotangent * all_vp) ; wp .* all_vp];

        end
        
        function V_smooth = spectralSmoothing(mesh, L, k)
            % Performs spectral mesh smoothing through a low-pass filtering
            % of the Laplacian eigenvectors, in which only the k lowest
            % frequencies are preserved.

            % TODO_A2 Task 5b
            %
            % Perform spectral smoothing. In order to do that, perform
            % a sparse eigendecomposition of the Laplacian L that
            % computes only the eigenvectors associated with the k
            % smallest-magnitude eigenvalues. Then project the vertex
            % positions onto the basis spanned by these eigenvectors
            % and reconstruct a filtered version of the mesh.
            
            %=================================================
            % first try
            %=================================================
            %all_vp = mesh.getAllVertices().getTrait('position');
            %d = eigs(L,k,'smallestabs');
            %pd = padarray(diag(d),[nv-2,nv-2],0,'post');
            %V_smooth = all_vp * pd * all_vp';
            
            %=================================================
            % final
            %=================================================
            all_vp = mesh.toFaceVertexMesh();
			[d,~] = eigs(L,k,'smallestabs');
            d = real(d);
			V_smooth = d * (d' * all_vp);

        end
    end
end