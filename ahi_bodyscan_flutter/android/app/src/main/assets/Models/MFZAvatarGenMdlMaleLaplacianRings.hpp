//
//  MFZAvatarGenMdlMaleLaplacianRings
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdlMaleLaplacianRings_hpp
#define MFZAvatarGenMdlMaleLaplacianRings_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenCommon.hpp"

namespace mfz_avatar_gen {

    class mdl_male_laplacian_rings {
    private:
    // Model data
        static const int c_male_laplacian_rings[N_VERTS_INV];
        static const int c_male_model_laplacian_rings_as_vector[N_L_RINGS_VEC];
    // Model wrapper
        std::vector<int> m_male_laplacian_rings;
        std::vector<int> m_male_laplacian_rings_as_vectors;
    // Singleton constructor
        mdl_male_laplacian_rings(void);                       // Don't Implement.
        mdl_male_laplacian_rings(mdl_male_laplacian_rings const&);  // Don't Implement.
        void operator=(mdl_male_laplacian_rings const&);      // Don't implement
    public:
        // Singleton methods
        static mdl_male_laplacian_rings *getInstance(void) {
            static mdl_male_laplacian_rings instance;
            return &instance;
        }
        // Class methods
        std::vector<int> &getLaplacianRings(void) const;
        std::vector<int> &getLaplacianRingsAsVectors(void) const;
    };

}

#endif /* MFZAvatarGenMdlMaleLaplacianRings_hpp */
