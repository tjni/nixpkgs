{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  gfortran,
  fftwSinglePrec,
  doxygen,
  swig,
  enablePython ? false,
  python3Packages,
  enableOpencl ? true,
  opencl-headers,
  ocl-icd,
  config,
  enableCuda ? config.cudaSupport,
  cudaPackages,
  addDriverRunpath,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "openmm";
  version = "8.3.1";

  src = fetchFromGitHub {
    owner = "openmm";
    repo = "openmm";
    rev = finalAttrs.version;
    hash = "sha256-3e0+8f2V+UCrPJA1wQUZKPvjpmWU9FfOAt9Ako0Lnl0=";
  };

  # "This test is stochastic and may occasionally fail". It does.
  postPatch = ''
    rm \
      platforms/*/tests/Test*BrownianIntegrator.* \
      platforms/*/tests/Test*LangevinIntegrator.* \
      serialization/tests/TestSerializeIntegrator.cpp
  '';

  nativeBuildInputs = [
    cmake
    gfortran
    swig
    doxygen
    python3Packages.python
  ]
  ++ lib.optionals enablePython [
    python3Packages.build
    python3Packages.installer
    python3Packages.wheel
  ]
  ++ lib.optional enableCuda addDriverRunpath;

  buildInputs = [
    fftwSinglePrec
  ]
  ++ lib.optionals enableOpencl [
    ocl-icd
    opencl-headers
  ]
  ++ lib.optional enableCuda cudaPackages.cudatoolkit;

  propagatedBuildInputs = lib.optionals enablePython (
    with python3Packages;
    [
      setuptools
      python
      numpy
      cython
    ]
  );

  cmakeFlags = [
    "-DBUILD_TESTING=ON"
    "-DOPENMM_BUILD_AMOEBA_PLUGIN=ON"
    "-DOPENMM_BUILD_CPU_LIB=ON"
    "-DOPENMM_BUILD_C_AND_FORTRAN_WRAPPERS=ON"
    "-DOPENMM_BUILD_DRUDE_PLUGIN=ON"
    "-DOPENMM_BUILD_PME_PLUGIN=ON"
    "-DOPENMM_BUILD_RPMD_PLUGIN=ON"
    "-DOPENMM_BUILD_SHARED_LIB=ON"
  ]
  ++ lib.optionals enablePython [
    "-DOPENMM_BUILD_PYTHON_WRAPPERS=ON"
  ]
  ++ lib.optionals enableOpencl [
    "-DOPENMM_BUILD_OPENCL_LIB=ON"
    "-DOPENMM_BUILD_AMOEBA_OPENCL_LIB=ON"
    "-DOPENMM_BUILD_DRUDE_OPENCL_LIB=ON"
    "-DOPENMM_BUILD_RPMD_OPENCL_LIB=ON"
  ]
  ++ lib.optionals enableCuda [
    "-DCUDA_SDK_ROOT_DIR=${cudaPackages.cudatoolkit}"
    "-DOPENMM_BUILD_AMOEBA_CUDA_LIB=ON"
    "-DOPENMM_BUILD_CUDA_LIB=ON"
    "-DOPENMM_BUILD_DRUDE_CUDA_LIB=ON"
    "-DOPENMM_BUILD_RPMD_CUDA_LIB=ON"
    "-DCMAKE_LIBRARY_PATH=${cudaPackages.cudatoolkit}/lib64/stubs"
  ];

  postInstall = lib.strings.optionalString enablePython ''
    export OPENMM_LIB_PATH=$out/lib
    export OPENMM_INCLUDE_PATH=$out/include
    cd python
    ${python3Packages.python.pythonOnBuildForHost.interpreter} -m build --no-isolation --outdir dist/ --wheel
    ${python3Packages.python.pythonOnBuildForHost.interpreter} -m installer --prefix $out dist/*.whl
  '';

  postFixup = ''
    for lib in $out/lib/plugins/*CUDA.so $out/lib/plugins/*Cuda*.so; do
      addDriverRunpath "$lib"
    done
  '';

  # Couldn't get CUDA to run properly in the sandbox
  doCheck = !enableCuda && !enableOpencl;

  meta = with lib; {
    description = "Toolkit for molecular simulation using high performance GPU code";
    mainProgram = "TestReferenceHarmonicBondForce";
    homepage = "https://openmm.org/";
    license = with licenses; [
      gpl3Plus
      lgpl3Plus
      mit
    ];
    platforms = platforms.linux;
    maintainers = [ maintainers.sheepforce ];
  };
})
