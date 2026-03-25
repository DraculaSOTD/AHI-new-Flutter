//
//  MFZAvatarGenCommon.hpp
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#ifndef MFZAvatarGenCommon_hpp
#define MFZAvatarGenCommon_hpp

#include <stdio.h>
#include <vector>
#include "MFZAvatarGenMdl.hpp"

namespace mfz_avatar_gen {

     class common {
     private:
         gender_t m_gender;
         // Singleton constructor
         common(gender_t gender);
         common(void);                   // Don't Implement.
         common(common const&);          // Don't Implement.
         void operator=(common const&);  // Don't implement
     public:
         // Singleton methods
         static common *getInstance(gender_t gender) {
             static common instance(gender);
             return &instance;
         }
         static common *getInstance() {
             return getInstance(male); // either the gender has been properally set, or fallback to Male
         }
         // Class methods
         std::vector<int> &getInvRightCalf(void) const;
         std::vector<int> &getInvRightThigh(void) const;
         std::vector<int> &getInvRightUpperArm(void) const;
         std::vector<double> &getMvnMu(void) const;
         std::vector<double> &getMvnMu(gender_t gender) const; // Allows gender override
         std::vector< std::vector<double> > &getRanges(void) const;
         std::vector< std::vector<double> > &getRanges(gender_t gender) const; // Allows gender override
         std::vector< std::vector<double> > &getCov(void) const;
         std::vector< std::vector<double> > &getCov(gender_t gender) const; // Allows gender override
         std::vector<double> &getAvgVerts(void) const;
         std::vector<double> &getAvgVerts(gender_t gender) const; // Allows gender override
         std::vector<double> &getVertsInv(void) const;
         std::vector<double> &getVertsInv(gender_t gender) const; // Allows gender override
         std::vector<int> &getFaces(void) const;
         std::vector<int> &getFaces(gender_t gender) const; // Allows gender override
         std::vector<int> &getFacesInv(void) const;
         std::vector<int> &getFacesInv(gender_t gender) const; // Allows gender override
         std::vector< std::vector<double> > &getSv(void) const;
         std::vector< std::vector<double> > &getSv(gender_t gender) const; // Allows gender override
         std::vector< std::vector<double> > &getSvInv(void) const;
         std::vector< std::vector<double> > &getSvInv(gender_t gender) const; // Allows gender override
         std::vector< std::vector<double> > &getSkV(void) const;
         std::vector< std::vector<double> > &getSkV(gender_t gender) const; // Allows gender override
         std::vector< std::vector<double> > &getBonW(void) const;
         std::vector< std::vector<double> > &getBonW(gender_t gender) const; // Allows gender override
         std::vector< std::vector<double> > &getBonWInv(void) const;
         std::vector< std::vector<double> > &getBonWInv(gender_t gender) const; // Allows gender override
         std::vector<int> &getLaplacianRings(void) const;
         std::vector<int> &getLaplacianRings(gender_t gender) const; // Allows gender override
         std::vector<int> &getLaplacianRingsAsVectors(void) const;
         std::vector<int> &getLaplacianRingsAsVectors(gender_t gender) const; // Allows gender override
     };

}

#endif /* MFZAvatarGenCommon_hpp */
