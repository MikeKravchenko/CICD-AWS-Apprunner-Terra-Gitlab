# REQURED ENV:
# NAME - name of the application
# PORT - port to bind

FROM python:3.11

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY s3_write.py .

CMD ["python", "s3_write.py"]
