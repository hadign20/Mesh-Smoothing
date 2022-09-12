classdef TriangleMesh < handle
    % TriangleMesh Represents a manifold triangle mesh, possibly with
    % boundary. The data structure is a halfedge mesh, in which faces have
    % CCW winding and boundaries have CW winding. Vertices, halfedges,
    % edges, and faces are stored separately, and each type of element can
    % have traits associated with it (e.g. vertex positions, face normals,
    % edge colors)
    
    properties(Access=public)
        V_traits % Array of structs, in which each element stores per-vertex information. By default, only a 1-by-3 position vector is stored. This array of structs can be arbitrarily expanded by further fields. However, fields are restricted to containing either scalars or row-vectors.
        E_traits % Array of structs, in which each element stores per-edge information. This array of structs can be arbitrarily expanded. However, fields are restricted to containing either scalars or row-vectors.
        HE_traits % Array of structs, in which each element stores per-halfedge information. This array of structs can be arbitrarily expanded. However, fields are restricted to containing either scalars or row-vectors.
        F_traits % Array of structs, in which each element stores per-face information. This array of structs can be arbitrarily expanded. However, fields are restricted to containing either scalars or row-vectors.
    end
    
    properties(GetAccess=public,SetAccess=private)
        V_he % nv-by-1 array, the i-th element is the index of a halfedge that starts from vertex i
        HE_from % nhe-by-1 array, the i-th element is the index of the vertex from which halfedge i starts
        HE_to % nhe-by-1 array, the i-th element is the index of the vertex to which halfedge i points
        HE_next % nhe-by-1 array, the i-th element is the index of the halfedge that comes after halfedge i in an halfedge cycle
        HE_prev % nhe-by-1 array, the i-th element is the index of the halfedge that comes before halfedge i in an halfedge cycle
        HE_twin % nhe-by-1 array, the i-th element is the index of the halfedge that runs between the same vertices as halfedge i, but in the opposite direction
        HE_face % nhe-by-1 array, the i-th element is either the index of the face to which halfedge i belongs, or 0 if halfedge i is on the boundary
        HE_edge % nhe-by-1 array, the i-th element is the index of the edge associated with halfedge i
        E_he % ne-by-1 array, the i-th element is the index of one of the halfedges associated with edge i
        F_he % nf-by-1 array, the i-th element is the index of a halfedge belonging to face i
        
        num_vertices % nv, the number of vertices in the mesh
        num_faces % nf, the number of faces in the mesh
        num_halfedges % nhe, the number of halfedges in the mesh
        num_edges % ne, the number of edges in the mesh
    end
    
    methods
        function obj = TriangleMesh(V,F)
            % Creates a new triangle mesh with full connectivity information from an indexed face list.
            % V - nv-by-3 matrix that stores the coordinates of the i-th
            % vertex in the i-th row.
            % F - nf-by-3 matrix that stores the vertex indices comprising
            % the i-th face (CCW winding) in the i-th row.
            
            % Throw away vertices that are not connected to any faces
            v_keep = unique(F(:));
            keep_indexer = zeros(1,size(V,1));
            keep_indexer(v_keep) = 1:length(v_keep);
            V = V(v_keep,:);
            F = keep_indexer(F);
            
            obj.num_vertices = size(V,1);
            obj.num_faces = size(F,1);
            
            % Copy vertex positions to traits
            temp = num2cell(V,2);
            obj.V_traits(obj.num_vertices).position = 0;
            [obj.V_traits.position] = deal(temp{:});
            
            % Fill in from, next, prev, and face properties of halfedges
            % (except boundary halfedges)
            he_list = zeros(obj.num_faces*3,2);
            he_list(1:3:end,:) = [F(:,1) F(:,2)];
            he_list(2:3:end,:) = [F(:,2) F(:,3)];
            he_list(3:3:end,:) = [F(:,3) F(:,1)];
            obj.HE_from = he_list(:,1);
            obj.HE_to = he_list(:,2);
            obj.HE_next = repmat([2;3;1],obj.num_faces,1) + kron(3*(0:(obj.num_faces-1))',[1;1;1]);
            obj.HE_prev = repmat([3;1;2],obj.num_faces,1) + kron(3*(0:(obj.num_faces-1))',[1;1;1]);
            obj.HE_face = kron((1:obj.num_faces)', [1;1;1]);
            
            % Fill in face and vertex connectivity data
            obj.F_he = (1:3:(obj.num_faces*3))';
            obj.V_he = zeros(obj.num_vertices, 1);
            obj.V_he(he_list(:,1)) = 1:(obj.num_faces*3);
            
            % Generate lookup table for twin halfedges
            he_lookup = sparse(he_list(:,1), he_list(:,2), 1:(3*obj.num_faces));
            obj.HE_twin = full(he_lookup(sub2ind(size(he_lookup), he_list(:,2), he_list(:,1))));
            
            % Add boundary halfedge loops (except next and prev properties)
            he_offset = obj.num_faces*3;
            twin_less_indices = find(obj.HE_twin==0);
            num_twin_less = length(twin_less_indices);
            new_he_indices = (he_offset+1):(he_offset+num_twin_less);
            obj.HE_twin(twin_less_indices) = new_he_indices;
            obj.HE_twin(new_he_indices) = twin_less_indices;
            obj.HE_from(new_he_indices) = obj.HE_to(twin_less_indices);
            obj.HE_to(new_he_indices) = obj.HE_from(twin_less_indices);
            obj.HE_face(new_he_indices) = 0;
            
            % Fill in next property of boundary halfedges by iterating
            % around the "to" vertex of the boundary halfedge until another
            % boundary halfedge is found. Derive prev property from next
            % property.
            next_candidates = obj.HE_twin(new_he_indices);
            next_confirmed = zeros(size(next_candidates));
            candidate_offsets = zeros(size(next_candidates));
            while ~isempty(next_candidates)
                done_logical = obj.HE_face(next_candidates) == 0;
                done_indices = find(done_logical);
                next_confirmed(done_indices + candidate_offsets(done_logical)) = next_candidates(done_logical);
                next_candidates = next_candidates(~done_logical);
                candidate_offsets = candidate_offsets + cumsum(done_logical);
                candidate_offsets = candidate_offsets(~done_logical);
                next_candidates = obj.HE_twin(obj.HE_prev(next_candidates));
            end
            obj.HE_next(new_he_indices) = next_confirmed;
            obj.HE_prev(obj.HE_next(new_he_indices)) = new_he_indices;
            
            obj.num_halfedges = 3*obj.num_faces + num_twin_less;
            
            % Generate edges and fill in HE_edge and E_he
            he_vertices = sort([obj.HE_from obj.HE_to], 2);
            [~, obj.E_he, obj.HE_edge] = unique(he_vertices, 'rows');
            obj.num_edges = length(obj.E_he);
        end
        
        function [V,F] = toFaceVertexMesh(obj)
            % Returns an nv-by-3 matrix of vertex positions and an nf-by-3
            % matrix of triangle indices describing the mesh.
            V = reshape([obj.V_traits.position],3,[])';
            if nargout > 1
                F = [obj.HE_from(obj.HE_prev(obj.F_he))...
                    obj.HE_from(obj.F_he)...
                    obj.HE_from(obj.HE_next(obj.F_he))];
            end
        end
        
        function he = getHalfedge(obj,index)
            % Returns the index'th halfedge of the mesh. If index is a
            % vector, returns an object pointing to a list of
            % halfedges.
            if islogical(index)
                if length(index) <= obj.num_halfedges
                    he = TM_Halfedge(obj, find(index));
                else
                    error('Halfedge logical index too long!');
                end
            elseif isnumeric(index)
                if any((index > obj.num_halfedges) | (index < 1))
                    error('Halfedge Index out of bounds!');
                else
                    he = TM_Halfedge(obj, index);
                end
            end
        end
        
        function he = getAllHalfedges(obj)
            % Returns an object pointing to a list of all halfedges.
            he = TM_Halfedge(obj, 1:obj.num_halfedges);
        end
        
        function e = getEdge(obj,index)
            % Returns the index'th edge of the mesh. If index is a
            % vector, returns an object pointing to a list of
            % edges.
            if islogical(index)
                if length(index) <= obj.num_edges
                    e = TM_Edge(obj, find(index));
                else
                    error('Edge logical index too long!');
                end
            elseif isnumeric(index)
                if any((index > obj.num_edges) | (index < 1))
                    error('Edge Index out of bounds!');
                else
                    e = TM_Edge(obj, index);
                end
            end
        end
        
        function e = getAllEdges(obj)
            % Returns an object pointing to a list of all edges.
            e = TM_Edge(obj, 1:obj.num_edges);
        end
        
        function v = getVertex(obj,index)
            % Returns the index'th vertex of the mesh. If index is a
            % vector, returns an object pointing to a list of
            % vertices.
            if islogical(index)
                if length(index) <= obj.num_vertices
                    v = TM_Vertex(obj, find(index));
                else
                    error('Vertex logical index too long!');
                end
            elseif isnumeric(index)
                if any((index > obj.num_vertices) | (index < 1))
                    error('Vertex Index out of bounds!');
                else
                    v = TM_Vertex(obj, index);
                end
            end
        end
        
        function v = getAllVertices(obj)
            % Returns an object pointing to a list of all vertices.
            v = TM_Vertex(obj, 1:obj.num_vertices);
        end
        
        function f = getFace(obj,index)
            % Returns the index'th face of the mesh. If index is a
            % vector, returns an object pointing to a list of
            % faces.
            if islogical(index)
                if length(index) <= obj.num_faces
                    f = TM_Face(obj, find(index));
                else
                    error('Face logical index too long!');
                end
            elseif isnumeric(index)
                if any((index > obj.num_faces) | (index < 1))
                    error('Face Index out of bounds!');
                else
                    f = TM_Face(obj, index);
                end
            end
        end
        
        function f = getAllFaces(obj)
            % Returns an object pointing to a list of all faces.
            f = TM_Face(obj, 1:obj.num_faces);
        end
    end
end