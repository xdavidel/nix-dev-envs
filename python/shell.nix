{
  pkgs ?
  # If pkgs is not defined, instanciate nixpkgs from locked commit
  let
    lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    nixpkgs = fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";

      sha256 = lock.narHash;
    };
  in
    import nixpkgs {},
  ...
}: let
  /*
  Change this value ({major}.{min}) to
  update the Python virtual-environment
  version. When you do this, make sure
  to delete the `.venv` directory to
  have the hook rebuild it for the new
  version, since it won't overwrite an
  existing one. After this, reload the
  development shell to rebuild it.
  You'll see a warning asking you to
  do this when version mismatches are
  present. For safety, removal should
  be a manual step, even if trivial.
  */
  version = "3.13";

  concatMajorMinor = v:
    pkgs.lib.pipe v [
      pkgs.lib.versions.splitVersion
      (pkgs.lib.sublist 0 2)
      pkgs.lib.concatStrings
    ];
  python = pkgs."python${concatMajorMinor version}";
in
  pkgs.mkShell {
    venvDir = ".venv";

    postShellHook = ''
      venvVersionWarn() {
      	local venvVersion
      	venvVersion="$("$venvDir/bin/python" -c 'import platform; print(platform.python_version())')"

      	[[ "$venvVersion" == "${python.version}" ]] && return

      	cat <<EOF
      Warning: Python version mismatch: [$venvVersion (venv)] != [${python.version}]
               Delete '$venvDir' and reload to rebuild for version ${python.version}
      EOF
      }

      venvVersionWarn
    '';

    packages = with python.pkgs; [
      venvShellHook
      pip

      # Add whatever else you'd like here.
      # pkgs.basedpyright

      # pkgs.black
      # or
      # python.pkgs.black

      # pkgs.ruff
      # or
      # python.pkgs.ruff
    ];
  }
