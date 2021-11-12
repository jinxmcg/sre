FROM python:3.9-slim-bullseye
WORKDIR /app
COPY requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt
COPY ./src .
CMD [ "python3", "main.py"]