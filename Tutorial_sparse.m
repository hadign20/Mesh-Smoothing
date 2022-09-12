% Matrices involved in the processing of meshes are usually quadratic in
% the number of vertices (=nv). For a mesh with 10^4 vertices, this gives
% 10^8 matrix entries, which is too much to store and process in dense
% form.
%
% Luckily, these matrices are often sparse, meaning that the number of
% non-zero elements per row is not in O(nv), but in O(1). This gives a
% total of O(nv) non-zero entries in the matrix. It is more efficient to
% store only these non-zero entries along with their row and column
% indices instead of a two-dimensional array of all matrix entries.
%
% Example: to describe an identity matrix with 1000 rows and columns, it
% would be inefficient to store all 10^6 elements. Instead, we could store
% a list of non-zero entries along with their position in the matrix. This
% would take the form of
% [1 1 1;
%  2 2 1;
%  3 3 1;
%  .....
%  .....
%  999 999 1;
%  1000 1000 1]
%
% Matlab has a dedicated data type 'sparse double' to store large matrices
% in this form. The most useful constructor for this matrix is
%
% sparse(row_indices, col_indices, values, num_rows, num_cols),
%
% in which the first three arguments are vectors, that give the row
% indices, column indices, and values of all non-zero entries. For example,
% to construct a forward finite difference matrix
%
% [-1  1  0  0;
%   0 -1  1  0;
%   0  0 -1  1],
%
% we could use

fd_m = sparse([1:3 1:3], [1:3 2:4], [-ones(1,3) ones(1,3)], 3, 4);
display(full(fd_m));

% Many of Matlab's matrix and vector operations are overloaded to work
% with sparse matrices as well. For example, you can concatenate sparse
% matrices just like dense ones. 

x = [fd_m; speye(4)];
display(full(x));

% Matrix-vector multiplications and linear solves can be performed with
% sparse matrices as well. Note that linear solves are automatically
% performed in a least-squares sense if the system of linear
% equations is overdetermined.

y = x * [3;4;5;6];
display(y);
x2 = x \ [1;1;1;2.5;3.5;5.5;6.5];
display(x2);

% A very useful property of the sparse constructor allows implicit
% summation of entries at the same position. E.g., to compute the following
% matrix
%
% [ 0 1 0 0 0;
%   0 1 1 0 0;
%   1 2 2 2 1;
%   0 0 1 1 0;
%   0 0 0 1 0 ],
%
% we could use the following constructur.

m = sparse([1:3 2:4 3:5 3*ones(1,5)],...
    [kron([2 3 4], [1 1 1]) 1:5],...
    ones(1,14));
display(full(m));

% This is vital if a large matrix is constructed from a number of
% overlapping submatrices. However, you will not be required to do this
% until Assignment 3.