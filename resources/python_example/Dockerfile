FROM alpine

RUN apk update
RUN apk add python3

EXPOSE 8000

CMD ["/usr/bin/python3","-m","http.server","8000"]
