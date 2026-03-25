//
//  MFZAvatarGenMdlMaleInvVerts
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdlMaleInvVerts_hpp
#define MFZAvatarGenMdlMaleInvVerts_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenCommon.hpp"

namespace mfz_avatar_gen {

    class mdl_male_inv_verts {
    private:
    // Model data
        static const double c_male_vertices_inv[N_VERTS_INV_3];
        static const double c_male_sv_inv[N_VERTS_INV_3][N_MU];
    // Model wrapper
        std::vector<double> m_male_vertices_inv;
        std::vector< std::vector<double> > m_male_sv_inv;
    // Singleton constructor
        mdl_male_inv_verts(void);                       // Don't Implement.
        mdl_male_inv_verts(mdl_male_inv_verts const&);  // Don't Implement.
        void operator=(mdl_male_inv_verts const&);      // Don't implement
    public:
        // Singleton methods
        static mdl_male_inv_verts *getInstance(void) {
            static mdl_male_inv_verts instance;
            return &instance;
        }
        // Class methods
        std::vector<double> &getInvVerts(void) const;
        std::vector< std::vector<double> > &getInvSv(void) const;
    };

}

#endif /* MFZAvatarGenMdlMaleInvVerts_hpp */
