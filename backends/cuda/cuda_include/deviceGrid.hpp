
#ifndef EQUELLE_DEVICEGRID_HEADER_INCLUDED
#define EQUELLE_DEVICEGRID_HEADER_INCLUDED

#include <cuda.h>
#include <cuda_runtime.h>

#include <vector>

#include <thrust/device_vector.h>
#include <thrust/host_vector.h>

#include <opm/core/grid/GridManager.hpp>


namespace equelleCUDA 
{

    //! Class for keeping track of subsets. Inheriting thrust::device_vector<int>
    /*!
      This is simply a minimally extended thrust::device_vector.
      It is used such that given a complete set (allCells(), allFaces()) no extra 
      indices are stored. We flag this by a boolean member variable.
      For subsets the indices within the set is stored as a thrust::device_vector.

      Since the class inherite thrust::device_vector, all vector member functions are
      available and public.
    */
    class Collection : public thrust::device_vector<int> 
    {	
    public:
	//! Default constructor
	Collection();
	
	//! Constructor used for full sets.
	/*!
	  Insert value 'true' to create a full collection.
	  No extra storage used.
	  Will throw an exception if input value is 'false'.
	  \param full boolean indicating that the collection is complete.
	*/
	explicit Collection(const bool full);
	//! Constructor for creating a subset Collection
	/*!
	  Give as input the indices that will be part of the collection.
	*/
	explicit Collection(const thrust::device_vector<int>& indices);
	
	//! Copy constructor
	Collection(const Collection& coll);
	
	//! Destructor
	~Collection();
	
	/*! 
	  \return true if the Collection is full, false otherwise
	*/
	bool isFull() const;
	//! Copy the device_vector to host memory.
	/*!
	  A member function to copy the values over to device memory.
	  This function is added since we not are able to cast Collection 
	  straight to thrust::host_vector. 
	  Most naturally used in debugging.
	*/
	thrust::host_vector<int> toHost() const;
	
    private:
	bool full_;
	
    }; // class Collection

    	


    
    class DeviceGrid {

    public:
	DeviceGrid();
	explicit DeviceGrid( const UnstructuredGrid& grid);

	// Copy constructor:
	DeviceGrid( const DeviceGrid& grid);

	// This is a pure debugger function.
	// We mark each collection with an ID to keep track of
	// which ones are destructed.
	int setID(int a);

	// Grid operations
	Collection allCells() const;
	Collection allFaces() const;

	Collection boundaryFaces() const;
	Collection interiorFaces() const;
	
	Collection interiorCells() const;
	Collection boundaryCells() const;


	// Get functions:
	int dimensions() const;
	int number_of_cells() const;
	int number_of_faces() const;
	
	
	~DeviceGrid();

    private:
	
	// Member variables for unstructured grids
	const int dimensions_;
	const int number_of_cells_;
	const int number_of_faces_;
	const int size_cell_faces_; // Extra variable compared to UnstructuredGrid
	
	// Member arrays for unstructured grids
	double* cell_centroids_; 
	int* cell_facepos_;
	int* cell_faces_;
	double* cell_volumes_;
	double* face_areas_;
	int* face_cells_;
	double* face_normals_;

	int id_;
	
	// Error handling:
	mutable cudaError_t cudaStatus_;
	void checkError_(const std::string& msg) const;

    }; // class DeviceGrid


    struct unchanged
    {
	const int val;
	unchanged(int val_in) : val(val_in) {}
	__host__ __device__ 
	bool operator()(const int x) {
	    return (x == val); 
	}
    };


    // KERNELS
    __global__ void boundaryFacesKernel( int* b_faces,
					 const int* face_cells,
					 const int number_of_faces);


} // namespace equelleCUDA

#endif // EQUELLE_DEVICEGRID_HEADER_INCLUDE 
