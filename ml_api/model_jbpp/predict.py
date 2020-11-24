import numpy as np
import pandas as pd
from model_jbpp.processing.data_management import load_pipeline
from model_jbpp.config import config
from model_jbpp import __version__ as _version

import logging
import typing as t
_logger = logging.getLogger(__name__)

pipeline_file_name = f"{config.PIPELINE_SAVE_FILE}{_version}.pkl"
_price_pipe = load_pipeline(file_name=pipeline_file_name)


def make_prediction(*, input_data: t.Union[pd.DataFrame, dict],
                    ) -> dict:
    """Make a prediction using a saved model pipeline.

    Args:
        input_data: Array of model prediction inputs.

    Returns:
        Predictions for each input row, as well as the model version.
    """
    data = pd.DataFrame(input_data)

    output = _price_pipe.predict(data)

    results = {"predictions": output, "version": _version}

    _logger.info(
        f"Making predictions with model version: {_version} "
        f"Inputs: {input_data} "
        f"Predictions: {results}"
    )

    return results
