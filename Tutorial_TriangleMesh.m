load_paths();

% Create half-edge data structure and load model (manifold with boundary)
mesh = ModelLoader.loadOBJ('data/nefertiti.obj');

% To query a single element, use the following syntax
f1 = mesh.getFace(1);
he_of_f1 = f1.halfedge();
v1 = he_of_f1.from();
v2 = he_of_f1.to();
v3 = he_of_f1.next().to();

% Elements (such as vertices, halfedges, edges, and faces) have 'traits',
% or properties. To query a single trait of a single element, use the
% following syntax. Initially, the only trait in a triangle mesh is the
% vertex trait 'position' that stores a 1-by-3 vertex position.
vpos1 = v1.getTrait('position');
vpos2 = v2.getTrait('position');
vpos3 = v3.getTrait('position');

% To change an existing trait, use
v1.setTrait('position', vpos1 + [0 1 0]);

[V,F] = mesh.toFaceVertexMesh();

figure;
trimesh(F,V(:,1),V(:,2),V(:,3));
axis equal tight vis3d;

% New traits are added the same way. However, they are automatically added
% to all elements, even if there are only explicitly set for a single one.
% For example
v1.setTrait('normal', [1 0 0]);
% will create the vertex trait 'normal', set the value of the first vertex
% to [1 0 0]. All others will be initialized to [].

% To query multiple elements at the same time, you can use a vector of
% indices instead of a single index, e.g.
faces = mesh.getFace(1:10);
% All commands will be applied to all faces, e.g.
halfedges = faces.halfedge();
% now refers to a set of ten halfedges, each of which belongs to one of the
% ten faces.
% Querying traits of multiple elements returns the traits as rows of a
% matrix.
vp = halfedges.from().getTrait('position');
% is a 10x3 matrix containing the positions of the 'from' vertices of the
% 10 halfedges.
% To set traits for multiple elements, pass the trait values to the
% setTraits(...) methods in the same way: one trait value per row
vp = bsxfun(@plus, vp, [0 1 0]);
halfedges.from().setTrait('position', vp);

[V,F] = mesh.toFaceVertexMesh();

figure;
trimesh(F,V(:,1),V(:,2),V(:,3));
axis equal tight vis3d;

% Due to the syntax for getting/setting traits of multiple elements, only
% scalars and row-vectors are supported as traits. Do NOT use column
% vectors or matrices as traits in this framework!

% This way you can parallelize many whole-mesh operations. This example
% shifts all vertices with a z-coordinate above 0.5 by the vector [0 0 1].
v = mesh.getAllVertices();
all_vp = v.getTrait('position');
upper_v = mesh.getVertex(v.index(all_vp(:,3) > 0.5));
upper_vp = upper_v.getTrait('position');
upper_v.setTrait('position', bsxfun(@plus, upper_vp, [0 0 1]));

[V,F] = mesh.toFaceVertexMesh();

figure;
trimesh(F,V(:,1),V(:,2),V(:,3));
axis equal tight vis3d;

% All tasks in Assignment 1 are possible without using any loops. Although
% for some tasks you have to get creative in order to do that :)