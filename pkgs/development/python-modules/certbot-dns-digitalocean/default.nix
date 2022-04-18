{ buildPythonPackage
, acme
, certbot
, python-digitalocean
, pytestCheckHook
, pythonOlder
}:

buildPythonPackage rec {
  pname = "certbot-dns-digitalocean";

  inherit (certbot) src version;
  disabled = pythonOlder "3.6";

  propagatedBuildInputs = [
    acme
    certbot
    python-digitalocean
  ];

  checkInputs = [
    pytestCheckHook
  ];

  pytestFlagsArray = [ "-o cache_dir=$(mktemp -d)" ];

  sourceRoot = "source/certbot-dns-digitalocean";

  meta = certbot.meta // {
    description = "DigitalOcean DNS Authenticator plugin for Certbot";
  };
}
