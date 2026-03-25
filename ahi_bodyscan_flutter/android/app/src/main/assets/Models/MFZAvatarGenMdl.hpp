//
//  MFZAvatarGenMdl.hpp
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdl_hpp
#define MFZAvatarGenMdl_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenMdlBase.hpp"

namespace mfz_avatar_gen {

    class common_model {
    private:
    // Constants
        static const int c_inv_right_calf[N_INV_RCALF];
        static const int c_inv_right_thigh[N_INV_RTHIGH];
        static const int c_inv_right_uarm[N_INV_R_UARM];
    // Class attributes
        std::vector<int> m_inv_right_calf;
        std::vector<int> m_inv_right_thigh;
        std::vector<int> m_inv_right_uarm;
    // Singleton constructor
        common_model(void);                   // Don't Implement.
        common_model(common_model const&);    // Don't Implement.
        void operator=(common_model const&);  // Don't implement
    public:
    // Singleton methods
        static common_model *getInstance(void) {
            static common_model instance;
            return &instance;
        }
    // Class methods
        std::vector<int> &getInvRightCalf(void) const;
        std::vector<int> &getInvRightThigh(void) const;
        std::vector<int> &getInvRightUpperArm(void) const;
    };

}

#endif /* MFZAvatarGenMdl_hpp */