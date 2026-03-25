//
//  MFZAvatarGenMdlMaleVerts
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdlMaleVerts_hpp
#define MFZAvatarGenMdlMaleVerts_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenCommon.hpp"

namespace mfz_avatar_gen {

    class mdl_male_verts {
    private:
    // Model data
        static const double c_male_vertices[N_VERTS_3];
        static const double c_male_mvn_mu[N_MU];
        static const double c_male_cov[N_MU][N_MU];
        static const double c_male_ranges[N_MU][2];
        static const double c_male_sym_skel[N_SKELS][3];
        static const double c_male_shape_vectors_transposed[N_VERTS_3][N_MU];
    // Model wrapper
        std::vector<double> m_male_avg_vertices;
        std::vector<double> m_male_mvn_mu;
        std::vector< std::vector<double> > m_male_ranges;
        std::vector< std::vector<double> > m_male_cov;
        std::vector< std::vector<double> > m_male_sv;
        std::vector< std::vector<double> > m_male_SkV;
    // Singleton constructor
        mdl_male_verts(void);                   // Don't Implement.
        mdl_male_verts(mdl_male_verts const&);  // Don't Implement.
        void operator=(mdl_male_verts const&);  // Don't implement
    public:
        // Singleton methods
        static mdl_male_verts *getInstance(void) {
            static mdl_male_verts instance;
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

#endif /* MFZAvatarGenMdlMaleVerts_hpp */
