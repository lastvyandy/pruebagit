#==============================================================================
# BASE IMAGE 
# 
#==============================================================================
FROM python:3.11-slim-buster as base

# SET TIMEZONE
ENV TZ=America/Santiago

# Install BUILD_DEPS
ARG BUILD_DEPS="tzdata sudo gcc build-essential unixodbc-dev"
RUN apt update \
    && apt-get install -y ${BUILD_DEPS} \
    # Install pipenv
    && pip install pipenv \
    && rm -rf /var/lib/apt/lists/* \
    # SET TIMEZONE
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Creamos el usuario administrador de la app y nos aseguramos de que pueda ejecutar sudo
# Seteamos el nombre del usuario que usaremos en el container
# ENV USERNAME=appadmin
ARG USERNAME=appadmin
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd -g $USER_GID $USERNAME \
    && useradd -mr -u $USER_UID -g $USERNAME $USERNAME \
    && groupmod --gid $USER_GID $USERNAME \
    && usermod --uid $USER_UID --gid $USER_GID $USERNAME

RUN chown -R $USER_UID:$USER_GID /home/$USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

#==============================================================================
# DEVELOP IMAGE
# 
#==============================================================================
FROM base as develop_image

ARG USERNAME=appadmin

USER ${USERNAME}

# Esta variable de entorno hace que el directorio .venv creado por pipenv este en el directorio del proyecto
ENV PIPENV_VENV_IN_PROJECT=1

# creamos los directorios necesarios para la instalación de las extensiones de vs code
RUN mkdir -p /home/${USERNAME}/app \
    /home/${USERNAME}/.vscode-server/extensions \
    /home/${USERNAME}/.vscode-server-insiders/extensions \
    && chown -R ${USERNAME} \
    /home/${USERNAME}/app \
    /home/${USERNAME}/.vscode-server \
    /home/${USERNAME}/.vscode-server-insiders

WORKDIR /home/${USERNAME}/app

ENV PATH="/home/${USERNAME}/app/.venv/bin:${PATH}"

#==============================================================================
# PRODUCTION IMAGE
#
#==============================================================================
FROM base as deploy_image

ARG USERNAME=appadmin

USER ${USERNAME}

COPY --from=develop_image /home/${USERNAME}/app /home/${USERNAME}/app

WORKDIR /home/${USERNAME}/app
ENV PATH="/home/${USERNAME}/app/.venv/bin:${PATH}"