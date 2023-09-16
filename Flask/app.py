from flask import Flask, render_template
from waitress import serve
from os import path, walk


# creates a Flask application
app = Flask(__name__)
app.config["TEMPLATES_AUTO_RELOAD"] = True


@app.route("/")
def hello():
	message = "Hello, World"
	return render_template('goober.html',
						message=message)


# run the application
if __name__ == "__main__":
	serve(app, host='0.0.0.0', port=5020, threads=1, url_prefix='/sub', url_scheme='https')
