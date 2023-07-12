FROM cmake:focal-20221019

# Install Intel compilers and MKL library
ENV DEBIAN_FRONTEND="noninteractive"
RUN : \
    && apt update \
    && apt install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        wget \
    && wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
    | gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
    | tee /etc/apt/sources.list.d/oneAPI.list \
    && apt update \
    && apt install -y --no-install-recommends \
        intel-oneapi-compiler-dpcpp-cpp/all \
        intel-oneapi-compiler-fortran/all \
        intel-oneapi-mkl \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && :
