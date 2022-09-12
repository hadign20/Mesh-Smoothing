classdef TM_Vertex
    % An object pointing to one or more vertices of a TriangleMesh.
    properties(GetAccess=public, SetAccess=private)
        mesh % A reference to the TriangleMesh
        index % The index (indices) of the referenced vertex (vertices)
    end
    
    methods(Access = {?TriangleMesh, ?TM_Halfedge, ?TM_Face, ?TM_Edge})
        function obj = TM_Vertex(mesh, index)
            obj.mesh = mesh;
            obj.index = index;
        end
    end
    
    methods
        function ret = halfedge(obj)
            % Returns a halfedge (list of halfedges) pointing away from the
            % vertex (list of vertices).
            ret = TM_Halfedge(obj.mesh, obj.mesh.V_he(obj.index));
        end
        
        function ret = getTraits(obj)
            % Returns a struct (array of structs) of the traits of the
            % referenced vertex (vertices)
            ret = obj.mesh.V_traits(obj.index);
        end
        
        function ret = getTrait(obj, name)
            % Returns the trait 'name' of the referenced vertex (vertices).
            % If the object references more than one vertex, the trait will
            % be returned in a matrix that contains the trait of the
            % i-th referenced vertex in its i-th row.
            ret = reshape([obj.mesh.V_traits(obj.index).(name)], ...
                size(obj.mesh.V_traits(1).(name),2), [])';
        end
        
        function setTrait(obj, name, val)
            % Sets a trait of the referenced vertex (vertices). If a list
            % of vertices is referenced, val is the same format as returned by
            % getTrait.
            if size(val,1) > 1
                temp = num2cell(val,2);
                [obj.mesh.V_traits(obj.index).(name)] = temp{:};
            else
                [obj.mesh.V_traits(obj.index).(name)] = deal(val);
            end
        end
    end
end