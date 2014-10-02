db:
	mongod --dbpath ./mongo_data

app:
	rerun --pattern "{*.rb,config.ru}" rackup
