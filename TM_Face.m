classdef TM_Face
    % An object pointing to one or more faces of a TriangleMesh.
    properties(GetAccess=public, SetAccess=private)
        mesh % A reference to the TriangleMesh
        index % The index (indices) of the referenced faces (vertices)
    end
    
    methods(Access = {?TriangleMesh, ?TM_Halfedge, ?TM_Vertex, ?TM_Edge})
        function obj = TM_Face(mesh, index)
            obj.mesh = mesh;
            obj.index = index;
        end
    end
    
    methods
        function ret = halfedge(obj)
            % Returns a halfedge (list of halfedges) which is part of the
            % face (list of faces).
            ret = TM_Halfedge(obj.mesh, obj.mesh.F_he(obj.index));
        end
        
        function ret = getTraits(obj)
            % Returns a struct (array of structs) of the traits of the
            % referenced face (faces)
            ret = obj.mesh.F_traits(obj.index);
        end
        
        function ret = getTrait(obj, name)
            % Returns the trait 'name' of the referenced face (faces).
            % If the object references more than one face, the trait will
            % be returned in a matrix that contains the trait of the
            % i-th referenced face in its i-th row.
            ret = reshape([obj.mesh.F_traits(obj.index).(name)], ...
                size(obj.mesh.F_traits(1).(name),2), [])';
        end
        
        function setTrait(obj, name, val)
            % Sets a trait of the referenced face (faces). If a list
            % of faces is referenced, val is the same format as returned by
            % getTrait.
            if size(val,1) > 1
                temp = num2cell(val,2);
                [obj.mesh.F_traits(obj.index).(name)] = temp{:};
            else
                [obj.mesh.F_traits(obj.index).(name)] = deal(val);
            end
        end
    end
end