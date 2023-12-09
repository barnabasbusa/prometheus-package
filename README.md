Prometheus Package
============
This is a [Kurtosis](https://github.com/kurtosis-tech/kurtosis/) package for starting a Prometheus server.

Run this package
----------------
If you have [Kurtosis installed][install-kurtosis], run:

```bash
kurtosis run github.com/kurtosis-tech/prometheus-package
```

If you don't have Kurtosis installed, [click here to run this package on the Kurtosis playground](https://gitpod.io/?autoStart=true&editor=code#https://github.com/kurtosis-tech/playground-gitpod).

To blow away the created [enclave][enclaves-reference], run `kurtosis clean -a`.

#### Configuration

<details>
    <summary>Click to see configuration</summary>

You can configure this package using the JSON structure below. The default values for each parameter are shown.

NOTE: the `//` lines are not valid JSON; you will need to remove them!

# TODO: change these for metrics jobs
```javascript
{
    // The name to print
    "name": "John Snow"
}
```

The arguments can then be passed in to `kurtosis run`.

For example:

```bash
kurtosis run github.com/kurtosis-tech/prometheus-package '{"name":"Maynard James Keenan"}'
```

You can also store the JSON args in a file, and use `--args-file` flag to slot them in:

```bash
kurtosis run github.com/kurtosis-tech/prometheus-package --args-file args.json
```

</details>

Use this package in your package
--------------------------------
Kurtosis packages can be composed inside other Kurtosis packages. To use this package in your package:

First, import this package by adding the following to the top of your Starlark file:

```python
# For remote packages: 
prometheus = import_module("github.com/kurtosis-tech/prometheus-package/main.star") 
```

If you want to use a fork or specific version of this package in your own package, you can replace the dependencies in your `kurtosis.yml` file using the [replace](https://docs.kurtosis.com/concepts-reference/kurtosis-yml/#replace) primitive. 
Within your `kurtosis.yml` file:
```python
name: github.com/example-org/example-repo
replace:
    github.com/kurtosis-tech/prometheus-package: github.com/YOURUSER/THISREPO@YOURBRANCH
```

Then, call the this package's `run` function somewhere in your Starlark script:

```python

# TODO: add code giving an example of setting up the metrics jobs
prometheus_url = prometheus-package.run(plan, args)
```

Develop on this package
-----------------------
1. [Install Kurtosis][install-kurtosis]
1. Clone this repo
1. For your dev loop, run `kurtosis clean -a && kurtosis run .` inside the repo directory


<!-------------------------------- LINKS ------------------------------->
[install-kurtosis]: https://docs.kurtosis.com/install
[enclaves-reference]: https://docs.kurtosis.com/concepts-reference/enclaves
