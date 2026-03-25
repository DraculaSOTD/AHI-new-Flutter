//
//  MFZAvatarGenMdlMaleFaces
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdlMaleFaces_hpp
#define MFZAvatarGenMdlMaleFaces_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenCommon.hpp"

namespace mfz_avatar_gen {

    class mdl_male_faces {
    private:
    // Model data
        static const int c_male_faces[N_FACES_3];
    // Model wrapper
        std::vector<int> m_male_faces;
    // Singleton constructor
        mdl_male_faces(void);                   // Don't Implement.
        mdl_male_faces(mdl_male_faces const&);  // Don't Implement.
        void operator=(mdl_male_faces const&);  // Don't implement
    public:
        // Singleton methods
        static mdl_male_faces *getInstance(void) {
            static mdl_male_faces instance;
            return &instance;
        }
        // Class methods
        std::vector<int> &getFaces(void) const;
    };

}

#endif /* MFZAvatarGenMdlMaleFaces_hpp */
