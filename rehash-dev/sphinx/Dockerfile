FROM macbre/sphinxsearch

EXPOSE 9312

COPY ./sphinx.conf /sphinx.conf.in
COPY ./start.sh /

RUN mkdir /sphinx

ENTRYPOINT [ "/bin/sh", "/start.sh" ]
