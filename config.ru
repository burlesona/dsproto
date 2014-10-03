require_relative './initializer'

# Setup Root Router
map('/'){ run Docserver::APIRouter }
