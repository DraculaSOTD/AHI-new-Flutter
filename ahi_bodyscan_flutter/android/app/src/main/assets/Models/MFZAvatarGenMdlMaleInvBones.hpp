//
//  MFZAvatarGenMdlMaleInvBones
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdlMaleInvBones_hpp
#define MFZAvatarGenMdlMaleInvBones_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenCommon.hpp"

namespace mfz_avatar_gen {

    class mdl_male_inv_bones {
    private:
    // Model data
        static const double c_male_bone_weights_inv[N_VERTS_INV_3][N_BONES];
    // Model wrapper
        std::vector< std::vector<double> > m_male_BonW_inv;
    // Singleton constructor
        mdl_male_inv_bones(void);                   // Don't Implement.
        mdl_male_inv_bones(mdl_male_inv_bones const&);  // Don't Implement.
        void operator=(mdl_male_inv_bones const&);  // Don't implement
    public:
        // Singleton methods
        static mdl_male_inv_bones *getInstance(void) {
            static mdl_male_inv_bones instance;
            return &instance;
        }
        // Class methods
        std::vector< std::vector<double> > &getBonWInv(void) const;
    };

}

#endif /* MFZAvatarGenMdlMaleInvBones_hpp */
