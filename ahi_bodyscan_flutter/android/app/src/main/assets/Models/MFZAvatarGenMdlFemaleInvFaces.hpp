//
//  MFZAvatarGenMdlFemaleInvFaces
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdlFemaleInvFaces_hpp
#define MFZAvatarGenMdlFemaleInvFaces_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenCommon.hpp"

namespace mfz_avatar_gen {

    class mdl_female_inv_faces {
    private:
    // Model data
        static const int c_female_faces_inv[N_FACES_INV_3];
    // Model wrapper
        std::vector<int> m_female_faces_inv;
    // Singleton constructor
        mdl_female_inv_faces(void);                   // Don't Implement.
        mdl_female_inv_faces(mdl_female_inv_faces const&);  // Don't Implement.
        void operator=(mdl_female_inv_faces const&);  // Don't implement
    public:
        // Singleton methods
        static mdl_female_inv_faces *getInstance(void) {
            static mdl_female_inv_faces instance;
            return &instance;
        }
        // Class methods
        std::vector<int> &getFacesInv(void) const;
    };

}

#endif /* MFZAvatarGenMdlFemaleInvFaces_hpp */
