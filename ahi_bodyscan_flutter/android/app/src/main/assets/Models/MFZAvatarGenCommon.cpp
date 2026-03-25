//
//  MFZAvatarGenCommon.cpp
//
//  Copyright MyFiziq (ASX:MYQ) 2017.
//

#include "MFZAvatarGenCommon.hpp"
#include "MFZAvatarGenMdlMaleVerts.hpp"
#include "MFZAvatarGenMdlMaleFaces.hpp"
#include "MFZAvatarGenMdlMaleBones.hpp"
#include "MFZAvatarGenMdlMaleInvVerts.hpp"
#include "MFZAvatarGenMdlMaleInvFaces.hpp"
#include "MFZAvatarGenMdlMaleInvBones.hpp"
#include "MFZAvatarGenMdlMaleLaplacianRings.hpp"
#include "MFZAvatarGenMdlFemaleVerts.hpp"
#include "MFZAvatarGenMdlFemaleFaces.hpp"
#include "MFZAvatarGenMdlFemaleBones.hpp"
#include "MFZAvatarGenMdlFemaleInvVerts.hpp"
#include "MFZAvatarGenMdlFemaleInvFaces.hpp"
#include "MFZAvatarGenMdlFemaleInvBones.hpp"
#include "MFZAvatarGenMdlFemaleLaplacianRings.hpp"

using namespace mfz_avatar_gen;

// Class methods

common::common(gender_t g)
{
    m_gender = g;
}

std::vector<int> &common::getInvRightCalf(void) const {
    return common_model::getInstance()->getInvRightCalf();
}
std::vector<int> &common::getInvRightThigh(void) const {
    return common_model::getInstance()->getInvRightThigh();
}
std::vector<int> &common::getInvRightUpperArm(void) const {
    return common_model::getInstance()->getInvRightUpperArm();
}
std::vector<double> &common::getMvnMu(void) const {
    return getMvnMu(m_gender);
}
std::vector<double> &common::getMvnMu(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_verts *m = mdl_male_verts::getInstance();
        return m->getMvnMu();
    } else {
        const mdl_female_verts *f = mdl_female_verts::getInstance();
        return f->getMvnMu();
    }
}
std::vector< std::vector<double> > &common::getRanges(void) const {
    return getRanges(m_gender);
}
std::vector< std::vector<double> > &common::getRanges(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_verts *m = mdl_male_verts::getInstance();
        return m->getRanges();
    } else {
        const mdl_female_verts *f = mdl_female_verts::getInstance();
        return f->getRanges();
    }
}
std::vector< std::vector<double> > &common::getCov(void) const {
    return getCov(m_gender);
}
std::vector< std::vector<double> > &common::getCov(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_verts *m = mdl_male_verts::getInstance();
        return m->getCov();
    } else {
        const mdl_female_verts *f = mdl_female_verts::getInstance();
        return f->getCov();
    }
}
std::vector<double> &common::getAvgVerts(void) const {
    return getAvgVerts(m_gender);
}
std::vector<double> &common::getAvgVerts(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_verts *m = mdl_male_verts::getInstance();
        return m->getAvgVerts();
    } else {
        const mdl_female_verts *f = mdl_female_verts::getInstance();
        return f->getAvgVerts();
    }
}
std::vector<double> &common::getVertsInv(void) const {
    return getVertsInv(m_gender);
}
std::vector<double> &common::getVertsInv(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_inv_verts *m = mdl_male_inv_verts::getInstance();
        return m->getInvVerts();
    } else {
        const mdl_female_inv_verts *f = mdl_female_inv_verts::getInstance();
        return f->getInvVerts();
    }
}
std::vector<int> &common::getFaces(void) const {
    return getFaces(m_gender);
}
std::vector<int> &common::getFaces(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_faces *m = mdl_male_faces::getInstance();
        return m->getFaces();
    } else {
        const mdl_female_faces *f = mdl_female_faces::getInstance();
        return f->getFaces();
    }
}
std::vector<int> &common::getFacesInv(void) const {
    return getFacesInv(m_gender);
}
std::vector<int> &common::getFacesInv(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_inv_faces *m = mdl_male_inv_faces::getInstance();
        return m->getFacesInv();
    } else {
        const mdl_female_inv_faces *f = mdl_female_inv_faces::getInstance();
        return f->getFacesInv();
    }
}
std::vector< std::vector<double> > &common::getSv(void) const {
    return getSv(m_gender);
}
std::vector< std::vector<double> > &common::getSv(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_verts *m = mdl_male_verts::getInstance();
        return m->getSv();
    } else {
        const mdl_female_verts *f = mdl_female_verts::getInstance();
        return f->getSv();
    }
}
std::vector< std::vector<double> > &common::getSvInv(void) const {
    return getSvInv(m_gender);
}
std::vector< std::vector<double> > &common::getSvInv(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_inv_verts *m = mdl_male_inv_verts::getInstance();
        return m->getInvSv();
    } else {
        const mdl_female_inv_verts *f = mdl_female_inv_verts::getInstance();
        return f->getInvSv();
    }
}
std::vector< std::vector<double> > &common::getSkV(void) const {
    return getSkV(m_gender);
}
std::vector< std::vector<double> > &common::getSkV(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_verts *m = mdl_male_verts::getInstance();
        return m->getSkV();
    } else {
        const mdl_female_verts *f = mdl_female_verts::getInstance();
        return f->getSkV();
    }
}
std::vector< std::vector<double> > &common::getBonW(void) const {
    return getBonW(m_gender);
}
std::vector< std::vector<double> > &common::getBonW(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_bones *m = mdl_male_bones::getInstance();
        return m->getBonW();
    } else {
        const mdl_female_bones *f = mdl_female_bones::getInstance();
        return f->getBonW();
    }
}
std::vector< std::vector<double> > &common::getBonWInv(void) const {
    return getBonWInv(m_gender);
}
std::vector< std::vector<double> > &common::getBonWInv(gender_t gender) const {
    const mdl_male_inv_bones *m = mdl_male_inv_bones::getInstance();
    const mdl_female_inv_bones *f = mdl_female_inv_bones::getInstance();
    return (gender == male) ? m->getBonWInv() : f->getBonWInv();
}
std::vector<int> &common::getLaplacianRings(void) const {
    return getLaplacianRings(m_gender);
}
std::vector<int> &common::getLaplacianRings(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_laplacian_rings *m = mdl_male_laplacian_rings::getInstance();
        return m->getLaplacianRings();
    } else {
        const mdl_female_laplacian_rings *f = mdl_female_laplacian_rings::getInstance();
        return f->getLaplacianRings();
    }
}
std::vector<int> &common::getLaplacianRingsAsVectors(void) const {
    return getLaplacianRingsAsVectors(m_gender);
}
std::vector<int> &common::getLaplacianRingsAsVectors(gender_t gender) const {
    if (gender == gender_t::male) {
        const mdl_male_laplacian_rings *m = mdl_male_laplacian_rings::getInstance();
        return m->getLaplacianRingsAsVectors();
    } else {
        const mdl_female_laplacian_rings *f = mdl_female_laplacian_rings::getInstance();
        return f->getLaplacianRingsAsVectors();
    }
}
