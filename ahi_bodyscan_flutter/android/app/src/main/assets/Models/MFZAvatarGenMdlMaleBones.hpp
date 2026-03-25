//
//  MFZAvatarGenMdlMaleBones
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdlMaleBones_hpp
#define MFZAvatarGenMdlMaleBones_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenCommon.hpp"

namespace mfz_avatar_gen {

    class mdl_male_bones {
    private:
    // Model data
        static const double c_male_bone_weights[N_VERTS_3][N_BONES];
    // Model wrapper
        std::vector< std::vector<double> > m_male_BonW;
    // Singleton constructor
        mdl_male_bones(void);                   // Don't Implement.
        mdl_male_bones(mdl_male_bones const&);  // Don't Implement.
        void operator=(mdl_male_bones const&);  // Don't implement
    public:
        // Singleton methods
        static mdl_male_bones *getInstance(void) {
            static mdl_male_bones instance;
            return &instance;
        }
        // Class methods
        std::vector< std::vector<double> > &getBonW(void) const;
    };

}

#endif /* MFZAvatarGenMdlMaleBones_hpp */
