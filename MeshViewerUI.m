classdef MeshViewerUI < handle
    properties(Access=private)
        fig
        axes
        lights
        DISPLAY
        
        model_stats_text
        preserve_volume_ui
        wl_ui
        wp_ui
        eigenfunctions_ui
        shading_type_group
        
        model_patch
        model_vertex_patch
        model_vn_patch
        model_fn_patch
        grid_patch
        boundary_patch
        bounding_box_patch
        
        normal_scale
        vertex_normal_weighting
        mesh
        last_file
        
        L_uniform
        L_Cotangent
        
        L_uniform_dirty
        L_Cotangent_dirty
        
        basic_lambda
        recompute_every_iteration
        laplacian_weighting
        initial_mesh_volume
        initial_vertex_positions
        preserve_volume
        num_iterations
        lsq_weighting
        num_eigenfunctions
        laplacian_normalized
        quantile_range
    end
    
    properties(Access=private, Constant)
        edge_color = [0 0 0]
        vertex_color = [0 0 0]
        face_color = [0.6 0.6 1]
        bb_color = [0.4 0.4 0.4];
        grid_color = [0.7 0.7 0.7];
        boundary_color = [1 0.2 0.2];
        face_normal_color = [1 0 0.5];
        vertex_normal_color = [1 0.5 0];
        
        align_view_text = {'+X','-X','+Y','-Y','+Z','-Z'};
        align_view_angles = [-90 0;90 0;0 0;180 0;0 -90;0 90];
    end
    
    methods
        function obj = MeshViewerUI()
            obj.fig = figure('Name','Mesh Viewer',...
                'Visible','off','Position',[360,500,1200,600]);
            
            obj.axes = axes('Parent',obj.fig,'Units','pixels',...
                'Position',[30 30 540 540],'Units','normalized',...
                'DataAspectRatio',[1 1 1]);
            xlabel('x');
            ylabel('y');
            zlabel('z');
            
            hold on;
            
            light_angles = [-45 45; -135 45; 90 -30];
            for i=1:size(light_angles,1)
                obj.lights{i} = lightangle(light_angles(i,1), light_angles(i,2));
            end
            
            obj.model_patch = patch('Vertices',[],'Faces',[],...
                'EdgeColor',obj.edge_color,'FaceColor',obj.face_color,...
                'FaceLighting','none','SpecularStrength',0.5,'SpecularExponent',20);
            obj.model_vertex_patch = patch('Vertices',[],'Faces',[],...
                'MarkerFaceColor',obj.vertex_color,'MarkerSize',4,'Marker','o',...
                'MarkerEdgeColor','none','Visible','off');
            obj.grid_patch = patch('Vertices',[],'Faces',[],...
                'EdgeColor',obj.grid_color,'FaceColor','none');
            obj.bounding_box_patch = patch('Vertices',[],'Faces',[],...
                'EdgeColor',obj.bb_color,'FaceColor','none','LineWidth',1);
            obj.boundary_patch = patch('Vertices',[],'Faces',[],...
                'EdgeColor',obj.boundary_color,'FaceColor','none','LineWidth',2,...
                'Visible','off');
            obj.model_fn_patch = patch('Vertices',[],'Faces',[],...
                'EdgeColor',obj.face_normal_color,'FaceColor','none',...
                'LineWidth',1.5,'Visible','off');
            obj.model_vn_patch = patch('Vertices',[],'Faces',[],...
                'EdgeColor',obj.vertex_normal_color,'FaceColor','none',...
                'LineWidth',1.5,'Visible','off');
            
            % Model Stats
            obj.model_stats_text = uicontrol('Style','text','String','',...
                'Position',[0 582 200 20],'Units','normalized','HorizontalAlignment','left');
            
            % File Panel
            file_panel = uipanel(obj.fig,'Title','File','Units','pixels',...
                'Position',[700 540 490 56],'Units','normalized');
            uicontrol(file_panel,'Style','pushbutton','String','Load Model...',...
                'Position',[5 20 80 20],'Units','normalized','Callback',@obj.loadModelPressed);
            
            % View Panel
            view_panel = uipanel(obj.fig,'Title','View','Units','pixels',...
                'Position',[700 440 490 96],'Units','normalized');
            
            % V,E,F
            uicontrol(view_panel,'Style','checkbox','String','Vertices',...
                'Position',[5 64 60 20],'Units','normalized','Value',0,'Callback',@obj.viewOptionChanged);
            uicontrol(view_panel,'Style','checkbox','String','Edges',...
                'Position',[75 64 50 20],'Units','normalized','Value',1,'Callback',@obj.viewOptionChanged);
            uicontrol(view_panel,'Style','checkbox','String','Faces',...
                'Position',[135 64 60 20],'Units','normalized','Value',1,'Callback',@obj.viewOptionChanged);
            
            % Grid, BB, Boundary
            uicontrol(view_panel,'Style','checkbox','String','Grid',...
                'Position',[5 44 50 20],'Units','normalized','Value',1,'Callback',@obj.viewOptionChanged);
            uicontrol(view_panel,'Style','checkbox','String','Bounding Box',...
                'Position',[60 44 90 20],'Units','normalized','Value',1,'Callback',@obj.viewOptionChanged);
            uicontrol(view_panel,'Style','checkbox','String','Boundary',...
                'Position',[5 24 90 20],'Units','normalized','Value',0,'Callback',@obj.viewOptionChanged);
            
            % Normals
            uicontrol(view_panel,'Style','checkbox','String','Vertex Normals',...
                'Position',[240 64 100 20],'Units','normalized','Value',0,'Callback',@obj.viewOptionChanged);
            vn_type_group = uibuttongroup(view_panel,'BorderType','none',...
                'Units','pixels','Position',[350 64 200 20],'Units','normalized',...
                'SelectionChanged',@obj.vertexNormalWeightingChanged);
            uicontrol(vn_type_group, 'Style','radiobutton','String','area',...
                'Position',[0 0 50 20],'Units','normalized');
            uicontrol(vn_type_group, 'Style','radiobutton','String','angle',...
                'Position',[50 0 50 20],'units','normalized');
            obj.vertex_normal_weighting = 'area';
            
            uicontrol(view_panel,'Style','checkbox','String','Face Normals',...
                'Position',[240 44 100 20],'Units','normalized','Value',0,'Callback',@obj.viewOptionChanged);
            uicontrol(view_panel,'Style','text','String','Scale:',...
                'Position',[240 20 40 20],'Units','normalized','HorizontalAlignment','left');
            uicontrol(view_panel,'Style','slider','Min',-2,'Max',2,'SliderStep',[0.2/4 0.5/4],...
                'Position',[280 24 150 20],'Units','normalized','Value',0,'Callback',@obj.normalScaleChanged);
            obj.normal_scale = 0.04;
            
            % Align View
            uicontrol(view_panel,'Style','text','String','Align View',...
                'Position',[5 0 60 20],'Units','normalized','HorizontalAlignment','left');
            for i=1:6
                uicontrol(view_panel,'Style','pushbutton','String',obj.align_view_text{i},...
                    'Position',[65+(i-1)*30 2 25 20],'Units','normalized','UserData',i,...
                    'Callback',@obj.alignViewPressed);
            end
            
            % Shading Panel
            shading_panel = uipanel(obj.fig,'Title','Shading','Units','pixels',...
                'Position',[700 380 490 56],'Units','normalized');
            
            uicontrol(shading_panel,'Style','text','String','Type:',...
                'Position',[5 20 60 20],'Units','normalized','HorizontalAlignment','left');
            obj.shading_type_group = uibuttongroup(shading_panel,'BorderType','none',...
                'Units','pixels','Position',[50 4 380 40],'Units','normalized',...
                'SelectionChanged',@obj.shadingTypeChanged);
            uicontrol(obj.shading_type_group,'Style','radiobutton','String','none',...
                'Position',[0 20 50 20],'Units','normalized');
            uicontrol(obj.shading_type_group,'Style','radiobutton','String','flat',...
                'Position',[50 20 50 20],'Units','normalized');
            uicontrol(obj.shading_type_group,'Style','radiobutton','String','Gouraud',...
                'Position',[90 20 70 20],'Units','normalized');
            uicontrol(obj.shading_type_group,'Style','radiobutton','String','mean curvature', ...
                'Position',[0 0 100 20],'Units','normalized');
            uicontrol(obj.shading_type_group,'Style','radiobutton','String','Gaussian curvature', ...
                'Position',[100 0 120 20],'Units','normalized');
            uicontrol(shading_panel,'Style','text', 'String', 'Quantile Range', ...
                'Position',[285 -1 80 20],'Units','normalized','HorizontalAlignment','left');
            uicontrol(shading_panel,'Style','edit','String','0.05',...
                'Position',[365 2 40 20],'Units','normalized','HorizontalAlignment','left',...
                'Callback',@obj.quantileRangeChanged,'UserData',{1,0.05});
            uicontrol(shading_panel,'Style','text', 'String', '-', ...
                'Position',[405 1 10 20],'Units','normalized');
            uicontrol(shading_panel,'Style','edit','String','0.95',...
                'Position',[415 2 40 20],'Units','normalized','HorizontalAlignment','left',...
                'Callback',@obj.quantileRangeChanged,'UserData',{2,0.95});
            obj.quantile_range = [0.05 0.95];
            
            % Laplacian Panel
            laplacian_panel = uipanel(obj.fig,'Title','Laplacian','Units','pixels',...
                'Position',[700 320 490 56],'Units','normalized');
            
            uicontrol(laplacian_panel,'Style','text','String','Weighting:',...
                'Position',[5 20 60 20],'Units','normalized','HorizontalAlignment','left');
            laplacian_weighting_group = uibuttongroup(laplacian_panel,'BorderType','none',...
                'Units','pixels','Position',[65 24 250 20],'Units','normalized',...
                'SelectionChanged',@obj.laplacianWeightingChanged);
            uicontrol(laplacian_weighting_group,'Style','radiobutton','String','uniform',...
                'Position',[0 0 65 20],'Units','normalized');
            uicontrol(laplacian_weighting_group,'Style','radiobutton','String','Cotangent',...
                'Position',[65 0 80 20],'Units','normalized');
            uicontrol(laplacian_panel, 'Style','checkbox','String','normalized',...
                'Position',[210 24 100 20],'Units','normalized','Callback',@obj.laplacianNormalizedChanged,...
                'Value',1);
            uicontrol(laplacian_panel,'Style','checkbox','String','Recompute every iteration',...
                'Position',[5 4 150 20],'Units','normalized','Value',1,'Callback',@obj.recomputeCheckboxChanged);
            uicontrol(laplacian_panel,'Style','pushbutton','String','Recompute once',...
                'Position',[160 2 100 20],'Units','normalized','Callback',@obj.recomputeOnceCallback);
            
            obj.laplacian_weighting = 'uniform';
            obj.laplacian_normalized = 1;
            obj.recompute_every_iteration = 1;
            obj.L_uniform_dirty = 1;
            obj.L_Cotangent_dirty = 1;
            
            % Smoothing Panel
            smoothing_panel = uipanel(obj.fig,'Title','Smoothing','Units','pixels',...
                'Position',[700 100 490 216],'Units','normalized');
            
            % Num Iterations
            uicontrol(smoothing_panel, 'Style','text','String','Iterations',...
                'Position',[5 180 60 20],'Units','normalized','HorizontalAlignment','left');
            iterations_ui = NumericSliderEdit(smoothing_panel,[80 183 150 20],1,20,@obj.iterationsChanged);
            iterations_ui.setInteger(1);
            iterations_ui.setValue(1);
            iterations_ui.setSliderStep([1/19 5/19]);
            % Preserve Volume
            obj.preserve_volume_ui = uicontrol(smoothing_panel, 'Style','checkbox','String','Preserve volume',...
                'Position',[240 183 120 20],'Units','normalized','Callback',@obj.preserveVolumeChanged);
            
            % Lambda
            uicontrol(smoothing_panel, 'Style','text','String','Lambda',...
                'Position',[5 155 45 20],'Units','normalized','HorizontalAlignment','left');
            basic_lambda_ui = NumericSliderEdit(smoothing_panel,[80 158 150 20],0,5,@obj.basicLambdaChanged);
            
            % Explicit & Implicit
            uicontrol(smoothing_panel, 'Style','pushbutton','String','Explicit Smoothing',...
                'Position',[5 132 100 20],'Units','normalized','Callback',@obj.basicSmoothingCallback,...
                'UserData','explicit');
            uicontrol(smoothing_panel, 'Style','pushbutton','String','Implicit Smoothing',...
                'Position',[110 132 100 20],'Units','normalized','Callback',@obj.basicSmoothingCallback,...
                'UserData','implicit');
            % Reset
            uicontrol(smoothing_panel, 'Style','pushbutton','String','Reset',...
                'Position',[220 132 60 20],'Units','normalized','Callback',@obj.resetMeshCallback);
            
            %DISPLAY = uicontrol('Style', 'text','fontsize',20,'position',[330 132 60 20],'backgroundcolor',[0,0,0]);
            
            obj.basic_lambda = 1;
            obj.preserve_volume = 0;
            obj.num_iterations = 1;
            
            % WL - WP Slider
            obj.wl_ui = uicontrol(smoothing_panel, 'Style','text','String','0.500 = WL',...
                'Position',[5 104 65 20],'Units','normalized','HorizontalAlignment','left');
            uicontrol(smoothing_panel, 'Style','slider','Min',0.001,'Max',0.999,'SliderStep',[0.1 0.2],...
                'Position',[70 106 100 20],'Value',0.5,'Units','normalized','Callback',@obj.wlwpSliderChanged);
            obj.wp_ui = uicontrol(smoothing_panel, 'Style','text','String','WP = 0.500',...
                'Position',[175 104 60 20],'Units','normalized','HorizontalAlignment','left');
            uicontrol(smoothing_panel, 'Style','pushbutton','String','LSQ Smoothing',...
                'Position',[5 80 100 20],'Units','normalized','Callback',@obj.basicSmoothingCallback,...
                'UserData','lsq');
            uicontrol(smoothing_panel, 'Style','pushbutton','String','Triangle Optimization',...
                'Position',[110 80 130 20],'Units','normalized','Callback',@obj.basicSmoothingCallback,...
                'UserData','triangle');
            
            obj.lsq_weighting = 0.5;
            
            % Spectral Smoothing
            uicontrol(smoothing_panel, 'Style','text','String','Eigenfunctions', ...
                'Position',[5 54 80 20],'Units','normalized','HorizontalAlignment','left');
            obj.eigenfunctions_ui = NumericSliderEdit(smoothing_panel,[90 56 150 20],1,20,@obj.eigenfunctionsChanged);
            obj.eigenfunctions_ui.setValue(1);
            obj.eigenfunctions_ui.setSliderStep([1/19 5/19]);
            obj.eigenfunctions_ui.setInteger(1);
            uicontrol(smoothing_panel, 'Style','pushbutton','String','Spectral Smoothing',...
                'Position',[5 30 120 20],'Units','normalized','Callback',@obj.basicSmoothingCallback,...
                'UserData','spectral');
            
            
            movegui(obj.fig,'center');
            obj.fig.Visible = 'on';
            
            basic_lambda_ui.setValue(1);
        end
        
        function quantileRangeChanged(obj, source, data)
            val = str2double(source.String);
            if isnan(val)
                source.String = source.UserData{2};
            else
                if val < 0 || val > 1
                    val = min(max(val,0),1);
                    source.String = val;
                end
                source.UserData{2} = val;
                obj.quantile_range(source.UserData{1}) = val;
                obj.updateShading(obj.shading_type_group.SelectedObject.String);
            end
        end
        
        function laplacianNormalizedChanged(obj, source, data)
            obj.laplacian_normalized = source.Value;
            obj.L_uniform_dirty = 1;
            obj.L_Cotangent_dirty = 1;
        end
        
        function eigenfunctionsChanged(obj, val)
            obj.num_eigenfunctions = val;
        end
        
        function wlwpSliderChanged(obj,source,data)
            obj.lsq_weighting = source.Value;
            obj.wl_ui.String = sprintf('%0.3f = WL', 1-obj.lsq_weighting);
            obj.wp_ui.String = sprintf('WP = %0.3f', obj.lsq_weighting);
        end
        
        function resetMeshCallback(obj,source,data)
            obj.mesh.getAllVertices().setTrait('position',obj.initial_vertex_positions);
            obj.updateModel();
            obj.L_uniform_dirty = 1;
            obj.L_Cotangent_dirty = 1;
        end
        
        function iterationsChanged(obj,val)
            obj.num_iterations = val;
        end
        
        function basicSmoothingCallback(obj,source,data)
            format short g
            t1=clock;
            for i=1:obj.num_iterations
                switch source.UserData
                    case 'implicit'
                        V_smooth = MeshSmoothing.implicitSmoothing(obj.mesh,obj.getLaplacian(),obj.basic_lambda);
                    case 'explicit'
                        V_smooth = MeshSmoothing.explicitSmoothing(obj.mesh,obj.getLaplacian(),obj.basic_lambda);
                    case 'lsq'
                        V_smooth = MeshSmoothing.lsqSmoothing(obj.mesh,obj.getLaplacian(),1-obj.lsq_weighting, obj.lsq_weighting);
                    case 'triangle'
                        V_smooth = MeshSmoothing.triangleSmoothing(obj.mesh, obj.getLaplacian('uniform'), obj.getLaplacian('Cotangent'), ...
                            1-obj.lsq_weighting, obj.lsq_weighting);
                    case 'spectral'
                        V_smooth = MeshSmoothing.spectralSmoothing(obj.mesh, obj.getLaplacian(), obj.num_eigenfunctions);
                    otherwise
                        V_smooth = obj.mesh.toFaceVertexMesh();
                end
                obj.mesh.getAllVertices().setTrait('position',V_smooth);
                if obj.recompute_every_iteration
                    obj.L_uniform_dirty = 1;
                    obj.L_Cotangent_dirty = 1;
                    if i~=obj.num_iterations
                        MeshHelper.calculateHalfedgeTraits(obj.mesh);
                    end
                end
            end
            
            if obj.preserve_volume
                new_vol = MeshHelper.computeVolume(obj.mesh);
                if abs(new_vol) > 10e-10
                    MeshHelper.scaleMesh(obj.mesh, (obj.initial_mesh_volume / new_vol)^(1/3));
                end
            end
            obj.updateModel(0);
            format short g
            t2=clock;
            time=etime(t2,t1);  
            %set(@obj.DISPLAY,'string',time)
            
        end
        
        function L = getLaplacian(obj,type)
            if nargin < 2
                type = obj.laplacian_weighting;
            end
            switch type
                case 'uniform'
                    if obj.L_uniform_dirty
                        obj.L_uniform = MeshLaplacian.computeUniformLaplacian(obj.mesh,obj.laplacian_normalized);
                        obj.L_uniform_dirty = 0;
                    end
                    L = obj.L_uniform;
                    return;
                case 'Cotangent'
                    if obj.L_Cotangent_dirty
                        obj.L_Cotangent = MeshLaplacian.computeCotangentLaplacian(obj.mesh,obj.laplacian_normalized);
                        obj.L_Cotangent_dirty = 0;
                    end
                    L = obj.L_Cotangent;
                    return;
            end
        end
        
        function preserveVolumeChanged(obj,source,data)
            obj.preserve_volume = source.Value;
        end
        
        function laplacianWeightingChanged(obj,source,data)
            obj.laplacian_weighting = data.NewValue.String;
        end
        
        function recomputeOnceCallback(obj, source, data)
            obj.L_uniform_dirty = 1;
            obj.L_Cotangent_dirty = 1;
        end
        
        function recomputeCheckboxChanged(obj,source,data)
            obj.recompute_every_iteration = source.Value;
            if obj.recompute_every_iteration
                obj.L_uniform_dirty = 1;
                obj.L_Cotangent_dirty = 1;
            end
        end
        
        function basicLambdaChanged(obj,val)
            obj.basic_lambda = val;
        end
        
        function alignViewPressed(obj,source,data)
            i = source.UserData;
            view(obj.align_view_angles(i,:));
        end
        
        function vertexNormalWeightingChanged(obj,source,data)
            obj.vertex_normal_weighting = data.NewValue.String;
            MeshHelper.calculateVertexNormals(obj.mesh, obj.vertex_normal_weighting);
            obj.updateVertexNormalModel();
        end
        
        function loadModelPressed(obj,source,data)
            filters = {'*.obj', 'OBJ Files (*.mat)';...
                '*.*', 'All Files (*.*)'};
            if isempty(obj.last_file)
                [filename, pathname] = uigetfile(filters, 'Load Model...');
            else
                [filename, pathname] = uigetfile(filters, 'Load Model...', obj.last_file);
            end
            if ~(isnumeric(filename) && isnumeric(pathname))
                obj.last_file = [pathname filename];
                obj.loadModel(obj.last_file);
            end
        end
        
        function shadingTypeChanged(obj,source,data)
            obj.updateShading(data.NewValue.String);
        end
        
        function updateShading(obj, str)
            obj.model_patch.FaceVertexCData = [];
            obj.model_patch.FaceColor = obj.face_color;
            v_colors = [];
            switch str
                case 'none'
                    obj.model_patch.FaceLighting = str;
                case 'flat'
                    obj.model_patch.FaceLighting = str;
                case 'Gouraud'
                    obj.model_patch.FaceLighting = str;
                case 'mean curvature'
                    v_colors = obj.mesh.getAllVertices().getTrait('mean_curv');
                case 'Gaussian curvature'
                    v_colors = obj.mesh.getAllVertices().getTrait('gauss_curv');
            end
            if ~isempty(v_colors)
                obj.model_patch.FaceLighting = 'none';
                obj.model_patch.FaceColor = 'interp';
                c_min = quantile(v_colors, obj.quantile_range(1));
                c_max = quantile(v_colors, obj.quantile_range(2));
                v_colors(v_colors < c_min) = c_min;
                v_colors(v_colors > c_max) = c_max;
                obj.model_patch.FaceVertexCData = v_colors;
                colorbar
            else
                colorbar('off');
            end
        end
        
        function normalScaleChanged(obj,source,data)
            obj.normal_scale = 0.04*(3^source.Value);
            obj.updateFaceNormalModel();
            obj.updateVertexNormalModel();
        end
        
        function viewOptionChanged(obj, source, data)
            switch(source.String)
                case 'Vertices'
                    obj.model_vertex_patch.Visible = val2vis(source.Value);
                case 'Edges'
                    if source.Value==1
                        obj.model_patch.EdgeColor = obj.edge_color;
                    else
                        obj.model_patch.EdgeColor = 'none';
                    end
                case 'Faces'
                    if source.Value==1
                        obj.model_patch.FaceColor = obj.face_color;
                    else
                        obj.model_patch.FaceColor = 'none';
                    end
                case 'Vertex Normals'
                    obj.model_vn_patch.Visible = val2vis(source.Value);
                case 'Face Normals'
                    obj.model_fn_patch.Visible = val2vis(source.Value);
                case 'Grid'
                    obj.grid_patch.Visible = val2vis(source.Value);
                case 'Bounding Box'
                    obj.bounding_box_patch.Visible = val2vis(source.Value);
                case 'Boundary'
                    obj.boundary_patch.Visible = val2vis(source.Value);
                otherwise
            end
        end
        
        function loadModel(obj, filename)
            obj.mesh = ModelLoader.loadOBJ(filename);
            
            obj.updateModelStats();
            
            obj.updateModel();
            
            obj.initial_mesh_volume = MeshHelper.computeVolume(obj.mesh);
            obj.initial_vertex_positions = obj.mesh.toFaceVertexMesh();
            obj.L_uniform_dirty = 1;
            obj.L_Cotangent_dirty = 1;
            hasBoundary = MeshHelper.hasBoundary(obj.mesh);
            obj.preserve_volume_ui.Enable = val2vis(~hasBoundary);
            if hasBoundary
                obj.preserve_volume_ui.Value = 0;
            end
            obj.eigenfunctions_ui.setMin(1);
            obj.eigenfunctions_ui.setMax(obj.mesh.num_vertices-2);
            obj.eigenfunctions_ui.setSliderStep([1 5]/(obj.mesh.num_vertices-3));
        end
        
        function updateModel(obj,reset_camera)
            if nargin < 2
                reset_camera = 1;
            end
            [V,F] = obj.mesh.toFaceVertexMesh();
            
            obj.model_patch.Vertices = V;
            obj.model_patch.Faces = F;
            
            obj.model_vertex_patch.Vertices = V;
            obj.model_vertex_patch.Faces = (1:obj.mesh.num_vertices)';
            
            obj.updateAxes(reset_camera);
            
            MeshHelper.calculateFaceTraits(obj.mesh);
            MeshHelper.calculateVertexTraits(obj.mesh);
            MeshHelper.calculateHalfedgeTraits(obj.mesh);
            MeshHelper.calculateVertexNormals(obj.mesh, obj.vertex_normal_weighting);
            MeshHelper.calculateDiscreteCurvatures(obj.mesh);
            obj.updateShading(obj.shading_type_group.SelectedObject.String);
            
            obj.updateGridModel();
            obj.updateBoundingBoxModel();
            obj.updateBoundaryModel();
            obj.updateFaceNormalModel();
            obj.updateVertexNormalModel();
        end
        
        function updateModelStats(obj)
            nv = obj.mesh.num_vertices;
            ne = obj.mesh.num_edges;
            nf = obj.mesh.num_faces;
            
            obj.model_stats_text.String = sprintf(...
                ' v %i e %i f %i',nv,ne,nf);
        end
        
        function updateAxes(obj,reset_camera)
            if nargin < 2
                reset_camera = 1;
            end
            V = obj.mesh.toFaceVertexMesh();
            
            pmin = min(V,[],1);
            pmax = max(V,[],1);
            
            view_offset = max(max(0.1*(pmax-pmin)), 1e-3);
            view_min = pmin - view_offset;
            view_max = pmax + view_offset;
            
            axis vis3d;
            if reset_camera
                view(-60,30);
                zoom out;
                zoom(0.7);
            end
            
            xlim([view_min(1) view_max(1)]);
            ylim([view_min(2) view_max(2)]);
            zlim([view_min(3) view_max(3)]);
        end
        
        function updateGridModel(obj)
            r = max([obj.axes.XLim(2)-obj.axes.XLim(1)...
                obj.axes.YLim(2)-obj.axes.YLim(1)]);
            step = 10^round(log(r/10)/log(10));
            x_ticks = ((ceil(obj.axes.XLim(1)/step)*step):step:(floor(obj.axes.XLim(2)/step)*step))';
            y_ticks = ((ceil(obj.axes.YLim(1)/step)*step):step:(floor(obj.axes.YLim(2)/step)*step))';
            v1 = [kron(x_ticks,[1;1]) repmat(obj.axes.YLim(:),length(x_ticks),1)];
            v2 = [repmat(obj.axes.XLim(:),length(y_ticks),1) kron(y_ticks,[1;1])];
            
            height = 0;
            zl = zlim;
            if zl(1)>0
                height = zl(1)*0.99+zl(2)*0.01;
            end
            obj.grid_patch.Vertices = [[v1;v2] height*ones(2*(length(x_ticks)+length(y_ticks)),1)];
            obj.grid_patch.Faces = reshape(1:size(obj.grid_patch.Vertices,1),2,[])';
        end
        
        function updateBoundingBoxModel(obj)
            if isempty(obj.mesh)
                return;
            end
            [p_min, p_max] = MeshHelper.getBoundingBox(obj.mesh);
            [V,E] = GeometryHelper.buildBoxEdges(p_min,p_max);
            
            obj.bounding_box_patch.Vertices = V;
            obj.bounding_box_patch.Faces = E;
        end
        
        function updateBoundaryModel(obj)
            [V_start, V_end] = MeshHelper.getBoundaryEdges(obj.mesh);
            
            obj.boundary_patch.Vertices = reshape([V_start'; V_end'],3,[])';
            obj.boundary_patch.Faces = reshape(1:size(obj.boundary_patch.Vertices,1),2,[])';
        end
        
        function updateFaceNormalModel(obj)
            if ~isfield(obj.mesh.F_traits, 'normal') || ...
                    ~isfield(obj.mesh.F_traits, 'centroid')
                obj.model_fn_patch.Vertices = [];
                obj.model_fn_patch.Faces = [];
                return;
            end
            
            f = obj.mesh.getAllFaces();
            v1 = f.getTrait('centroid');
            v2 = v1 + f.getTrait('normal')*obj.normal_scale;
            
            obj.model_fn_patch.Vertices = reshape([v1'; v2'],3,[])';
            obj.model_fn_patch.Faces = reshape(1:size(obj.model_fn_patch.Vertices,1),2,[])';
        end
        
        function updateVertexNormalModel(obj)
            if ~isfield(obj.mesh.V_traits, 'normal')
                obj.model_vn_patch.Vertices = [];
                obj.model_vn_patch.Faces = [];
                return;
            end
            
            v = obj.mesh.getAllVertices();
            v1 = v.getTrait('position');
            v2 = v1 + v.getTrait('normal')*obj.normal_scale;
            
            obj.model_vn_patch.Vertices = reshape([v1'; v2'],3,[])';
            obj.model_vn_patch.Faces = reshape(1:size(obj.model_vn_patch.Vertices,1),2,[])';
        end
    end
end