# ベースイメージから始めます
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

# Pythonバージョンの指定
ARG python_version="3.11.7"

# シェルの設定
SHELL ["bash", "-c"]

# 環境変数の設定
ENV HOME /root

# パッケージのアップデートとインストール
RUN apt update \
    && apt -y upgrade \
    && apt install -y git curl wget build-essential libssl-dev libffi-dev libncurses5-dev zlib1g zlib1g-dev libreadline-dev libbz2-dev libsqlite3-dev liblzma-dev

# pyenvのインストール
RUN curl https://pyenv.run | bash
ENV PYENV_ROOT $HOME/.pyenv
ENV PATH $PATH:$PYENV_ROOT/bin:$PYENV_ROOT/shims

# pyenvの設定
RUN echo 'eval "$(pyenv init -)"' >> $HOME/.bashrc

# 作業ディレクトリの設定
WORKDIR /workdir

# Python環境のセットアップ
COPY ./requirements.txt ./requirements.txt
RUN pyenv install ${python_version} \
    && pyenv global ${python_version} \
    && pip install -r requirements.txt 


# Anacondaのインストール
RUN wget https://repo.anaconda.com/archive/Anaconda3-2023.07-2-Linux-x86_64.sh \
    && bash Anaconda3-2023.07-2-Linux-x86_64.sh -b  \
    && rm Anaconda3-2023.07-2-Linux-x86_64.sh 

# パスの設定
ENV PATH /root/anaconda3/bin:$PATH

# Anacondaのアップデート
RUN conda update conda -y \
    && conda update --all -y

RUN pip install -r requirements.txt

RUN pip install -i https://pypi.org/simple/ bitsandbytes


RUN apt install -y openssh-server
# SSHサーバーの設定
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# ポートの公開
EXPOSE 8888 22

# 起動スクリプトの作成
CMD service ssh start && \
    jupyter lab --ip=0.0.0.0 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password='' --NotebookApp.allow_origin='*'
