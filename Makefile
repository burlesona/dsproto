db:
	rethinkdb

app:
	rerun --pattern "{*.rb,config.ru}" rackup
