//
//  MFZAvatarGenMdlFemaleBones
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdlFemaleBones_hpp
#define MFZAvatarGenMdlFemaleBones_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenCommon.hpp"

namespace mfz_avatar_gen {

    class mdl_female_bones {
    private:
    // Model data
        static const double c_female_bone_weights[N_VERTS_3][N_BONES];
    // Model wrapper
        std::vector< std::vector<double> > m_female_BonW;
    // Singleton constructor
        mdl_female_bones(void);                   // Don't Implement.
        mdl_female_bones(mdl_female_bones const&);  // Don't Implement.
        void operator=(mdl_female_bones const&);  // Don't implement
    public:
        // Singleton methods
        static mdl_female_bones *getInstance(void) {
            static mdl_female_bones instance;
            return &instance;
        }
        // Class methods
        std::vector< std::vector<double> > &getBonW(void) const;
    };

}

#endif /* MFZAvatarGenMdlFemaleBones_hpp */
