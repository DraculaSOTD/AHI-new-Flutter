//
//  MFZAvatarGenMdlFemaleInvBones
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdlFemaleInvBones_hpp
#define MFZAvatarGenMdlFemaleInvBones_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenCommon.hpp"

namespace mfz_avatar_gen {

    class mdl_female_inv_bones {
    private:
    // Model data
        static const double c_female_bone_weights_inv[N_VERTS_INV_3][N_BONES];
    // Model wrapper
        std::vector< std::vector<double> > m_female_BonW_inv;
    // Singleton constructor
        mdl_female_inv_bones(void);                   // Don't Implement.
        mdl_female_inv_bones(mdl_female_inv_bones const&);  // Don't Implement.
        void operator=(mdl_female_inv_bones const&);  // Don't implement
    public:
        // Singleton methods
        static mdl_female_inv_bones *getInstance(void) {
            static mdl_female_inv_bones instance;
            return &instance;
        }
        // Class methods
        std::vector< std::vector<double> > &getBonWInv(void) const;
    };

}

#endif /* MFZAvatarGenMdlFemaleInvBones_hpp */
