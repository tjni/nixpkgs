{ lib
, fetchFromGitHub
, buildPythonPackage
, pillow
, pytestCheckHook
, setuptools
, wheel
}:

buildPythonPackage rec {
  pname = "captcha";
  version = "0.5.0";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "lepture";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-TPPuf0BRZPSHPSF0HuGxhjhoSyZQ7r86kSjkrztgZ5w=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  propagatedBuildInputs = [ pillow ];

  pythonImportsCheck = [ "captcha" ];

  nativeCheckInputs = [ 
    pytestCheckHook
  ];

  meta = with lib; {
    description = "A captcha library that generates audio and image CAPTCHAs";
    homepage = "https://github.com/lepture/captcha";
    license = licenses.bsd3;
    maintainers = with maintainers; [ Flakebi ];
  };
}
