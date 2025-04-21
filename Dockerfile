# Stage1: Builder阶段
FROM python:3.9-slim as builder

WORKDIR /app

#设置国内加速源(适用于中国用户)
RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip install --user --no-cache-dir -r requirements.txt

# Stage2: Runtime阶段
FROM python:3.9-slim

WORKDIR /app

#仅复制必要文件(排除开发文件)
COPY --from=builder /root/.local /root/.local
COPY --from=builder /usr/lib/x86_64-linux-gnu/libpq.so* /usr/lib/x86_64-linux-gnu/
COPY . .

#确保PATH包含用户安装目录
ENV PATH=/root/.local/bin:$PATH

#声明服务端口(按需修改)
EXPOSE 5000

CMD ["gunicorn", "--config", "gunicorn_conf.py", "wsgi:app"]
