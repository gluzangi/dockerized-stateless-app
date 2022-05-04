FROM node:16.14

# set app ENV_VAR
ENV NODE_ENV production
ENV NPM_CONFIG_LOGLEVEL info

# create app directory
WORKDIR /usr/src/app

# bundle and build production ready app sourcecode
COPY app/ .
RUN npm ci --only-production

# set container port and init script
EXPOSE 80 
EXPOSE 8080

CMD ["npm", "start"]
