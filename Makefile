.DEFAULT_GOAL := help
##help: List available tasks on this project
help:
	@echo ""
	@echo "These are the available commands"
	@echo ""
	@grep -E '\#\#[a-zA-Z\.\-]+:.*$$' $(MAKEFILE_LIST) \
		| tr -d '##' \
		| awk 'BEGIN {FS = ": "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}' \

##up: Start dockers
.PHONY:up
up:
	docker compose up -d --build --remove-orphans -t 0

##down: Down dockers
.PHONY:down
down:
	docker compose down -t 0

##build: Build dockers
.PHONY:build
build:
	docker compose build --no-cache