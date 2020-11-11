FROM docker

RUN apk add -U \
	aws-cli \
	curl

RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" \
	&& chmod +x ./kubectl \
	&& mv ./kubectl /usr/local/bin/kubectl

WORKDIR /app

COPY ./src/ .

RUN chmod +x prepull.sh

ENTRYPOINT exec /app/prepull.sh
