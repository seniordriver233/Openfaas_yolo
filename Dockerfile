FROM ghcr.io/openfaas/classic-watchdog:0.2.2 as watchdog
FROM python

#FROM alpine:3.13
#ADD https://github.com/openfaas/faas/releases/download/0.18.10/fwatchdog /usr/bin
COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog



# Add non root user
RUN useradd -ms /bin/bash app

WORKDIR /home/app/

COPY mid6.mp4           .
COPY index.py           .
COPY requirements.txt   .

#YOLOv5
#RUN git clone https://github.com/ultralytics/yolov5.git
#RUN wget https://github.com/ultralytics/yolov5/releases/download/v7.0/yolov5n.pt
#RUN pip install -r requirements.txt --target=/home/app/python
#RUN python yolov5/export.py --weights YOLOv5n.pt --include onnx


RUN chown -R app /home/app && \
  mkdir -p /home/app/python && chown -R app /home/app
USER app
ENV PATH=$PATH:/home/app/.local/bin:/home/app/python/bin/
ENV PYTHONPATH=$PYTHONPATH:/home/app/python

RUN pip install -r requirements.txt --target=/home/app/python
RUN pip install opencv-python-headless -i https://pypi.tuna.tsinghua.edu.cn/simple

RUN mkdir -p function
RUN touch ./function/__init__.py

WORKDIR /home/app/

USER root

WORKDIR /home/app/darknet



#YOLOv3
RUN wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names 
RUN wget https://raw.githubusercontent.com/pjreddie/darknet/master/cfg/yolov3.cfg 
RUN wget -q https://pjreddie.com/media/files/yolov3.weights

WORKDIR /home/app/

COPY function function

RUN chown -R app:app ./ && \
  chmod -R 777 /home/app/python

USER app

ENV fprocess="python3 index.py"
EXPOSE 8080

HEALTHCHECK --interval=3s CMD [ -e /tmp/.lock ] || exit 1

CMD ["fwatchdog"]
