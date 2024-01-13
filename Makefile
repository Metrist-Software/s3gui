.PHONY: dev run db.reset

# If you want to run under IEx, simply do `make ELIXIR=iex run` or `run2`
ELIXIR = elixir

# `make dev` is pretty much what you would do after a reboot
dev:
	docker-compose up -d
	docker cp simplesamlphp-setup/saml20-sp-remote.php idp:/var/www/simplesamlphp/metadata/saml20-sp-remote.php
	docker cp simplesamlphp-setup/authsources.php idp:/var/www/simplesamlphp/config/authsources.php
	docker-compose restart idp
	sudo apt -y install libxml2-utils
	epmd -daemon
	mix deps.get

# `make dev-setup` is for a fresh checkout
dev-setup: dev db.reset
	./cert-setup.sh

# Release locks that pgAdmin, ... probably is holding by resetting
# docker-compose before we reset the dev and test databases
db.reset:
	docker-compose restart
	MIX_ENV=dev make do.db.reset

do.db.reset:
	mix ecto.reset

run_backend:
	npm install --prefix assets
	mix ecto.migrate
	${ELIXIR_ACTION} --sname ${ELIXIR_SNAME} -S mix phx.server

run:
	make ELIXIR_ACTION=$(ELIXIR) ELIXIR_SNAME=first run_backend

run2:
	make ELIXIR_ACTION=$(ELIXIR) ELIXIR_SNAME=second PORT=4444 run_backend

run.iex:
	make ELIXIR_ACTION=iex ELIXIR_SNAME=first run_backend

run2.iex:
	make ELIXIR_ACTION=iex ELIXIR_SNAME=second PORT=4444 run_backend
