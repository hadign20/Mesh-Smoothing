# Mesh-Processing

Task 1:
The mesh Laplacian is a square matrix of the same size as the mesh vertices, where the diagonal elements are all set to a specific value (to make the sum of each row be zero), and the remaining elements are the corresponding Laplace weight of two connected vertices. In case of normalized uniform Laplacian, we use the similar weights for all elements, and we normalize them by dividing each value by the degree of the corresponding vertex and by setting the diagonal value to -1 to make the sum of each row be zero. For the non-normalized case, we set the diagonal element to the negative of the degree and the rest are set to one (where the two vertices are connected). In case of cotangent Laplacian, the same rules apply, only this time we set the weights to the sum of the cotangent of the angles of two adjacent faces. This way the smoothed mesh is calculated with consideration of the triangulation and original shape of the mesh with regards to the size of angles in each face.	

![image](https://user-images.githubusercontent.com/24352869/189672850-1490f608-f8a2-4a26-b7f9-1445b5d6039a.png)

 
This L_ij is for the normalized Laplacian where w_ij is 1 divided by degree in case of uniform Laplacian and is 1 divided by sum of cotangents in case of cotangent Laplacian.



Task 2:
	In explicit Euler method we calculate the Laplacian operator x_(n+1)=(I+dt λL) x_n. Here we do not put a separate value for dt since it is a constant alongside λ. So we calculate each version of the mesh based on the previous version added by a portion of its Laplacian.
	In implicit Euler method according to x_n=(I-dt λL) x_(n+1) we solve the equation of older versions based on the newer versions using Matlab’s \ operator. 
	To preserve the volume of the mesh to avoid shrinking we need to calculate the volume of the mesh based on this formula:
	
	![image](https://user-images.githubusercontent.com/24352869/189673033-a85d8915-8ddd-4744-9a38-5f0b2d955cd6.png)

 
and x_k^1,x_k^2,x_k^3  are the three vertices of the kth triangle. We first calculate the value of g and N and then use dot product of g and N divided by 6 to calculate the final volume.
original	Explicit Euler’s method (20 iter)	Implicit Euler’s method (20 iter)	Volume preserving (Explicit 20 iter)
 
 



![image](https://user-images.githubusercontent.com/24352869/189673084-46405207-cfd5-4b96-bb90-ea0e312546dd.png)

 
 
 
 


Task 3:
According to [(W_L L)/W_P ] 〖V'〗_d=[(W_L f)/(W_P V_d )] for mesh smoothing we can put f=0 and end up with a matrix on the right side with first n rows to be 0 and last n rows to be the current vertices multiplied by Wp. Then we can solve the equation by using Matlab’s \ operator.
Least-squares mesh smoothing with 5 iterations
original	w_P=0.5 and 
w_L=0.5	w_P=0.111 and 
w_L=0.889	w_P=0.884 and 
w_L=0.116
 
 
 
 ![image](https://user-images.githubusercontent.com/24352869/189673156-d2d216c2-7e8c-46bc-9964-ddd6bfb3a2ca.png)



A high value for w_P makes the smoothing very conservative about the original shape of the mesh.
Task 4:
According to [(W_L L)/W_P ] 〖V'〗_d=[(W_L f)/(W_P V_d )] for detail preserving triangle shape optimization we can put f=∆_(d,c) and end up with a 3-column matrix on the right side with first n rows to be W_L ∆_(d,c)  and last n rows to be the current vertices multiplied by W_P. Then we can solve the equation by using Matlab’s \ operator the same way we did for Task 3.
Detail preserving triangle shape optimization with 20 iterations
original	w_P=0.5 and 
w_L=0.5	w_P=0.039 and 
w_L=0.961	w_P=0.961 and 
w_L=0.039
 
 ![image](https://user-images.githubusercontent.com/24352869/189673195-64ad0023-6fa4-40d9-8c78-4144fcad5f68.png)

 
 


As seen in the figure, by using a high value for w_P we tend to preserve the original shape of the mesh. Even with a very low value for w_P and high value for w_L the mesh is still not smoothed after 20 iterations. 



Task 5:
	For the case of non-normalized Laplacian we should have the diagonal elements of the Laplacian matrix to be the negative of the degree of each vertex and the element (i,j) to be the weight between two vertices which is decided by user. So in case of uniform Laplacian we can use the sparse function in Matlab (like Task 1) without normalizing the values. In case of cotangent Laplacian we need to have the diagonal elements to be negative of the sum of the cotangent of the angles in the two adjacent triangles of the corresponding half-edge. For the remaining elements we should put the sum of cotangents of the two angles in adjacent triangles as the weight between each pair of connected vertices.
 
	According to the formula
	
	![image](https://user-images.githubusercontent.com/24352869/189673265-dc5c1154-0b73-4f9d-9975-f0498b8059c1.png)

 
We can use Matlab’s eigs function to calculate the k smallest eigenvalues (Dm) and then use that to calculate the updated vertex positions corresponding to only those k eigenvectors.
Task 6:
First we set the area for boundary edges to be 0. Then we separate the calculations of acute and obtuse triangles according to this:
 
Since in the algorithm they have to be considered as two types of triangles in calculating the voronoi area:
 
We can use Matlab’s all function to see whether all angles of a face are less than 90 degrees or not. Then for the non-obtuse triangles we use the cotangent Laplacian formula to calculate the area:
 
And for the obtuse triangles we consider algorithm’s suggestion to set the area ¼ of the triangle area. Finally we can calculate the discrete mean and Gaussian curvatures.
 
original	mean	Gaussian
 
 
 ![image](https://user-images.githubusercontent.com/24352869/189673305-8f96fe87-0d7a-4e0d-9089-d1cf2f5e88f5.png)


 
 ![image](https://user-images.githubusercontent.com/24352869/189673354-2d26f5e4-82df-4fcc-8d53-b28304adcbce.png)


![image](https://user-images.githubusercontent.com/24352869/189673402-20e07a05-6436-413b-ae8b-f9fd3c7285ee.png)

 


In both cases the curvature is stronger around the bending areas of the surface. However, Gaussian curvature shows a better approximation of the straight and curved parts of the surface.
Task 7:
	The re-computation of the Laplacian after each iteration makes the process slower which is noticeable in case of high number of iterations. However, it improves the accuracy as it recalculates the weights at each iteration based on the new position and geometry of the vertices. 
In case of uniform Laplacian, there is not much difference in the performance. This is because recalculation of the vertex positions happens by using a uniform weight without considering the shape and triangulation of the mesh. However, in case of cotangent Laplacian, the triangulation and specifically the angles of the triangles are taken into account when computing the smoothed version of the mesh. This means that the re-computation of the Laplacian after each iteration tends to preserve the original shape of the mesh (position of the vertices) better. Therefore, by accepting more time complexity we can get a more precise and well-smoothed mesh. This becomes more noticeable when the number of iterations increase.
original	Explicit smoothing by using uniform Laplacian (20 iterations, lambda=1) without re-computation of Laplacian	Explicit smoothing by using uniform Laplacian (20 iterations, lambda=1) with  re-computation of Laplacian
 
 
Elapsed time = 0.22s	 
Elapsed time = 1.234s
original	Explicit smoothing by using cotangent Laplacian (20 iterations, lambda=1) without re-computation of Laplacian	Explicit smoothing by using cotangent Laplacian (20 iterations, lambda=1) with  re-computation of Laplacian
 
 
Elapsed time = 0.267s	 
Elapsed time = 1.715s

Paying attention to the ears and fingers of the armadillo we can see they are better reserved in case of re-computing the Laplacian at each iteration. However, it is noticeably slower. In general, explicit smoothing is affected more than implicit and least-squared methods.
	Implicit integration is better in case of performance. However, in order to simplify the process explicit smoothing is preferred.  In general, implicit smoothing can be faster than explicit. Because of the sparseness of the Laplacian matrix, the step-size is larger and therefore, each iteration is more efficient. In case of using implicit smoothing, the stability results in fewer iterations. In case of improving the performance of smoothing by using a polynomial sum of Laplacian operator, the sparseness decreases which in turn increases the computational complexity of the process. With explicit smoothing we have more flexibility to choose which part of the mesh to focus on. In explicit smoothing the connectivity of the vertices do not change and the changes are only the position of them. New vertices cannot be introduced to the mesh at each iteration and the existing vertices stay in the mesh connected to the same vertices they were connected to. 
	Having w_L=0 and w_P=0 does not make sense, since the formula [(W_L L)/W_P ] 〖V'〗_d=[(W_L f)/(W_P V_d )] becomes 0=0. Also according to the formula, having w_L=1 and w_P=1 doesn’t make any difference in the mesh, and therefore is useless. The values of w_L and w_P are chosen from 0 to 1 as weights to control the amount of smoothing vs. shape preserving without disturbing the wholesome structure of the mesh. As a result, we choose these values between 0 and 1 to favor either the smoothing factor or shape preserving factor (both of which can vary in different parts of the mesh) without losing the general shape of the surface. If we choose these values from any range, we might end up with a completely different mesh which is not desirable.
	In case of uniform Laplacian, the weights are uniform and apply to all vertices whether they are on the boundary or not. However, in case of cotangent Laplacian, the weights are calculated according to the angles on the two neighboring faces on the sides of the half-edge. Therefore, if the half-edge is on the boundary and has only one face next to it, just the angle of that face is considered and the other angle is set to zero. In the code:
val_od = he.prev().getTrait('cot_angle').*(he.face().index > 0)+ ...  
         he.twin().prev().getTrait('cot_angle').*(he.twin().face().index > 0); 
the Boolean value of (he.face().index > 0) indicated if there is no adjacent face to the half-edge the value of 'cot_angle' will count as zero.
The position of boundary edges is mostly preserved during the smoothing process and closed boundaries tend to turn into a circular shape after some iterations. The non-boundary part of the mesh tends to flatten towards the plane created by the boundary. The undesirable effect is that the closed boundary edges in shape of a hole (usually caused by inaccuracies in the scanning process) stay on the surface of the mesh and do not dissolve in the process of smoothing (they do not go away even when the whole mesh is shrunk).
original	smoothed
 
 

 
 
![image](https://user-images.githubusercontent.com/24352869/189673455-0136d5ca-57ed-4851-a224-d78b6831a324.png)

 
 


	Because it should be symmetric to get the right eigenvalues. If we use normalized Laplacian, the general shape of the mesh will be lost due to the loss of symmetry between the mapped vertex positions.
original	Spectral smoothing with non-normalized Laplacian operator (k=50)	Spectral smoothing with normalized Laplacian operator (k=50)
 
 ![image](https://user-images.githubusercontent.com/24352869/189673524-44de70c2-29d2-47f1-9358-986603f80e94.png)

 


If we use the normalized version of the Laplacian the difference between the eigenvalues will not be enough to estimate the mesh correctly. 
	In case of k=0, the result of the spectral smoothing is just a point at the origin of the space. Because we are not actually using any of the vertices on the mesh and there will be an empty matrix for eigenvectors. So we will have an empty (all zero) matrix of size nv×0 for the eigenvectors and no eigenvalue. In other words we are multiplying the vertex matrix by zero which results in [0,0,0].
In case of k=1, the result will be a point in space. This is because we are only using the smallest eigenvalue which in turn will make the resulting eigenvectors to be a matrix of size nv×1 and we will end up with the same value for all vertices of the mesh.
In case of k=2, the result will be a line in space. As we are only keeping two smallest eigenvalues, we end up with two eigenvectors that map the whole mesh into a line. By having a low value for k we are not capturing much information about the mesh to be able to perform smoothing while keeping the general shape, because the dimensions are not enough.


![image](https://user-images.githubusercontent.com/24352869/189673578-c6b34933-862b-4ceb-9c15-9af1e1921380.png)

