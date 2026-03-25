
#include <cereal/types/vector.hpp>
#include <cereal/types/memory.hpp>
#include <cereal/archives/portable_binary.hpp>
#include <iostream>
#include <sstream>
#include "MFZAvatarGenCommon.hpp"

#ifndef cv_encoder_hpp
#define cv_encoder_hpp

// SVR class

struct AHIModelCV {
  std::string                         name;
  int                                 type; // 1: vi, 2: vd, 3: vvd
  std::vector<int>                    vi;
  std::vector<double>                 vd;
  std::vector< std::vector<double> >  vvd;

  template <class Archive>
  void serialize( Archive & ar ) {
    ar( name, type, vi, vd, vvd );
  }
};

void encode_cv(const std::string &cv_name, int t, const std::vector<int> &vi, const std::vector<double> &vd, const std::vector< std::vector<double> > &vvd) {
  std::cout << "Encoding CV model " << cv_name << " ... " << std::endl;
  AHIModelCV cv;
  cv.name = cv_name;
  cv.type = t;
  if (t == 1) {
    cv.vi = vi;
  } else if (t == 2) {
    cv.vd = vd;
  } else if (t == 3) {
    cv.vvd = vvd;
  }
  std::ostringstream oss;
  oss << "../Encoded/" << cv_name << ".cereal";
  std::string s = oss.str();
  // Serialize
  std::ofstream os(s, std::ios::binary);
  cereal::PortableBinaryOutputArchive archive(os);
  archive(cv);
}

void encode_cvs() {
  const mfz_avatar_gen::common *c = mfz_avatar_gen::common::getInstance();
  std::vector<int> bvi;
  std::vector<double> bvd;
  std::vector< std::vector<double> > bvvd;

  // 1 dim, int
  encode_cv("InvRightCalf", 1, c->getInvRightCalf(), bvd, bvvd);
  encode_cv("InvRightThigh", 1, c->getInvRightThigh(), bvd, bvvd);
  encode_cv("InvRightUpperArm", 1, c->getInvRightUpperArm(), bvd, bvvd);
  encode_cv("Faces_male", 1, c->getFaces(mfz_avatar_gen::gender_t::male), bvd, bvvd);
  encode_cv("Faces_female", 1, c->getFaces(mfz_avatar_gen::gender_t::female), bvd, bvvd);
  encode_cv("FacesInv_male", 1, c->getFacesInv(mfz_avatar_gen::gender_t::male), bvd, bvvd);
  encode_cv("FacesInv_female", 1, c->getFacesInv(mfz_avatar_gen::gender_t::female), bvd, bvvd);
  encode_cv("LaplacianRings_male", 1, c->getLaplacianRings(mfz_avatar_gen::gender_t::male), bvd, bvvd);
  encode_cv("LaplacianRings_female", 1, c->getLaplacianRings(mfz_avatar_gen::gender_t::female), bvd, bvvd);
  encode_cv("LaplacianRingsAsVectors_male", 1, c->getLaplacianRingsAsVectors(mfz_avatar_gen::gender_t::male), bvd, bvvd);
  encode_cv("LaplacianRingsAsVectors_female", 1, c->getLaplacianRingsAsVectors(mfz_avatar_gen::gender_t::female), bvd, bvvd);

  // 1 dim, double
  encode_cv("MvnMu_male", 2, bvi, c->getMvnMu(mfz_avatar_gen::gender_t::male), bvvd);
  encode_cv("MvnMu_female", 2, bvi, c->getMvnMu(mfz_avatar_gen::gender_t::female), bvvd);
  encode_cv("AvgVerts_male", 2, bvi, c->getAvgVerts(mfz_avatar_gen::gender_t::male), bvvd);
  encode_cv("AvgVerts_female", 2, bvi, c->getAvgVerts(mfz_avatar_gen::gender_t::female), bvvd);
  encode_cv("VertsInv_male", 2, bvi, c->getVertsInv(mfz_avatar_gen::gender_t::male), bvvd);
  encode_cv("VertsInv_female", 2, bvi, c->getVertsInv(mfz_avatar_gen::gender_t::female), bvvd);

  // 2 dim, double
  encode_cv("Ranges_male", 3, bvi, bvd, c->getRanges(mfz_avatar_gen::gender_t::male));
  encode_cv("Ranges_female", 3, bvi, bvd, c->getRanges(mfz_avatar_gen::gender_t::female));
  encode_cv("Cov_male", 3, bvi, bvd, c->getCov(mfz_avatar_gen::gender_t::male));
  encode_cv("Cov_female", 3, bvi, bvd, c->getCov(mfz_avatar_gen::gender_t::female));
  encode_cv("Sv_male", 3, bvi, bvd, c->getSv(mfz_avatar_gen::gender_t::male));
  encode_cv("Sv_female", 3, bvi, bvd, c->getSv(mfz_avatar_gen::gender_t::female));
  encode_cv("SvInv_male", 3, bvi, bvd, c->getSvInv(mfz_avatar_gen::gender_t::male));
  encode_cv("SvInv_female", 3, bvi, bvd, c->getSvInv(mfz_avatar_gen::gender_t::female));
  encode_cv("SkV_male", 3, bvi, bvd, c->getSkV(mfz_avatar_gen::gender_t::male));
  encode_cv("SkV_female", 3, bvi, bvd, c->getSkV(mfz_avatar_gen::gender_t::female));
  encode_cv("BonW_male", 3, bvi, bvd, c->getBonW(mfz_avatar_gen::gender_t::male));
  encode_cv("BonW_female", 3, bvi, bvd, c->getBonW(mfz_avatar_gen::gender_t::female));
  encode_cv("BonWInv_male", 3, bvi, bvd, c->getBonWInv(mfz_avatar_gen::gender_t::male));
  encode_cv("BonWInv_female", 3, bvi, bvd, c->getBonWInv(mfz_avatar_gen::gender_t::female));
}


void do_cv_check(const std::string &cv_name, int t, const std::vector<int> &vi, const std::vector<double> &vd, const std::vector< std::vector<double> > &vvd) {
  // Info
  std::cout << "Verifying CV model " << cv_name << " ... ";
  std::ostringstream oss;
  oss << "../Encoded/" << cv_name << ".cereal";
  std::string s = oss.str();
  // De-Serialize
  std::ifstream is(s);
  cereal::PortableBinaryInputArchive archive(is);
  // Read into object
  AHIModelCV cv;
  archive(cv);
  // Name
  if (cv.name.compare(cv_name) != 0) {
    std::cout << "FAILED" << std::endl;
    return;
  }
  // Type
  if (cv.type != t) {
    std::cout << "FAILED" << std::endl;
    return;
  }
  // Data
  if (t == 1) {
    std::vector<int> cv_vi = cv.vi;
    for (int i = 0; i < vi.size(); i++) {
      if (cv_vi[i] != vi[i]) {
        std::cout << "FAILED" << std::endl;
        return;
      }
    }
  } else if (t == 2) {
    std::vector<double> cv_vd = cv.vd;
    for (int i = 0; i < vd.size(); i++) {
      if (cv_vd[i] != vd[i]) {
        std::cout << "FAILED" << std::endl;
        return;
      }
    }
  } else if (t == 3) {
    std::vector< std::vector<double> > cv_vvd = cv.vvd;
    for (int i = 0; i < vvd.size(); i++) {
      for (int j = 0; j < vvd[i].size(); j++) {
        if (cv_vvd[i][j] != vvd[i][j]) {
          std::cout << "FAILED" << std::endl;
          return;
        }
      }
    }
  }
  // Success
  std::cout << "OK" << std::endl;
}


void verify_cvs() {
  const mfz_avatar_gen::common *c = mfz_avatar_gen::common::getInstance();
  std::vector<int> bvi;
  std::vector<double> bvd;
  std::vector< std::vector<double> > bvvd;

  // 1 dim, int
  do_cv_check("InvRightCalf", 1, c->getInvRightCalf(), bvd, bvvd);
  do_cv_check("InvRightThigh", 1, c->getInvRightThigh(), bvd, bvvd);
  do_cv_check("InvRightUpperArm", 1, c->getInvRightUpperArm(), bvd, bvvd);
  do_cv_check("Faces_male", 1, c->getFaces(mfz_avatar_gen::gender_t::male), bvd, bvvd);
  do_cv_check("Faces_female", 1, c->getFaces(mfz_avatar_gen::gender_t::female), bvd, bvvd);
  do_cv_check("FacesInv_male", 1, c->getFacesInv(mfz_avatar_gen::gender_t::male), bvd, bvvd);
  do_cv_check("FacesInv_female", 1, c->getFacesInv(mfz_avatar_gen::gender_t::female), bvd, bvvd);
  do_cv_check("LaplacianRings_male", 1, c->getLaplacianRings(mfz_avatar_gen::gender_t::male), bvd, bvvd);
  do_cv_check("LaplacianRings_female", 1, c->getLaplacianRings(mfz_avatar_gen::gender_t::female), bvd, bvvd);
  do_cv_check("LaplacianRingsAsVectors_male", 1, c->getLaplacianRingsAsVectors(mfz_avatar_gen::gender_t::male), bvd, bvvd);
  do_cv_check("LaplacianRingsAsVectors_female", 1, c->getLaplacianRingsAsVectors(mfz_avatar_gen::gender_t::female), bvd, bvvd);

  // 1 dim, double
  do_cv_check("MvnMu_male", 2, bvi, c->getMvnMu(mfz_avatar_gen::gender_t::male), bvvd);
  do_cv_check("MvnMu_female", 2, bvi, c->getMvnMu(mfz_avatar_gen::gender_t::female), bvvd);
  do_cv_check("AvgVerts_male", 2, bvi, c->getAvgVerts(mfz_avatar_gen::gender_t::male), bvvd);
  do_cv_check("AvgVerts_female", 2, bvi, c->getAvgVerts(mfz_avatar_gen::gender_t::female), bvvd);
  do_cv_check("VertsInv_male", 2, bvi, c->getVertsInv(mfz_avatar_gen::gender_t::male), bvvd);
  do_cv_check("VertsInv_female", 2, bvi, c->getVertsInv(mfz_avatar_gen::gender_t::female), bvvd);

  // 2 dim, double
  do_cv_check("Ranges_male", 3, bvi, bvd, c->getRanges(mfz_avatar_gen::gender_t::male));
  do_cv_check("Ranges_female", 3, bvi, bvd, c->getRanges(mfz_avatar_gen::gender_t::female));
  do_cv_check("Cov_male", 3, bvi, bvd, c->getCov(mfz_avatar_gen::gender_t::male));
  do_cv_check("Cov_female", 3, bvi, bvd, c->getCov(mfz_avatar_gen::gender_t::female));
  do_cv_check("Sv_male", 3, bvi, bvd, c->getSv(mfz_avatar_gen::gender_t::male));
  do_cv_check("Sv_female", 3, bvi, bvd, c->getSv(mfz_avatar_gen::gender_t::female));
  do_cv_check("SvInv_male", 3, bvi, bvd, c->getSvInv(mfz_avatar_gen::gender_t::male));
  do_cv_check("SvInv_female", 3, bvi, bvd, c->getSvInv(mfz_avatar_gen::gender_t::female));
  do_cv_check("SkV_male", 3, bvi, bvd, c->getSkV(mfz_avatar_gen::gender_t::male));
  do_cv_check("SkV_female", 3, bvi, bvd, c->getSkV(mfz_avatar_gen::gender_t::female));
  do_cv_check("BonW_male", 3, bvi, bvd, c->getBonW(mfz_avatar_gen::gender_t::male));
  do_cv_check("BonW_female", 3, bvi, bvd, c->getBonW(mfz_avatar_gen::gender_t::female));
  do_cv_check("BonWInv_male", 3, bvi, bvd, c->getBonWInv(mfz_avatar_gen::gender_t::male));
  do_cv_check("BonWInv_female", 3, bvi, bvd, c->getBonWInv(mfz_avatar_gen::gender_t::female));
}

#endif /* svr_encoder_hpp */