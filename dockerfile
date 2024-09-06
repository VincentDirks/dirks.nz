FROM node:16
EXPOSE 3000

RUN mkdir /app
WORKDIR /app
COPY . /app/

RUN npm install