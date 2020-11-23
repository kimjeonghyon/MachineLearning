import typing as t

from marshmallow import Schema, fields, ValidationError

from api import config

from pprint import pprint

class InvalidInputError(Exception):
    """Invalid model input."""

SYNTAX_ERROR_FIELD_MAP = {
    '6~7_ride': 'ride_6_7',
    '7~8_ride': 'ride_7_8',
    '8~9_ride': 'ride_8_9',
    '9~10_ride': 'ride_9_10',
    '10~11_ride': 'ride_10_11',
    '11~12_ride': 'ride_11_12',
    '6~7_takeoff': 'takeoff_6_7',
    '7~8_takeoff': 'takeoff_7_8',
    '8~9_takeoff': 'takeoff_8_9',
    '9~10_takeoff': 'takeoff_9_10',
    '10~11_takeoff': 'takeoff_10_11',
    '11~12_takeoff': 'takeoff_11_12'
}

# SYNTAX_ERROR_FIELD_MAP_SWAP = { value:key for key, value in SYNTAX_ERROR_FIELD_MAP.items()}

# 모델 1 : 입력 변수 스키마
class JBPPSchema(Schema):
    in_out = fields.Integer()
    latitude = fields.Float()
    longitude = fields.Float()
    ride_6_7 = fields.Float()
    ride_7_8 = fields.Float()
    ride_8_9 = fields.Float()
    ride_9_10 = fields.Float()
    ride_10_11 = fields.Float()
    ride_11_12 = fields.Float()
    takeoff_6_7 = fields.Float()
    takeoff_7_8 = fields.Float()
    takeoff_8_9 = fields.Float()
    takeoff_9_10 = fields.Float()
    takeoff_10_11 = fields.Float()
    takeoff_11_12 = fields.Float()
    weekday_0 = fields.Integer()
    weekday_1 = fields.Integer()
    weekday_2 = fields.Integer()
    weekday_3 = fields.Integer()
    weekday_4 = fields.Integer()
    weekday_5 = fields.Integer()
    weekday_6 = fields.Integer()
    dis_jejusi = fields.Float()
    dis_seoquipo = fields.Float()


def _filter_error_rows(errors: dict,
                       validated_input: t.List[dict]
                       ) -> t.List[dict]:
    """Remove input data rows with errors."""

    indexes = errors.keys()
    for index in sorted(indexes, reverse=True):
        del validated_input[index]
    return validated_input


def validate_inputs(input_data):
    """Check prediction inputs against schema."""

    schema = JBPPSchema(strict=True,many=True)
    errors = None

    for dict in input_data:
        for key, value in SYNTAX_ERROR_FIELD_MAP.items():
            dict[value] = dict[key]
            del dict[key]

    errors = None
    try:
        schema.load(input_data)
    except ValidationError as exc:
        errors = exc.messages

    for dict in input_data:
        for key, value in SYNTAX_ERROR_FIELD_MAP.items():
            dict[key] = dict[value]
            del dict[value]

    if errors:
        validated_input = _filter_error_rows(
            errors=errors,
            validated_input=input_data)
    else:
        validated_input = input_data

    return validated_input, errors
