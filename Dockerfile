FROM python:3.7
WORKDIR /app
COPY app.py /app
RUN pip install flask
CMD ["python", "app.py"]
