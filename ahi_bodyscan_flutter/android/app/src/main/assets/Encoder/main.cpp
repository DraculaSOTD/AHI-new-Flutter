/* main.cpp */

#include <stdio.h>
#include <iostream>

#include <fstream>

#include "encoder_sv.hpp"
#include "encoder_cv.hpp"

// MAIN
int main(int argc, char* argv[])
{
  // SVR models
  std::cout << std::endl;
  std::cout << "#### ENCODE SVRs ####" << std::endl;
  encode_svrs();
  std::cout << std::endl;
  verify_svrs();
  std::cout << std::endl;

  // CV models
  std::cout << std::endl;
  std::cout << "#### ENCODE CVs ####" << std::endl;
  encode_cvs();
  std::cout << std::endl;
  verify_cvs();
  std::cout << std::endl;

  return 0;
}
