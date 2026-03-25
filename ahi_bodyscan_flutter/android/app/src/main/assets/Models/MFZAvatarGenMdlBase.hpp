//
//  MFZAvatarGenMdlBase.hpp
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenMdlBase_hpp
#define MFZAvatarGenMdlBase_hpp

#include <stdio.h>
#include <vector>
#include <string>

namespace mfz_avatar_gen {

    const unsigned int N_INV_RCALF    = 343;
    const unsigned int N_INV_RTHIGH   = 302;
    const unsigned int N_INV_R_UARM   = 304;
    const float MIN_H                = 50.00;
    const float MAX_H                = 255.00;
    const float MIN_W                = 16.00;
    const float MAX_W                = 300.00;
    const unsigned int N_VERTS        = 1002;
    const unsigned int N_VERTS_3      = 3006;
    const unsigned int N_VERTS_INV    = 10777;
    const unsigned int N_VERTS_INV_3  = 32331;
    const unsigned int N_FACES        = 2000;
    const unsigned int N_FACES_3      = 6000;
    const unsigned int N_FACES_INV    = 21550;
    const unsigned int N_FACES_INV_3  = 64650;
    const unsigned int N_MU           = 7;
    const unsigned int N_BONES        = 17;
    const unsigned int N_SKELS        = 18;
    const unsigned int N_L_RINGS_VEC  = 75427;

    typedef enum gender_t {
        male,
        female
    } gender_t;

    typedef enum view_t {
        front,
        side
    } view_t;

}

#endif /* MFZAvatarGenMdlBase_hpp */
