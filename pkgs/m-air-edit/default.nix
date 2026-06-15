{
  lib,
  stdenv,
  fetchurl,
  alsa-lib,
  curl,
  autoPatchelfHook,
  libusb1,
  avahi,
  openssl,
  freetype,
  libGL,
}:

let

  digilentPackages = import ../../data/packages.nix;
  inherit (digilentPackages.m-air-edit) version systems;
  srcInfo = systems.${stdenv.targetPlatform.system};

in

stdenv.mkDerivation rec {
  pname = "m-air-edit";
  inherit version;

  src = fetchurl {
    inherit (srcInfo) url hash;
    curlOptsList = [
      "-A"
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
    ];
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    alsa-lib
    libusb1
    avahi
    openssl
    curl
    freetype
    libGL
  ];

  unpackCmd = "mkdir out; tar -xf $curSrc --directory out";

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    ls
    cp -a M-AIR-Edit $out/bin/m-air-edit

    # ACTION=="add", ATTR{idVendor}=="0403", ATTR{manufacturer}=="Digilent", GROUP="plugdev", TAG+="uaccess", RUN+="$out/sbin/dftdrvdtch %s{busnum} %s{devnum}"

    runHook postInstall
  '';

  dontAutoPatchelf = true;

  postFixup = ''
    autoPatchelf "$out"

    for lib in $(find "$out/lib" -type f); do
      lib_rpath="$(patchelf --print-rpath "$lib")"
      echo "Adding self to RPATH of library $lib"
      patchelf --set-rpath "$out/lib:$lib_rpath" "$lib"
    done;
  '';

  meta = with lib; {
    description = "M-AIR-EDIT";
    homepage = "https://midasconsoles.com/en/products/0605-aaf";
    downloadPage = "https://cdn-media.empowertribe.com/7862d36048ce4d9a8facf7210591093c/";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = builtins.attrNames systems;
  };
}
