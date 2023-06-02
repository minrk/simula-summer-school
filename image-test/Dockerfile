ARG IMAGE
FROM ${IMAGE}
COPY --chown=${NB_UID} . /test
WORKDIR /test
ENV PYTHONUNBUFFERED=1
CMD ["pytest", "-v"]
