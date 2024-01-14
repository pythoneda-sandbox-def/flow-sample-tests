# pythoneda-sandbox/flow-sample-tests

Definition of <https://github.com/pythoneda-sandbox/flow-sample-tests>.

## How to run the tests

``` sh
nix run https://github.com/pythoneda-sandbox-def/flow-sample-tests
```

## How to declare it in your flake

Check the latest tag of this repository and use it instead of the `[version]` placeholder below.

```nix
{
  description = "[..]";
  inputs = rec {
    [..]
    pythoneda-sandbox-flow-sample-tests = {
      [optional follows]
      url =
        "github:pythoneda-sandbox-def/flow-sample-tests/[version]";
    };
  };
  outputs = [..]
};
```

Should you use another PythonEDA modules, you might want to pin those also used by this project. The same applies to [nixpkgs](https://github.com/nixos/nixpkgs "nixpkgs") and [flake-utils](https://github.com/numtide/flake-utils "flake-utils").

Use the specific package depending on your system (one of `flake-utils.lib.defaultSystems`) and Python version:

- `#packages.[system].pythoneda-sandbox-flow-sample-tests-python38` 
- `#packages.[system].pythoneda-sandbox-flow-sample-tests-python39` 
- `#packages.[system].pythoneda-sandbox-flow-sample-tests-python310` 
- `#packages.[system].pythoneda-sandbox-flow-sample-tests-python311` 
