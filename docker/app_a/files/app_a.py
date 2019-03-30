from flask import Flask, request
import requests
from prometheus_flask_exporter import PrometheusMetrics

application = Flask(__name__)
metrics = PrometheusMetrics(application)
metrics.info('app_info', 'Application info', version='1.0.3')

@application.route('/hello')
def hello():
    return 'Hello there'


@application.route('/jobs', methods=['POST'])
def jobs():
    token = request.headers['Authorization']
    data = {"token": token}
    result = requests.post('http://0.0.0.0:5001/auth', data=data).content
    if result == "density":
        return 'Jobs:\nTitle: Devops\nDescription: Awesome\n'
    else:
        return "fail"


if __name__ == "__main__":
    application.run(host='0.0.0.0', port=5000)
