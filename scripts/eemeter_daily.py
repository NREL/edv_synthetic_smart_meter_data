#!/usr/bin/env python
# -*- coding: utf-8 -*-

import eemeter
import sys
import logging
import json
import pytz
import pprint

from pkg_resources import resource_stream
from eemeter.io import meter_data_from_csv, temperature_data_from_csv
from dateutil.parser import parse as parse_date

def bsync_total_meter_saving(meter_data_file, metadata_file):
    """
    Return total meter savings with bsync xml time-series metered data.
    """

    # Load baseline data from csv:
    with open(meter_data_file) as csv:
        meter_data = meter_data_from_csv(csv, gzipped=False, freq="daily")
    print("meter data: ", meter_data)

    with resource_stream("eemeter.samples", "il-tempF.csv.gz") as csv:
        temperature_data = temperature_data_from_csv(csv, gzipped=True, freq="hourly")
    print("temperature data: ", temperature_data)

    with open(metadata_file, "r") as j:
        data = json.load(j)
        baseline_start_date = pytz.UTC.localize(parse_date(data["baseline_start_date"]))
        baseline_end_date = pytz.UTC.localize(parse_date(data["baseline_end_date"]))

    baseline_meter_data, warnings = eemeter.get_baseline_data(
        meter_data, start=baseline_start_date, end=baseline_end_date, max_days=None
    )
    print("baseline meter data: ", baseline_meter_data)

    # create a design matrix for baseline dataset
    baseline_design_matrix = eemeter.create_caltrack_daily_design_matrix(
        baseline_meter_data, temperature_data,
    )
    print("baseline design matrix: ", baseline_design_matrix)

    # Run CalTRACK Daily Methods:
    baseline_model = eemeter.fit_caltrack_usage_per_day_model(
        baseline_design_matrix,
    )

    baseline_model.candidates = [baseline_model.model]
    print("CalTRACK Baseline model results:")
    print(json.dumps(baseline_model.json(with_candidates=True), indent=4,sort_keys=True))

    """
    print("CalTRACK model results in json:")
    pprint.pprint(eemeter.CalTRACKUsagePerDayModelResults(
        status="SUCCESS",
        method_name="caltrack_usage_per_day",
        interval="daily",
        model=baseline_model.model,
        r_squared_adj=baseline_model.r_squared_adj,
        # candidates=baseline_model.candidates,
        candidates=[baseline_model.model],
        warnings=warnings,
        settings={
            "fit_cdd": True,
            "minimum_non_zero_cdd": 10,
            "minimum_non_zero_hdd": 10,
            "minimum_total_cdd": 20,
            "minimum_total_hdd": 20,
            "beta_cdd_maximum_p_value": 1,
            "beta_hdd_maximum_p_value": 1,
        },
    ).json(with_candidates=True))
    """
    # Plot baseline meter data:
    ax = eemeter.plot_energy_signature(baseline_meter_data, temperature_data, title="Baseline")
    data = ax.collections[0].get_offsets()
    print("Plot data: ", data.shape, ax.get_title())

    with open(metadata_file, "r") as f:
        data = json.load(f)
        report_start_date = pytz.UTC.localize(parse_date(data["report_start_date"]))
        report_end_date = pytz.UTC.localize(parse_date(data["report_end_date"]))

    # Get a year of reporting period data
    reporting_meter_data, warnings = eemeter.get_reporting_data(
        meter_data, start=report_start_date, end=report_end_date, max_days=None
    )
    print("reporting meter data: ", reporting_meter_data)
    # Compute metered savings
    metered_savings_dataframe, error_bands = eemeter.metered_savings(
        baseline_model, reporting_meter_data,
        temperature_data, with_disaggregated=True
    )
    print("metered savings dataframe: ", metered_savings_dataframe)

    # Total metered savings
    total_metered_savings = metered_savings_dataframe.metered_savings.sum()
    print("total metered savings: ", total_metered_savings)

    return total_metered_savings


if __name__ == "__main__":
    meter_data_file = metadata_file = ""
    if len(sys.argv) == 3:
        meter_data_file = sys.argv[1]
        metadata_file = sys.argv[2]
    else:
        logging.error("ERROR - Missing input meter data file")

    bsync_total_meter_saving(meter_data_file, metadata_file)
