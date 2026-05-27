# Official Cline Kanban Docker deployment
# https://docs.cline.bot/guides/remote-access#docker-deployment

FROM node:22

WORKDIR /app

EXPOSE 3484

CMD ["npx", "--yes", "kanban@latest", "--host", "0.0.0.0"]
