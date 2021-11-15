FROM python:3.9-slim-bullseye

# create user and group to run the scaler
RUN groupadd -r camunda && useradd --no-log-init -ms /bin/bash -r -g camunda camunda
USER camunda

# remove the output buffer so we can see logs in realtime
ENV PYTHONUNBUFFERED=1
# preadd the path of the user pip install to the PATH
ENV PATH="/home/camunda/.local/bin:${PATH}"

WORKDIR /home/camunda

# copy the requirements.txt and install
COPY --chown=camunda:camunda requirements.txt requirements.txt
RUN pip install --user --no-cache-dir -r requirements.txt

# copy source code last so it is rebuilt only when changed
COPY --chown=camunda:camunda ./src .
CMD [ "python3", "main.py"]