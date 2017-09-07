# This Dockerfile uses Docker Multi-Stage Builds
# See https://docs.docker.com/engine/userguide/eng-image/multistage-build/

### Base Image
# Setup up a base image to use in Build and Runtime images
FROM node:8.4.0-alpine AS base

WORKDIR /app
COPY package.json .

### Build Image
# Installs build dependencies and npm packages
# Creates artifacts to copy into Runtime image
FROM base AS build

# Install build OS packages
RUN set -ex && \
        buildDeps=' \
                make \
                gcc \
                g++ \
                python \
                py-pip \
                curl \
                openssl \
        ' && \
    apk add --no-cache \
       --virtual .build-deps $buildDeps

#Copy application into build image
COPY . .

# Install npm packages
RUN npm install -g
RUN npm install --silent --save-dev -g \
       gulp-cli \
       typescript

# Compile typescript sources to javascript artifacts
RUN tsc --target es5 connector.ts

### Runtime Image
# Copy artifacts from Build image and setups up entrypoint/cmd to run app
FROM base AS runtime

# Copy artifacts from Build Image
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/*.js ./
COPY --from=build /app/LICENSE ./

# Runtime command
ENTRYPOINT ["node"]
CMD ["connector.js"]
