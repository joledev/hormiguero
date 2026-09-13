{
  description = "Hormiguero - arena de colonias programables";

  inputs = {
    # ANCLADO A nixos-26.05, NO A unstable, y es una desviacion deliberada
    # respecto a lo que dice el ticket ANT-2.
    #
    # El motivo es elixir-ls. El servidor de lenguaje vive en el sistema
    # (~/nixos-config, modules/development.nix) y sale de nixpkgs 26.05:
    # concretamente esta construido con Elixir 1.18.5 sobre OTP 27.3.4.17.
    # ElixirLS no solo lee el codigo, lo COMPILA por dentro para saber que
    # funciones existen. Si el devShell trajera un Elixir de otra rama, el
    # editor estaria compilando el proyecto con un Elixir distinto del que
    # usa `mix` en la terminal, y eso se manifiesta como diagnosticos
    # fantasma que no reproduces al compilar a mano.
    #
    # De regalo: al ser la MISMA revision que el sistema, todos estos
    # paquetes ya estan en el /nix/store de esta maquina. El primer
    # `nix develop` no descarga la cadena BEAM, entra al instante.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Fijamos Erlang/OTP 27 y sobre el, Elixir 1.18.
        #
        # Se toma el conjunto `beam.packages.erlang_27` entero en vez de
        # `pkgs.elixir` y `pkgs.erlang` sueltos porque esos dos NO CASAN: el
        # default de nixpkgs es OTP 28.5.0.6 para `erlang`, mientras que
        # `pkgs.elixir` 1.18.5 esta compilado contra OTP 27.3.4.17. Pelados
        # tendrias `erl` de una version y un Elixir que por dentro arrastra
        # otra. Del conjunto salen emparejados por construccion.
        beam = pkgs.beam.packages.erlang_27;
        elixir = beam.elixir_1_18;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            elixir
            beam.erlang
            beam.hex

            # Phoenix recompila al guardar usando inotify en Linux.
            pkgs.inotify-tools

            # Cliente de Postgres para hablarle al contenedor. Es SOLO el
            # cliente que hace falta (psql, pg_dump): el servidor corre en
            # Docker, no aqui.
            pkgs.postgresql_17

            pkgs.docker-compose
            pkgs.gh
            pkgs.git
          ];

          shellHook = ''
            # Mantiene las dependencias de Mix y Hex dentro del proyecto,
            # en vez de ensuciar tu $HOME.
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex
            export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH

            # Erlang necesita un locale UTF-8 o se queja al arrancar.
            export LANG=C.UTF-8
            export ERL_AFLAGS="-kernel shell_history enabled"

            echo "hormiguero devShell"
            echo "  elixir  $(elixir --version | tail -1)"
            echo "  erlang  OTP $(erl -noshell -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt().')"
          '';
        };
      });
}
