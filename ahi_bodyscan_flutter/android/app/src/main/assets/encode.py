#!/usr/bin/env python3

""" Serialize all model datasets into Cereal encoded files.
"""

from __future__ import print_function
from pathlib import Path
import os
import sys
import shutil

# {0} - CPP file name, eg: MFZAvatarGenJointModel.
# {1} - The CoreML model name.
# {2} - The byte array size.
mdl_header = """
//
//  AHI
//
//  Copyright (c) AHI. All rights reserved.
//

#ifndef {0}_hpp
#define {0}_hpp

#include <stdio.h>
#include <vector>

namespace ahi_ml_gen {{

  const size_t N_{1}   =   {2};

    class {0} {{
    private:
    // Model data
        static const uint8_t c_{1}[N_{1}];
    // Model wrapper
        std::vector<uint8_t> m_{1};
    // Singleton constructor
        {0}(void);                   // Don't Implement.
        {0}({0} const&);             // Don't Implement.
        void operator=({0} const&);  // Don't implement
    public:
        // Singleton methods
        static {0} *getInstance(void) {{
            static {0} instance;
            return &instance;
        }}
        // Class methods
        std::vector<uint8_t> &get_{1}(void) const;
    }};

}}

#endif /* {0}_hpp */
"""

# {0} - CPP file name, eg: MFZAvatarGenJointModel.
# {1} - The CoreML model name.
# {2} - The byte array dump of the mlmodel.
mdl_source = """
//
//  AHI
//
//  Copyright (c) AHI. All rights reserved.
//

#include "{0}.hpp"

using namespace ahi_ml_gen;

// Class methods

{0}::{0}(void) : m_{1}(c_{1}, c_{1} + sizeof(c_{1}) / sizeof(uint8_t))
{{ }}

std::vector<uint8_t> &{0}::get_{1}(void) const {{
    return const_cast<std::vector<uint8_t>&>(m_{1});
}}

// Model data

const uint8_t {0}::c_{1}[N_{1}] = {{
  {2}
}};

"""

# {0} - List of SVR includes
svr_header = """
#ifndef svr_hpp
#define svr_hpp

#include <stdio.h>
#include <vector>
#include <string>

{0}

std::string svrs[] = {{
{1}
}};

std::vector< std::vector<double> > getVectors(std::string svr) {{
    std::vector< std::vector<double> > returnVector;
    if (false) {{
        // do nothing
    }}
    {2}
    return returnVector;
}}


std::vector< double > getCoefficients(std::string svr) {{
    std::vector< double > returnVector;
    if (false) {{
        // do nothing
    }}
    {3}
    return returnVector;
}}

std::vector< double > getIntercepts(std::string svr) {{
    std::vector< double > returnVector;
    if (false) {{
        // do nothing
    }}
    {4}
    return returnVector;
}}

#endif /* svr_hpp */
"""

# {0} - Name of the SVR
svr_include = "#include \"{0}.hpp\"\n"

svr_get_vector = """
    else if (svr == \"{0}\") {{
      size_t countRows = sizeof({0}::vectors)/sizeof({0}::vectors[0]);
      for (int idx = 0; idx < countRows; idx++) {{
        returnVector.push_back(std::vector<double>(std::begin({0}::vectors[idx]), std::end({0}::vectors[idx])));
      }}
    }}
"""

svr_get_coefficients = """
    else if (svr == \"{0}\") {{
      returnVector = std::vector<double>(std::begin({0}::coefficients), std::end({0}::coefficients));
    }}
"""

svr_get_intercepts = """
    else if (svr == \"{0}\") {{
      returnVector = std::vector<double>(std::begin({0}::intercepts), std::end({0}::intercepts));
    }}
"""


def main(arguments):
    # Get root directory
    dir_path = os.path.dirname(os.path.realpath(__file__))
    root_path = Path(dir_path).joinpath('Models')
    # Scan directory for .mlmodel files
    for file_path in root_path.glob('*.mlmodel'):
        if file_path.is_file():
            dest_path = Path( os.path.dirname(file_path) ).joinpath('..').joinpath('Encoded').joinpath( os.path.basename(file_path) )
            shutil.copyfile(file_path, dest_path)
    # Scan directory for SVR .hpp files
    svr_includes = []
    hpp_path = None
    for file_path in root_path.glob('*svr*.hpp'):
        if file_path.is_file():
            namespace_name = None
            with open(file_path, 'r') as header_file:
                for header_line in header_file:
                    if "namespace" in header_line:
                        header_line_components = header_line.split('{')
                        if len(header_line_components) > 0:
                            namespace_components = header_line_components[0].split(' ')
                        if len(namespace_components) > 1:
                            namespace_name = namespace_components[1]
                            break
            if namespace_name is None:
                print("Error finding name")
                continue
            hpp_path = Path( os.path.dirname(file_path) ).joinpath('..').joinpath('Encoder').joinpath('svr.hpp')
            dest_path = Path( os.path.dirname(file_path) ).joinpath('..').joinpath('Encoder').joinpath(namespace_name + '.hpp')
            shutil.copyfile(file_path, dest_path)
            svr_includes.append( namespace_name )
            # Write SVR includes file
            svr_includes_block = ""
            svr_names_block = ""
            svr_vectors_block = ""
            svr_coeff_block = ""
            svr_inters_block = ""
    for svr in svr_includes:
        svr_includes_block += svr_include.format(svr)
        svr_names_block += f"  \"{svr}\", \n"
        svr_vectors_block += svr_get_vector.format(svr)
        svr_coeff_block += svr_get_coefficients.format(svr)
        svr_inters_block += svr_get_intercepts.format(svr)
        svr_includes_header = svr_header.format(svr_includes_block, svr_names_block, svr_vectors_block, svr_coeff_block, svr_inters_block)
    with open(hpp_path, 'w') as f:
        f.write(svr_includes_header)
    # Older MFZ Avatar CV models
    for file_path in root_path.glob('MFZAvatarGen*'):
        if file_path.is_file():
            dest_path = Path( os.path.dirname(file_path) ).joinpath('..').joinpath('Encoder').joinpath( os.path.basename(file_path) )
            shutil.copyfile(file_path, dest_path)
    # Encode to Cereal
    os.chdir("Encoder")
    os.system("plz run //:ahi_bs_encoder")

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
