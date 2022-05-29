#!/usr/bin/bash

echo "Directory name: $1"

activate(){
  . venv/bin/activate
}

fileinitpy() {
  cat << EOF > __init__.py
from flask import Flask, request, jsonify
from flask_cors import CORS
from ariadne import graphql_sync
from ariadne.constants import PLAYGROUND_HTML
from app.api import schema
from app.config.default import Dev

app = Flask(__name__)
CORS(app)
app.config.from_object(Dev)

@app.route('/api', methods=["GET"])
def graphql_playground():
  return PLAYGROUND_HTML, 200


@app.route("/api", methods=["POST"])
def graphql_server():
  data = request.get_json()
  success, result = graphql_sync(
    schema,
    data,
    context_value=request,
    debug = app.debug
  )
  status_code = 200 if success else 400
  return jsonify(result), status_code

EOF
}

fileapiinit() {
  cd api
  cat << EOF > __init__.py
from os import path
from ariadne import (
  load_schema_from_path,
  make_executable_schema,
  snake_case_fallback_resolvers,
  ObjectType
)
from app.api.mtation.greeting import greeting
from app.api.queries.sayhi import say_hi

mutation = ObjectType("Mutation")
query = ObjectType("Query")

mutation.set_field('greeting', greeting)
query.set_field('sayhi', say_hi)

type_defs = load_schema_from_path("app/api/schemas/schema.graphql")
schema = make_executable_schema(
    type_defs, query, mutation, snake_case_fallback_resolvers
)
EOF
  cd ..
}

filegreating() {
  cd api/mtation
  cat << EOF > greeting.py
from app.handler.constant.defreps import def_respond


def greeting(obj, info, **kwargs):
  payload = def_respond('greeting')

  try:
    payload['status'] = True
    payload['messag'] = kwargs['said']
  except Exception as e:
    payload['messag'] = f"Greeting: {str(e)}"

  return payload
EOF
  cd ../../
}

filesyahi() {
  cd api/queries
  cat << EOF > sayhi.py
from app.handler.constant.defreps import def_respond


def say_hi(obj, info, **kwargs):
  payload = def_respond('say_hi')

  try:
    payload['status'] = True
    payload['messag'] = 'Ok'
  except Exception as e:
    payload['messag'] = f"sayhi: {str(e)}"

  return payload
EOF
  cd ../../
}

fileschema() {
  cd api/schemas
  cat << EOF > schema.graphql

type defresps {
  status            : Boolean
  messag            : String
  topath            : String
}


type Query {
  sayhi: defresps!
}

type Mutation {
  greeting(said: String!): defresps!
}
EOF
  cd ../../
}

defrespond() {
  cd handler/constant
  cat << EOF > defreps.py
def def_respond(topath):
  resps = {
    'status': False,
    'messag': 'Try again!',
    'topath': topath
  }

  return resps
EOF
  cd ../../
}

configdef() {
  cd config
  cat << EOF > default.py
class Config(object):
  TESTING=False
  DEBUG=False

class Dev(Config):
  DEBUG=True

class Pro(Config):
  pass

EOF
  cd ..
}

makedir(){
  mkdir app
  cd app
  fileinitpy
  mkdir api assets config db handler
  fileapiinit
  mkdir api/mtation
  filegreating
  mkdir api/queries
  filesyahi
  mkdir api/schemas
  fileschema
  mkdir handler/constant
  defrespond
  configdef
}

installlib() {
  pip3 install flask flask-cors ariadne
  pip3 freeze > requirements.txt
  makedir
}

filerunpy(){
  cat << EOF > run.py
from app import app
if __name__ == '__main__':
  app.run(host='localhost', port=8080)
EOF
}

virtualenv(){
  filerunpy
  python3 -m venv venv
  activate
  installlib
}



parent() {
  mkdir "$1"
  cd "$1"
  virtualenv
}

if [ -d "$1" ]
then
  echo "$1/ exists. Use unique directory name"
else
  parent $1
  echo "\n"
  echo "================================================"
  echo "| cd $1 and type python3 run.py             |"
  echo "| Type http://127.0.0.1:8080/api on browser    |"
  echo "================================================"
fi
