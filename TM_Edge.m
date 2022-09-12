classdef TM_Edge
    % An object pointing to one or more edges of a TriangleMesh.
    properties(GetAccess=public, SetAccess=private)
        mesh % A reference to the TriangleMesh
        index % The index (indices) of the referenced edge (edges)
    end
    
    methods(Access = {?TriangleMesh, ?TM_Halfedge, ?TM_Face, ?TM_Vertex})
        function obj = TM_Edge(mesh, index)
            obj.mesh = mesh;
            obj.index = index;
        end
    end
    
    methods
        function ret = halfedge(obj)
            % Returns a halfedge (list of halfedges) which is part of the
            % edge (list of edges).
            ret = TM_Halfedge(obj.mesh, obj.mesh.E_he(obj.index));
        end
        
        function ret = getTraits(obj)
            % Returns a struct (array of structs) of the traits of the
            % referenced edge (edges)
            ret = obj.mesh.E_traits(obj.index);
        end
        
        function ret = getTrait(obj, name)
            % Returns the trait 'name' of the referenced edge (edges).
            % If the object references more than one edge, the trait will
            % be returned in a matrix that contains the trait of the
            % i-th referenced edge in its i-th row.
            ret = reshape([obj.mesh.E_traits(obj.index).(name)], ...
                size(obj.mesh.E_traits(1).(name),2), [])';
        end
        
        function setTrait(obj, name, val)
            % Sets a trait of the referenced edge (edges). If a list
            % of edges is referenced, val is the same format as returned by
            % getTrait.
            if size(val,1) > 1
                temp = num2cell(val,2);
                [obj.mesh.E_traits(obj.index).(name)] = temp{:};
            else
                [obj.mesh.E_traits(obj.index).(name)] = deal(val);
            end
        end
    end
end