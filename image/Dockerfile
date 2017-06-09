FROM jupyter/scipy-notebook:bb222f49222e

ADD environment.yml .
RUN conda env update -n root environment.yml \
 && rm environment.yml

ADD requirements.txt .
RUN pip install --no-cache -r requirements.txt \
 && rm requirements.txt

WORKDIR /home/$NB_USER
# ENTRYPOINT []
CMD start-singleuser.sh
