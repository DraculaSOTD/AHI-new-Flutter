
#include <cereal/types/vector.hpp>
#include <cereal/types/memory.hpp>
#include <cereal/archives/portable_binary.hpp>
#include <iostream>
#include <sstream>
#include "svr.hpp"

#ifndef svr_encoder_hpp
#define svr_encoder_hpp

// SVR class

struct AHIModelSVR {
  std::string                         name;
  std::vector< std::vector<double> >  vectors;
  std::vector< double >               coefficients;
  std::vector< double >               intercepts;

  template <class Archive>
  void serialize( Archive & ar ) {
    ar( name, vectors, coefficients, intercepts );
  }
};


void encode_svrs() {
  for (auto svr_name : svrs) {
    std::cout << "Encoding SVR model " << svr_name << " ... " << std::endl;
    AHIModelSVR svr;
    svr.name = svr_name;
    svr.vectors = getVectors(svr_name);
    svr.coefficients = getCoefficients(svr_name);
    svr.intercepts = getIntercepts(svr_name);
    // std::cout << svr_name << " [0][0] = " << svr.vectors[0][0] << std::endl;
    std::ostringstream oss;
    oss << "../Encoded/" << svr_name << ".cereal";
    std::string s = oss.str();
    // Serialize
    std::ofstream os(s, std::ios::binary);
    cereal::PortableBinaryOutputArchive archive(os);
    archive(svr);
  }
}


bool do_svr_check(const AHIModelSVR &svr, const std::string &svr_name) {
  // Name
  if (svr.name.compare(svr_name) != 0) {
    return false;
  }
  // Vectors
  std::vector< std::vector<double> > vec = getVectors(svr_name);
  for (size_t x = 0; x < vec.size(); ++x) {
    for (size_t y = 0; y < vec[x].size(); ++y) {
      if (vec[x][y] != svr.vectors[x][y]) {
        return false;
      }
    }
  }
  // Coefficients
  std::vector<double> coeff = getCoefficients(svr_name);
  for (size_t i = 0; i < coeff.size(); ++i) {
    if (coeff[i] != svr.coefficients[i]) {
      return false;
    }
  }
  // Intercepts
  std::vector<double> inter = getIntercepts(svr_name);
  for (size_t i = 0; i < inter.size(); ++i) {
    if (inter[i] != svr.intercepts[i]) {
      return false;
    }
  }
  // Done
  return true;
}


void verify_svrs() {
  for (auto svr_name : svrs) {
    std::cout << "Verifying SVR model " << svr_name << " ... ";
    std::ostringstream oss;
    oss << "../Encoded/" << svr_name << ".cereal";
    std::string s = oss.str();
    // De-Serialize
    std::ifstream is(s);
    cereal::PortableBinaryInputArchive archive(is);
    // Read into object
    AHIModelSVR svr;
    archive(svr);
    // Validate
    if (do_svr_check(svr, svr_name)) {
      std::cout << "OK" << std::endl;
    } else {
      std::cout << "FAILED" << std::endl;
    }
  }
}

#endif /* svr_encoder_hpp */