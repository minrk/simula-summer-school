ARG IMAGE
FROM ${IMAGE}
RUN python3 -m pip install pytest psutil
COPY --chown=${NB_UID} . /test
WORKDIR /test
ENV PYTHONUNBUFFERED=1
CMD ["pytest"]
