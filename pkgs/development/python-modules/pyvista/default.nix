{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  matplotlib,
  numpy,
  pillow,
  pooch,
  pythonAtLeast,
  scooby,
  setuptools,
  typing-extensions,
  vtk,
}:

buildPythonPackage rec {
  pname = "pyvista";
  version = "0.45.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pyvista";
    repo = "pyvista";
    tag = "v${version}";
    hash = "sha256-9N1dF/zwjzoxX4xYIr5084M9pAk3YK3T48OUnCoC0NU=";
  };

  build-system = [ setuptools ];

  dependencies = [
    matplotlib
    numpy
    pillow
    pooch
    scooby
    typing-extensions
    vtk
  ];

  # Fatal Python error: Aborted
  doCheck = false;

  pythonImportsCheck = [ "pyvista" ];

  meta = with lib; {
    broken = pythonAtLeast "3.13"; # segfault
    description = "Easier Pythonic interface to VTK";
    homepage = "https://pyvista.org";
    changelog = "https://github.com/pyvista/pyvista/releases/tag/${src.tag}";
    license = licenses.mit;
    maintainers = with maintainers; [ wegank ];
  };
}
