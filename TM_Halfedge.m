classdef TM_Halfedge
    % An object pointing to one or more halfedges of a TriangleMesh.
    properties(GetAccess=public, SetAccess=private)
        mesh % A reference to the TriangleMesh
        index % The index (indices) of the referenced halfedge (halfedges)
    end
    
    methods(Access = {?TriangleMesh, ?TM_Vertex, ?TM_Face, ?TM_Edge})
        function obj = TM_Halfedge(mesh, index)
            obj.mesh = mesh;
            obj.index = index;
        end
    end
    
    methods
        function ret = next(obj)
            % Returns the next halfedge (halfedges) of the current one
            % (ones).
            ret = TM_Halfedge(obj.mesh, obj.mesh.HE_next(obj.index));
        end
        
        function ret = prev(obj)
            % Returns the previous halfedge (halfedges) of the current one
            % (ones).
            ret = TM_Halfedge(obj.mesh, obj.mesh.HE_prev(obj.index));
        end
        
        function ret = twin(obj)
            % Returns the twin (=opposite) halfedge (halfedges) of the current one
            % (ones).
            ret = TM_Halfedge(obj.mesh, obj.mesh.HE_twin(obj.index));
        end
        
        function ret = from(obj)
            % Returns the vertex (vertices) from which this halfedge (these
            % halfedges) originate(s)
            ret = TM_Vertex(obj.mesh, obj.mesh.HE_from(obj.index));
        end
        
        function ret = to(obj)
            % Returns the vertex (vertices) to which this halfedge (these
            % halfedges) point(s)
            ret = TM_Vertex(obj.mesh, obj.mesh.HE_to(obj.index));
        end
        
        function ret = face(obj)
            % Returns the face (face) to which this halfedge (these
            % halfedges) belong(s). For boundary halfedges, a Face object
            % with index 0 is returned.
            ret = TM_Face(obj.mesh, obj.mesh.HE_face(obj.index));
        end
        
        function ret = edge(obj)
            % Returns the edge (edges) to which this halfedge (these
            % halfedges) belong(s)
            ret = TM_Edge(obj.mesh, obj.mesh.HE_edge(obj.index));
        end
        
        function ret = getTraits(obj)
            % Returns a struct (array of structs) of the traits of the
            % referenced halfedge (halfedges)
            ret = obj.mesh.HE_traits(obj.index);
        end
        
        function ret = getTrait(obj, name)
            % Returns the trait 'name' of the referenced halfedge (halfedges).
            % If the object references more than one halfedge, the trait will
            % be returned in a matrix that contains the trait of the
            % i-th referenced halfedge in its i-th row.
            ret = reshape([obj.mesh.HE_traits(obj.index).(name)], ...
                size(obj.mesh.HE_traits(1).(name),2), [])';
        end
        
        function setTrait(obj, name, val)
            % Sets a trait of the referenced halfedge (halfedges). If a list
            % of halfedges is referenced, val is the same format as returned by
            % getTrait.
            if size(val,1) > 1
                temp = num2cell(val,2);
                [obj.mesh.HE_traits(obj.index).(name)] = temp{:};
            else
                [obj.mesh.HE_traits(obj.index).(name)] = deal(val);
            end
        end
    end
end