# SGXDPDK Firewall

A firewall application that leverages DPDK for performance and SGX for security.

## Requirement

Hardware:
- CPU: [SGX-supported hardwares](https://github.com/ayeks/SGX-hardware)
  - e.g., Intel i7-6700
- 10 GbE NIC: [DPDK-supported hardwares](https://core.dpdk.org/supported/)
  - e.g., Intel X540-AT2 

Software:
- Ubuntu 16.04.3 LTS
- [DPDK 17.05.2](http://git.dpdk.org/dpdk-stable/tag/?h=v17.05.2)
- [Intel SGX for Linux 2.1](https://github.com/intel/linux-sgx/tree/sgx_2.1)

## Build

### Install DPDK

Install DPDK 17.05.2 following [Getting Started Guide for Linux](https://doc.dpdk.org/guides-17.05/linux_gsg/index.html).

Make sure your can build and run DPDK sample applications before start building this project.

### Install SGX 

Install Intel SGX for Linux 2.1 following its [README](https://github.com/intel/linux-sgx/tree/sgx_2.1).

Make sure you have the full installation including [Intel SGX Linux Driver 2.1](https://github.com/intel/linux-sgx-driver/tree/sgx_driver_2.1) and you can run SGX sample applications before moving to the next steps.

### Build firewall

At first, export DPDK and SGX environment varibles (adjust according to your system)

```bash
export RTE_SDK=~/dpdk-stable-17.05.2
export RTE_TARGET=x86_64-native-linuxapp-gcc
export SGX_SDK=/opt/intel/sgxsdk
source $SGX_SDK/environment
```

Then, you can build this project for different targets

- Build the native version of firewall without SGX
    ```
    make native
    ```
    > This will generate a binary 'firewall_native' that does not need SGX support.
    > It is the unmodified version of DPDK ip_pipeline application.

- Build the SGX full-copy firewall in hardware release mode
    ``` 
    make SGX_PRERELEASE=1 SGX_DEBUG=0 ENABLE_FULL_COPY=1 ENABLE_INPUT_SKETCH=1
    ```
    > This will generate a binary `firewall_sgx` and a SGX enclave file `enclave.so`

- Build the SGX near-zero-copy firewall in hardware release mode
    ```
    make SGX_PRERELEASE=1 SGX_DEBUG=0 ENABLE_INPUT_SKETCH=1
    ```
    > This will generate a binary `firewall_sgx` and a SGX enclave file `enclave.so`

To clean the working directory, just run `make clean`. This is necessary when switching from one target to another.

If you want to build the SGX applications in simulation mode or other modes, check the [`Makefile`](https://github.com/Gnnng/sgxdpdk-firewall/blob/master/Makefile) for more information.

## Run

All three applications are developed based on DPDK sample application `ip_pipeline`. The `firewall` pipeline type is choosen in the config file `config/*.cfg`. Here's an example to run the application with port mask `1` and config file `config/sgx_firewall.cfg`. For the full explanation of the commandline options, check the `ip_pipeline` [doc](https://doc.dpdk.org/guides-17.05/sample_app_ug/ip_pipeline.html) (search for "Running the application").

```bash
# native version
sudo firewall_native -p1 -f config/sgx_firewall.cfg
# sgx version
sudo firewall_sgx -p1 -f config/sgx_firewall.cfg
```

## Documentation

- [DPDK 17.05.2 IP Pipeline Application User Guide](https://doc.dpdk.org/guides-17.05/sample_app_ug/ip_pipeline.html)
- [DPDK 17.05.2 Programmer's Guide](https://doc.dpdk.org/guides-17.05/prog_guide/index.html)
- [DPDK API reference](https://doc.dpdk.org/api/) (latest version, not 17.05.2)
- [SGX SDK 2.1 Documentation](https://download.01.org/intel-sgx/linux-2.1/docs/)

<!-- ## Citation

Our paper "Practical Verifiable In-network Filtering for DDoS defense" is now public at https://arxiv.org/abs/1901.00955. If you find our code useful, please consider citing the paper.
```
@misc{1901.00955,
Author = {Deli Gong and Muoi Tran and Shweta Shinde and Hao Jin and Vyas Sekar and Prateek Saxena and Min Suk Kang},
Title = {Practical Verifiable In-network Filtering for DDoS defense},
Year = {2019},
Eprint = {arXiv:1901.00955},
}
``` -->

## License

The project is licensed under [MIT License](https://github.com/Gnnng/sgxdpdk-firewall/blob/master/LICENSE).