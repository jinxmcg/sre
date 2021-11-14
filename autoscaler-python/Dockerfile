FROM python:3.9-slim-bullseye
RUN groupadd -r camunda && useradd --no-log-init -ms /bin/bash -r -g camunda camunda
USER camunda
WORKDIR /home/camunda
ENV PYTHONUNBUFFERED=1
ENV PATH="/home/camunda/.local/bin:${PATH}"
COPY --chown=camunda:camunda requirements.txt requirements.txt
RUN pip install --user --upgrade pip
RUN /home/camunda/.local/bin/pip install --user --no-cache-dir -r requirements.txt
COPY --chown=camunda:camunda ./src .
CMD [ "python3", "main.py"]