from flask import Blueprint, request, jsonify
# 모델 1. 제주 퇴근시간 버스승차인원예측 (jeju_bus_passenser_predict)
from model_jbpp import __version__ as _version
from model_jbpp.predict import make_prediction
# 모델 2.
# _version
# make_prediction

import os
from werkzeug.utils import secure_filename

from api.config import get_logger
from api.validation import validate_inputs
from api import __version__ as api_version

_logger = get_logger(logger_name=__name__)


prediction_app = Blueprint('prediction_app', __name__)


@prediction_app.route('/health', methods=['GET'])
def health():
    if request.method == 'GET':
        _logger.info('health status OK')
        return 'ok'


@prediction_app.route('/version', methods=['GET'])
def version():
    if request.method == 'GET':
        return jsonify({'model_version': _version,
                        'api_version': api_version})

# 모델 1. 제주 퇴근시간 버스승차인원예측 (jeju_bus_passenser_predict)
@prediction_app.route('/predict/jbpp', methods=['POST'])
def predict_jbpp():
    if request.method == 'POST':

        json_data = request.get_json()
        _logger.debug(f'Inputs: {json_data}')

        input_data, errors = validate_inputs(input_data=json_data)

        result = make_prediction(input_data=input_data)
        _logger.debug(f'Outputs: {result}')

        predictions = result.get('predictions').tolist()
        version = result.get('version')

        return jsonify({'predictions': predictions,
                        'version': version,
                        'errors': errors})


# 모델 2.
# @prediction_app.route('/predict/####', methods=['POST'])
# def predict_####():
