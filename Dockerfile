# syntax=docker/dockerfile-upstream:master-labs
FROM ubuntu:jammy

# args
ARG PROJECT="Jupyter-Covasim"
ARG PACKAGES="git mc htop neovim gcc supervisor curl nginx"

# miniconda
ARG CONDASETUP=Miniconda3-py39_22.11.1-1-Linux-x86_64.sh
ARG CONDAURL=https://repo.anaconda.com/miniconda/${CONDASETUP}
ARG CONDADIR="/miniconda"
ARG CONDAENV=juco
ARG CONDA_PREFIX=${CONDADIR}/envs/${CONDAENV}
ARG CONDADEPS=requirements.yaml

# miniconda environment
ENV PATH=${CONDADIR}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CONDA_PREFIX}/lib/:$LD_LIBRARY_PATH

# covasim
ARG COVASIM_DIR=/covasim
ARG COVASIM_WEBAPP="https://github.com/InstituteforDiseaseModeling/covasim_webapp.git"
ARG COVASIM_APP="https://github.com/InstituteforDiseaseModeling/covasim.git"
ARG COVASIM_APP_TAG="v3.1.4"  # add empty string to clone latest files

### setup env for using conda
ENV PATH="/miniconda/bin:${PATH}"

### install packages
RUN apt update && apt install -y ${PACKAGES}

## install miniconda
ADD --checksum=sha256:e685005710679914a909bfb9c52183b3ccc56ad7bb84acc861d596fcbe5d28bb ${CONDAURL} /
RUN chmod a+x /${CONDASETUP}
RUN /bin/bash /${CONDASETUP} -b -p ${CONDADIR} # /bin/bash workaround for defect shellscript

## update conda if current version is not up-to-date
RUN conda update -n base -c defaults conda

# copy conda dependency files for generation at build time (not at start-up time)
ADD --chown=1000:root assets/${CONDADEPS} /root

## setup conda environment
WORKDIR /root

# conda specific dependencies
RUN conda env create -f ${CONDADEPS}

# init conda prompt
RUN conda init bash

# setup default conda environment in containers
RUN echo 'conda activate juco' >> ~/.bashrc

## let all RUN's after the following line run within the conda environment
SHELL [ "conda", "run", "-n", "juco", "/bin/bash", "--login", "-c" ]

# update conda to prevent error: No module named '_sysconfigdata_x86_64_conda_linux_gnu'
RUN ${CONDADIR}/bin/conda update python

# create covasim webapp directory
RUN mkdir ${COVASIM_DIR}

# copy nginx site configuration
COPY ./assets/docker_nginx.conf /etc/nginx/sites-enabled/default

# copy supervisord config
COPY ./assets/supervisord.conf /etc/

### clone git repository
RUN git clone --depth=1 -b ${COVASIM_APP_TAG} ${COVASIM_APP} ${COVASIM_DIR}/covasim
RUN git clone --depth=1 ${COVASIM_WEBAPP} ${COVASIM_DIR}/webapp

# install covasim
WORKDIR ${COVASIM_DIR}/covasim
RUN python3 -m pip install .

# bytecode compile python libraries to improve startup times
RUN python3 -m compileall $(python3 -c "import covasim,os;print(os.path.dirname(covasim.__file__))" | tail -n 1)
RUN cd data && ./run_scrapers

WORKDIR ${COVASIM_DIR}/webapp
RUN python3 -m pip install .

WORKDIR /notebooks

## volumes
VOLUME [ "/notebooks" ]
VOLUME [ "/root/.cache" ] # cache volume (pip3) (avoid pip installs)

# jupyter notebook
EXPOSE 8888/tcp

# covasim webapp
EXPOSE 8000/tcp