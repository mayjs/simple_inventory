FROM python:slim
MAINTAINER Johannes May "johannes@may-se.de"

COPY ./requirements.txt /app/requirements.txt
WORKDIR /app
RUN pip install -r requirements.txt
COPY inventory_web.py /app

ENV INVENTORY_WEB_DATA_DIR /data

ENTRYPOINT [ "python" ]
CMD [ "inventory_web.py" ]
