FROM node:4.8.3
MAINTAINER himmel17

# ENV http_proxy=http://proxy.atg.sony.co.jp:10080/
# ENV https_proxy=https://proxy.atg.sony.co.jp:10080/
# RUN npm -g config set proxy http://proxy.atg.sony.co.jp:10080 && \
# 	npm -g config set https-proxy https://proxy.atg.sony.co.jp:10080 && \
# 	npm config set strict-ssl false && \
# 	npm -g config set registry http://registry.npmjs.org/

# RUN npm install -g coffee-script yo generator-hubot  &&  \
# 	useradd hubot -m
RUN npm install -g coffee-script yo generator-hubot

ARG user_name="hubot"
ARG user_id=1001
ARG group_name="rsd"
ARG group_id=1001

# ユーザ設定
# ユーザID,グループIDをパラメータにすることでホストボリュームに対する操作を
# ユーザ権限で実行できるようにしている．
RUN groupadd -g ${group_id} ${group_name} && \
	useradd --create-home --shell /bin/bash \
	--uid ${user_id} --gid ${group_id} --home-dir /home/${user_name} \
	${user_name}

ENV BOT_NAME="bot"
ENV BOT_OWNER="No owner specified"
ENV BOT_DESC="Hubot with rocketbot adapter"

ENV ROCKETCHAT_URL=43.30.154.37:3000
ENV ROCKETCHAT_ROOM="general"
ENV ROCKETCHAT_USER="bot"
ENV ROCKETCHAT_PASSWORD="botpassword"

USER hubot
WORKDIR /home/hubot

# ENV EXTERNAL_SCRIPTS=hubot-diagnostics,hubot-help,hubot-google-images,hubot-google-translate,hubot-pugme,hubot-maps,hubot-rules,hubot-shipit
ENV EXTERNAL_SCRIPTS=hubot-diagnostics,hubot-help,hubot-google-images,hubot-google-translate,hubot-pugme,hubot-maps,hubot-rules,hubot-shipit,hubot-seen,hubot-links,hubot-mongodb-brain,hubot-rss-reader

RUN yo hubot --owner="$BOT_OWNER" --name="$BOT_NAME" --description="$BOT_DESC" --defaults && \
	sed -i /heroku/d ./external-scripts.json && \
	sed -i /redis-brain/d ./external-scripts.json && \
	npm install --save hubot-scripts

ADD . /home/hubot/node_modules/hubot-rocketchat

# hack added to get around owner issue: https://github.com/docker/docker/issues/6119
USER root
RUN chown hubot:hubot -R /home/hubot/node_modules/hubot-rocketchat
USER hubot

RUN cd /home/hubot/node_modules/hubot-rocketchat && \
	npm install --save && \
	#coffee -c /home/hubot/node_modules/hubot-rocketchat/src/*.coffee && \
	cd /home/hubot

CMD node -e "console.log(JSON.stringify('$EXTERNAL_SCRIPTS'.split(',')))" > external-scripts.json && \
	npm install --save $(node -e "console.log('$EXTERNAL_SCRIPTS'.split(',').join(' '))") && \
	bin/hubot -n $BOT_NAME -a rocketchat
