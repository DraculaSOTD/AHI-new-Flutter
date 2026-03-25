//
//  MFZAvatarGenMdlFemaleVerts
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdlFemaleVerts_hpp
#define MFZAvatarGenMdlFemaleVerts_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenCommon.hpp"

namespace mfz_avatar_gen {

    class mdl_female_verts {
    private:
    // Model data
        static const double c_female_vertices[N_VERTS_3];
        static const double c_female_mvn_mu[N_MU];
        static const double c_female_cov[N_MU][N_MU];
        static const double c_female_ranges[N_MU][2];
        static const double c_female_sym_skel[N_SKELS][3];
        static const double c_female_shape_vectors_transposed[N_VERTS_3][N_MU];
    // Model wrapper
        std::vector<double> m_female_avg_vertices;
        std::vector<double> m_female_mvn_mu;
        std::vector< std::vector<double> > m_female_ranges;
        std::vector< std::vector<double> > m_female_cov;
        std::vector< std::vector<double> > m_female_sv;
        std::vector< std::vector<double> > m_female_SkV;
    // Singleton constructor
        mdl_female_verts(void);                   // Don't Implement.
        mdl_female_verts(mdl_female_verts const&);  // Don't Implement.
        void operator=(mdl_female_verts const&);  // Don't implement
    public:
        // Singleton methods
        static mdl_female_verts *getInstance(void) {
            static mdl_female_verts instance;
            return &instance;
        }
        // Class methods
        std::vector<double> &getAvgVerts(void) const;
        std::vector<double> &getMvnMu(void) const;
        std::vector< std::vector<double> > &getCov(void) const;
        std::vector< std::vector<double> > &getRanges(void) const;
        std::vector< std::vector<double> > &getSv(void) const;
        std::vector< std::vector<double> > &getSkV(void) const;
    };

}

#endif /* MFZAvatarGenMdlFemaleVerts_hpp */
