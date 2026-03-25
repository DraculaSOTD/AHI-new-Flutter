//
//  MFZAvatarGenMdlFemaleFaces
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdlFemaleFaces_hpp
#define MFZAvatarGenMdlFemaleFaces_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenCommon.hpp"

namespace mfz_avatar_gen {

    class mdl_female_faces {
    private:
    // Model data
        static const int c_female_faces[N_FACES_3];
    // Model wrapper
        std::vector<int> m_female_faces;
    // Singleton constructor
        mdl_female_faces(void);                   // Don't Implement.
        mdl_female_faces(mdl_female_faces const&);  // Don't Implement.
        void operator=(mdl_female_faces const&);  // Don't implement
    public:
        // Singleton methods
        static mdl_female_faces *getInstance(void) {
            static mdl_female_faces instance;
            return &instance;
        }
        // Class methods
        std::vector<int> &getFaces(void) const;
    };

}

#endif /* MFZAvatarGenMdlFemaleFaces_hpp */
